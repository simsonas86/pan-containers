local ox_inventory = exports.ox_inventory
local ox_target = exports.ox_target
local targetTemplate = {
    size = vec3(0.2, 0.2, 0.2),
    drawSprite = true
}
local Targets = {}

local ContainerBlip = nil

local isRaycasting = false
local pause = false
local container = nil
local finalCoords = nil
local finalHeading = nil
local placementCoords = { nil, nil, nil }
local corners = nil
local areCornersValid = { 'invalid', 'invalid', 'invalid', 'invalid'}
local lock = nil

-- Functions

local function createCuttingTarget()
    local cuttingData = {
        coords = Config.keyCuttingCoords,
        radius = 0.8,
        debug = Config.debug,
        drawSprite = true,
        options = {
            label = 'Cut a Key',
            name = 'key_cutting',
            icon = 'fas fa-box-open',
            event = 'pan-containers:client:duplicate',
        }
    }
    ox_target:addSphereZone(cuttingData)
end

createCuttingTarget()

local function exitPlacement()
    DeleteEntity(container)
    isRaycasting = false
    pause = false
    container = nil
    placementCoords = { nil, nil, nil }
    corners = nil
    areCornersValid = { 'invalid', 'invalid', 'invalid', 'invalid'}
    lock = nil
    lib.hideTextUI()
end

local function spawnContainer()
    local coords = GetEntityCoords(cache.ped)
    lib.requestModel(Config.containerModel)
    container = CreateObjectNoOffset(Config.containerModel, coords.x, coords.y, coords.z-5.0, false, true, false)
    Wait(1)
    return container
end

local function validatePlacement()
    for i in pairs(corners) do
        CreateThread(function()
            while isRaycasting do
                local hit, _, _, _, _ = lib.raycast.fromCoords(corners[i], (corners[i] + vec3(0,0,10)), nil, container)
                if hit == 1 then
                    areCornersValid[i]= 'invalid'
                else
                    areCornersValid[i]= 'valid'
                end
            end
        end)
        Wait(1)
    end
end

local function getPointsOnModel()
    CreateThread(function()
        local minimum, maximum = GetModelDimensions( Config.containerModel )
        local size = (maximum - minimum)
        local length, width, height = size.y, size.x, size.z

        while isRaycasting do
            local vForward, vRight, vUp, Position = GetEntityMatrix(container)

            corners = {
                vec3(	Position.x - (length/2 * vForward.x) - (width/2 * vRight.x),
                        Position.y - (length/2 * vForward.y) - (width/2 * vRight.y),
                        Position.z - (length/2 * vForward.z) - (width/2 * vRight.z) + height),

                vec3(	Position.x - (length/2 * vForward.x) + (width/2 * vRight.x),
                        Position.y - (length/2 * vForward.y) + (width/2 * vRight.y),
                        Position.z - (length/2 * vForward.z) + (width/2 * vRight.z) + height),

                vec3(	Position.x + (length/2 * vForward.x) + (width/2 * vRight.x),
                        Position.y + (length/2 * vForward.y) + (width/2 * vRight.y),
                        Position.z + (length/2 * vForward.z) + (width/2 * vRight.z) + height),

                vec3(	Position.x + (length/2 * vForward.x) - (width/2 * vRight.x),
                        Position.y + (length/2 * vForward.y) - (width/2 * vRight.y),
                        Position.z + (length/2 * vForward.z) - (width/2 * vRight.z) + height),
            }

            lock =
            vec3( 	Position.x - (length/2 * vForward.x),
                    Position.y - (length/2 * vForward.y),
                    Position.z - (length/2 * vForward.z) + (0.4 * height))
            Wait(1)
        end
    end)
    while not corners do Wait(1) end
    validatePlacement()
end

local function drawLockMarker()
    CreateThread(function()
        while isRaycasting do
            if placementCoords then
                local marker = lib.marker.new({
                    type = 28,
                    coords = lock,
                    width = 0.1,
                    height = 0.1,
                    color = { r = 80, g = 170, b = 50, a = 255 }
                })
                marker:draw()
            end
            Wait(1)
        end
    end)
end

local function drawCornerMarkers()
    while not corners do Wait(1) end
    for i in pairs(corners) do
        CreateThread(function()
            while isRaycasting do
                local coords = corners[i]
                local color = Config.drawColors[areCornersValid[i]]
                DrawMarker(
                        6,
                        coords.x, coords.y, coords.z,
                        0,0,0,
                        0,0,0,
                        0.2,0.2,0.2,
                        color[1], color[2], color[3], color[4],
                        false,
                        true,
                        0,
                        false,
                        nil,
                        nil,
                        false
                )
                Wait(1)
            end
        end)
    end
end

