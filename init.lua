math.randomseed(os.time())

local params = require('params')
local Cron = require('Cron')
local NovaCity = {}
local categories = { "common", "rare", "exotic", "badlands", "special" }                                            
local currentVehicleToSwap = { common = 1, rare = 1, exotic = 1, badlands = 1, special = 1 }
local currentVehicleToSwapTo = { common = 1, rare = 1, exotic = 1, badlands = 1, special = 1 }
local initialDelay = { common = 10.0, rare = 20.0, exotic = 30.0, badlands = 15.0, special = 15.0 }
local isInitialReplacementDone = { common = false, rare = false, exotic = false, badlands = false, special = false }
local swapDelay = { common = 60.0, rare = 90.0, exotic = 120.0, badlands = 60.0, special = 60.0 }
local moddedVehicles = {}
local vehiclesToSwap = { common = {}, rare = {}, exotic = {}, badlands = {}, special = {} }                         
local vehiclesToSwapTo = { common = {}, rare = {}, exotic = {}, badlands = {}, special = {} }

local swapDelayRange = { common = { min = 5.0, max = 60.0 }, rare = { min = 10.0, max = 120.0 }, exotic = { min = 20.0, max = 180.0 }, badlands = { min = 15.0, max = 60.0 }, special = { min = 15.0, max = 60.0 } }

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

local function loadVehicleFile(filePath, category, vehicleTable)
    local file = io.open(filePath, 'r')
    if file then
        local content = file:read('*all')
        file:close()

        if content == "" then
            print("Warning: File " .. filePath .. " is empty. Swapping may not work correctly.")
        else
            local vehicles = parseJsonArray(content)

            for _, vehicle in ipairs(vehicles) do
                if TweakDB:GetFlat(vehicle .. ".entityTemplatePath") then
                    vehicleTable[category][#vehicleTable[category] + 1] = vehicle
                end
            end
            shuffleArray(vehicleTable[category])
        end
    else
        print("Error: File not found - " .. filePath .. ". Creating an empty one.")
        file = io.open(filePath, 'w')
        local sampleLayout =
        '[\n  { "name": "Vehicle.v_name_of_first_vehicle" },\n  { "name": "Vehicle.v_name_of_second_vehicle" }\n]'
        file:write(sampleLayout)
        file:close()
    end
end

registerForEvent("onInit", function()
    for _, category in ipairs(categories) do
        -- Load modded vehicles
        loadVehicleFile(
        'swapToModded/moddedVehicles' .. string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2) .. '.json',
            category, vehiclesToSwapTo)

        -- Load custom vehicles
        loadVehicleFile('custom/' .. category .. '/customVehicles.json', category, vehiclesToSwap)

        -- Load vanilla vehicles
        loadVehicleFile(
        'swapToVanilla/vanillaVehicles' .. string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2) .. '.json',
            category, vehiclesToSwapTo)

        -- Load vehicles to swap
        loadVehicleFile(
        'swapFromVanilla/vehiclesToSwap' ..
        string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2) .. '.json', category, vehiclesToSwap)
    end
end)

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
    print("Swapped " .. vehicleToSwap .. " (" .. category .. ") with " .. vehicle .. " (" .. category .. ")")

    -- Add the swapped vehicle back into the pool of vehicles to swap
    vehiclesToSwap[category][#vehiclesToSwap[category] + 1] = vehicle

    -- Add the swapped modded vehicle back into the pool of vehicles to swap to
    -- Add it multiple times to increase its probability of being selected
    for i = 1, 5 do
        vehiclesToSwapTo[category][#vehiclesToSwapTo[category] + 1] = vehicleToSwap
    end

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

return NovaCity
