local ox_inventory = exports.ox_inventory
local Config = require 'shared.config'

-- Container class definition
local Container = {}
Container.__index = Container

function Container.new(id, label, coords, heading, target)
    local self = setmetatable({}, Container)
    self.id = id
    self.label = label
    self.coords = coords
    self.heading = heading
    self.target = target
    self.entity = nil
    return self
end

function Container:spawn()
    local container = CreateObjectNoOffset(Config.containerModel, self.coords.x, self.coords.y, self.coords.z, true, true,
        false)
    SetEntityHeading(container, self.heading)
    FreezeEntityPosition(container, true)

    -- Store container data in entity state
    Entity(container).state.id = self.id
    Entity(container).state.label = self.label
    Entity(container).state.target = self.target

    self.entity = NetworkGetNetworkIdFromEntity(container)
    return self
end

function Container:registerInventory()
    if not ox_inventory:GetInventory('container_' .. self.id) then
        ox_inventory:RegisterStash('container_' .. self.id, 'Container', Config.containerSlots, Config.containerWeight,
            nil, nil, self.target)
    end
    return self
end

function Container:delete()
    local entity = NetworkGetEntityFromNetworkId(self.entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        return true
    end
    return false
end

function Container:toTable()
    return {
        entity = self.entity,
        coords = self.coords,
        heading = self.heading,
        target = self.target
    }
end

-- Container Manager (singleton)
local ContainerManager = {
    containers = {}
}

function ContainerManager:getContainer(id)
    return self.containers[id]
end

function ContainerManager:addContainer(container)
    self.containers[container.id] = container:toTable()
end

function ContainerManager:removeContainer(id)
    self.containers[id] = nil
end

function ContainerManager:getAllContainers()
    return self.containers
end

return {
    Container = Container,
    ContainerManager = ContainerManager
}
