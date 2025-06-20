local InventoryIntegration = require 'server.modules.inventory'

local Validation = {}

function Validation.validateContainerData(source, data)
    local ped = GetPlayerPed(source)
    if not InventoryIntegration.hasContainerGPS(source) then
        lib.print.warn('Player [' .. source .. '] triggered \'pan-containers:server:saveContainerData\' without having a gps')
        return false
    end

    -- Type validation
    if type(data.label) ~= 'string' and type(data.coords) ~= 'vector3' and type(data.heading) ~= 'number' and type(data.target) ~= 'vector3' then
        lib.print.warn('Unexpected types received from: ' .. source )
        return false
    end

    -- Distance validation
    if math.abs(#(GetEntityCoords(ped) - data.coords)) > 10 then
        lib.print.warn('Player [' .. source .. '] attempted to place a container out of range (10)')
        return false
    end

    -- Heading validation
    if data.heading > 360 or data.heading < 0 then
        lib.print.warn('Player [' .. source .. '] attempted to place a container with a heading out of the expected range of values')
        return false
    end

    -- Target validation
    if math.abs(#(GetEntityCoords(ped) - data.target)) > 15 then
        lib.print.warn('Player [' .. source .. '] attempted to place a container with the target out of range (15)')
        return false
    end

    -- Label validation
    if not data.label:match("^[a-zA-Z0-9 ]+$") then
        lib.print.warn('Player [' .. source .. '] attempted to use invalid characters in container label')
        return false
    end

    local container = {}
    container.label = json.encode(data.label)
    container.coords = json.encode(data.coords)
    container.heading = json.encode(data.heading)
    container.target = json.encode(data.target)
    return true, container
end

return Validation
