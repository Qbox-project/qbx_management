local sharedConfig = require 'config.shared'
local jobs = exports.qbx_core:GetJobs()
local gangs = exports.qbx_core:GetGangs()

-- Bans players for various exploits against the script.
---@param id string
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


-- Returns account balance for the given society account
---@param account string Name of job/gang account to get balance for
---@return number
lib.callback.register('qbx_management:server:getAccount', function(_, account)
	return exports['Renewed-Banking']:getAccountMoney(account) or 0
end)

-- Takes money from the society account and adds the money as cash to the source player.
---@param src number
---@param amount number Amount to withdraw
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
	if exports['Renewed-Banking']:removeAccountMoney(account, amount) then
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

-- Takes money from the source player and adds the money to the society account.
---@param src number
---@param amount number Amount to deposit
---@param group 'job'|'gang'
---@return boolean success
---@return Player? player populated if successful
---@return string? accountName populated if successful
local function depositMoney(src, amount, group)
	local player = exports.qbx_core:GetPlayer(src)

	if not player.PlayerData[group].isboss then exploitBan(src, 'depositMoney Exploiting') return false end
	local account = player.PlayerData[group].name
	if player.Functions.RemoveMoney('cash', amount) then
		exports['Renewed-Banking']:addAccountMoney(account, amount)
		local logArea = group == 'gang' and 'gang' or 'boss'
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Deposit Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. account .. ')', false)
		exports.qbx_core:Notify(src, 'You have deposited: $' ..amount, 'success')
        return true, player, account
	else
		exports.qbx_core:Notify(src, 'You dont have enough money to add!', 'error')
        return false, player, account
    end
end

-- Get a list of employees for a given group. Currently uses MySQL queries to return offline players.
-- Once an export is available to reliably return offline players this can rewriten.
---@param groupName string Name of job/gang to get employees of
---@param group 'job'|'gang'
---@return table?
lib.callback.register('qbx_management:server:getEmployees', function(source, groupName, group)
	local player = exports.qbx_core:GetPlayer(source)

	if not player.PlayerData[group].isboss then exploitBan(source, 'GetEmployees Exploiting') return end

	local employees = {}
	local players = MySQL.query.await('SELECT * FROM `players` WHERE ?? LIKE \'%'.. groupName ..'%\'', {group})
	if not players then return {} end
	for _, player in pairs(players) do
		local isOnline = exports.qbx_core:GetPlayerByCitizenId(player.citizenid)
		local isOffline = json.decode(player[group])
		if isOnline then
			employees[#employees + 1] = {
			cid = isOnline.PlayerData.citizenid,
			grade = isOnline.PlayerData[group].grade,
			isboss = isOnline.PlayerData[group].isboss,
			name = '🟢 ' .. isOnline.PlayerData.charinfo.firstname .. ' ' .. isOnline.PlayerData.charinfo.lastname
			}
		elseif isOffline.name == groupName then
			employees[#employees + 1] = {
			cid = player.citizenid,
			grade =  isOffline.grade,
			isboss = isOffline.isboss,
			name = '❌ ' ..  json.decode(player.charinfo).firstname .. ' ' .. json.decode(player.charinfo).lastname
			}
		end
	end
    table.sort(employees, function(a, b)
		return a.grade.level > b.grade.level
	end)
	return employees
end)

-- Callback for updating the grade information of online players
---@param cid string CitizenId of player who is being promoted/demoted
---@param grade integer Grade number target for target employee
---@param group 'job'|'gang'
lib.callback.register('qbx_management:server:updateGrade', function(source, cid, grade, group)
	local player = exports.qbx_core:GetPlayer(source)
	local employee = exports.qbx_core:GetPlayerByCitizenId(cid)
	local jobName = player.PlayerData[group].name

	if not player.PlayerData[group].isboss then exploitBan(source, 'UpdateGrade Exploiting') return end
	if grade > player.PlayerData[group].grade.level then exports.qbx_core:Notify(source, 'You cannot promote to this rank!', 'error') return end

	if not employee then
        exports.qbx_core:Notify(source, 'Civilian is not in city.', 'error')
        return
    end

    local success, gradeName
    if group == 'gang' then
        success = employee.Functions.SetGang(jobName, grade)
		gradeName = gangs[jobName].grades[grade].name
    else
        success = employee.Functions.SetJob(jobName, grade)
		gradeName = jobs[jobName].grades[grade].name
    end

    if success then
        exports.qbx_core:Notify(source, 'Successfully promoted!', 'success')
        exports.qbx_core:Notify(employee.PlayerData.source, 'You have been promoted to ' ..gradeName..'.', 'success')
    else
        exports.qbx_core:Notify(source, 'Grade does not exist.', 'error')
    end
	return nil
end)

