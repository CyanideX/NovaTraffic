math.randomseed(os.time())

local params = require('params')
local Cron = require('Cron')
local NovaTraffic = {}
local modVersion = "1.0.0"
local categories = { "common", "rare", "exotic", "badlands", "special" }
local currentVehicleToSwap = { common = 1, rare = 1, exotic = 1, badlands = 1, special = 1 }
local currentVehicleToSwapTo = { common = 1, rare = 1, exotic = 1, badlands = 1, special = 1 }
local initialDelay = { common = 1.0, rare = 2.0, exotic = 3.0, badlands = 4.0, special = 5.0 }
local isInitialReplacementDone = { common = false, rare = false, exotic = false, badlands = false, special = false }
local vehiclesToSwap = { common = {}, rare = {}, exotic = {}, badlands = {}, special = {} }
local vehiclesToSwapTo = { common = {}, rare = {}, exotic = {}, badlands = {}, special = {} }

local swapDelayRange = { common = { min = 500.0, max = 600.0 }, rare = { min = 100.0, max = 120.0 }, exotic = { min = 2.0, max = 3.0 }, badlands = { min = 150.0, max = 600.0 }, special = { min = 105.0, max = 600.0 } }

local function scaleSwapDelay(category)
    local range = swapDelayRange[category]
    return ((range.max - range.min) / currentVehicleToSwap[category]) + range.min
end

local function parseJsonArray(json)
    local array = {}
    for name in string.gmatch(json, '{ "name": "([^"]+)" }') do
        array[#array + 1] = name
    end
    return array
end

local function shuffleArray(array)
    for i = #array, 2, -1 do
        local j = math.random(i)
        array[i], array[j] = array[j], array[i]
    end
end

function is_valid_json(str)
    local success, result = pcall(json.decode, str)
    return success and type(result) == 'table'
end

local settings =
{
	Current = {
		debugOutput = true,
	},
	Default = {
		debugOutput = true,
	}
}

function debugPrint(message)
    if settings.Current.debugOutput then
        print(IconGlyphs.CarHatchback .. " Nova Traffic: " .. message)
    end
end

-- Register a CET hotkey to toggle debug output
registerHotkey("NTDebugToggle", "Toggle Console Debug", function()
    settings.Current.debugOutput = not settings.Current.debugOutput
    print(IconGlyphs.CarHatchback .. " Nova Traffic: Debug output " .. (settings.Current.debugOutput and "enabled" or "disabled"))
    SaveSettings()
end)

local function loadVehicleFile(filePath, category, vehicleTable)
    local file = io.open(filePath, 'r')
    if file then
        local content = file:read('*all')
        file:close()

        if content == "" then
            debugPrint("Warning: File " .. filePath .. " is empty. Swapping may not work correctly.")
        else
            local vehicles = parseJsonArray(content)

            -- Check if the vehicles array is empty or not
            if #vehicles == 0 then
                debugPrint("Warning: No valid entries in " .. filePath .. ". Skipping this file.")
                return
            end

            for _, vehicle in ipairs(vehicles) do
                if TweakDB:GetFlat(vehicle .. ".entityTemplatePath") then
                    vehicleTable[category][#vehicleTable[category] + 1] = vehicle
                end
            end
            shuffleArray(vehicleTable[category])
        end
    else
        debugPrint("Error: File not found - " .. filePath .. ". Creating an empty one.")
        file = io.open(filePath, 'w')
        local sampleLayout =
        '[\n  \n]'
        file:write(sampleLayout)
        file:close()
    end
end

function checkFolder(folder)
    local files = dir(folder)
    local customVehiclesLoaded = false
    for _, file in ipairs(files) do
        local extension = file.name:match("^.+(%..+)$")
        if extension == ".json" then
            local file2 = io.open(folder .. '/' .. file.name, 'r')
            if file2 then
                local content = file2:read('*all')
                if not is_valid_json(content) then
                    debugPrint('Failed to load mod vehicles.')
                end
                file2:close()
                local customVehicles = parseJsonArray(content)
                for _, vehicle in ipairs(customVehicles) do
                    if TweakDB:GetFlat(vehicle.name .. '.entityTemplatePath') ~= nil then
                        vehicleTable["exotic"][#vehicleTable["exotic"] + 1] = vehicle.name
                        debugPrint("Loaded custom vehicle: " .. vehicle.name)
                        customVehiclesLoaded = true
                    end
                end
            else
                return
            end
        else
            debugPrint('Skipping file without json extension in' .. folder)
        end
    end
    if not customVehiclesLoaded then
        debugPrint("No custom folder vehicles loaded!")
    end
end

registerForEvent("onInit", function()
    LoadSettings()
    
    for _, category in ipairs(categories) do
        if category == "exotic" then
            checkFolder("custom")
        end

        -- Load modded vehicles
        loadVehicleFile(
            'swapToModded/moddedVehicles' ..
            string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2) .. '.json', category, vehiclesToSwapTo)

        -- Load user vehicles
        loadVehicleFile('userVehicles/userVehicles' ..
            string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2) .. '.json', category, vehiclesToSwap)

        -- Load vanilla vehicles
        loadVehicleFile(
            'swapToVanilla/vanillaVehicles' ..
            string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2) .. '.json', category, vehiclesToSwapTo)

        -- Load vehicles to swap
        loadVehicleFile(
            'swapFromVanilla/vehiclesToSwap' ..
            string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2) .. '.json', category, vehiclesToSwap)
    end
end)

