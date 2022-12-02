local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = QBCore.Functions.GetPlayerData().job
local shownBossMenu = false
local DynamicMenuItems = {}

-- UTIL
local function CloseMenuFull()
    lib.hideContext()
    lib.hideTextUI()

    shownBossMenu = false
end

local function AddBossMenuItem(data, id)
    local menuID = id or (#DynamicMenuItems + 1)

    DynamicMenuItems[menuID] = deepcopy(data)

    return menuID
end
exports('AddBossMenuItem', AddBossMenuItem)

local function RemoveBossMenuItem(id)
    DynamicMenuItems[id] = nil
end
exports('RemoveBossMenuItem', RemoveBossMenuItem)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('qb-bossmenu:client:OpenMenu', function()
    if not PlayerJob.name or not PlayerJob.isboss then
        return
    end

    local bossMenu = {
        {
            title = "Manage Employees",
            description = "Check your Employees List",
            icon = 'fa-solid fa-list',
            event = 'qb-bossmenu:client:employeelist'
        },
        {
            title = "Hire Employees",
            description = "Hire Nearby Civilians",
            icon = 'fa-solid fa-hand-holding',
            event = 'qb-bossmenu:client:HireMenu'
        },
        {
            title = "Storage Access",
            description = "Open Storage",
            icon = 'fa-solid fa-box-open',
            event = 'qb-bossmenu:client:Stash'
        },
        {
            title = "Outfits",
            description = "See Saved Outfits",
            icon = 'fa-solid fa-shirt',
            event = 'qb-bossmenu:client:Wardrobe'
        },
        {
            title = "Money Management",
            description = "Check your Company Balance",
            icon = 'fa-solid fa-sack-dollar',
            event = 'qb-bossmenu:client:SocietyMenu'
        }
    }

    for _, v in pairs(DynamicMenuItems) do
        bossMenu[#bossMenu + 1] = v
    end

    lib.registerContext({
        id = 'open_bossMenu',
        title = "Boss Menu - " .. string.upper(PlayerJob.label),
        options = bossMenu
    })
    lib.showContext('open_bossMenu')
end)

RegisterNetEvent('qb-bossmenu:client:employeelist', function()
    local EmployeesMenu = {}

    QBCore.Functions.TriggerCallback('qb-bossmenu:server:GetEmployees', function(cb)
        for _, v in pairs(cb) do
            EmployeesMenu[#EmployeesMenu + 1] = {
                title = v.name,
                description = v.grade.name,
                event = 'qb-bossmenu:client:ManageEmployee',
                args = {
                    player = v,
                    work = PlayerJob
                }
            }
        end

        EmployeesMenu[#EmployeesMenu + 1] = {
            title = "Return",
            icon = 'fa-solid fa-angle-left',
            event = 'qb-bossmenu:client:OpenMenu'
        }

        lib.registerContext({
            id = 'open_bossManage',
            title = "Manage Employees - " .. string.upper(PlayerJob.label),
            options = EmployeesMenu
        })
        lib.showContext('open_bossManage')
    end, PlayerJob.name)
end)

RegisterNetEvent('qb-bossmenu:client:ManageEmployee', function(data)
    local EmployeeMenu = {}

    for k, v in pairs(QBCore.Shared.Jobs[data.work.name].grades) do
        EmployeeMenu[#EmployeeMenu + 1] = {
            title = v.name,
            description = "Grade: " .. k,
            serverEvent = 'qb-bossmenu:server:GradeUpdate',
            args = {
                cid = data.player.empSource,
                grade = tonumber(k),
                gradename = v.name
            }
        }
    end

    EmployeeMenu[#EmployeeMenu + 1] = {
        title = "Fire Employee",
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'qb-bossmenu:server:FireEmployee',
        args = data.player.empSource
    }
    EmployeeMenu[#EmployeeMenu + 1] = {
        title = "Return",
        icon = 'fa-solid fa-angle-left',
        event = 'qb-bossmenu:client:OpenMenu'
    }

    lib.registerContext({
        id = 'open_bossMember',
        title = "Manage " .. data.player.name .. " - " .. string.upper(PlayerJob.label),
        options = EmployeeMenu
    })
    lib.showContext('open_bossMember')
end)

RegisterNetEvent('qb-bossmenu:client:Stash', function()
    exports.ox_inventory:openInventory('stash', 'boss_' .. PlayerJob.name)
end)

RegisterNetEvent('qb-bossmenu:client:Wardrobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('qb-bossmenu:client:HireMenu', function()
    local HireMenu = {}

    QBCore.Functions.TriggerCallback('qb-bossmenu:getplayers', function(players)
        for _, v in pairs(players) do
            if v and v ~= cache.playerId then
                HireMenu[#HireMenu + 1] = {
                    title = v.name,
                    description = "Citizen ID: " .. v.citizenid .. " - ID: " .. v.sourceplayer,
                    serverEvent = 'qb-bossmenu:server:HireEmployee',
                    args = v.sourceplayer
                }
            end
        end

        HireMenu[#HireMenu + 1] = {
            title = "Return",
            icon = 'fa-solid fa-angle-left',
            event = 'qb-bossmenu:client:OpenMenu'
        }

        lib.registerContext({
            id = 'open_bossHire',
            title = "Hire Employees - " .. string.upper(PlayerJob.label),
            options = HireMenu
        })
        lib.showContext('open_bossHire')
    end)
end)

RegisterNetEvent('qb-bossmenu:client:SocietyMenu', function()
    QBCore.Functions.TriggerCallback('qb-bossmenu:server:GetAccount', function(amount)
        local SocietyMenu = {
            {
                title = "Deposit",
                icon = 'fa-solid fa-money-bill-transfer',
                description = "Deposit Money into account",
                event = 'qb-bossmenu:client:SocetyDeposit',
                args = comma_value(amount)
            },
            {
                title = "Withdraw",
                icon = 'fa-solid fa-money-bill-transfer',
                description = "Withdraw Money from account",
                event = 'qb-bossmenu:client:SocetyWithDraw',
                args = comma_value(amount)
            },
            {
                title = "Return",
                icon = 'fa-solid fa-angle-left',
                event = 'qb-bossmenu:client:OpenMenu'
            }
        }

        lib.registerContext({
            id = 'open_bossSociety',
            title = "Balance: $" .. comma_value(amount) .. " - " .. string.upper(PlayerJob.label),
            options = SocietyMenu
        })
        lib.showContext('open_bossSociety')
    end, PlayerJob.name)
end)

RegisterNetEvent('qb-bossmenu:client:SocetyDeposit', function(money)
    local deposit = lib.inputDialog('Deposit Money', {
        {
            type = 'input',
            label = "Available Balance",
            disabled = true,
            default = money
        },
        {
            type = 'number',
            label = "Amount"
        }
    })

    if not deposit[2] then
        lib.notify({
            description = 'Amount value is missing!',
            type = 'error'
        })

        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    local depositAmount = tonumber(deposit[2])

    if depositAmount <= 0 then
        lib.notify({
            description = 'Amount need to be higher than zero!',
            type = 'error'
        })

        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    TriggerServerEvent('qb-bossmenu:server:depositMoney', depositAmount)
end)

RegisterNetEvent('qb-bossmenu:client:SocetyWithDraw', function(balance)
    local withdraw = lib.inputDialog("Withdraw Money", {
        {
            type = 'input',
            label = "Available Balance",
            disabled = true,
            default = balance
        },
        {
            type = 'number',
            label = "Amount"
        }
    })

    if not withdraw[2] then
        lib.notify({
            description = 'Amount value is missing!',
            type = 'error'
        })

        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    local withdrawAmount = tonumber(withdraw[2])

    if withdrawAmount > tonumber(balance) then
        lib.notify({
            description = 'You cant withdraw that amount of money!',
            type = 'error'
        })

        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    TriggerServerEvent('qb-bossmenu:server:withdrawMoney', withdrawAmount)
end)

-- MAIN THREAD
CreateThread(function()
    if Config.UseTarget then
        for job, zones in pairs(Config.BossMenuZones) do
            for _, data in ipairs(zones) do
                exports.ox_target:addBoxZone({
                    coords = data.coords,
                    size = data.size,
                    rotation = data.rotation,
                    options = {
                        {
                            name = 'boss_menu',
                            event = 'qb-bossmenu:client:OpenMenu',
                            icon = "fa-solid fa-right-to-bracket",
                            label = "Boss Menu",
                            canInteract = function(_, _, _, _)
                                return job == PlayerJob.name and PlayerJob.isboss
                            end
                        }
                    }
                })
            end
        end
    else
        while true do
            local wait = 2500
            local pos = GetEntityCoords(cache.ped)
            local inRangeBoss = false
            local nearBossmenu = false

            if PlayerJob then
                wait = 0

                for k, v in pairs(Config.BossMenus) do
                    for _, coords in pairs(v) do
                        if k == PlayerJob.name and PlayerJob.isboss then
                            if #(pos - coords) < 5.0 then
                                inRangeBoss = true

                                if #(pos - coords) <= 1.5 then
                                    nearBossmenu = true

                                    if not shownBossMenu then
                                        lib.showTextUI("[E] - Open Job Management")

                                        shownBossMenu = true
                                    end

                                    if IsControlJustReleased(0, 38) then
                                        lib.hideTextUI()

                                        TriggerEvent('qb-bossmenu:client:OpenMenu')
                                    end
                                end

                                if not nearBossmenu and shownBossMenu then
                                    CloseMenuFull()

                                    shownBossMenu = false
                                end
                            end
                        end
                    end
                end

                if not inRangeBoss then
                    Wait(1500)

                    if shownBossMenu then
                        CloseMenuFull()

                        shownBossMenu = false
                    end
                end
            end

            Wait(wait)
        end
    end
end)