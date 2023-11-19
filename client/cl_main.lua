local jobs = exports.qbx_core:GetJobs()
local gangs = exports.qbx_core:GetGangs()
local DynamicMenuItems = {}

function CommaValue(amount)
    local numChanged

    repeat
        amount, numChanged = string.gsub(amount, '^(-?%d+)(%d%d%d)', '%1,%2')
    until numChanged == 0

    return amount
end

---@return table
function FindPlayers()
	local playerCoords = GetEntityCoords(cache.ped)
    local closePlayers = lib.getNearbyPlayers(playerCoords, 10, false)
    for _, v in pairs(closePlayers) do
        v.id = GetPlayerServerId(v.id)
    end
	return lib.callback.await('qbx_management:server:getplayers', false, closePlayers)
end

---@param type 'job'|'gang'
RegisterNetEvent('qbx_management:client:SocietyMenu', function(type)
    local amount = lib.callback.await('qbx_management:server:getAccount', false, QBX.PlayerData[type].name)
    local SocietyMenu = {
        {
            title = 'Deposit',
            icon = 'fa-solid fa-money-bill-transfer',
            description = 'Deposit Money',
            event = 'qbx_management:client:SocietyDeposit',
            args = {
                type = type,
                amount = amount
            }
        },
        {
            title = 'Withdraw',
            icon = 'fa-solid fa-money-bill-transfer',
            description = 'Withdraw Money',
            event = 'qbx_management:client:SocietyWithdraw',
            args = {
                type = type,
                amount = amount
            }
        },
        {
            title = 'Return',
            icon = 'fa-solid fa-angle-left',
            event = 'qbx_management:client:OpenMenu',
            args = type
        }
    }

    lib.registerContext({
        id = 'qbx_management_open_Society',
        title = 'Balance: $' .. CommaValue(amount) .. ' - ' .. string.upper(QBX.PlayerData[type].label),
        options = SocietyMenu
    })

    lib.showContext('qbx_management_open_Society')
end)

---@param data {amount: number, type: 'job'|'gang'}
RegisterNetEvent('qbx_management:client:SocietyDeposit', function(data)
    local deposit = lib.inputDialog('Deposit Money', {
        {
            type = 'input',
            label = 'Available Balance',
            disabled = true,
            default = CommaValue(data.amount)
        },
        {
            type = 'number',
            label = 'Amount'
        }
    })

    if not deposit then
        TriggerEvent('qbx_management:client:SocietyMenu', data.type)
        return
    end

    if not deposit[2] then
        exports.qbx_core:Notify('Amount value is missing!', 'error')

        TriggerEvent('qbx_management:client:SocietyMenu', data.type)
        return
    end

    local depositAmount = tonumber(deposit[2])

    if depositAmount <= 0 then
        exports.qbx_core:Notify('Amount need to be higher than zero!', 'error')

        TriggerEvent('qbx_management:client:SocietyMenu', data.type)
        return
    end

    TriggerServerEvent('qbx_management:server:depositMoney', data.type, depositAmount)
end)

---@param data {amount: number, type: 'job'|'gang'}
RegisterNetEvent('qbx_management:client:SocietyWithdraw', function(data)
    local withdraw = lib.inputDialog('Withdraw Money', {
        {
            type = 'input',
            label = 'Available Balance',
            disabled = true,
            default = CommaValue(data.amount)
        },
        {
            type = 'input',
            label = 'Amount'
        }
    })

    if not withdraw then
        TriggerEvent('qbx_management:client:SocietyMenu', data.type)
        return
    end

    if not withdraw[2] then
        exports.qbx_core:Notify('Amount value is missing!', 'error')

        TriggerEvent('qbx_management:client:SocietyMenu', data.type)
        return
    end

    local withdrawAmount = tonumber(withdraw[2])

    if withdrawAmount > tonumber(data.amount) then
        exports.qbx_core:Notify('You cant withdraw that amount of money!', 'error')

        TriggerEvent('qbx_management:client:SocietyMenu', data.type)
        return
    end


    TriggerServerEvent('qbx_management:server:withdrawMoney', data.type, withdrawAmount)
end)

---@param type 'job'|'gang'
RegisterNetEvent('qbx_management:client:Stash', function(type)
    local stash = type == 'gang' and 'gang_'..QBX.PlayerData.gang.name or 'boss_'..QBX.PlayerData.job.name
    exports.ox_inventory:openInventory('stash', stash)
end)

