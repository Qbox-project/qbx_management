local jobs = exports.qbx_core:GetJobs()
local gangs = exports.qbx_core:GetGangs()

---@param id number
---@param reason string
local function exploitBan(id, reason)
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
lib.callback.register('qbx_management:server:getAccount', function(source, account)
	return exports['Renewed-Banking']:getAccountMoney(account) or 0
end)

---@param account string
---@param amount number
local function addMoney(account, amount)
	exports['Renewed-Banking']:addAccountMoney(account, amount)
end

---@param account string
---@param amount number
---@return boolean
local function removeMoney(account, amount)
	if amount <= 0 then return false end
	return exports['Renewed-Banking']:removeAccountMoney(account, amount)
end

---@param src number
---@param amount number
---@param group 'job'|'gang'
---@param reason string
---@return boolean success
---@return Player? player populated if successful
---@return string? accountName populated if successful
local function withdrawMoney(src, amount, group, reason)
	local player = exports.qbx_core:GetPlayer(src)

	if not player.PlayerData[group].isboss then exploitBan(src, 'withdrawMoney Exploiting') return false end

	if amount <= 0 then return false end

	local account = player.PlayerData[group].name
	if removeMoney(account, amount) then
        player.Functions.AddMoney('cash', amount, reason)
		local logArea = group == 'gang' and 'gang' or 'boss'
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
---@param group 'job'|'gang'
---@return boolean success
---@return Player? player populated if successful
---@return string? accountName populated if successful
local function depositMoney(src, amount, group)
	local player = exports.qbx_core:GetPlayer(src)

	if not player.PlayerData[group].isboss then exploitBan(src, 'depositMoney Exploiting') return false end
	local account = player.PlayerData[group].name
	if player.Functions.RemoveMoney('cash', amount) then
		addMoney(account, amount)
		local logArea = group == 'gang' and 'gang' or 'boss'
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
---@param group 'gang'|'job'
---@return table?
local function getEmployees(src, accountName, group)
	local player = exports.qbx_core:GetPlayer(src)

	if not player.PlayerData[group].isboss then exploitBan(src, 'GetEmployees Exploiting') return end

	local employees = {}
	local players = MySQL.query.await('SELECT * FROM `players` WHERE ?? LIKE \'%'.. accountName ..'%\'', {group})
	if not players then return {} end
	for _, value in pairs(players) do
		local isOnline = exports.qbx_core:GetPlayerByCitizenId(value.citizenid)
		local isOffline = json.decode(value[group])
		if isOnline then
			employees[#employees + 1] = {
			empSource = isOnline.PlayerData.citizenid,
			grade = isOnline.PlayerData[group].grade,
			isboss = isOnline.PlayerData[group].isboss,
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
---@param data {cid: string, grade: integer, gradename: string, group: 'job'|'gang'}
local function updateGrade(src, data)
	local player = exports.qbx_core:GetPlayer(src)
	local employee = exports.qbx_core:GetPlayerByCitizenId(data.cid)

	if not player.PlayerData[data.group].isboss then exploitBan(src, 'UpdateGrade Exploiting') return end
	if data.grade > player.PlayerData[data.group].grade.level then exports.qbx_core:Notify(src, 'You cannot promote to this rank!', 'error') return end

	if not employee then
        exports.qbx_core:Notify(src, 'Civilian is not in city.', 'error')
        return
    end

    local success
    if data.group == 'gang' then
        success = employee.Functions.SetGang(player.PlayerData[data.group].name, data.grade)
    else
        success = employee.Functions.SetJob(player.PlayerData[data.group].name, data.grade)
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
---@param group 'job'|'gang'
---@return table?
lib.callback.register('qbx_management:server:getemployees', function(source, accountName, group)
	return getEmployees(source, accountName, group)
end)

---@param data table
---@return table?
RegisterNetEvent('qbx_management:server:updateGrade', function(data)
	updateGrade(source, data)
	TriggerClientEvent('qbx_management:client:openMenu', source, data.group)
end)

---@param data {source: number, grade: number, group: 'job'|'gang'}
RegisterNetEvent('qbx_management:server:HireEmployee', function(data)
	local player = exports.qbx_core:GetPlayer(source)
	local target = exports.qbx_core:GetPlayer(data.source)
	
    if not player.PlayerData[data.group].isboss then
        exploitBan(source, 'HireEmployee Exploiting')
        return
    end
	
    if not target then
        exports.qbx_core:Notify(source, 'Civilian is not in city.', 'error')
        return
    end

	local jobName = player.PlayerData[data.group].name
	local logArea = data.group == 'gang' and 'gang' or 'boss'

    local success = data.group == 'gang' and target.Functions.SetGang(jobName, data.grade) or target.Functions.SetJob(jobName, data.grade)
    local grade = data.group == 'gang' and gangs[jobName].grades[data.grade].name or jobs[jobName].grades[data.grade].name

    if success then
        local playerFullName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        local targetFullName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
        local organizationLabel = player.PlayerData[data.group].label

        exports.qbx_core:Notify(source, 'You hired ' .. targetFullName .. ' into ' .. organizationLabel, 'success')
        exports.qbx_core:Notify(target.PlayerData.source, 'You have been hired into ' .. organizationLabel, 'success')
        TriggerEvent('qb-log:server:CreateLog', logArea..'menu', grade, 'yellow', playerFullName.. ' successfully recruited ' .. targetFullName .. ' (' .. organizationLabel .. ')', false)
    else
        exports.qbx_core:Notify(source, 'Couldn\'t hire civilian', 'error')
    end
	TriggerClientEvent('qbx_management:client:openMenu', source, data.group)
end)

---@param data {source: number, group: 'job'|'gang'}
RegisterNetEvent('qbx_management:server:fireEmployee', function(data)
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local employee = exports.qbx_core:GetPlayerByCitizenId(data.source) or nil
	local playerFullName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
	local organizationLabel = player.PlayerData[data.group].label
	local logArea = data.group == 'gang' and 'gang' or 'boss'
	
	if not player.PlayerData[data.group].isboss then exploitBan(src, 'FireEmployee Exploiting') return end
	
	local logType = data.group == 'gang' and 'Gang Member fired!' or 'Employee fired!'
	if employee then
		local employeeFullName = employee.PlayerData.charinfo.firstname .. ' ' .. employee.PlayerData.charinfo.lastname
		if employee.PlayerData.citizenid == player.PlayerData.citizenid then
			local message = data.group == 'gang' and 'You can\'t kick yourself out of the gang!' or 'You can\'t fire yourself'
			exports.qbx_core:Notify(src, message, 'error')
			return
		end
	
		if employee.PlayerData[data.group].grade.level > player.PlayerData[data.group].grade.level then
			exports.qbx_core:Notify(src, 'You cannot fire your boss!', 'error')
			return
		end
	
		local success = data.group == 'gang' and employee.Functions.SetGang('none', 0) or employee.Functions.SetJob('unemployed', 0)
		if not success then
			exports.qbx_core:Notify(src, 'Unable to fire citizen.', 'error')
			return
		end
	
		local notifyMessage = data.group == 'gang' and 'You have been expelled from the gang!' or 'You have been fired! Good luck.'
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', data.group..' Fire', 'orange', playerFullName .. ' successfully fired ' .. employeeFullName .. ' (' .. organizationLabel .. ')', false)
		exports.qbx_core:Notify(src, logType, 'success')
		exports.qbx_core:Notify(employee.PlayerData.source, notifyMessage, 'error')
	else
		local offlineEmployee = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {data.source})
		if not offlineEmployee[1] then
			exports.qbx_core:Notify(src, 'Civilian doesn\'t exist?', 'error')
			return
		end
	
		employee = offlineEmployee[1]
		employee[data.group] = json.decode(employee[data.group])
		employee.charinfo = json.decode(employee.charinfo)
		local employeeFullName = employee.charinfo.firstname .. ' ' .. employee.charinfo.lastname
	
		if employee[data.group].grade.level > player.PlayerData.gang.grade.level then
			exports.qbx_core:Notify(src, 'You cannot fire this citizen!', 'error')
			return
		end
	
		local role = {
			name = data.group == 'gang' and 'none' or 'unemployed',
			label = data.group == 'gang' and gangs['none'].label or jobs['unemployed'].label,
			payment = data.group == 'gang' and 0 or jobs['unemployed'].grades[0].payment,
			onduty = data.group ~= 'gang',
			isboss = false,
			grade = {
				name = data.group == 'gang' and gangs['none'].grades[0].name or jobs['unemployed'].grades[0].name,
				level = 0
			}
		}
	
		local updateColumn = data.group == 'gang' and 'gang' or 'job'
		MySQL.update(string.format('UPDATE players SET %s = ? WHERE citizenid = ?', updateColumn), {json.encode(role), data.source})
		exports.qbx_core:Notify(src, logType, 'success')
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', data.group..' Fire', 'orange', playerFullName .. ' successfully fired ' .. employeeFullName .. ' (' .. organizationLabel .. ')', false)
	end
	TriggerClientEvent('qbx_management:client:openMenu', src, data.group)
end)

---@param group 'job'|'gang'
---@param amount number
RegisterNetEvent('qbx_management:server:withdrawMoney', function(group, amount)
	local success, player, account = withdrawMoney(source, amount, group, group == 'gang' and 'Gang menu withdraw' or 'Boss menu withdraw')
	if not success or not player then return end
	local logArea = group == 'gang' and 'gang' or 'boss'
	
	TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Withdraw Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully withdrew $' .. amount .. ' (' .. account .. ')', false)
	TriggerClientEvent('qbx_management:client:openMenu', source, group)
end)

---@param group 'job'|'gang'
---@param amount number
RegisterNetEvent('qbx_management:server:depositMoney', function(group, amount)
	local success, player, account = depositMoney(source, amount, group)
	if not success or not player then return end

	local logArea = group == 'gang' and 'gang' or 'boss'
	TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Deposit Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. account .. ')', false)
	TriggerClientEvent('qbx_management:client:openMenu', source, group)
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


