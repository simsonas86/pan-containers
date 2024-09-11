Config = {

    debug = true,

    target = 'ox',      -- Supported: 'ox'
    inventory = 'ox',   -- Supported: 'ox'

    containerModel = joaat('prop_container_05a'),   --Technically changeable but might need slight tweaking in code right now
    cargobobModel = joaat('cargobob2'),
    pedModel = joaat('s_m_m_marine_01'),

    spawnRadiusMin = 250,       -- Radius to spawn cargobob
    spawnRadiusMax = 500,       -- Radius to spawn cargobob
    spawnHeight = 200,          -- Height at which to spawn cargobob

    containerSlots = 20,        -- Requires server restart
    containerWeight = 50000,    -- Requires server restart

    keyCuttingCoords = vector3(169.81, -1799.71, 29.46),

    drawColors = {                          -- Colours for corner markers when placement is valid or invalid
        ['valid'] 	= { 80, 170, 50, 255 }, -- RGBA
        ['invalid'] = { 170, 80, 50, 255 }  -- RGBA
    }
}