local function formatVehicleName(vehicle)
    local name = vehicle:gsub("Vehicle%.v_[^_]+_", ""):gsub("_", " ")
    return name:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end)
end

local function replace(initialVehicle, newVehicle)
    if TweakDB:GetFlat(initialVehicle .. ".isReplaced") then
        return
    end
    for _, param in ipairs(params) do
        TweakDB:SetFlatNoUpdate(initialVehicle .. "." .. param, TweakDB:GetFlat(newVehicle .. "." .. param))
    end
    TweakDB:Update(initialVehicle)
    TweakDB:SetFlat(initialVehicle .. ".isReplaced", true)
    TweakDB:SetFlatNoUpdate('Vehicle.v_standard2_archer_hella.entityTemplatePath',
        'base//vehicles//custom//v_custom_archer_hella_combat_cab.ent')
    TweakDB:SetFlatNoUpdate('Vehicle.v_standard2_chevalier_thrax.entityTemplatePath',
        'base//vehicles//custom//v_custom_chevalier_thrax_combat_cab.ent')
end

local function vehicleReplacement(category)
    -- Shuffle the current vehicles to swap and to swap to
    currentVehicleToSwap[category] = math.random(#vehiclesToSwap[category])
    currentVehicleToSwapTo[category] = math.random(#vehiclesToSwapTo[category])

    local vehicleToSwap = vehiclesToSwap[category][currentVehicleToSwap[category]]
    local vehicle = vehiclesToSwapTo[category][currentVehicleToSwapTo[category]]

    -- Check if the vehicle to swap is the same as the vehicle to swap to
    while vehicleToSwap == vehicle do
        -- If they are the same, get the next vehicle in the list to swap to
        currentVehicleToSwapTo[category] = (currentVehicleToSwapTo[category] % #vehiclesToSwapTo[category]) + 1
        vehicle = vehiclesToSwapTo[category][currentVehicleToSwapTo[category]]
    end

    replace(vehicleToSwap, vehicle)
    debugPrint("Swapped " .. formatVehicleName(vehicleToSwap) .. " (" .. category:upper() .. ") with " .. formatVehicleName(vehicle) .. " (" .. category:upper() .. ")")

    currentVehicleToSwap[category] = (currentVehicleToSwap[category] % #vehiclesToSwap[category]) + 1
    currentVehicleToSwapTo[category] = (currentVehicleToSwapTo[category] % #vehiclesToSwapTo[category]) + 1
    if currentVehicleToSwap[category] == 1 then
        shuffleArray(vehiclesToSwap[category])
    end
    if currentVehicleToSwapTo[category] == 1 then
        shuffleArray(vehiclesToSwapTo[category])
    end

    local delay = scaleSwapDelay(category)
    Cron.After(delay, function() vehicleReplacement(category) end)
end

registerForEvent("onUpdate", function(delta)
    Cron.Update(delta)
    for category, _ in pairs(currentVehicleToSwap) do
        if not isInitialReplacementDone[category] and currentVehicleToSwap[category] == 1 and currentVehicleToSwapTo[category] == 1 then
            Cron.After(initialDelay[category], function() vehicleReplacement(category) end)
            isInitialReplacementDone[category] = true
        end
    end
end)

local function DrawGUI()
    -- Check if the CET window is open
	if not cetOpen then
		return
	end

    if ImGui.Begin("Nova Traffic - v" .. modVersion, true, ImGuiWindowFlags.NoScrollbar) then
        ImGui.Dummy(0, 10)
        ImGui.Text("Debug:")
        ImGui.Separator()
        ImGui.Dummy(0, 10)

        local changed
        settings.Current.debugOutput, changed = ImGui.Checkbox("Debug Console Output", settings.Current.debugOutput)
        if changed then
            print(IconGlyphs.CarHatchback .. " Nova Traffic: Toggled debug output to " .. tostring(settings.Current.debugOutput))
            SaveSettings()
        end
        ImGui.Dummy(0, 10)
    end
end

registerForEvent("onDraw", function()
    DrawGUI()
end)

registerForEvent("onOverlayOpen", function()
    cetOpen = true
end)

registerForEvent("onOverlayClose", function()
    cetOpen = false
end)

function SaveSettings()
    local saveData = {
        debugOutput = settings.Current.debugOutput,
    }

    local file = io.open("settings.json", "w")
    if file then
        file:write(json.encode(saveData))
        file:close()
        print(IconGlyphs.CarHatchback .. " Nova Traffic: Settings saved successfully")
    else
        print(IconGlyphs.CarHatchback .. " Nova Traffic: ERROR - Unable to open file for writing")
    end
end

function LoadSettings()
    local file = io.open("settings.json", "r")
    local saveNeeded = false

    if file then
        local content = file:read("*all")
        file:close()
        local loadedSettings = json.decode(content)
        
        -- Check for missing parameters and set defaults if necessary
        if loadedSettings.debugOutput == nil then
            loadedSettings.debugOutput = settings.Default.debugOutput
            saveNeeded = true
        end

        settings.Current.debugOutput = loadedSettings.debugOutput

        if saveNeeded then
            SaveSettings()
            print(IconGlyphs.CarHatchback .. " Nova Traffic: Settings loaded and updated successfully")
        else
            print(IconGlyphs.CarHatchback .. " Nova Traffic: Settings loaded successfully")
        end
    else
        print(IconGlyphs.CarHatchback .. " Nova Traffic: Settings file not found")
        print(IconGlyphs.CarHatchback .. " Nova Traffic: Creating default settings file")
        SaveSettings()
    end
end


return NovaTraffic
