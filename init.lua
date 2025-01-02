-- Import required modules
local ResolutionPresets = require("Modules/ResolutionPresets")
local WindowUtils = require("Modules/WindowUtils")

math.randomseed(os.time())

local params = require('params')
local Cron = require('Cron')
local NovaTraffic = {}
local modVersion = "1.6.0"
local categories = { "common", "rare", "exotic", "badlands", "special", "utility" }
local currentVehicleToSwap = { common = 1, rare = 1, exotic = 1, badlands = 1, special = 1, utility = 1 }
local currentVehicleToSwapTo = { common = 1, rare = 1, exotic = 1, badlands = 1, special = 1, utility = 1 }
local initialDelay = { common = 1.0, rare = 2.0, exotic = 3.0, badlands = 4.0, special = 5.0, utility = 6.0 }
local isInitialReplacementDone = { common = false, rare = false, exotic = false, badlands = false, special = false, utility = false }
local vehiclesToSwap = { common = {}, rare = {}, exotic = {}, badlands = {}, special = {}, utility = {} }
local vehiclesToSwapTo = { common = {}, rare = {}, exotic = {}, badlands = {}, special = {}, utility = {} }
local customVehiclesToSwapTo = { common = {}, rare = {}, exotic = {}, badlands = {}, special = {}, utility = {} }

local sliderToggle = false

-- Define window settings
local windowSettings = {
    mainWindow = {
        windowName = "Nova Traffic"
    },
}

