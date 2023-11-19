local jobs = exports.qbx_core:GetJobs()
local gangs = exports.qbx_core:GetGangs()

local function commaValue(amount)
    local numChanged

    repeat
        amount, numChanged = string.gsub(amount, '^(-?%d+)(%d%d%d)', '%1,%2')
    until numChanged == 0

    return amount
end

---@return table
local function findPlayers()
    local closePlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 10, false)
    for _, v in pairs(closePlayers) do
        v.id = GetPlayerServerId(v.id)
    end
	return lib.callback.await('qbx_management:server:getplayers', false, closePlayers)
end

---@param group 'job'|'gang'
RegisterNetEvent('qbx_management:client:societyMenu', function(group)
    local amount = lib.callback.await('qbx_management:server:getAccount', false, QBX.PlayerData[group].name)
    local societyMenu = {
        {
            title = 'Deposit',
            icon = 'fa-solid fa-money-bill-transfer',
            description = 'Deposit Money',
            event = 'qbx_management:client:SocietyDeposit',
            args = {
                group = group,
                amount = amount
            }
        },
        {
            title = 'Withdraw',
            icon = 'fa-solid fa-money-bill-transfer',
            description = 'Withdraw Money',
            event = 'qbx_management:client:societyWithdraw',
            args = {
                group = group,
                amount = amount
            }
        },
        {
            title = 'Return',
            icon = 'fa-solid fa-angle-left',
            event = 'qbx_management:client:openMenu',
            args = group
        }
    }

    lib.registerContext({
        id = 'qbx_management_open_Society',
        title = 'Balance: $' .. commaValue(amount) .. ' - ' .. string.upper(QBX.PlayerData[group].label),
        options = societyMenu
    })

    lib.showContext('qbx_management_open_Society')
end)

---@param data {amount: number, group: 'job'|'gang'}
RegisterNetEvent('qbx_management:client:SocietyDeposit', function(data)
    local deposit = lib.inputDialog('Deposit Money', {
        {
            type = 'input',
            label = 'Available Balance',
            disabled = true,
            default = commaValue(data.amount)
        },
        {
            type = 'number',
            label = 'Amount'
        }
    })

    if not deposit then
        TriggerEvent('qbx_management:client:societyMenu', data.group)
        return
    end

    if not deposit[2] then
        exports.qbx_core:Notify('Amount value is missing!', 'error')

        TriggerEvent('qbx_management:client:societyMenu', data.group)
        return
    end

    local depositAmount = tonumber(deposit[2])

    if depositAmount <= 0 then
        exports.qbx_core:Notify('Amount need to be higher than zero!', 'error')

        TriggerEvent('qbx_management:client:societyMenu', data.group)
        return
    end

    TriggerServerEvent('qbx_management:server:depositMoney', data.group, depositAmount)
end)

---@param data {amount: number, group: 'job'|'gang'}
RegisterNetEvent('qbx_management:client:societyWithdraw', function(data)
    local withdraw = lib.inputDialog('Withdraw Money', {
        {
            type = 'input',
            label = 'Available Balance',
            disabled = true,
            default = commaValue(data.amount)
        },
        {
            type = 'input',
            label = 'Amount'
        }
    })

    if not withdraw then
        TriggerEvent('qbx_management:client:societyMenu', data.group)
        return
    end

    local withdrawAmount = tonumber(withdraw[2])

    if not withdrawAmount then
        exports.qbx_core:Notify('Amount value is missing!', 'error')

        TriggerEvent('qbx_management:client:societyMenu', data.group)
        return
    end


    if withdrawAmount > tonumber(data.amount) then
        exports.qbx_core:Notify('You cant withdraw that amount of money!', 'error')

        TriggerEvent('qbx_management:client:societyMenu', data.group)
        return
    end


    TriggerServerEvent('qbx_management:server:withdrawMoney', data.group, withdrawAmount)
end)

---@param group 'job'|'gang'
RegisterNetEvent('qbx_management:client:stash', function(group)
    local stash = group == 'gang' and 'gang_'..QBX.PlayerData.gang.name or 'boss_'..QBX.PlayerData.job.name
    exports.ox_inventory:openInventory('stash', stash)
end)

