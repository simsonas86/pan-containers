local ToConvert = {}

local function GetAllExistingUUIDs()
    if pcall(function()
        ToConvert = MySQL.query.await('SELECT `id`, `uuid` FROM pan_containers WHERE `uuid` IS NOT NULL')
    end) then
    else
        warn('Unable to convert UUIDs, column `uuid` does not exist.')
        return false
    end

    if not ToConvert then return end
    return true
end

local function ConvertOldInventories()
    for _, v in ipairs(ToConvert) do
        local oldName = 'container_'..v.uuid
        local newName = 'container_'..v.id
        MySQL.update('UPDATE ox_inventory SET `name` = ? WHERE `name` = ?', { newName, oldName },
        function()
            lib.print.info(oldName..' -> '..newName)
        end)
        MySQL.update('UPDATE pan_containers SET `uuid` = ? WHERE `uuid` = ?', { nil, v.uuid }, function() end)
    end

    MySQL.query('DROP INDEX `uuid` ON pan_containers')
    MySQL.query('ALTER TABLE pan_containers DROP COLUMN `uuid`')
end

if GetConvar('pan:convert', 'false') == 'true' then
    RegisterCommand('pan-containers:convert', function()
        if GetAllExistingUUIDs() then
            ConvertOldInventories()
        end
    end)
end