local ui = {
	tooltip = function(text, alwaysShow)
		if ImGui.IsItemHovered() and text ~= "" then
			ImGui.BeginTooltip()
			ImGui.SetTooltip(text)
			ImGui.EndTooltip()
		end
	end
}

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
            rare = { min = 350, max = 600 },
            exotic = { min = 400, max = 600 },
            badlands = { min = 350, max = 600 },
            special = { min = 350, max = 600 },
            utility = { min = 400, max = 600 }
        },
        swapRatio = 0.5,
        modActive = true,
        gridEnabled = true,
        animationEnabled = true,
        animationTime = 0.2,
    },
    Default = {
        debugOutput = true,
        swapDelay = {
            common = { min = 500, max = 600 },
            rare = { min = 350, max = 600 },
            exotic = { min = 400, max = 600 },
            badlands = { min = 350, max = 600 },
            special = { min = 350, max = 600 },
            utility = { min = 400, max = 600 }
        },
        swapRatio = 0.5,
        modActive = true,
        gridEnabled = true,
        animationEnabled = true,
        animationTime = 0.2,
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
        local sampleLayout = '{\n  "common": { "swapFrom": [], "swapTo": [] },\n  "rare": { "swapFrom": [], "swapTo": [] },\n  "exotic": { "swapFrom": [], "swapTo": [] },\n  "badlands": { "swapFrom": [], "swapTo": [] },\n  "special": { "swapFrom": [], "swapTo": [] },\n  "utility": { "swapFrom": [], "swapTo": [] }\n}'
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
                                else
                                    debugPrint("Warning: Vehicle " .. vehicle.name .. " does not exist in game. Skipping this entry.")
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
    if not settings.Current.modActive then
        -- Reset the state when mod is disabled
        for category, _ in pairs(currentVehicleToSwap) do
            isInitialReplacementDone[category] = false
            currentVehicleToSwap[category] = 1
            currentVehicleToSwapTo[category] = 1
        end
        return
    end

    if Game.GetSystemRequestsHandler():IsPreGame() or Game.GetSystemRequestsHandler():IsGamePaused() then
        return
    end

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

    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, buttonRadius)
    ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, 2)
    ImGui.PushStyleColor(ImGuiCol.ScrollbarBg, ImGui.GetColorU32(0, 0, 0, 0))
    ImGui.PushStyleColor(ImGuiCol.ScrollbarGrab, ImGui.GetColorU32(0.8, 0.8, 1, 0.5))
    
    -- ImGui.SetNextWindowSizeConstraints(width / 100 * 15, height / 100 * 19, width / 100 * 50, height / 100 * 90)
    
    if ImGui.Begin("Nova Traffic", true) then
        -- ImGui.Dummy(0, 4)

        -- Set the font scale for the window
		ImGui.SetWindowFontScale(customFontScale)
        
        -- Add the checkbox at the top of the GUI
        settings.Current.modActive, changed = ImGui.Checkbox("Enable Vehicle Swapping", settings.Current.modActive)
        if changed then
            local status = settings.Current.modActive and "Enabled" or "Disabled"
            print(IconGlyphs.CarHatchback .. " Nova Traffic: " .. status)
            SaveSettings()
            if settings.Current.modActive then
                -- Restart the vehicle replacement process when re-enabled
                for category, _ in pairs(currentVehicleToSwap) do
                    Cron.After(initialDelay[category], function() vehicleReplacement(category) end)
                    isInitialReplacementDone[category] = true
                end
            end
        end
        -- ImGui.Dummy(0, 0)
        settings.Current.debugOutput, changed = ImGui.Checkbox("Debug Console Output", settings.Current.debugOutput)
        if changed then
            print(IconGlyphs.CarHatchback .. " Nova Traffic: Toggled debug output to " .. tostring(settings.Current.debugOutput))
            SaveSettings()
        end
        ImGui.Dummy(0, dummySpacingYValue)
        ImGui.Text("Adjustments:")
        ImGui.Separator()

        -- Set the width of the slider to the width of the window minus the padding
        local windowWidth = ImGui.GetWindowWidth()
        ImGui.PushItemWidth(windowWidth - timeSliderXPadding - 2)

        -- Set the width and height of the slider to match the game time slider
        ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 10, sliderHeight)
        ImGui.SetNextItemWidth(windowWidth - timeSliderXPadding - 2)

        settings.Current.swapRatio, changed = ImGui.SliderFloat("", settings.Current.swapRatio, 0.0, 1.0, "%.2f")
        if changed then
            SaveSettings()
        end
        ui.tooltip("Adjust the ratio of vanilla vehicles swaps to custom vehicle swaps.\n\n0.0 will swap only vanilla and 1.0 will swap only custom vehicles.")
        
        ImGui.PopStyleVar()


        ImGui.PushStyleColor(ImGuiCol.CheckMark, ImGui.GetColorU32(1, 0.2, 0.2, 1.0))
        ImGui.PushStyleColor(ImGuiCol.FrameBg, ImGui.GetColorU32(1, 0.0, 0.0, 0.2))
        ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, ImGui.GetColorU32(1, 0.2, 0.2, 0.5))
        ImGui.PushStyleColor(ImGuiCol.FrameBgActive, ImGui.GetColorU32(1.0, 0.0, 0.0, 0.6))

        sliderToggle, changed = ImGui.Checkbox("Adjust Swap Timers", sliderToggle)
        if changed then
            print(IconGlyphs.CarHatchback .. " Nova Traffic: Toggled swap timers to " .. tostring(sliderToggle))
            SaveSettings()
        end
        ImGui.PopStyleColor(4)
        ui.tooltip("Changing slider values is NOT recommended.\n\nYou may need to reload CET mods for changes to take effect.")
        
        if sliderToggle then
            ImGui.Dummy(0, 10)
            ImGui.Text("Swap delay timers (min to max in seconds):")
            ImGui.Dummy(0, 4)

            -- Set the width of the slider to the width of the window minus the padding
            local windowWidth = ImGui.GetWindowWidth()
            ImGui.PushItemWidth(windowWidth - buttonWidth - 6)

            for _, category in ipairs(categories) do
                local minDelay = settings.Current.swapDelay[category].min
                local maxDelay = settings.Current.swapDelay[category].max
                ImGui.PushStyleColor(ImGuiCol.SliderGrab, ImGui.GetColorU32(1, 0.2, 0.2, 1.0))
                ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, ImGui.GetColorU32(1, 0.2, 0.2, 0.5))
                ImGui.PushStyleColor(ImGuiCol.SliderGrabActive, ImGui.GetColorU32(1, 0.2, 0.2, 1.0))
                ImGui.PushStyleColor(ImGuiCol.FrameBg, ImGui.GetColorU32(1, 0.0, 0.0, 0.2))
                ImGui.PushStyleColor(ImGuiCol.FrameBgActive, ImGui.GetColorU32(1.0, 0.0, 0.0, 0.6))
                minDelay, changed = ImGui.SliderInt("Min " .. string.sub(category, 1, 1):upper() .. string.sub(category, 2) .. "##", minDelay, 1, 600)
                if changed then
                    settings.Current.swapDelay[category].min = minDelay
                    if minDelay > settings.Current.swapDelay[category].max then
                        settings.Current.swapDelay[category].max = minDelay
                    end
                    SaveSettings()
                end
                maxDelay, changed = ImGui.SliderInt("Max " .. string.sub(category, 1, 1):upper() .. string.sub(category, 2) .. "##", maxDelay, minDelay, 600)
                if changed then
                    settings.Current.swapDelay[category].max = maxDelay
                    SaveSettings()
                end
                ImGui.PopStyleColor(5)
                ImGui.Dummy(0, 2)
                ImGui.Separator()
                ImGui.Dummy(0, 2)
            end
            if ImGui.Button("Default Values") then
                settings.Current = settings.Default
                SaveSettings()
            end
        end
        --ImGui.Dummy(0, 10)

        ImGui.Dummy(0, 0)
        ImGui.Text("Settings:")
        ImGui.Separator()

        settings.Current.gridEnabled, changed = ImGui.Checkbox("Grid Snap", settings.Current.gridEnabled)
        if changed then
            print(IconGlyphs.CarHatchback .. " Nova Traffic: Toggled grid to " .. tostring(settings.Current.gridEnabled))
            if not settings.Current.gridEnabled then
            settings.Current.animationEnabled = false -- Disable animation if grid is disabled
            end
            SaveSettings()
        end
        ui.tooltip("Toggle windows snapping to grid.")

        ImGui.SameLine(windowWidth / 2)
        if not settings.Current.gridEnabled then
            ImGui.BeginDisabled()
        end
        settings.Current.animationEnabled, changed = ImGui.Checkbox("Animate Snap", settings.Current.animationEnabled)
        if changed then
            print(IconGlyphs.CarHatchback .. " Nova Traffic: Toggled animations to " .. tostring(settings.Current.animationEnabled))
            SaveSettings()
        end
        ui.tooltip("Toggle animation of windows when snapping to grid from released position.")
        if not settings.Current.gridEnabled then
            ImGui.EndDisabled()
        end

        if not settings.Current.gridEnabled or not settings.Current.animationEnabled then
            ImGui.BeginDisabled()
        end
        ImGui.PushStyleColor(ImGuiCol.Text, ImGui.GetColorU32(1, 1, 1, 0.7))
        ImGui.Text("Animation Speed:")
        ImGui.PopStyleColor()

        -- Set the width of the slider to the width of the window minus the padding
        local windowWidth = ImGui.GetWindowWidth()
        ImGui.PushItemWidth(windowWidth - timeSliderXPadding - 2)
        ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 10, 10)
        settings.Current.animationTime, changed = ImGui.SliderFloat("##animationSpeed",
        settings.Current.animationTime, 0.1, 1.0, "%.2f")
        if changed then
            print(IconGlyphs.CarHatchback .. " Nova Traffic: Changed animation speed to " .. string.format("%.2f", settings.Current.animationTime))
            SaveSettings()
        end
        ImGui.PopStyleVar()
        ui.tooltip("Set grid snapping animation in seconds.")
        if not settings.Current.gridEnabled or not settings.Current.animationEnabled then
            ImGui.EndDisabled()
        end
    end

    ImGui.PopStyleVar(2)
    ImGui.PopStyleColor(2)

    ImGui.SetWindowFontScale(1) --return font size back to default

    WindowUtils.UpdateWindow(windowSettings.mainWindow.windowName, settings.Current.gridEnabled, settings.Current.animationEnabled, settings.Current.animationTime)
    
    ImGui.End()
