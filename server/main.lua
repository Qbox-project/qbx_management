local jobs = exports.qbx_core:GetJobs()
local gangs = exports.qbx_core:GetGangs()

---@param id number
---@param reason string
function ExploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(id),
        exports.qbx_core:GetIdentifier(id, 'license'),
        exports.qbx_core:GetIdentifier(id, 'discord'),
        exports.qbx_core:GetIdentifier(id, 'ip'),
        reason,
        2147483647,
        'qb-management'
    })

    TriggerEvent('qb-log:server:CreateLog', 'bans', 'Player Banned', 'red', string.format('%s was banned by %s for %s', GetPlayerName(id), 'qbx_management', reason), true)

    DropPlayer(id, 'You were permanently banned by the server for: Exploiting')
end


---@param account string
---@return number
lib.callback.register('qbx_management:server:getAccount', function(_, account)
	return exports['Renewed-Banking']:getAccountMoney(account) or 0
end)

---@param account string
---@param amount number
function AddMoney(account, amount)
	exports['Renewed-Banking']:addAccountMoney(account, amount, 'qbx_management')
end

---@param account string
---@param amount number
---@return boolean
function RemoveMoney(account, amount)
	if amount <= 0 then return false end
	return exports['Renewed-Banking']:removeAccountMoney(account, amount, 'qbx_management')
end

---@param src number
---@param amount number
---@param type 'job'|'gang'
---@param reason string
---@return boolean success
---@return Player? player populated if successful
---@return string? accountName populated if successful
function WithdrawMoney(src, amount, type, reason)
	local player = exports.qbx_core:GetPlayer(src)

	if not player.PlayerData[type].isboss then ExploitBan(src, 'withdrawMoney Exploiting') return false end

	local account = player.PlayerData[type].name
	if RemoveMoney(account, amount) then
        player.Functions.AddMoney('cash', amount, reason)
		local logArea = type == 'gang' and 'gang' or 'boss'
		exports.qbx_core:Notify(src, 'You have withdrawn: $' ..amount, 'success')
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Withdraw Money', 'orange', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully withdrew $' .. amount .. ' (' .. account .. ')', false)
        return true, player, account
	else
		exports.qbx_core:Notify(src, 'You dont have enough money in the account!', 'error')
        return false, player, account
    end
end

---@param src number
---@param amount number
---@param type 'job'|'gang'
---@return boolean success
---@return Player? player populated if successful
---@return string? accountName populated if successful
function DepositMoney(src, amount, type)
	local player = exports.qbx_core:GetPlayer(src)

	if not player.PlayerData[type].isboss then ExploitBan(src, 'depositMoney Exploiting') return false end
	local account = player.PlayerData[type].name
	if player.Functions.RemoveMoney('cash', amount) then
		AddMoney(account, amount)
		local logArea = type == 'gang' and 'gang' or 'boss'
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Deposit Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. account .. ')', false)
		exports.qbx_core:Notify(src, 'You have deposited: $' ..amount, 'success')
        return true, player, account
	else
		exports.qbx_core:Notify(src, 'You dont have enough money to add!', 'error')
        return false, player, account
    end
end

---@param src number
---@param accountName string
---@param type 'gang'|'job'
---@return table?
function GetEmployees(src, accountName, type)
	local player = exports.qbx_core:GetPlayer(src)

	if not player.PlayerData[type].isboss then ExploitBan(src, 'GetEmployees Exploiting') return end

	local employees = {}
	local players = MySQL.query.await('SELECT * FROM `players` WHERE ?? LIKE \'%'.. accountName ..'%\'', {type})
	if not players then return {} end
	for _, value in pairs(players) do
		local isOnline = exports.qbx_core:GetPlayerByCitizenId(value.citizenid)
		local isOffline = json.decode(value[type])
		if isOnline then
			employees[#employees + 1] = {
			empSource = isOnline.PlayerData.citizenid,
			grade = isOnline.PlayerData[type].grade,
			isboss = isOnline.PlayerData[type].isboss,
			name = '🟢 ' .. isOnline.PlayerData.charinfo.firstname .. ' ' .. isOnline.PlayerData.charinfo.lastname
			}
		elseif isOffline.name == accountName then
			employees[#employees + 1] = {
			empSource = value.citizenid,
			grade =  isOffline.grade,
			isboss = isOffline.isboss,
			name = '❌ ' ..  json.decode(value.charinfo).firstname .. ' ' .. json.decode(value.charinfo).lastname
			}
		end
	end
    table.sort(employees, function(a, b)
		return a.grade.level > b.grade.level
	end)
	return employees