-- Callback to hire online player as employee of a given group
---@param employee integer Server ID of target employee to be hired
---@param group 'job'|'gang'
lib.callback.register('qbx_management:server:hireEmployee', function(source, employee, group)
	local player = exports.qbx_core:GetPlayer(source)
	local target = exports.qbx_core:GetPlayer(employee)
	
    if not player.PlayerData[group].isboss then
        exploitBan(source, 'HireEmployee Exploiting')
        return
    end
	
    if not target then
        exports.qbx_core:Notify(source, 'Civilian is not in city.', 'error')
        return
    end

	local jobName = player.PlayerData[group].name
	local logArea = group == 'gang' and 'gang' or 'boss'

    local success = group == 'gang' and target.Functions.SetGang(jobName, group) or target.Functions.SetJob(jobName, group)
    local grade = group == 'gang' and gangs[jobName].grades[0].name or jobs[jobName].grades[0].name

    if success then
        local playerFullName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        local targetFullName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
        local organizationLabel = player.PlayerData[group].label
		exports.qbx_core:Notify(source, ('You hired %s into %s'):format(targetFullName, organizationLabel), 'success')
        exports.qbx_core:Notify(target.PlayerData.source, 'You have been hired into ' .. organizationLabel, 'success')
        TriggerEvent('qb-log:server:CreateLog', logArea..'menu', grade, 'yellow', playerFullName.. ' successfully recruited ' .. targetFullName .. ' (' .. organizationLabel .. ')', false)
    else
        exports.qbx_core:Notify(source, 'Couldn\'t hire civilian', 'error')
    end
	return nil
end)

-- Returns playerdata for a given table of player server ids.
---@param closePlayers table Table of player data for possible hiring
---@return table
lib.callback.register('qbx_management:server:getPlayers', function(_, closePlayers)
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

-- Function to fire an online player from a given group
-- Should be merged with the offline player function once an export from the core is available
---@param source integer
---@param employee Player Player object of player being fired
---@param player Player Player object of player initiating firing action
---@param group 'job'|'gang'
local function fireOnlineEmployee(source, employee, player, group)
	if employee.PlayerData.citizenid == player.PlayerData.citizenid then
		local message = group == 'gang' and 'You can\'t kick yourself out of the gang!' or 'You can\'t fire yourself'
		exports.qbx_core:Notify(source, message, 'error')
		return false
	end

	if employee.PlayerData[group].grade.level > player.PlayerData[group].grade.level then
		exports.qbx_core:Notify(source, 'You cannot fire your boss!', 'error')
		return false
	end

	local success = group == 'gang' and employee.Functions.SetGang('none', 0) or employee.Functions.SetJob('unemployed', 0)
	if success then
		local notifyMessage = group == 'gang' and 'You have been expelled from the gang!' or 'You have been fired! Good luck.'
		exports.qbx_core:Notify(employee.PlayerData.source, notifyMessage, 'error')
		return true
	end
	exports.qbx_core:Notify(source, 'Unable to fire citizen.', 'error')
	return false
end

-- Function to fire an offline player from a given group
-- Should be merged with the online player function once an export from the core is available
---@param source integer
---@param employee string citizenid of player to be fired
---@param player Player Player object of player initiating firing action
---@param group 'job'|'gang'
local function fireOfflineEmployee(source, employee, player, group)
	local offlineEmployee = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {employee})
	if not offlineEmployee[1] then
		exports.qbx_core:Notify(source, 'Civilian doesn\'t exist?', 'error')
		return false, nil
	end

	employee = offlineEmployee[1]
	employee[group] = json.decode(employee[group])
	employee.charinfo = json.decode(employee.charinfo)

	if employee[group].grade.level > player.PlayerData[group].grade.level then
		exports.qbx_core:Notify(source, 'You cannot fire your boss!', 'error')
		return false, nil
	end

	local role = {
		name = group == 'gang' and 'none' or 'unemployed',
		label = group == 'gang' and gangs['none'].label or jobs['unemployed'].label,
		payment = group == 'gang' and 0 or jobs['unemployed'].grades[0].payment,
		onduty = group ~= 'gang',
		isboss = false,
		grade = {
			name = group == 'gang' and gangs['none'].grades[0].name or jobs['unemployed'].grades[0].name,
			level = 0
		}
	}

	local updateColumn = group == 'gang' and 'gang' or 'job'
	local employeeFullName = employee.charinfo.firstname .. ' ' .. employee.charinfo.lastname
	local success = MySQL.update.await(string.format('UPDATE players SET %s = ? WHERE citizenid = ?', updateColumn), {json.encode(role), employee.citizenid})
	if success > 0 then
		return true, employeeFullName
	end
	return false, nil
