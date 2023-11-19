local shownGangMenu = false

-- UTIL
local function CloseMenuFull()
    lib.hideContext()
    lib.hideTextUI()
    shownGangMenu = false
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
end)

RegisterNetEvent('qbx_management:client:gangOpenMenu', function()
    TriggerEvent('qbx_management:client:OpenMenu', 'gang')
end)

-- MAIN THREAD
CreateThread(function()
    if Config.UseTarget then
        for gang, zones in pairs(Config.GangMenuZones) do
            for i = 1, #zones do
                local data = zones[i]
                exports.ox_target:addBoxZone({
                    coords = data.coords,
                    size = data.size,
                    rotation = data.rotation,
                    options = {
                        {
                            name = 'gang_menu',
                            event = 'qbx_management:client:gangOpenMenu',
                            icon = 'fa-solid fa-right-to-bracket',
                            label = 'Gang Menu',
                            groups = gang
                        }
                    }
                })
            end
        end
    else
        local wait
        while true do
            local pos = GetEntityCoords(cache.ped)
            local nearGangmenu = false
            wait = 1000

            if QBX.PlayerData.gang then
                wait = 100
                for k, v in pairs(Config.GangMenus) do
                    for _, coords in pairs(v) do
                        if k == QBX.PlayerData.gang.name and QBX.PlayerData.gang.isboss then
                            if #(pos - coords) <= 1.5 then
                                nearGangmenu = true

                                if not shownGangMenu then
                                    lib.showTextUI('[E] - Open Gang Management')
                                    shownGangMenu = true
                                end

                                wait = 0

                                if IsControlJustReleased(0, 38) then
                                    lib.hideTextUI()
                                    TriggerEvent('qbx_management:client:gangOpenMenu')
                                end
                            end
                        end
                    end
                end

                if not nearGangmenu then
                    wait = 1000
                    if shownGangMenu then
                        CloseMenuFull()
                        shownGangMenu = false
                    end
                end
            end

            Wait(wait)
        end
    end
end)
