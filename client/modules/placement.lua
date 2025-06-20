local Config = require 'shared.config'
local Utility = require 'shared.utilities'

local Placement = {}

-- State variables
local isRaycasting = false
local pause = false
local container = nil
local finalCoords = nil
local finalHeading = nil
local placementCoords = { nil, nil, nil }
local corners = nil
local areCornersValid = { 'invalid', 'invalid', 'invalid', 'invalid'}
local lock = nil

-- Exit placement mode
function Placement.exitPlacement()
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

-- Spawn a container for placement
local function spawnContainer()
    local coords = GetEntityCoords(cache.ped)
    lib.requestModel(Config.containerModel)
    container = CreateObjectNoOffset(Config.containerModel, coords.x, coords.y, coords.z-5.0, false, true, false)
    Wait(1)
    return container
end

-- Validate placement by checking corners
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

-- Get points on the container model
local function getPointsOnModel()
    CreateThread(function()
        local minimum, maximum = GetModelDimensions(Config.containerModel)
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

-- Draw lock marker
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

-- Draw corner markers
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

-- Draw placement container
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

-- Show confirmation dialog
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

-- Save container data
local function saveContainerData(label)
    local data = {
        label = label,
        coords = GetEntityCoords(container),
        heading = GetEntityHeading(container),
        target = lock
    }
    TriggerServerEvent('pan-containers:server:saveContainerData', data)
end

-- Control handling thread
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
                Placement.exitPlacement()
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

                -- Store coordinates before exiting placement
                local savedPlacementCoords = placementCoords
                local savedFinalCoords = finalCoords
                local savedFinalHeading = finalHeading

                Placement.exitPlacement()

                -- Start delivery after successful placement with saved coordinates
                TriggerEvent('pan-containers:client:startDelivery', savedPlacementCoords, savedFinalCoords, savedFinalHeading)

                ::escape::
            end
        end
    end)
end

-- Start raycast for container placement
function Placement.startRaycast()
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
end

-- Check if raycast is active
function Placement.isRaycastActive()
    return isRaycasting
end

-- Get final coordinates and heading
function Placement.getFinalPosition()
    return finalCoords, finalHeading
end

-- Get placement coordinates
function Placement.getPlacementCoords()
    return placementCoords
end

-- Set placement coordinates
function Placement.setPlacementCoords(coords)
    placementCoords = coords
end

-- Get container entity
function Placement.getContainer()
    return container
end

-- Get lock position
function Placement.getLockPosition()
    return lock
end

return Placement
