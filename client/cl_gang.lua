local QBCore = exports['qb-core']:GetCoreObject()
local PlayerGang = QBCore.Functions.GetPlayerData().gang
local shownGangMenu = false
local DynamicMenuItems = {}

-- UTIL
local function CloseMenuFullGang()
    lib.hideContext()
    lib.hideTextUI()

    shownGangMenu = false
end

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerGang = QBCore.Functions.GetPlayerData().gang
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(InfoGang)
    PlayerGang = InfoGang
end)

RegisterNetEvent('qb-gangmenu:client:Stash', function()
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', 'boss_' .. PlayerGang.name, {
        maxweight = 4000000,
        slots = 100
    })
    TriggerEvent('inventory:client:SetCurrentStash', 'boss_' .. PlayerGang.name)
end)

RegisterNetEvent('qb-gangmenu:client:Warbobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

local function AddGangMenuItem(data, id)
    local menuID = id or (#DynamicMenuItems + 1)

    DynamicMenuItems[menuID] = deepcopy(data)

    return menuID
end
exports('AddGangMenuItem', AddGangMenuItem)

local function RemoveGangMenuItem(id)
    DynamicMenuItems[id] = nil
end
exports('RemoveGangMenuItem', RemoveGangMenuItem)

RegisterNetEvent('qb-gangmenu:client:OpenMenu', function()
    shownGangMenu = true

    local gangMenu = {
        {
            title = Lang:t('menu.gang_manage_members_title'),
            icon = 'fa-solid fa-list',
            description = Lang:t('menu.gang_manage_members_description'),
            event = 'qb-gangmenu:client:ManageGang'
        },
        {
            title = Lang:t('menu.gang_hire_member_title'),
            icon = 'fa-solid fa-hand-holding',
            description = Lang:t('menu.gang_hire_member_description'),
            event = 'qb-gangmenu:client:HireMembers'
        },
        {
            title = Lang:t('menu.gang_stash_title'),
            icon = 'fa-solid fa-box-open',
            description = Lang:t('menu.gang_stash_description'),
            event = 'qb-gangmenu:client:Stash'
        },
        {
            title = Lang:t('menu.gang_outfits_title'),
            description = Lang:t('menu.gang_outfits_description'),
            icon = 'fa-solid fa-shirt',
            event = 'qb-gangmenu:client:Warbobe'
        },
        {
            title = Lang:t('menu.gang_money_management_title'),
            icon = 'fa-solid fa-sack-dollar',
            description = Lang:t('menu.gang_money_management_description'),
            event = 'qb-gangmenu:client:SocietyMenu'
        }
    }

    for _, v in pairs(DynamicMenuItems) do
        gangMenu[#gangMenu + 1] = v
    end

    gangMenu[#gangMenu + 1] = {
        title = Lang:t('menu.gang_exit_title'),
        icon = 'fa-solid fa-angle-left',
        onSelect = function()
            lib.hideContext()
        end
    }

    lib.registerContext({
        id = 'open_gangMenu',
        title = "Gang Management - " .. string.upper(PlayerGang.label),
        options = gangMenu
    })
    lib.showContext('open_gangMenu')
end)

RegisterNetEvent('qb-gangmenu:client:ManageGang', function()
    local GangMembersMenu = {}

    QBCore.Functions.TriggerCallback('qb-gangmenu:server:GetEmployees', function(cb)
        for _, v in pairs(cb) do
            GangMembersMenu[#GangMembersMenu + 1] = {
                title = v.name,
                description = v.grade.name,
                icon = 'fa-solid fa-circle-user',
                event = 'qb-gangmenu:lient:ManageMember',
                args = {
                    player = v,
                    work = PlayerGang
                }
            }
        end

        GangMembersMenu[#GangMembersMenu + 1] = {
            title = "Return",
            icon = 'fa-solid fa-angle-left',
            event = 'qb-gangmenu:client:OpenMenu'
        }

        lib.registerContext({
            id = 'open_gangManage',
            title = "Manage Gang Members - " .. string.upper(PlayerGang.label),
            options = GangMembersMenu
        })
        lib.showContext('open_gangManage')
    end, PlayerGang.name)
end)

RegisterNetEvent('qb-gangmenu:lient:ManageMember', function(data)
    local MemberMenu = {}

    for k, v in pairs(QBCore.Shared.Gangs[data.work.name].grades) do
        MemberMenu[#MemberMenu + 1] = {
            title = v.name,
            description = "Grade: " .. k,
            serverEvent = 'qb-gangmenu:server:GradeUpdate',
            icon = 'fa-solid fa-file-pen',
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
        id = 'open_gangMember',
        title = "Manage " .. data.player.name .. " - " .. string.upper(PlayerGang.label),
        options = MemberMenu
    })
    lib.showContext('open_gangMember')
end)

RegisterNetEvent('qb-gangmenu:client:HireMembers', function()
    local HireMembersMenu = {}

    QBCore.Functions.TriggerCallback('qb-gangmenu:getplayers', function(players)
        for _, v in pairs(players) do
            if v and v ~= cache.playerId then
                HireMembersMenu[#HireMembersMenu + 1] = {
                    title = v.name,
                    description = "Citizen ID: " .. v.citizenid .. " - ID: " .. v.sourceplayer,
                    icon = 'fa-solid fa-user-check',
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
            id = 'open_gangHire',
            title = "Hire Gang Members - " .. string.upper(PlayerGang.label),
            options = HireMembersMenu
        })
        lib.showContext('open_gangHire')
    end)
end)

RegisterNetEvent('qb-gangmenu:client:SocietyMenu', function()
    QBCore.Functions.TriggerCallback('qb-gangmenu:server:GetAccount', function(cb)
        local SocietyMenu = {
            {
                title = "Deposit",
                icon = 'fa-solid fa-money-bill-transfer',
                description = "Deposit Money",
                event = 'qb-gangmenu:client:SocietyDeposit',
                args = comma_value(cb)
            },
            {
                title = "Withdraw",
                icon = 'fa-solid fa-money-bill-transfer',
                description = "Withdraw Money",
                event = 'qb-gangmenu:client:SocietyWithdraw',
                args = comma_value(cb)
            },
            {
                title = "Return",
                icon = 'fa-solid fa-angle-left',
                event = 'qb-gangmenu:client:OpenMenu'
            }
        }

        lib.registerContext({
            id = 'open_gangSociety',
            title = "Balance: $" .. comma_value(cb) .. " - " .. string.upper(PlayerGang.label),
            options = SocietyMenu
        })
        lib.showContext('open_gangSociety')
    end, PlayerGang.name)
end)

RegisterNetEvent('qb-gangmenu:client:SocietyDeposit', function(saldoattuale)
    local deposit = lib.inputDialog("Deposit Money", {
        {
            type = 'number',
            label = "Available Balance",
            disabled = true,
            default = saldoattuale
        },
        {
            type = 'number',
            label = "Amount"
        }
    })

    if not deposit and next(deposit) then
        return
    end

    local depositAmount = tonumber(deposit[1])

    if depositAmount <= 0 then
        return
    end

    TriggerServerEvent('qb-gangmenu:server:depositMoney', depositAmount)
end)

RegisterNetEvent('qb-gangmenu:client:SocietyWithdraw', function(saldoattuale)
    local withdraw = lib.inputDialog("Withdraw Money", {
        {
            type = 'input',
            label = "Available Balance",
            disabled = true,
            default = saldoattuale
        },
        {
            type = 'input',
            label = "Amount"
        }
    })

    if not withdraw and next(withdraw) then
        return
    end

    local withdrawAmount = tonumber(withdraw[1])

    if withdrawAmount <= 0 then
        return
    end

    TriggerServerEvent('qb-gangmenu:server:withdrawMoney', withdrawAmount)
end)

-- MAIN THREAD
CreateThread(function()
    if Config.UseTarget then
        for gang, zones in pairs(Config.GangMenuZones) do
            for index, data in ipairs(zones) do
                exports['qb-target']:AddBoxZone(gang..'-GangMenu'..index, data.coords, data.length, data.width, {
                    name = gang .. '-GangMenu' .. index,
                    heading = data.heading,
                    minZ = data.minZ,
                    maxZ = data.maxZ
                }, {
                    options = {
                        {
                            type = 'client',
                            event = 'qb-gangmenu:client:OpenMenu',
                            icon = 'fas fa-sign-in-alt',
                            label = "Gang Menu",
                            canInteract = function()
                                return gang == PlayerGang.name and PlayerGang.isboss
                            end
                        }
                    },
                    distance = 2.5
                })
            end
        end
    else
        while true do
            local wait = 2500
            local pos = GetEntityCoords(cache.ped)
            local inRangeGang = false
            local nearGangmenu = false

            if PlayerGang then
                wait = 0

                for k, v in pairs(Config.GangMenus) do
                    if k == PlayerGang.name and PlayerGang.isboss then
                        if #(pos - v) < 5.0 then
                            inRangeGang = true

                            if #(pos - v) <= 1.5 then
                                nearGangmenu = true

                                if not shownGangMenu then
                                    lib.showTextUI("[E] - Open Gang Management")
                                end

                                if IsControlJustReleased(0, 38) then
                                    lib.hideTextUI()

                                    TriggerEvent('qb-gangmenu:client:OpenMenu')
                                end
                            end

                            if not nearGangmenu and shownGangMenu then
                                CloseMenuFullGang()

                                shownGangMenu = false
                            end
                        end
                    end
                end

                if not inRangeGang then
                    Wait(1500)

                    if shownGangMenu then
                        CloseMenuFullGang()

                        shownGangMenu = false
                    end
                end
            end

            Wait(wait)
        end
    end
end)