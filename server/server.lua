local ox_inventory = exports.ox_inventory
local Containers = {}

-- Functions

local function spawnContainer(uuid, label, coords, heading, target)
    local container = CreateObjectNoOffset(Config.containerModel, coords.x, coords.y, coords.z, true, true, false) -- Creating the container object
    SetEntityHeading(container, heading)
    FreezeEntityPosition(container, true)

    -- Storing container data in entity state
    Entity(container).state.uuid = uuid
    Entity(container).state.label = label
    Entity(container).state.target = target

    Containers[uuid] = {
        entity = NetworkGetNetworkIdFromEntity(container),
        coords = vector3(coords.x, coords.y, coords.z),
        heading = heading,
        target = vector3(target.x, target.y, target.z)
    }
    if not ox_inventory:GetInventory('container_'..uuid) then
        ox_inventory:RegisterStash('container_'..uuid, 'Container', Config.containerSlots, Config.containerWeight, nil, nil, coords)
    end
end

local function loadContainers()
    local response = {{}}
    response = MySQL.query.await('SELECT * FROM pan_containers')
    if not response then return end

    for k, v in pairs(response) do
        local uuid = tonumber(v.uuid) or nil
        local label = tostring(v.label) or nil
        local coords = json.decode(v.coords)
        local heading = tonumber(v.heading) or 0
        local target = json.decode(v.target)

        if not Containers[uuid] then
            spawnContainer(uuid, label, coords, heading, target)
        end
    end
    lib.print.info('Loaded '..#response..' containers from the database')
end

-- Function to unload containers
local function unloadContainers()
    for k, v in pairs(Containers) do
        local entity = NetworkGetEntityFromNetworkId(v.entity)
        if DoesEntityExist(entity) then
            DeleteEntity(entity) -- Deleting container entity
            Containers[k] = nil -- Removing container from table
        end
    end
end

local function validateData(source, data)
    local ped = GetPlayerPed(source)
    if ox_inventory:Search(source, 'count', 'containergps') <= 0 then
        lib.print.warn('Player [' .. source .. '] triggered \'pan-containers:server:saveContainerData\' without having a gps')
        return false
    end
    if type(data.label) ~= 'string' and type(data.coords) ~= 'vector3' and type(data.heading) ~= 'number' and type(data.target) ~= 'vector3' then
        lib.print.warn('Unexpected types received from: ' .. source )
        return false
    end
    local container = {}
    if math.abs(#(GetEntityCoords(ped) - data.coords)) > 10 then
        lib.print.warn('Player [' .. source .. '] attempted to place a container out of range (10)')
        return false
    end
    if data.heading > 360 or data.heading < 0 then
        lib.print.warn('Player [' .. source .. '] attempted to place a container with a heading out of the expected range of values')
        return false
    end
    if math.abs(#(GetEntityCoords(ped) - data.target)) > 15 then
        lib.print.warn('Player [' .. source .. '] attempted to place a container with the target out of range (15)')
        return false
    end
    container.label = json.encode(data.label)
    container.coords = json.encode(data.coords)
    container.heading = json.encode(data.heading)
    container.target = json.encode(data.target)
    return true, container
end

local function afterSave(src, newRow)
    local response = MySQL.query.await('SELECT `uuid`, `coords`, `label` FROM `pan_containers` where `id` = ?', {newRow})
    local keydata = table.unpack(response)

    -- Remove the gps
    ox_inventory:RemoveItem(src, 'containergps', 1)

    -- Create a key
    local keymetadata = {
        uuid = keydata.uuid,
        coords = keydata.coords,
        keylabel = string.gsub(keydata.label, '\"', '')
    }
    ox_inventory:AddItem(src, 'containerkey', 1, keymetadata)
end

local function saveContainerToDatabase(source, data)
    local src = source
    local success, validData = validateData(source, data)
    if not success then return end

    -- Inserting container data into database
    local newRow = MySQL.insert.await('INSERT INTO `pan_containers` (label, coords, heading, target) VALUES (?, ?, ?, ?)', {
        validData.label,
        validData.coords,
        validData.heading,
        validData.target
    })

    afterSave(src, newRow)
end

-- Callbacks

lib.callback.register('pan-containers:server:canplace', function(source)
    local src = source
    local count = ox_inventory:Search(src, 'count', 'containergps')
    if count > 0 then
        return true
    end
    return false
end)

lib.callback.register('pan-containers:server:haskey', function(source)
    local src = source
    local count = ox_inventory:Search(src, 'count', 'containerkey')
    if count > 0 then
        return true
    end
    return false
end)

-- Hooks

local createItemHook = ox_inventory:registerHook('createItem', function(payload)
    local invId = payload.inventoryId
    local metadata = payload.metadata
    local count = ox_inventory:Search(invId, 'count', 'containerkey', metadata)

    if Containers[metadata.uuid] and count == 0 then
        TriggerClientEvent('pan-containers:client:createtargets', payload.inventoryId, Containers[metadata.uuid])
    end
    return metadata
end, {
    print = true,
    itemFilter = {
        containerkey = true
    }
})

local swapKeyHook = ox_inventory:registerHook('swapItems', function(payload)
    local src = payload.source
    local metadata = payload.fromSlot.metadata
    local fromInv = payload.fromInventory
    local toInv = payload.toInventory
    local count = ox_inventory:Search(src, 'count', 'containerkey', metadata)
    lib.print.info(payload)
    lib.print.warn('UUID: ' .. 'container_' .. metadata.uuid)
    lib.print.warn('Inv UUID: ' .. toInv)
    if toInv == 'container_' .. tostring(metadata.uuid) then
        return false
    end
    if (fromInv == src and fromInv ~= toInv and count == 1) then --Moving the key out of inventory handling
        TriggerClientEvent('pan-containers:client:removetargets', src, Containers[payload.fromSlot.metadata.uuid].entity)
        return true
    elseif (toInv == src and fromInv ~= toInv and count == 0) then --Moving the key into inventory handling
        TriggerClientEvent('pan-containers:client:createtargets', src, Containers[payload.fromSlot.metadata.uuid])
        return true
    end
    return true
end, {
    print = true,
    itemFilter = {
        containerkey = true
    }
})

-- Events

RegisterNetEvent('pan-containers:server:saveContainerData', function(data)
    local src = source
    saveContainerToDatabase(src, data)
end)

RegisterNetEvent('pan-containers:server:loadcontainers', function()
    local src = source
    loadContainers()
    TriggerEvent('pan-containers:server:loadcontainertargets', src)
end)

RegisterNetEvent('pan-containers:server:loadcontainertargets', function(player)
    print(source, player)
    local src = nil
    if player then
        src = player
    else
        src = source
    end

    local slots = ox_inventory:GetSlotsWithItem(src, 'containerkey')

    local uniqueKeys = {}
    local storedUUIDs = {}

    for _, v in ipairs(slots) do
        if not table.contains(storedUUIDs, v.metadata.uuid) then
            storedUUIDs[#storedUUIDs+1] = v.metadata.uuid
            uniqueKeys[#uniqueKeys+1] = v
        end
    end

    for _, v in ipairs(storedUUIDs) do
        TriggerClientEvent('pan-containers:client:createtargets', src, Containers[v])
    end
end)

RegisterNetEvent('pan-containers:server:cutNewKey', function(data)
    local src = source
    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - Config.keyCuttingCoords) > 2 then return end -- if this is true someones cheatin
    if ox_inventory:Search(src, 'count', 'containerkey', data) <= 0 then return end -- same here

    if ox_inventory:Search(src, 'count', 'blankkey') <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            id = "missing_key",
            title = 'Missing a blank key!',
            type = 'error'
        })
        return
    end
    if ox_inventory:RemoveItem(src, 'blankkey', 1) then
        ox_inventory:AddItem(src, 'containerkey', 1, data)
    end

end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    loadContainers()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    unloadContainers()
    ox_inventory:removeHooks()
end)

-- Exports

exports('containergps', function(event, _, inventory, _, _)
    if event == 'usingItem' then
        local src = inventory.id
        local isRaycasting = lib.callback.await('pan-containers:isRaycastActive', src)
        if isRaycasting then return end -- Don't start again if already raycasting placement
        TriggerClientEvent('pan-containers:startraycast', src)
    end
end)