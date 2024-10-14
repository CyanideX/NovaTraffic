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
        swapDelay = {
            common = 30,
            rare = 90,
            exotic = 120,
            badlands = 120,
            special = 180
        }
    },
    Default = {
        debugOutput = true,
        swapDelay = {
            common = 30,
            rare = 90,
            exotic = 120,
            badlands = 120,
            special = 180
        }
    }
}

function debugPrint(message)
    if settings.Current.debugOutput then
        print(IconGlyphs.CarHatchback .. " Nova Traffic: " .. message)
    end
end

local function loadVehicleFiles(folder, category, vehicleTable)
    local files = dir(folder)
    local customVehiclesLoaded = false
    for _, file in ipairs(files) do
        local extension = file.name:match("^.+(%..+)$")
        if extension == ".json" then
            local file2 = io.open(folder .. '/' .. file.name, 'r')
            if file2 then
                local content = file2:read('*all')
                file2:close()

                if content == "" then
                    debugPrint("Warning: File " .. file.name .. " is empty. Swapping may not work correctly.")
                elseif not is_valid_json(content) then
                    debugPrint('Failed to load mod vehicles.')
                else
                    local vehicles = parseJsonArray(content)
                    if #vehicles == 0 then
                        debugPrint("Warning: No valid entries in " .. file.name .. ". Skipping this file.")
                    else
                        for _, vehicle in ipairs(vehicles) do
                            if TweakDB:GetFlat(vehicle .. ".entityTemplatePath") then
                                vehicleTable[category][#vehicleTable[category] + 1] = vehicle
                                customVehiclesLoaded = true
                            end
                        end
                        shuffleArray(vehicleTable[category])
                    end
                end
            else
                debugPrint("Error: File not found - " .. file.name .. ". Creating an empty one.")
                file2 = io.open(folder .. '/' .. file.name, 'w')
                local sampleLayout = '[\n  \n]'
                file2:write(sampleLayout)
                file2:close()
            end
        else
            debugPrint('Skipping file without json extension in ' .. folder)
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
            loadVehicleFiles("custom", category, vehiclesToSwapTo)
        end

        -- Load modded vehicles
        loadVehicleFiles('swapToModded', category, vehiclesToSwapTo)

        -- Load user vehicles
        loadVehicleFiles('userVehicles', category, vehiclesToSwap)

        -- Load vanilla vehicles
        loadVehicleFiles('swapToVanilla', category, vehiclesToSwapTo)

        -- Load vehicles to swap
        loadVehicleFiles('swapFromVanilla', category, vehiclesToSwap)
    end
end)

local function formatVehicleName(vehicle)
    return vehicle:gsub("Vehicle%.v_[^_]+_", ""):gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end)
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
    TweakDB:SetFlatNoUpdate('Vehicle.v_standard2_archer_hella.entityTemplatePath', 'base//vehicles//custom//v_custom_archer_hella_combat_cab.ent')
    TweakDB:SetFlatNoUpdate('Vehicle.v_standard2_chevalier_thrax.entityTemplatePath', 'base//vehicles//custom//v_custom_chevalier_thrax_combat_cab.ent')
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

    local delay = settings.Current.swapDelay[category] -- Use the user settings for swap delay
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

        ImGui.Text("Swap delay timers (in seconds):")
        for _, category in ipairs(categories) do
            local swapDelay = settings.Current.swapDelay[category]
            swapDelay, changed = ImGui.SliderInt(string.sub(category, 1, 1):upper() .. string.sub(category, 2) .. "##", swapDelay, 1, 600)
            if changed then
                settings.Current.swapDelay[category] = swapDelay
                SaveSettings()
                -- Update the swap delay immediately
                isInitialReplacementDone[category] = false
            end
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
        swapDelay = settings.Current.swapDelay
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

        if loadedSettings.swapDelay == nil then
            loadedSettings.swapDelay = settings.Default.swapDelay
            saveNeeded = true
        end

        settings.Current.debugOutput = loadedSettings.debugOutput
        settings.Current.swapDelay = loadedSettings.swapDelay

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