local function drawPlacementContainer()
    container = spawnContainer()
    SetEntityCollision(container, false, false)
    SetCanClimbOnEntity(container, false)
    SetObjectForceVehiclesToAvoid(container, false)
    SetEntityAlpha(container, 102, true)
    CreateThread(function()
        while isRaycasting do
            SetEntityCoords(container, placementCoords, false, false, false, false)
            finalCoords = placementCoords
            finalHeading = GetEntityHeading(container)
            Wait(1)
        end
    end)
    getPointsOnModel()
end

local function confirmationDialog()
    pause = true
    local input = lib.inputDialog(locale('placement'), { { type = 'input', label = locale('label'), placeholder = locale('placeholder'), description = locale('description'), required = true, max = 15 } })
    if not input then
        pause = false
        Utility.notify(locale('cancelled'), nil, 'error')
        return
    end
    return input[1]
end

local function saveContainerData(label)
    local data = {
        label = label,
        coords = GetEntityCoords(container),
        heading = GetEntityHeading(container),
        target = lock
    }
    TriggerServerEvent('pan-containers:server:saveContainerData', data)
end

local function createCargobobWithProperties()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped, true)
    local heading = GetEntityHeading(ped)

    -- Load models
    if lib.requestModel(Config.cargobobModel) then lib.print.verbose('Loaded the container model succesfully') end
    if lib.requestModel(Config.containerModel) then lib.print.verbose('Loaded the container model succesfully') end
    if lib.requestModel(Config.pedModel) then lib.print.verbose('Loaded the container model succesfully') end

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
    SetEntityCollision(container, true, false)

    -- Blip
    local cargoBlip = AddBlipForEntity(cargobob)
    SetBlipFlashes(cargoBlip, true)
    SetBlipColour(cargoBlip, 5)

    -- Ped task
    TaskVehicleDriveToCoord(cargoPed, cargobob, pedCoords.x, pedCoords.y, pedCoords.z + 30, 20.0, 0, GetEntityModel(cargobob), 786603, 7, 0)

    -- Play sound
    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)

    -- Release models
    SetModelAsNoLongerNeeded(Config.cargobobModel)
    SetModelAsNoLongerNeeded(Config.containerModel)
    SetModelAsNoLongerNeeded(Config.pedModel)

    return cargobob, cargoPed, deliveryContainer
end

local function dropContainer(cargobob, cargoPed, deliveryContainer)
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
    finalCoords = nil
    finalHeading = nil
    TriggerServerEvent('pan-containers:server:loadContainers')
    Wait(2000)

    -- Clear up cargobob and ped
    DeleteEntity(cargobob)
    DeleteEntity(cargoPed)
end

local function deliveryThread(cargobob, cargoPed, deliveryContainer)
    CreateThread(function()
        local ped = PlayerPedId()
        while true do
            Wait(100)
            local dist = #(placementCoords.xy - GetEntityCoords(deliveryContainer, false).xy)
            lib.print.debug(dist)
            if (dist <= 4) then
                lib.print.debug('Dropping')
                dropContainer(cargobob, cargoPed, deliveryContainer)
                return
            end
        end
    end)
end

local function startDelivery()
    local cargobob, cargoPed, deliveryContainer = createCargobobWithProperties()
    deliveryThread(cargobob, cargoPed, deliveryContainer)
end

local function controlHandlingThread()
    CreateThread(function()
        local rotationAmount = 5.0
        while isRaycasting do
            Wait(1)
            DisableControlAction(2, 200, true) -- Disable pause menu
            DisableControlAction(2, 26, true) -- Disable C to look behind
            DisableControlAction(2, 24, true) -- Disable confirm keybind
            DisableControlAction(2, 21, true) -- Disable shift keybind

            -- Close placeholder placement
            if IsDisabledControlJustReleased(2, 200) or IsControlJustReleased(2, 202) then
                isRaycasting = not isRaycasting
                exitPlacement()
            end

            -- Rotate Pos
            if IsDisabledControlJustReleased(2, 241) then
                if IsDisabledControlPressed(2, 21) then rotationAmount = rotationAmount * 0.5 end
                SetEntityRotation(container, 0.0, 0.0, GetEntityRotation(container).z + rotationAmount, 2, true)
                rotationAmount = 5
            end

            -- Rotate Neg
            if IsDisabledControlJustReleased(2, 242) then
                if IsDisabledControlPressed(2, 21) then rotationAmount = rotationAmount * 0.5 end
                SetEntityRotation(container, 0.0, 0.0, GetEntityRotation(container).z - rotationAmount, 2, true)
                rotationAmount = 5
            end

            -- Confirm placement
            if IsDisabledControlJustReleased(2, 24) then
                if lib.table.contains(areCornersValid, 'invalid') then
                    Utility.notify(locale('cancelled'), nil, 'error')
                    goto escape
                end
                local result = confirmationDialog()
                if not result then goto escape end
                saveContainerData(result)
                exitPlacement()

                startDelivery()

                ::escape::
            end
        end
    end)
end