end

-- Callback for firing a player from a given society.
-- Branches to online and offline functions depending on if the target is available.
-- Once an export is available this should be rewritten to remove the MySQL queries.
---@param employee string citizenid of employee to be fired
---@param group 'job'|'gang'
lib.callback.register('qbx_management:server:fireEmployee', function(source, employee, group)
	local player = exports.qbx_core:GetPlayer(source)
	local firedEmployee = exports.qbx_core:GetPlayerByCitizenId(employee) or nil
	local playerFullName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
	local organizationLabel = player.PlayerData[group].label
	
	if not player.PlayerData[group].isboss then exploitBan(source, 'FireEmployee Exploiting') return end
	
	local success, employeeFullName
	if firedEmployee then
		employeeFullName = firedEmployee.PlayerData.charinfo.firstname .. ' ' .. firedEmployee.PlayerData.charinfo.lastname
		success = fireOnlineEmployee(source, firedEmployee, player, group)
	else
		success, employeeFullName = fireOfflineEmployee(source, employee, player, group)
	end
	
	if success then
		local logArea = group == 'gang' and 'gang' or 'boss'
		local logType = group == 'gang' and 'Gang Member fired!' or 'Employee fired!'
		exports.qbx_core:Notify(source, logType, 'success')
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', group..' Fire', 'orange', playerFullName .. ' successfully fired ' .. employeeFullName .. ' (' .. organizationLabel .. ')', false)
	else
		exports.qbx_core:Notify(source, 'Unable to fire Citizen', 'error')
	end
	return nil
end)

-- Callback to withdraw money from a given group's society account and log the transaction
---@param group 'job'|'gang'
---@param amount number
lib.callback.register('qbx_management:server:withdrawMoney', function(source, group, amount)
	local success, player, account = withdrawMoney(source, amount, group, group == 'gang' and 'Gang menu withdraw' or 'Boss menu withdraw')
	if not success or not player then return nil end

	local logArea = group == 'gang' and 'gang' or 'boss'
	TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Withdraw Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully withdrew $' .. amount .. ' (' .. account .. ')', false)
	return nil
end)

-- Callback to deposit money to a given group's society account and log the transaction
---@param group 'job'|'gang'
---@param amount number
lib.callback.register('qbx_management:server:depositMoney', function(source, group, amount)
	local success, player, account = depositMoney(source, amount, group)
	if not success or not player then return nil end

	local logArea = group == 'gang' and 'gang' or 'boss'
	TriggerEvent('qb-log:server:CreateLog', logArea..'menu', 'Deposit Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. account .. ')', false)
	return nil
end)


-- Event Handlers
-- Sets up inventory stashes for all groups
AddEventHandler('onServerResourceStart', function(resourceName)
	if resourceName ~= 'ox_inventory' and resourceName ~= GetCurrentResourceName() then return end

	local data = sharedConfig.menus
	for groups, group in pairs(data) do
		local prefix = group.group == 'gang' and 'gang_' or 'boss_'
		exports.ox_inventory:RegisterStash(prefix .. groups, 'Stash: ' .. groups, 100, 4000000, false)
	end
end)


