-- Import modules
local Targeting = require 'client.modules.targeting'
local Placement = require 'client.modules.placement'
local Delivery = require 'client.modules.delivery'
local Container = require 'client.modules.container'
local ox_inventory = exports.ox_inventory

-- Initialize modules
Targeting.init()

-- Events
RegisterNetEvent('pan-containers:startraycast', function()
    Placement.startRaycast()
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
    elseif Targeting.getTargets()[data.entity] then
        lib.print.info('Suppressing excess target: '.. tostring(Targeting.getTargets()[data.entity]) )
    else
        Targeting.createTarget(data)
    end
end)

RegisterNetEvent('pan-containers:client:removetargets', function(entity)
    Targeting.removeTarget(entity)
end)

RegisterNetEvent('pan-containers:client:startDelivery', function(savedPlacementCoords, savedFinalCoords, savedFinalHeading)
    -- Use passed coordinates if available, otherwise fall back to placement module
    local finalCoords = savedFinalCoords or Placement.getFinalPosition()
    local finalHeading = savedFinalHeading
    local placementCoords = savedPlacementCoords or Placement.getPlacementCoords()

    if not finalHeading then
        _, finalHeading = Placement.getFinalPosition()
    end

    Delivery.startDelivery(placementCoords, finalCoords, finalHeading)
end)

-- Event handlers
AddEventHandler('pan-containers:client:duplicate', function()
    Container.duplicateKey()
end)

AddEventHandler('pan-containers:client:markContainer', function(slot)
    Container.markContainer(slot)
end)

-- Resource lifecycle events
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    if next(Targeting.getTargets()) == nil then TriggerServerEvent('pan-containers:server:loadContainerTargets') end
    ox_inventory:displayMetadata('keylabel', 'Label')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    if Placement.isRaycastActive() then
        Placement.exitPlacement()
    end
    Targeting.cleanup()
    Container.cleanup()
end)

-- Callbacks
lib.callback.register('pan-containers:isRaycastActive', function()
    return Placement.isRaycastActive()
end)