---@param type 'job'|'gang'
RegisterNetEvent('qbx_management:client:OpenMenu', function(type)
    if not QBX.PlayerData[type].name or not QBX.PlayerData[type].isboss then return end

    local bossMenu = {
        {
            title = type == 'gang' and 'Manage Gang Members' or 'Manage Employees',
            description = type == 'gang' and 'Recruit or Fire Gang Members' or 'Check your Employees List',
            icon = 'fa-solid fa-list',
            event = 'qbx_management:client:EmployeeList',
            args = type
        },
        {
            title = 'Hire Employees',
            description = type == 'gang' and 'Hire Gang Members' or 'Hire Nearby Civilians',
            icon = 'fa-solid fa-hand-holding',
            event = 'qbx_management:client:HireMenu',
            args = type
        },
        {
            title = 'Storage Access',
            description = type == 'gang' and 'Open Gang Stash' or 'Open Business Storage',
            icon = 'fa-solid fa-box-open',
            event = 'qbx_management:client:Stash',
            args = type
        },
        {
            title = 'Outfits',
            description = type == 'gang' and 'Change Clothes' or 'See Saved Outfits',
            icon = 'fa-solid fa-shirt',
            event = 'qbx_management:client:Wardrobe'
        },
        {
            title = 'Money Management',
            description = type == 'gang' and 'Check your Gang Balance' or 'Check your Company Balance',
            icon = 'fa-solid fa-sack-dollar',
            event = 'qbx_management:client:SocietyMenu',
            args = type
        }
    }

    for _, v in pairs(DynamicMenuItems) do
        bossMenu[#bossMenu + 1] = v
    end

    lib.registerContext({
        id = 'qbx_management_open_Menu',
        title = type == 'gang' and 'Gang Management - ' .. string.upper(QBX.PlayerData.gang.label) or 'Boss Menu - ' .. string.upper(QBX.PlayerData.job.label),
        options = bossMenu
    })
    lib.showContext('qbx_management_open_Menu')
end)

---@param type 'job'|'gang'
RegisterNetEvent('qbx_management:client:EmployeeList', function(type)
    local EmployeesMenu = {}
    local accountName = QBX.PlayerData[type].name
    local employees = lib.callback.await('qbx_management:server:getemployees', false, accountName, type)
    for _, v in pairs(employees) do
        EmployeesMenu[#EmployeesMenu + 1] = {
            title = v.name,
            description = v.grade.name,
            event = 'qbx_management:client:ManageEmployee',
            args = {
                type = type,
                player = v,
                work = QBX.PlayerData[type]
            }
        }
    end

    EmployeesMenu[#EmployeesMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        event = 'qbx_management:client:OpenMenu',
        args = type
    }

    lib.registerContext({
        id = 'qbx_management_open_Manage',
        title = type == 'gang' and 'Manage Gang Members - ' .. string.upper(QBX.PlayerData.gang.label) or 'Manage Employees - ' .. string.upper(QBX.PlayerData.job.label),
        options = EmployeesMenu
    })

    lib.showContext('qbx_management_open_Manage')
end)

---@param data {source: number, player: table, work: table, type: 'job'|'gang'}
RegisterNetEvent('qbx_management:client:ManageEmployee', function(data)
    local EmployeeMenu = {}
    local employeeLoop = data.type == 'gang' and gangs[data.work.name].grades or jobs[data.work.name].grades
    for k, v in pairs(employeeLoop) do
        EmployeeMenu[#EmployeeMenu + 1] = {
            title = v.name,
            description = 'Grade: ' .. k,
            serverEvent = 'qbx_management:server:GradeUpdate',
            args = {
                cid = data.player.empSource,
                grade = tonumber(k),
                gradename = v.name,
                type = data.type
            }
        }
    end

    EmployeeMenu[#EmployeeMenu + 1] = {
        title = data.type == 'gang' and 'Expel Gang Member' or 'Fire Employee',
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'qbx_management:server:FireEmployee',
        args = {
            source = data.player.empSource,
            type = data.type
        }
    }

    EmployeeMenu[#EmployeeMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        event = 'qbx_management:client:OpenMenu',
        args = data.type
    }

    lib.registerContext({
        id = 'qbx_management_open_Member',
        title = data.type == 'gang' and 'Manage ' .. data.player.name .. ' - ' .. string.upper(QBX.PlayerData.gang.label) or 'Manage ' .. data.player.name .. ' - ' .. string.upper(QBX.PlayerData.job.label),
        options = EmployeeMenu
    })

    lib.showContext('qbx_management_open_Member')
end)

---@param type 'job'|'gang'
RegisterNetEvent('qbx_management:client:HireMenu', function(type)
    local HireMenu = {}
    local players = FindPlayers()
    local hireName = QBX.PlayerData[type].name
    for _, v in pairs(players) do

        if v and v.citizenid ~= QBX.PlayerData.citizenid and v[type].name ~= hireName then
            HireMenu[#HireMenu + 1] = {
                title = v.name,
                description = 'Citizen ID: ' .. v.citizenid .. ' - ID: ' .. v.source,
                serverEvent = 'qbx_management:server:HireEmployee',
                args = {
                    source = v.source,
                    type = type,
                    grade = 0
                }
            }
        end
    end

    HireMenu[#HireMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        event = 'qbx_management:client:OpenMenu',
        args = type
    }

    lib.registerContext({
        id = 'qbx_management_open_Hire',
        title = type == 'gang' and 'Hire Gang Members - ' .. string.upper(QBX.PlayerData.gang.label) or 'Hire Employees - ' .. string.upper(QBX.PlayerData.job.label),
        options = HireMenu
    })

    lib.showContext('qbx_management_open_Hire')
end)

RegisterNetEvent('qbx_management:client:Wardrobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)