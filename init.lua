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
local customVehiclesToSwapTo = { common = {}, rare = {}, exotic = {}, badlands = {}, special = {} }

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

local settings = {
        Current = {
            debugOutput = true,
            swapDelay = {
                common = { min = 500, max = 600 },
                rare = { min = 150, max = 300 },
                exotic = { min = 400, max = 600 },
                badlands = { min = 150, max = 600 },
                special = { min = 150, max = 600 }
            },
            swapRatio = 0.5
        },
        Default = {
            debugOutput = true,
            swapDelay = {
                common = { min = 500, max = 600 },
                rare = { min = 150, max = 300 },
                exotic = { min = 400, max = 600 },
                badlands = { min = 150, max = 600 },
                special = { min = 150, max = 600 }
            },
            swapRatio = 0.5
        }
    
}

function debugPrint(message)
    if settings.Current.debugOutput then
        print(IconGlyphs.CarHatchback .. " Nova Traffic: " .. message)
    end
end

local function parseVehicleSwapJson(jsonContent)
    local data = json.decode(jsonContent)
    local vehiclesToSwap = {}
    local vehiclesToSwapTo = {}

    if data then
        for category, lists in pairs(data) do
            vehiclesToSwap[category] = lists.swapFrom
            vehiclesToSwapTo[category] = lists.swapTo
        end
    end
    return vehiclesToSwap, vehiclesToSwapTo
end

local function loadVehicleFile(filePath, vehicleTable, vehicleTableTo)
    local file = io.open(filePath, 'r')
    local customVehiclesLoaded = false
    if file then
        local content = file:read('*all')
        file:close()
        if content == "" then
            debugPrint("Warning: File " .. filePath .. " is empty. Swapping may not work correctly.")
        elseif not is_valid_json(content) then
            debugPrint('Failed to load mod vehicles.')
        else
            local vehicles, vehiclesTo = parseVehicleSwapJson(content)
            if vehicles and vehiclesTo then
                for category, vList in pairs(vehicles) do
                    for _, vehicle in ipairs(vList) do
                        if TweakDB:GetFlat(vehicle.name .. ".entityTemplatePath") then
                            vehicleTable[category] = vehicleTable[category] or {}
                            table.insert(vehicleTable[category], vehicle.name)
                            customVehiclesLoaded = true
                        end
                    end
                    shuffleArray(vehicleTable[category])
                end
                for category, vList in pairs(vehiclesTo) do
                    for _, vehicle in ipairs(vList) do
                        if TweakDB:GetFlat(vehicle.name .. ".entityTemplatePath") then
                            vehicleTableTo[category] = vehicleTableTo[category] or {}
                            table.insert(vehicleTableTo[category], vehicle.name)
                            customVehiclesLoaded = true
                        end
                    end
                    shuffleArray(vehicleTableTo[category])
                end
            else
                debugPrint("Warning: No valid vehicle swap lists in " .. filePath .. ". Skipping this file.")
            end
        end
    else
        debugPrint("Error: File not found - " .. filePath .. ". Creating an empty one.")
        file = io.open(filePath, 'w')
        local sampleLayout = '{\n  "common": { "swapFrom": [], "swapTo": [] },\n  "rare": { "swapFrom": [], "swapTo": [] },\n  "exotic": { "swapFrom": [], "swapTo": [] },\n  "badlands": { "swapFrom": [], "swapTo": [] },\n  "special": { "swapFrom": [], "swapTo": [] }\n}'
        file:write(sampleLayout)
        file:close()
    end
    if not customVehiclesLoaded then
        debugPrint("No custom folder vehicles loaded!")
    end
end

local function loadCustomVehicleFiles(folder, vehicleTableTo)
    local files = dir(folder)
    for _, file in ipairs(files) do
        if file.name:match("%.json$") then
            local filePath = folder .. '/' .. file.name
            local file = io.open(filePath, 'r')
            if file then
                local content = file:read('*all')
                file:close()
                if content ~= "" and is_valid_json(content) then
                    local _, vehiclesTo = parseVehicleSwapJson(content)
                    if vehiclesTo then
                        for category, vList in pairs(vehiclesTo) do
                            for _, vehicle in ipairs(vList) do
                                if TweakDB:GetFlat(vehicle.name .. ".entityTemplatePath") then
                                    vehicleTableTo[category] = vehicleTableTo[category] or {}
                                    table.insert(vehicleTableTo[category], vehicle.name)
                                end
                            end
                            shuffleArray(vehicleTableTo[category])
                        end
                    else
                        debugPrint("Warning: No valid vehicle swap lists in " .. filePath .. ". Skipping this file.")
                    end
                else
                    debugPrint("Failed to load user vehicles from " .. filePath)
                end
            else
                debugPrint("User vehicle file not found - " .. filePath)
            end
        end
    end