end

---@param src number
---@param data {cid: string, grade: integer, gradename: string, type: 'job'|'gang'}
function UpdateGrade(src, data)
	local player = exports.qbx_core:GetPlayer(src)
	local employee = exports.qbx_core:GetPlayerByCitizenId(data.cid)

	if not player.PlayerData[data.type].isboss then ExploitBan(src, 'GradeUpdate Exploiting') return end
	if data.grade > player.PlayerData[data.type].grade.level then exports.qbx_core:Notify(src, 'You cannot promote to this rank!', 'error') return end

	if not employee then
        exports.qbx_core:Notify(src, 'Civilian is not in city.', 'error')
        return
    end

    local success
    if data.type == 'gang' then
        success = employee.Functions.SetGang(player.PlayerData[data.type].name, data.grade)
    else
        success = employee.Functions.SetJob(player.PlayerData[data.type].name, data.grade)
    end

    if success then
        exports.qbx_core:Notify(src, 'Successfully promoted!', 'success')
        exports.qbx_core:Notify(employee.PlayerData.source, 'You have been promoted to ' ..data.gradename..'.', 'success')
    else
        exports.qbx_core:Notify(src, 'Grade does not exist.', 'error')
    end
end

---@param closePlayers table List of nearby server ids
---@return table
lib.callback.register('qbx_management:server:getplayers', function(_, closePlayers)
	local players = {}
	for _, v in pairs(closePlayers) do
		local player = exports.qbx_core:GetPlayer(v.id)
		players[#players + 1] = {
			id = v.id,
			name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
			citizenid = player.PlayerData.citizenid,
			job = player.PlayerData.job,
			gang = player.PlayerData.gang,
			source = player.PlayerData.source
		}
	end

	table.sort(players, function(a, b)
		return a.name < b.name
	end)

	return players
end)

---@param accountName string
---@param type 'job'|'gang'
---@return table?
lib.callback.register('qbx_management:server:getemployees', function(_, accountName, type)
	local src = source
	return GetEmployees(src, accountName, type)
end)

---@param data table
---@return table?
RegisterNetEvent('qbx_management:server:GradeUpdate', function(data)
	local src = source
	UpdateGrade(src, data)
	TriggerClientEvent('qbx_management:client:OpenMenu', src, data.type)
end)

---@param data {source: number, grade: number, type: 'job'|'gang'}
RegisterNetEvent('qbx_management:server:HireEmployee', function(data)
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local target = exports.qbx_core:GetPlayer(data.source)
	
    if not player.PlayerData[data.type].isboss then
        ExploitBan(src, 'HireEmployee Exploiting')
        return
    end
	
    if not target then
        exports.qbx_core:Notify(src, 'Civilian is not in city.', 'error')
        return
    end

	local jobName = player.PlayerData[data.type].name
	local logArea = data.type == 'gang' and 'gang' or 'boss'

    local success = data.type == 'gang' and target.Functions.SetGang(jobName, data.grade) or target.Functions.SetJob(jobName, data.grade)
    local grade = data.type == 'gang' and gangs[jobName].grades[data.grade].name or jobs[jobName].grades[data.grade].name

    if success then
        local playerFullName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        local targetFullName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
        local organizationLabel = player.PlayerData[data.type].label

        exports.qbx_core:Notify(src, 'You hired ' .. targetFullName .. ' into ' .. organizationLabel, 'success')
        exports.qbx_core:Notify(target.PlayerData.source, 'You have been hired as ' .. organizationLabel, 'success')
        TriggerEvent('qb-log:server:CreateLog', logArea..'menu', grade, 'yellow', playerFullName.. ' successfully recruited ' .. targetFullName .. ' (' .. organizationLabel .. ')', false)
    else
        exports.qbx_core:Notify(src, 'Couldn\'t hire civilian', 'error')
    end
	TriggerClientEvent('qbx_management:client:OpenMenu', src, data.type)
end)

