local shownBossMenu = false

-- UTIL
local function closeMenuFull()
    lib.hideContext()
    lib.hideTextUI()
    shownBossMenu = false
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
end)

RegisterNetEvent('qbx_management:client:bossOpenMenu', function()
    TriggerEvent('qbx_management:client:openMenu', 'job')
end)

-- MAIN THREAD
CreateThread(function()
    if Config.UseTarget then
        for job, zones in pairs(Config.BossMenuZones) do
            for i = 1, #zones do
                local data = zones[i]
                exports.ox_target:addBoxZone({
                    coords = data.coords,
                    size = data.size,
                    rotation = data.rotation,
                    debug = Config.PolyDebug,
                    options = {
                        {
                            name = 'boss_menu',
                            event = 'qbx_management:client:bossOpenMenu',
                            icon = 'fa-solid fa-right-to-bracket',
                            label = 'Boss Menu',
                            canInteract = function()
                                return job == QBX.PlayerData.job.name and QBX.PlayerData.job.isboss
                            end
                        }
                    }
                })
            end
        end
    else
        local wait
        while true do
            local pos = GetEntityCoords(cache.ped)
            local nearBossmenu = false
            wait = 1000

            if QBX.PlayerData.job then
                wait = 100
                for k, v in pairs(Config.BossMenus) do
                    for _, coords in pairs(v) do
                        if k == QBX.PlayerData.job.name and QBX.PlayerData.job.isboss then
                            if #(pos - coords) <= 1.5 then
                                nearBossmenu = true

                                if not shownBossMenu then
                                    lib.showTextUI('[E] - Open Job Management')
                                    shownBossMenu = true
                                end

                                wait = 0

                                if IsControlJustReleased(0, 38) then
                                    lib.hideTextUI()
                                    TriggerEvent('qbx_management:client:bossOpenMenu')
                                end
                            end
                        end
                    end
                end

                if not nearBossmenu then
                    wait = 1000
                    if shownBossMenu then
                        closeMenuFull()
                        shownBossMenu = false
                    end
                end
            end

            Wait(wait)
        end
    end
end)
