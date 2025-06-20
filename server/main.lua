-- Import modules
local ContainerModule = require 'server.modules.container'
local Database = require 'server.modules.database'
local Validation = require 'server.modules.validation'
local FrameworkIntegration = require 'server.modules.framework'
local InventoryIntegration = require 'server.modules.inventory'
local Config = require 'shared.config'
local Utility = require 'shared.utilities'

-- Setup container module
local Container = ContainerModule.Container
local ContainerManager = ContainerModule.ContainerManager

-- Initialize framework integration
FrameworkIntegration.initialize()

-- Initialize inventory hooks
InventoryIntegration.registerHooks()

-- Functions
local function loadContainers()
    local containers = Database.loadContainers()

    for _, v in pairs(containers) do
        local id = tonumber(v.id) or nil
        local label = tostring(v.label) or nil
        local coords = json.decode(v.coords)
        local heading = tonumber(v.heading) or 0
        local target = json.decode(v.target)

        if not ContainerManager:getContainer(id) then
            local container = Container.new(id, label, coords, heading, target)
            container:spawn():registerInventory()
            ContainerManager:addContainer(container)
        end
    end

    lib.print.info('Loaded '..#containers..' containers from the database')
end

local function unloadContainers()
    for id, containerData in pairs(ContainerManager:getAllContainers()) do
        local entity = NetworkGetEntityFromNetworkId(containerData.entity)
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
            ContainerManager:removeContainer(id)
        end
    end
end

local function saveContainerToDatabase(source, data)
    local src = source
    local success, validData = Validation.validateContainerData(source, data)
    if not success then return end

    local newRow = Database.saveContainer(validData)

    -- After save operations
    local keydata = Database.getContainerById(newRow)

    -- Remove the gps and create a key using inventory module
    InventoryIntegration.removeContainerGPS(src)

    -- Create a key
    local keymetadata = {
        id = keydata.id,
        coords = keydata.coords,
        keylabel = string.gsub(keydata.label, '\"', '')
    }
    InventoryIntegration.addContainerKey(src, keymetadata)
end

-- Callbacks
lib.callback.register('pan-containers:server:canplace', function(source)
    return InventoryIntegration.hasContainerGPS(source)
end)

lib.callback.register('pan-containers:server:haskey', function(source)
    return InventoryIntegration.hasContainerKey(source)
end)

-- Events
RegisterNetEvent('pan-containers:server:saveContainerData', function(data)
    local src = source
    saveContainerToDatabase(src, data)
end)

RegisterNetEvent('pan-containers:server:loadContainers', function()
    local src = source
    loadContainers()
    TriggerEvent('pan-containers:server:loadContainerTargets', src)
end)

RegisterNetEvent('pan-containers:server:loadContainerTargets', function(player)
    local src = player or source
    print('Triggered pan-containers:server:loadContainerTargets | src: ' .. tostring(src))
    local list = {}
    local slots = InventoryIntegration.getContainerKeys(src)
    if type(slots) ~= 'table' then
        return
    end
    for _, v in ipairs(slots) do
        if not table.contains(list, v.metadata.id) then
            list[#list+1] = v.metadata.id
            TriggerClientEvent('pan-containers:client:createtargets', src, ContainerManager:getContainer(v.metadata.id))
        end
    end
end)

RegisterNetEvent('pan-containers:server:cutNewKey', function(data)
    local src = source
    InventoryIntegration.cutNewKey(src, data)
end)

-- Resource lifecycle events
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    loadContainers()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    unloadContainers()
    InventoryIntegration.removeHooks()
end)

-- Exports
exports('containergps', InventoryIntegration.useContainerGPS)