---@param data {source: number, type: 'job'|'gang'}
RegisterNetEvent('qbx_management:server:FireEmployee', function(data)
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local employee = exports.qbx_core:GetPlayerByCitizenId(data.source) or nil
	local playerFullName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
	local organizationLabel = player.PlayerData[data.type].label
	local logArea = data.type == 'gang' and 'gang' or 'boss'
	
	if not player.PlayerData[data.type].isboss then ExploitBan(src, 'FireEmployee Exploiting') return end
	
	local logType = data.type == 'gang' and 'Gang Member fired!' or 'Employee fired!'
	if employee then
		local employeeFullName = employee.PlayerData.charinfo.firstname .. ' ' .. employee.PlayerData.charinfo.lastname
		if employee.PlayerData.citizenid == player.PlayerData.citizenid then
			local message = data.type == 'gang' and 'You can\'t kick yourself out of the gang!' or 'You can\'t fire yourself'
			exports.qbx_core:Notify(src, message, 'error')
			return
		end
	
		if employee.PlayerData[data.type].grade.level > player.PlayerData[data.type].grade.level then
			exports.qbx_core:Notify(src, 'You cannot fire your boss!', 'error')
			return
		end
	
		local success = data.type == 'gang' and employee.Functions.SetGang('none', 0) or employee.Functions.SetJob('unemployed', 0)
		if not success then
			exports.qbx_core:Notify(src, 'Unable to fire citizen.', 'error')
			return
		end
	
		local notifyMessage = data.type == 'gang' and 'You have been expelled from the gang!' or 'You have been fired! Good luck.'
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', data.type..' Fire', 'orange', playerFullName .. ' successfully fired ' .. employeeFullName .. ' (' .. organizationLabel .. ')', false)
		exports.qbx_core:Notify(src, logType, 'success')
		exports.qbx_core:Notify(employee.PlayerData.source, notifyMessage, 'error')
	else
		local offlineEmployee = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {data.source})
		if not offlineEmployee[1] then
			exports.qbx_core:Notify(src, 'Civilian doesn\'t exist?', 'error')
			return
		end
	
		employee = offlineEmployee[1]
		employee[data.type] = json.decode(employee[data.type])
		employee.charinfo = json.decode(employee.charinfo)
		local employeeFullName = employee.charinfo.firstname .. ' ' .. employee.charinfo.lastname
	
		if employee[data.type].grade.level > player.PlayerData.gang.grade.level then
			exports.qbx_core:Notify(src, 'You cannot fire this citizen!', 'error')
			return
		end
	
		local role = {
			name = data.type == 'gang' and 'none' or 'unemployed',
			label = data.type == 'gang' and gangs['none'].label or jobs['unemployed'].label,
			payment = data.type == 'gang' and 0 or jobs['unemployed'].grades[0].payment,
			onduty = data.type ~= 'gang',
			isboss = false,
			grade = {
				name = data.type == 'gang' and gangs['none'].grades[0].name or jobs['unemployed'].grades[0].name,
				level = 0
			}
		}
	
		local updateColumn = data.type == 'gang' and 'gang' or 'job'
		MySQL.update(string.format('UPDATE players SET %s = ? WHERE citizenid = ?', updateColumn), {json.encode(role), data.source})
		exports.qbx_core:Notify(src, logType, 'success')
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', data.type..' Fire', 'orange', playerFullName .. ' successfully fired ' .. employeeFullName .. ' (' .. organizationLabel .. ')', false)
	end
	TriggerClientEvent('qbx_management:client:OpenMenu', src, data.type)
end)

---@param type 'job'|'gang'
---@param amount number
RegisterNetEvent('qbx_management:server:withdrawMoney', function(type, amount)
	local src = source
	local success, player, account = WithdrawMoney(src, amount, type, type == 'gang' and 'Gang menu withdraw' or 'Boss menu withdraw')
	if not success or not player then return end
	local logArea = type == 'gang' and 'gang' or 'boss'
	
	TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Withdraw Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully withdrew $' .. amount .. ' (' .. account .. ')', false)
	TriggerClientEvent('qbx_management:client:OpenMenu', src, type)
end)

---@param type 'job'|'gang'
---@param amount number
RegisterNetEvent('qbx_management:server:depositMoney', function(type, amount)
	local src = source
	local success, player, account = DepositMoney(src, amount, type)
	if not success or not player then return end

	local logArea = type == 'gang' and 'gang' or 'boss'
	TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Deposit Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. account .. ')', false)
	TriggerClientEvent('qbx_management:client:OpenMenu', src, type)
end)


-- Event Handlers
AddEventHandler('onServerResourceStart', function(resourceName)
	if resourceName ~= 'ox_inventory' and resourceName ~= GetCurrentResourceName() then return end

	local data = Config.UseTarget and Config.BossMenuZones or Config.BossMenus
	for k in pairs(data) do
		exports.ox_inventory:RegisterStash('boss_' .. k, 'Stash: ' .. k, 100, 4000000, false)
	end

	data = Config.UseTarget and Config.GangMenuZones or Config.GangMenus
	for k in pairs(data) do
		exports.ox_inventory:RegisterStash('gang_' .. k, 'Stash: ' .. k, 100, 4000000, false)
	end
end)


