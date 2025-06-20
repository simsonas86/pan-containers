local Database = {}

function Database.loadContainers()
    local response = MySQL.query.await('SELECT * FROM pan_containers')
    if not response then return {} end
    return response
end

function Database.saveContainer(data)
    -- Inserting container data into database
    local newRow = MySQL.insert.await('INSERT INTO `pan_containers` (label, coords, heading, target) VALUES (?, ?, ?, ?)', {
        data.label,
        data.coords,
        data.heading,
        data.target
    })
    return newRow
end

function Database.getContainerById(id)
    local response = MySQL.query.await('SELECT `id`, `coords`, `label` FROM `pan_containers` where `id` = ?', {id})
    return table.unpack(response)
end

return Database