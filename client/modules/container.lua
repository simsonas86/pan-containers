local ox_inventory = exports.ox_inventory
local Utility = require 'shared.utilities'

local Container = {}

-- Container blip
local ContainerBlip = nil

-- Mark container on map
function Container.markContainer(slot)
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
end

-- Duplicate container key
function Container.duplicateKey()
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
end

-- Clean up resources
function Container.cleanup()
    if ContainerBlip then
        RemoveBlip(ContainerBlip)
        ContainerBlip = nil
    end
end

return Container