---@param group 'job'|'gang'
RegisterNetEvent('qbx_management:client:openMenu', function(group)
    if not QBX.PlayerData[group].name or not QBX.PlayerData[group].isboss then return end

    local bossMenu = {
        {
            title = group == 'gang' and 'Manage Gang Members' or 'Manage Employees',
            description = group == 'gang' and 'Recruit or Fire Gang Members' or 'Check your Employees List',
            icon = 'fa-solid fa-list',
            event = 'qbx_management:client:employeeList',
            args = group
        },
        {
            title = 'Hire Employees',
            description = group == 'gang' and 'Hire Gang Members' or 'Hire Nearby Civilians',
            icon = 'fa-solid fa-hand-holding',
            event = 'qbx_management:client:hireMenu',
            args = group
        },
        {
            title = 'Storage Access',
            description = group == 'gang' and 'Open Gang Stash' or 'Open Business Storage',
            icon = 'fa-solid fa-box-open',
            event = 'qbx_management:client:stash',
            args = group
        },
        {
            title = 'Outfits',
            description = group == 'gang' and 'Change Clothes' or 'See Saved Outfits',
            icon = 'fa-solid fa-shirt',
            event = 'qbx_management:client:Wardrobe'
        },
        {
            title = 'Money Management',
            description = group == 'gang' and 'Check your Gang Balance' or 'Check your Company Balance',
            icon = 'fa-solid fa-sack-dollar',
            event = 'qbx_management:client:societyMenu',
            args = group
        }
    }

    lib.registerContext({
        id = 'qbx_management_open_Menu',
        title = group == 'gang' and 'Gang Management - ' .. string.upper(QBX.PlayerData.gang.label) or 'Boss Menu - ' .. string.upper(QBX.PlayerData.job.label),
        options = bossMenu
    })
    lib.showContext('qbx_management_open_Menu')
end)

---@param group 'job'|'gang'
RegisterNetEvent('qbx_management:client:employeeList', function(group)
    local employeesMenu = {}
    local accountName = QBX.PlayerData[group].name
    local employees = lib.callback.await('qbx_management:server:getemployees', false, accountName, group)
    for _, v in pairs(employees) do
        employeesMenu[#employeesMenu + 1] = {
            title = v.name,
            description = v.grade.name,
            event = 'qbx_management:client:ManageEmployee',
            args = {
                group = group,
                player = v,
                work = QBX.PlayerData[group]
            }
        }
    end

    employeesMenu[#employeesMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        event = 'qbx_management:client:openMenu',
        args = group
    }

    lib.registerContext({
        id = 'qbx_management_open_Manage',
        title = group == 'gang' and 'Manage Gang Members - ' .. string.upper(QBX.PlayerData.gang.label) or 'Manage Employees - ' .. string.upper(QBX.PlayerData.job.label),
        options = employeesMenu
    })

    lib.showContext('qbx_management_open_Manage')
end)

---@param data {source: number, player: table, work: table, group: 'job'|'gang'}
RegisterNetEvent('qbx_management:client:ManageEmployee', function(data)
    local employeeMenu = {}
    local employeeLoop = data.group == 'gang' and gangs[data.work.name].grades or jobs[data.work.name].grades
    for k, v in pairs(employeeLoop) do
        employeeMenu[#employeeMenu + 1] = {
            title = v.name,
            description = 'Grade: ' .. k,
            serverEvent = 'qbx_management:server:updateGrade',
            args = {
                cid = data.player.empSource,
                grade = tonumber(k),
                gradename = v.name,
                group = data.group
            }
        }
    end

    employeeMenu[#employeeMenu + 1] = {
        title = data.group == 'gang' and 'Expel Gang Member' or 'Fire Employee',
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'qbx_management:server:fireEmployee',
        args = {
            source = data.player.empSource,
            group = data.group
        }
    }

    employeeMenu[#employeeMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        event = 'qbx_management:client:openMenu',
        args = data.group
    }

    lib.registerContext({
        id = 'qbx_management_open_Member',
        title = data.group == 'gang' and 'Manage ' .. data.player.name .. ' - ' .. string.upper(QBX.PlayerData.gang.label) or 'Manage ' .. data.player.name .. ' - ' .. string.upper(QBX.PlayerData.job.label),
        options = employeeMenu
    })

    lib.showContext('qbx_management_open_Member')
end)

---@param group 'job'|'gang'
RegisterNetEvent('qbx_management:client:hireMenu', function(group)
    local hireMenu = {}
    local players = findPlayers()
    local hireName = QBX.PlayerData[group].name
    for _, v in pairs(players) do

        if v and v.citizenid ~= QBX.PlayerData.citizenid and v[group].name ~= hireName then
            hireMenu[#hireMenu + 1] = {
                title = v.name,
                description = 'Citizen ID: ' .. v.citizenid .. ' - ID: ' .. v.source,
                serverEvent = 'qbx_management:server:HireEmployee',
                args = {
                    source = v.source,
                    group = group,
                    grade = 0
                }
            }
        end
    end

    hireMenu[#hireMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        event = 'qbx_management:client:openMenu',
        args = group
    }

    lib.registerContext({
        id = 'qbx_management_open_Hire',
        title = group == 'gang' and 'Hire Gang Members - ' .. string.upper(QBX.PlayerData.gang.label) or 'Hire Employees - ' .. string.upper(QBX.PlayerData.job.label),
        options = hireMenu
    })

    lib.showContext('qbx_management_open_Hire')
end)

RegisterNetEvent('qbx_management:client:Wardrobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)