end

registerForEvent("onDraw", function()
    DrawGUI()
end)

registerForEvent("onOverlayOpen", function()
    cetOpen = true

    width, height = GetDisplayResolution()
	ResolutionPresets.Set(width, height)
end)

registerForEvent("onOverlayClose", function()
    cetOpen = false
end)

function SaveSettings()
    local saveData = {
        debugOutput = settings.Current.debugOutput,
        swapDelay = settings.Current.swapDelay,
        swapRatio = settings.Current.swapRatio,
        modActive = settings.Current.modActive,
        gridEnabled = settings.Current.gridEnabled,
        animationEnabled = settings.Current.animationEnabled,
        animationTime = settings.Current.animationTime
    }
    local file = io.open("settings.json", "w")
    if file then
        file:write(json.encode(saveData))
        file:close()
        -- print(IconGlyphs.CarHatchback .. " Nova Traffic: Settings saved successfully")
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
        if loadedSettings.modActive == nil then
            loadedSettings.modActive = settings.Default.modActive
            saveNeeded = true
        end
        if loadedSettings.gridEnabled == nil then
            loadedSettings.gridEnabled = settings.Default.gridEnabled
            saveNeeded = true
        end
        if loadedSettings.animationEnabled == nil then
            loadedSettings.animationEnabled = settings.Default.animationEnabled
            saveNeeded = true
        end
        if loadedSettings.animationTime == nil then
            loadedSettings.animationTime = settings.Default.animationTime
            saveNeeded = true
        end
        settings.Current.debugOutput = loadedSettings.debugOutput
        settings.Current.swapDelay = loadedSettings.swapDelay
        settings.Current.swapRatio = loadedSettings.swapRatio
        settings.Current.modActive = loadedSettings.modActive
        settings.Current.gridEnabled = loadedSettings.gridEnabled
        settings.Current.animationEnabled = loadedSettings.animationEnabled
        settings.Current.animationTime = loadedSettings.animationTime
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