end

registerForEvent("onInit", function()
    LoadSettings()
    loadVehicleFile('vehicleSwaps.json', vehiclesToSwap, vehiclesToSwapTo)
    loadCustomVehicleFiles('custom', customVehiclesToSwapTo)
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

local function getRandomDelay(category)
    local minDelay = settings.Current.swapDelay[category].min
    local maxDelay = settings.Current.swapDelay[category].max
    return math.random(minDelay, maxDelay)
end

local function vehicleReplacement(category)
    currentVehicleToSwap[category] = math.random(#vehiclesToSwap[category])
    local vehicleToSwap = vehiclesToSwap[category][currentVehicleToSwap[category]]
    local vehicle

    if settings.Current.swapRatio == 1 then
        currentVehicleToSwapTo[category] = math.random(#customVehiclesToSwapTo[category])
        vehicle = customVehiclesToSwapTo[category][currentVehicleToSwapTo[category]]
    elseif settings.Current.swapRatio == 0 then
        currentVehicleToSwapTo[category] = math.random(#vehiclesToSwapTo[category])
        vehicle = vehiclesToSwapTo[category][currentVehicleToSwapTo[category]]
    else
        local useCustom = math.random() < settings.Current.swapRatio
        if useCustom then
            currentVehicleToSwapTo[category] = math.random(#customVehiclesToSwapTo[category])
            vehicle = customVehiclesToSwapTo[category][currentVehicleToSwapTo[category]]
        else
            currentVehicleToSwapTo[category] = math.random(#vehiclesToSwapTo[category])
            vehicle = vehiclesToSwapTo[category][currentVehicleToSwapTo[category]]
        end
    end

    replace(vehicleToSwap, vehicle)
    debugPrint("Swapped " .. formatVehicleName(vehicleToSwap) .. " (" .. category:upper() .. ") with " .. formatVehicleName(vehicle) .. " (" .. category:upper() .. ")")

    currentVehicleToSwap[category] = (currentVehicleToSwap[category] % #vehiclesToSwap[category]) + 1
    currentVehicleToSwapTo[category] = (currentVehicleToSwapTo[category] % #customVehiclesToSwapTo[category]) + 1

    if currentVehicleToSwap[category] == 1 then
        shuffleArray(vehiclesToSwap[category])
    end
    if currentVehicleToSwapTo[category] == 1 then
        shuffleArray(customVehiclesToSwapTo[category])
    end

    local delay = getRandomDelay(category)
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
        ImGui.Text("Swap delay timers (min to max in seconds):")
        for _, category in ipairs(categories) do
            local minDelay = settings.Current.swapDelay[category].min
            local maxDelay = settings.Current.swapDelay[category].max
            minDelay, changed = ImGui.SliderInt("Min " .. string.sub(category, 1, 1):upper() .. string.sub(category, 2) .. "##", minDelay, 1, 600)
            if changed then
                settings.Current.swapDelay[category].min = minDelay
                SaveSettings()
            end
            maxDelay, changed = ImGui.SliderInt("Max " .. string.sub(category, 1, 1):upper() .. string.sub(category, 2) .. "##", maxDelay, minDelay, 600)
            if changed then
                settings.Current.swapDelay[category].max = maxDelay
                SaveSettings()
            end
        end
        ImGui.Dummy(0, 10)
        ImGui.Text("Vanilla to Custom Swap Ratio:")
        settings.Current.swapRatio, changed = ImGui.SliderFloat("Swap Ratio", settings.Current.swapRatio, 0.0, 1.0, "%.2f")
        if changed then
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
        swapDelay = settings.Current.swapDelay,
        swapRatio = settings.Current.swapRatio -- Ensure swapRatio is saved
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
        if loadedSettings.swapRatio == nil then
            loadedSettings.swapRatio = settings.Default.swapRatio
            saveNeeded = true
        end
        settings.Current.debugOutput = loadedSettings.debugOutput
        settings.Current.swapDelay = loadedSettings.swapDelay
        settings.Current.swapRatio = loadedSettings.swapRatio
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
