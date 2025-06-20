local Config = require 'shared.config'

local Delivery = {}

-- Create cargobob with properties
local function createCargobobWithProperties()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped, true)
    local heading = GetEntityHeading(ped)

    -- Load models
    if lib.requestModel(Config.cargobobModel) then lib.print.verbose('Loaded the cargobob model successfully') end
    if lib.requestModel(Config.containerModel) then lib.print.verbose('Loaded the container model successfully') end
    if lib.requestModel(Config.pedModel) then lib.print.verbose('Loaded the ped model successfully') end

    local spawnPos = vec3(
        pedCoords.x + (math.random(-Config.spawnRadiusMax, Config.spawnRadiusMax) - math.random(-Config.spawnRadiusMin, Config.spawnRadiusMin)),
        pedCoords.y + (math.random(-Config.spawnRadiusMax, Config.spawnRadiusMax) - math.random(-Config.spawnRadiusMin, Config.spawnRadiusMin)),
        pedCoords.z + Config.spawnHeight
    )

    local cargobob = CreateVehicle(Config.cargobobModel, spawnPos.x, spawnPos.y, spawnPos.z+100, heading, true, true)
    local cargoPed = CreatePedInsideVehicle(cargobob, 26, Config.pedModel, -1, true, true)

    -- Configure cargobob
    SetEntityAsMissionEntity(cargobob, true, true)
    SetVehicleEngineOn(cargobob, true, true, false)
    SetHeliBladesFullSpeed(cargobob)
    SetVehicleStrong(cargobob, true)
    ModifyVehicleTopSpeed(cargobob, 0)

    -- Spawn cargobob hook
    CreatePickUpRopeForCargobob(cargobob, 0)

    -- Spawn container
    local cargoPos = GetEntityCoords(cargobob).xyz
    local deliveryContainer = CreateObject(Config.containerModel, cargoPos.x, cargoPos.y, cargoPos.z - 5, true, true, true)
    SetEntityCollision(deliveryContainer, true, false)

    -- Blip
    local cargoBlip = AddBlipForEntity(cargobob)
    SetBlipFlashes(cargoBlip, true)
    SetBlipColour(cargoBlip, 5)

    -- Ped task - Set target altitude higher to prevent low flying
    TaskVehicleDriveToCoord(cargoPed, cargobob, pedCoords.x, pedCoords.y, pedCoords.z + 80, 20.0, 0, GetEntityModel(cargobob), 786603, 7, 0)

    -- Play sound
    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)

    -- Release models
    SetModelAsNoLongerNeeded(Config.cargobobModel)
    SetModelAsNoLongerNeeded(Config.containerModel)
    SetModelAsNoLongerNeeded(Config.pedModel)

    return cargobob, cargoPed, deliveryContainer
end

-- Drop container at final position
local function dropContainer(cargobob, cargoPed, deliveryContainer, finalCoords, finalHeading)
    if cargobob == nil or not DoesEntityExist(cargobob) or cargoPed == nil or deliveryContainer == nil or finalCoords == nil or finalHeading == nil then
        lib.print.error('Missing one or more required entities or coordinates')
        return
    end

    -- Drops the container
    DetachEntityFromCargobob(cargobob, deliveryContainer)
    SetEntityCoords(deliveryContainer, finalCoords.x, finalCoords.y, GetEntityCoords(deliveryContainer).z, false, false, false, false)
    SetEntityHeading(deliveryContainer, finalHeading)
    SetEntityVelocity(deliveryContainer, 0, 0, GetEntityVelocity(deliveryContainer).z)
    SetEntityAngularVelocity(deliveryContainer, 0, 0, 0)

    -- Waits for container to land
    while not HasEntityCollidedWithAnything(deliveryContainer) do
        Citizen.Wait(10)
    end

    -- Snaps container to final position
    DeleteObject(deliveryContainer)
    TriggerServerEvent('pan-containers:server:loadContainers')
    Wait(2000)

    -- Clear up cargobob and ped
    DeleteEntity(cargobob)
    DeleteEntity(cargoPed)
