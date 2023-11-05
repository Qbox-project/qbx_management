local shownGangMenu = false
local DynamicMenuItems = {}
local gangs = exports.qbx_core:GetGangs()

-- UTIL
local function CloseMenuFull()
    lib.hideContext()
    lib.hideTextUI()
    shownGangMenu = false
end

local function AddGangMenuItem(data, id)
    local menuID = id or #DynamicMenuItems + 1
    DynamicMenuItems[menuID] = lib.table.deepclone(data)
    return menuID
end

exports("AddGangMenuItem", AddGangMenuItem)

local function RemoveGangMenuItem(id)
    DynamicMenuItems[id] = nil
end

exports("RemoveGangMenuItem", RemoveGangMenuItem)

RegisterNetEvent('qb-gangmenu:client:Stash', function()
    exports.ox_inventory:openInventory('stash', 'gang_' .. QBX.PlayerData.gang.name)
end)

RegisterNetEvent('qb-gangmenu:client:Warbobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('qb-gangmenu:client:OpenMenu', function()
    if not QBX.PlayerData.gang.name or not QBX.PlayerData.gang.isboss then return end

    shownGangMenu = true

    local gangMenu = {
        {
            title = 'Manage Gang Members',
            icon = 'fa-solid fa-list',
            description = 'Recruit or Fire Gang Members',
            event = 'qb-gangmenu:client:ManageGang'
        },
        {
            title = 'Recruit Members',
            icon = 'fa-solid fa-hand-holding',
            description = 'Hire Gang Members',
            event = 'qb-gangmenu:client:HireMembers'
        },
        {
            title = 'Storage Access',
            icon = 'fa-solid fa-box-open',
            description = 'Open Gang Stash',
            event = 'qb-gangmenu:client:Stash'
        },
        {
            title = 'Outfits',
            icon = 'fa-solid fa-shirt',
            description = 'Change Clothes',
            event = 'qb-gangmenu:client:Warbobe'
        },
        {
            title = 'Money Management',
            icon = 'fa-solid fa-sack-dollar',
            description = 'Check your Gang Balance',
            event = 'qb-gangmenu:client:SocietyMenu'
        }
    }

    for _, v in pairs(DynamicMenuItems) do
        gangMenu[#gangMenu + 1] = v
    end

    lib.registerContext({
        id = 'qb_management_open_gangMenu',
        title = "Gang Management - " .. string.upper(QBX.PlayerData.gang.label),
        options = gangMenu
    })

    lib.showContext('qb_management_open_gangMenu')
end)

RegisterNetEvent('qb-gangmenu:client:ManageGang', function()
    local GangMembersMenu = {}

    local employees = lib.callback.await('qb-gangmenu:server:GetEmployees', false, QBX.PlayerData.gang.name)
    for _, v in pairs(employees) do
        GangMembersMenu[#GangMembersMenu + 1] = {
            title = v.name,
            description = v.grade.name,
            event = 'qb-gangmenu:lient:ManageMember',
            args = {
                player = v,
                work = QBX.PlayerData.gang
            }
        }
    end

    GangMembersMenu[#GangMembersMenu + 1] = {
        title = "Return",
        icon = 'fa-solid fa-angle-left',
        event = 'qb-gangmenu:client:OpenMenu'
    }

    lib.registerContext({
        id = 'qb_management_open_gangManage',
        title = "Manage Gang Members - " .. string.upper(QBX.PlayerData.gang.label),
        options = GangMembersMenu
    })

    lib.showContext('qb_management_open_gangManage')
end)

RegisterNetEvent('qb-gangmenu:lient:ManageMember', function(data)
    local MemberMenu = {}

    for k, v in pairs(gangs[data.work.name].grades) do
        MemberMenu[#MemberMenu + 1] = {
            title = v.name,
            description = "Grade: " .. k,
            serverEvent = 'qb-gangmenu:server:GradeUpdate',
            args = {
                cid = data.player.empSource,
                grade = tonumber(k),
                gradename = v.name
            }
        }
    end

    MemberMenu[#MemberMenu + 1] = {
        title = "Fire",
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'qb-gangmenu:server:FireMember',
        args = data.player.empSource
    }

    MemberMenu[#MemberMenu + 1] = {
        title = "Return",
        icon = 'fa-solid fa-angle-left',
        event = 'qb-gangmenu:client:ManageGang'
    }

    lib.registerContext({
        id = 'qb_management_open_gangMember',
        title = "Manage " .. data.player.name .. " - " .. string.upper(QBX.PlayerData.gang.label),
        options = MemberMenu
    })

    lib.showContext('qb_management_open_gangMember')
end)

RegisterNetEvent('qb-gangmenu:client:HireMembers', function()
    local HireMembersMenu = {}

    local players = lib.callback.await('qb-gangmenu:getplayers')
    for _, v in pairs(players) do
        if v and v ~= cache.playerId then
            HireMembersMenu[#HireMembersMenu + 1] = {
                title = v.name,
                description = "Citizen ID: " .. v.citizenid .. " - ID: " .. v.sourceplayer,
                serverEvent = 'qb-gangmenu:server:HireMember',
                args = v.sourceplayer
            }
        end
    end

    HireMembersMenu[#HireMembersMenu + 1] = {
        title = "Return",
        icon = 'fa-solid fa-angle-left',
        event = 'qb-gangmenu:client:OpenMenu'
    }

    lib.registerContext({
        id = 'qb_management_open_gangHire',
        title = "Hire Gang Members - " .. string.upper(QBX.PlayerData.gang.label),
        options = HireMembersMenu
    })

    lib.showContext('qb_management_open_gangHire')
end)

RegisterNetEvent('qb-gangmenu:client:SocietyMenu', function()
    local amount = lib.callback.await('qb-gangmenu:server:GetAccount')
    local SocietyMenu = {
        {
            title = "Deposit",
            icon = 'fa-solid fa-money-bill-transfer',
            description = "Deposit Money",
            event = 'qb-gangmenu:client:SocietyDeposit',
            args = amount
        },
        {
            title = "Withdraw",
            icon = 'fa-solid fa-money-bill-transfer',
            description = "Withdraw Money",
            event = 'qb-gangmenu:client:SocietyWithdraw',
            args = amount
        },
        {
            title = "Return",
            icon = 'fa-solid fa-angle-left',
            event = 'qb-gangmenu:client:OpenMenu'
        }
    }

    lib.registerContext({
        id = 'qb_management_open_gangSociety',
        title = "Balance: $" .. comma_value(amount) .. " - " .. string.upper(QBX.PlayerData.gang.label),
        options = SocietyMenu
    })

    lib.showContext('qb_management_open_gangSociety')
end)

RegisterNetEvent('qb-gangmenu:client:SocietyDeposit', function(money)
    local deposit = lib.inputDialog("Deposit Money", {
        {
            type = 'input',
            label = "Available Balance",
            disabled = true,
            default = comma_value(money)
        },
        {
            type = 'number',
            label = "Amount"
        }
    })

    if not deposit then
        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    if not deposit[2] then
        exports.qbx_core:Notify('Amount value is missing!', 'error')

        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    local depositAmount = tonumber(deposit[2])

    if depositAmount <= 0 then
        exports.qbx_core:Notify('Amount need to be higher than zero!', 'error')

        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    TriggerServerEvent('qb-gangmenu:server:depositMoney', depositAmount)
end)

RegisterNetEvent('qb-gangmenu:client:SocietyWithdraw', function(money)
    local withdraw = lib.inputDialog("Withdraw Money", {
        {
            type = 'input',
            label = "Available Balance",
            disabled = true,
            default = comma_value(money)
        },
        {
            type = 'input',
            label = "Amount"
        }
    })

    if not withdraw then
        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    if not withdraw[2] then
        exports.qbx_core:Notify('Amount value is missing!', 'error')

        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    local withdrawAmount = tonumber(withdraw[2])

    if withdrawAmount > tonumber(money) then
        exports.qbx_core:Notify('You cant withdraw that amount of money!', 'error')

        TriggerEvent('qb-gangmenu:client:SocietyMenu')
        return
    end

    TriggerServerEvent('qb-gangmenu:server:withdrawMoney', withdrawAmount)
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
                            event = 'qb-gangmenu:client:OpenMenu',
                            icon = "fa-solid fa-right-to-bracket",
                            label = "Gang Menu",
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
                                    lib.showTextUI("[E] - Open Gang Management")
                                    shownGangMenu = true
                                end

                                wait = 0

                                if IsControlJustReleased(0, 38) then
                                    lib.hideTextUI()
                                    TriggerEvent('qb-gangmenu:client:OpenMenu')
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
