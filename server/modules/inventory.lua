local ox_inventory = exports.ox_inventory
local ContainerModule = require 'server.modules.container'
local ContainerManager = ContainerModule.ContainerManager
local Config = require 'shared.config'

local InventoryIntegration = {
    hooks = {}
}

function InventoryIntegration.registerHooks()
    -- Create item hook
    InventoryIntegration.hooks.createItemHook = ox_inventory:registerHook('createItem', function(payload)
        local invId = payload.inventoryId
        local metadata = payload.metadata
        local count = ox_inventory:Search(invId, 'count', 'containerkey', metadata)

        if ContainerManager:getContainer(metadata.id) and count == 0 then
            TriggerClientEvent('pan-containers:client:createtargets', payload.inventoryId, ContainerManager:getContainer(metadata.id))
        end
        return metadata
    end, {
        print = true,
        itemFilter = {
            containerkey = true
        }
    })

    -- Swap key hook
    InventoryIntegration.hooks.swapKeyHook = ox_inventory:registerHook('swapItems', function(payload)
        local src = payload.source
        local metadata = payload.fromSlot.metadata
        local fromInv = payload.fromInventory
        local toInv = payload.toInventory
        local count = ox_inventory:Search(src, 'count', 'containerkey', metadata)

        if toInv == 'container_' .. tostring(metadata.id) then
            return false
        end

        if (fromInv == src and fromInv ~= toInv and count == 1) then
            TriggerClientEvent('pan-containers:client:removetargets', src, ContainerManager:getContainer(payload.fromSlot.metadata.id).entity)
            return true
        elseif (toInv == src and fromInv ~= toInv and count == 0) then
            TriggerClientEvent('pan-containers:client:createtargets', src, ContainerManager:getContainer(payload.fromSlot.metadata.id))
            return true
        end
        return true
    end, {
        print = true,
        itemFilter = {
            containerkey = true
        }
    })
end

function InventoryIntegration.removeHooks()
    -- Only remove hooks registered by this module
    for _, hookId in pairs(InventoryIntegration.hooks) do
        ox_inventory:removeHooks(hookId)
    end
end

-- Inventory utility functions
function InventoryIntegration.hasContainerGPS(source)
    local count = ox_inventory:Search(source, 'count', 'containergps')
    return count > 0
end

function InventoryIntegration.hasContainerKey(source)
    local count = ox_inventory:Search(source, 'count', 'containerkey')
    return count > 0
end

function InventoryIntegration.removeContainerGPS(source)
    return ox_inventory:RemoveItem(source, 'containergps', 1)
end

function InventoryIntegration.addContainerKey(source, metadata)
    return ox_inventory:AddItem(source, 'containerkey', 1, metadata)
end

function InventoryIntegration.getContainerKeys(source)
    local slots = ox_inventory:GetSlotsWithItem(source, 'containerkey')
    return slots
end

function InventoryIntegration.cutNewKey(source, data)
    local src = source
    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - Config.keyCuttingCoords) > 2 then return false end
    if ox_inventory:Search(src, 'count', 'containerkey', data) <= 0 then return false end

    if ox_inventory:Search(src, 'count', 'blankkey') <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            id = "missing_key",
            title = 'Missing a blank key!',
            type = 'error'
        })
        return false
    end

    if ox_inventory:RemoveItem(src, 'blankkey', 1) then
        ox_inventory:AddItem(src, 'containerkey', 1, data)
        return true
    end

    return false
end

-- Export for containergps item
function InventoryIntegration.useContainerGPS(event, _, inventory, _, _)
    if event == 'usingItem' then
        local src = inventory.id
        local isRaycasting = lib.callback.await('pan-containers:isRaycastActive', src)
        if isRaycasting then return end
        TriggerClientEvent('pan-containers:startraycast', src)
    end
end

return InventoryIntegration
