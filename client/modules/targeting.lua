local ox_target = exports.ox_target
local Config = require 'shared.config'
local Utility = require 'shared.utilities'

local Targeting = {}

-- Target template for container targets
local targetTemplate = {
    size = vec3(0.2, 0.2, 0.2),
    drawSprite = true
}

-- Store all active targets
local Targets = {}

-- Create a target for key cutting
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

-- Create a target for a container
function Targeting.createTarget(data)
    targetTemplate.coords = data.target
    targetTemplate.options = {
        {
            name = 'open_container',
            icon = 'fa-solid fa-cube',
            label = 'Open Container',
            onSelect = function()
                exports.ox_inventory:openInventory('stash', { id = 'container_' .. Entity(NetworkGetEntityFromNetworkId(data.entity)).state.id })
            end
        }
    }
    Targets[data.entity] = ox_target:addBoxZone(targetTemplate)
    lib.print.verbose('Created zone: ' .. Targets[data.entity])
end

-- Remove a target for a container
function Targeting.removeTarget(entity)
    if not Targets[entity] then return end
    lib.print.verbose('Removed zone: ' .. Targets[entity])
    ox_target:removeZone(Targets[entity])
    Targets[entity] = nil
end

-- Initialize targeting system
function Targeting.init()
    createCuttingTarget()
end

-- Clean up targets on resource stop
function Targeting.cleanup()
    if #Targets > 0 then
        for i in #Targets do
            ox_target:removeZone(Targets[i])
        end
    end
end

-- Get all targets
function Targeting.getTargets()
    return Targets
end

return Targeting