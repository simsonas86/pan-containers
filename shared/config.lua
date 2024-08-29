Config = {

    debug = true,

    framework = 'qb',   -- Supported: 'ox' | 'qb'
    target = 'ox',      -- Supported: 'ox'
    inventory = 'ox',   -- Supported: 'ox'

    containerModel = joaat('prop_container_05a'),
    cargobobModel = joaat('cargobob2'),
    pedModel = joaat('s_m_m_marine_01'),

    spawnRadiusMin = 250,       -- Radius to spawn cargobob
    spawnRadiusMax = 500,       -- Radius to spawn cargobob
    spawnHeight = 200,          -- Height at which to spawn cargobob

    containerSlots = 20,        -- Requires server restart
    containerWeight = 50000,    -- Requires server restart

    keyCuttingCoords = vector3(169.81, -1799.71, 29.46),

    drawColors = {
        ['valid'] 	= { 80, 170, 50, 255 }, -- RGBA
        ['invalid'] = { 170, 80, 50, 255 }  -- RGBA
    }
}