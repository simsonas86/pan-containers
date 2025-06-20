local FrameworkIntegration = {}

local frameworks = {
    ['es_extended'] = 'esx:playerLoaded',
    ['ox_core'] = 'ox:playerLoaded',
    ['qbx_core'] = 'QBCore:Server:OnPlayerLoaded',
    ['qb-core'] = 'QBCore:Server:OnPlayerLoaded'
}

function FrameworkIntegration.initialize()
    local success = nil

    for framework, event in pairs(frameworks) do
        if GetResourceState(framework):find('start') then
            RegisterNetEvent(event, function()
                local src = source
                print('Triggered ' .. event .. ' | src: ' .. tostring(src))
                TriggerEvent('pan-containers:server:loadContainerTargets', src)
            end)
            print(('Supported framework found: %s'):format(framework:lower()))
            success = event
            break
        end
    end

    if not success then
        warn('No supported framework has been found. Some features will not work.')
    end

    return success
end

return FrameworkIntegration