end

-- Delivery thread
local function deliveryThread(cargobob, cargoPed, deliveryContainer, placementCoords, finalCoords, finalHeading)
    CreateThread(function()
        local ped = PlayerPedId()
        local startTime = GetGameTimer()
        local maxDeliveryTime = 120000 -- 2 minutes timeout
        local minAltitude = 15.0 -- Minimum altitude above ground
        local lastDistanceCheck = 0
        local stuckCounter = 0
        local maxStuckTime = 30000 -- 30 seconds of being stuck before forcing drop

        while true do
            Wait(100)

            -- Check if placementCoords is nil
            if not placementCoords then
                lib.print.error('placementCoords is nil, cannot calculate distance')
                dropContainer(cargobob, cargoPed, deliveryContainer, finalCoords, finalHeading)
                return
            end

            -- Get current positions
            local containerCoords = GetEntityCoords(deliveryContainer, false)
            local cargobobCoords = GetEntityCoords(cargobob, false)

            -- Calculate 2D distance to target
            local dist = #(vec2(placementCoords.x, placementCoords.y) - vec2(containerCoords.x, containerCoords.y))

            -- Calculate altitude above ground
            local groundZ = GetGroundZFor_3dCoord(containerCoords.x, containerCoords.y, containerCoords.z, false)
            local altitudeAboveGround = containerCoords.z - groundZ

            -- Check if cargobob is too close to ground (emergency drop)
            if altitudeAboveGround < minAltitude then
                lib.print.warn('Cargobob too close to ground (altitude: ' .. string.format("%.2f", altitudeAboveGround) .. 'm), forcing drop')
                dropContainer(cargobob, cargoPed, deliveryContainer, finalCoords, finalHeading)
                return
            end

            -- Check for timeout (emergency drop)
            local currentTime = GetGameTimer()
            if (currentTime - startTime) > maxDeliveryTime then
                lib.print.warn('Delivery timeout reached, forcing drop')
                dropContainer(cargobob, cargoPed, deliveryContainer, finalCoords, finalHeading)
                return
            end

            -- Check if cargobob is stuck (not making progress)
            if math.abs(dist - lastDistanceCheck) < 0.5 then
                stuckCounter = stuckCounter + 100 -- Add wait time
                if stuckCounter > maxStuckTime then
                    lib.print.warn('Cargobob appears stuck, forcing drop at current position')
                    dropContainer(cargobob, cargoPed, deliveryContainer, finalCoords, finalHeading)
                    return
                end
            else
                stuckCounter = 0 -- Reset stuck counter if making progress
            end
            lastDistanceCheck = dist

            -- Debug logging
            lib.print.debug('Distance: ' .. string.format("%.2f", dist) .. 'm, Altitude: ' .. string.format("%.2f", altitudeAboveGround) .. 'm, Time: ' .. string.format("%.1f", (currentTime - startTime) / 1000) .. 's')

            -- Normal drop condition - close enough to target and at safe altitude
            if (dist <= 4) and (altitudeAboveGround >= minAltitude) then
                lib.print.debug('Normal drop conditions met')
                dropContainer(cargobob, cargoPed, deliveryContainer, finalCoords, finalHeading)
                return
            end

            -- Extended drop condition - if very close but slightly outside normal range
            if (dist <= 8) and (altitudeAboveGround < (minAltitude + 5)) then
                lib.print.debug('Extended drop conditions met (close enough and low altitude)')
                dropContainer(cargobob, cargoPed, deliveryContainer, finalCoords, finalHeading)
                return
            end
        end
    end)
end

-- Start delivery process
function Delivery.startDelivery(placementCoords, finalCoords, finalHeading)
    local cargobob, cargoPed, deliveryContainer = createCargobobWithProperties()
    deliveryThread(cargobob, cargoPed, deliveryContainer, placementCoords, finalCoords, finalHeading)
end

return Delivery