local function createTarget(data)
    targetTemplate.coords = data.target
    targetTemplate.options = {
        {
            name = 'open_container',
            icon = 'fa-solid fa-cube',
            label = 'Open Container',
            onSelect = function()
                ox_inventory:openInventory('stash', { id = 'container_' .. Entity(NetworkGetEntityFromNetworkId(data.entity)).state.id })
            end
        }
    }
    Targets[data.entity] = ox_target:addBoxZone(targetTemplate)
    lib.print.verbose('Created zone: ' .. Targets[data.entity])
end

local function removeTarget(entity)
    if not Targets[entity] then return end
    lib.print.verbose('Removed zone: ' .. Targets[entity])
    ox_target:removeZone(Targets[entity])
    Targets[entity] = nil
end

-- Events

RegisterNetEvent('pan-containers:startraycast', function()
    local response = lib.callback.await('pan-containers:server:canplace')
    if not response then
        if GetCurrentResourceName() ~= GetInvokingResource() and GetCurrentResourceName() ~= nil then
            TriggerEvent('QBCore:Notify', locale('cheater'), 'error', 5000)
        end
        return
    end
    isRaycasting = true
    lib.showTextUI(locale('inputUi'), {
        position = "left-center"
    })
    CreateThread(function()
        while isRaycasting do
            while pause do Wait(1) end
            local _, _, endCoords, _, _ = lib.raycast.fromCamera(1, 4, 20)
            placementCoords = endCoords
        end
    end)
    drawPlacementContainer()
    drawLockMarker()
    drawCornerMarkers()
    controlHandlingThread()
end)

RegisterNetEvent('pan-containers:client:createtargets', function(data)
    local response = lib.callback.await('pan-containers:server:haskey')
    if not response then
        if GetCurrentResourceName() ~= GetInvokingResource() then return end
        TriggerEvent('QBCore:Notify', locale('cheater'), 'error', 5000)
        return
    end
    if not data then
        lib.print.error('Couldn\'t retrieve data for container!')
    elseif Targets[data.entity] then
        lib.print.info('Suppressing excess target: '.. tostring(Targets[data.entity]) )
    else
        createTarget(data)
    end
end)

RegisterNetEvent('pan-containers:client:removetargets', function(entity)
    removeTarget(entity)
end)

AddEventHandler('pan-containers:client:duplicate', function()
    local slotList = ox_inventory:GetSlotsWithItem('containerkey')
    local uniqueKeys = {}
    local storedIDs = {}

    for _, v in ipairs(slotList) do
        if not table.contains(storedIDs, v.metadata.id) then
            storedIDs[#storedIDs+1] = v.metadata.id
            uniqueKeys[#uniqueKeys+1] = v
        end
    end

    local contextOptions = {
        id = "key_cutting_menu",
        title = string.format('You have %d blank keys.', ox_inventory:Search('count', 'blankkey')),
        options = {
            [1] = {
                title = 'Choose a key to replicate:'
            }
        }
    }

    for _, v in ipairs(uniqueKeys) do
        local key = v
        contextOptions.options[#contextOptions.options+1] = {
            description = string.format('%d\\. %s', #contextOptions.options, key.metadata.keylabel),
            onSelect = function()
                TriggerServerEvent('pan-containers:server:cutNewKey', key.metadata)
            end,
        }
    end

    lib.registerContext(contextOptions)
    lib.showContext('key_cutting_menu')
end)

AddEventHandler('pan-containers:client:markContainer', function(slot)
    print('Triggered the markContainer event')
    local inv = ox_inventory:GetPlayerItems()
    local coords = json.decode(inv[slot].metadata.coords)
    if not ContainerBlip then
        ContainerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(ContainerBlip, 8)
        SetBlipColour(ContainerBlip, 5)
        SetBlipRoute(ContainerBlip, true)
        Utility.notify(locale('marked'), nil, 'success')
    else
        RemoveBlip(ContainerBlip)
        ContainerBlip = nil
        Utility.notify(locale('unmarked'), nil, 'error')
    end

end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    if not Targets then TriggerServerEvent('pan-containers:server:loadContainerTargets') end
    ox_inventory:displayMetadata('keylabel', 'Label')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    if isRaycasting then
        exitPlacement()
    end
    if #Targets > 0 then
        for i in #Targets do
            ox_target:removeZone(Targets[i])
        end
    end
end)

-- Callbacks

lib.callback.register('pan-containers:isRaycastActive', function()
    return isRaycasting
end)

-- Framework Dependant Events
if Config.framework == 'ox' then
    AddEventHandler('ox:playerLoaded', function()
        TriggerServerEvent('pan-containers:server:loadcontainertargets', cache.serverId)
    end)
elseif Config.framework == 'qb' then
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        TriggerServerEvent('pan-containers:server:loadcontainertargets', cache.serverId)
    end)
else
    lib.print.error('No supported framework selected.')
end

