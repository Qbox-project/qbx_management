lib.versionCheck('Qbox-project/qbx_management')

local sharedConfig = require 'config.shared'
local JOBS = exports.qbx_core:GetJobs()
local GANGS = exports.qbx_core:GetGangs()

-- Get a list of employees for a given group. Currently uses MySQL queries to return offline players.
-- Once an export is available to reliably return offline players this can rewriten.
---@param groupName string Name of job/gang to get employees of
---@param group 'job'|'gang'
---@return table?
lib.callback.register('qbx_management:server:getEmployees', function(source, groupName, group)
	local player = exports.qbx_core:GetPlayer(source)

	if not player.PlayerData[group].isboss then return end

	local employees = {}
	local players = FetchPlayerEntitiesByGroup(groupName, group)
	if not players then return {} end
	for _, employee in pairs(players) do
		local isOnline = exports.qbx_core:GetPlayerByCitizenId(employee.citizenid)
		local isOffline = json.decode(employee[group])
		if isOnline then
			employees[#employees + 1] = {
			cid = isOnline.PlayerData.citizenid,
			grade = isOnline.PlayerData[group].grade,
			isboss = isOnline.PlayerData[group].isboss,
			name = '🟢 '..isOnline.PlayerData.charinfo.firstname..' '..isOnline.PlayerData.charinfo.lastname
			}
		elseif isOffline.name == groupName then
			employees[#employees + 1] = {
			cid = employee.citizenid,
			grade =  isOffline.grade,
			isboss = isOffline.isboss,
			name = '❌ '..json.decode(employee.charinfo).firstname..' '..json.decode(employee.charinfo).lastname
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

	if not player.PlayerData[group].isboss then return end
	if grade > player.PlayerData[group].grade.level then exports.qbx_core:Notify(source, Lang:t('error.cant_promote'), 'error') return end

	if not employee then
        exports.qbx_core:Notify(source, Lang:t('error.not_around'), 'error')
        return
    end

    local success, gradeName
    if group == 'gang' then
        success = employee.Functions.SetGang(jobName, grade)
		gradeName = GANGS[jobName].grades[grade].name
    else
        success = employee.Functions.SetJob(jobName, grade)
		gradeName = JOBS[jobName].grades[grade].name
    end

    if success then
        exports.qbx_core:Notify(source, Lang:t('success.promoted'), 'success')
        exports.qbx_core:Notify(employee.PlayerData.source, Lang:t('success.promoted_to')..gradeName..'.', 'success')
    else
        exports.qbx_core:Notify(source, Lang:t('error.grade_not_exist'), 'error')
    end
	return nil
end)

-- Callback to hire online player as employee of a given group
---@param employee integer Server ID of target employee to be hired
---@param group 'job'|'gang'
lib.callback.register('qbx_management:server:hireEmployee', function(source, employee, group)
	local player = exports.qbx_core:GetPlayer(source)
	local target = exports.qbx_core:GetPlayer(employee)
	
    if not player.PlayerData[group].isboss then return end
	
    if not target then
        exports.qbx_core:Notify(source, Lang:t('error.not_around'), 'error')
        return
    end

	local jobName = player.PlayerData[group].name
	local logArea = group == 'gang' and 'gang' or 'boss'

    local success = group == 'gang' and target.Functions.SetGang(jobName, group) or target.Functions.SetJob(jobName, group)
    local grade = group == 'gang' and GANGS[jobName].grades[0].name or JOBS[jobName].grades[0].name
	
    if success then
        local playerFullName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
        local targetFullName = target.PlayerData.charinfo.firstname..' '..target.PlayerData.charinfo.lastname
        local organizationLabel = player.PlayerData[group].label
		exports.qbx_core:Notify(source, Lang:t('success.hired_into', {who = targetFullName, where = organizationLabel}), 'success')
        exports.qbx_core:Notify(target.PlayerData.source, Lang:t('success.hired_to')..organizationLabel, 'success')
        TriggerEvent('qb-log:server:CreateLog', logArea..'menu', grade, 'yellow', playerFullName..Lang:t('logs.recruited')..targetFullName..' ('..organizationLabel..')', false)
    else
        exports.qbx_core:Notify(source, Lang:t('error.couldnt_hire'), 'error')
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
			name = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname,
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
		local message = group == 'gang' and Lang:t('error.kick_yourself') or Lang:t('error.fire_yourself')
		exports.qbx_core:Notify(source, message, 'error')
		return false
	end

	if employee.PlayerData[group].grade.level > player.PlayerData[group].grade.level then
		exports.qbx_core:Notify(source, Lang:t('error.kick_boss'), 'error')
		return false
	end

	local success = group == 'gang' and employee.Functions.SetGang('none', 0) or employee.Functions.SetJob('unemployed', 0)
	if success then
		local notifyMessage = group == 'gang' and Lang:t('error.you_gang_fired') or Lang:t('error.you_job_fired')
		exports.qbx_core:Notify(employee.PlayerData.source, notifyMessage, 'error')
		return true
	end
	exports.qbx_core:Notify(source, Lang:t('error.unable_fire'), 'error')
	return false
end

-- Function to fire an offline player from a given group
-- Should be merged with the online player function once an export from the core is available
---@param source integer
---@param employee string citizenid of player to be fired
---@param player Player Player object of player initiating firing action
---@param group 'job'|'gang'
local function fireOfflineEmployee(source, employee, player, group)
	local offlineEmployee = FetchPlayerEntityByCitizenId(employee)
	if not offlineEmployee[1] then
		exports.qbx_core:Notify(source, Lang:t('error.person_doesnt_exist'), 'error')
		return false, nil
	end

	employee = offlineEmployee[1]
	employee[group] = json.decode(employee[group])
	employee.charinfo = json.decode(employee.charinfo)

	if employee[group].grade.level > player.PlayerData[group].grade.level then
		exports.qbx_core:Notify(source, Lang:t('error.fire_boss'), 'error')
		return false, nil
	end

	local role = {
		name = group == 'gang' and 'none' or 'unemployed',
		label = group == 'gang' and GANGS['none'].label or JOBS['unemployed'].label,
		payment = group == 'gang' and 0 or JOBS['unemployed'].grades[0].payment,
		onduty = group ~= 'gang',
		isboss = false,
		grade = {
			name = group == 'gang' and GANGS['none'].grades[0].name or JOBS['unemployed'].grades[0].name,
			level = 0
		}
	}

	local updateColumn = group == 'gang' and 'gang' or 'job'
	local employeeFullName = employee.charinfo.firstname..' '..employee.charinfo.lastname
	local success = UpdatePlayerJob(updateColumn, role, employee.citizenid)
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
	local playerFullName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
	local organizationLabel = player.PlayerData[group].label
	
	if not player.PlayerData[group].isboss then return end
	
	local success, employeeFullName
	if firedEmployee then
		employeeFullName = firedEmployee.PlayerData.charinfo.firstname..' '..firedEmployee.PlayerData.charinfo.lastname
		success = fireOnlineEmployee(source, firedEmployee, player, group)
	else
		success, employeeFullName = fireOfflineEmployee(source, employee, player, group)
	end
	
	if success then
		local logArea = group == 'gang' and 'gang' or 'boss'
		local logType = group == 'gang' and Lang:t('error.gang_fired') or Lang:t('error.job_fired')
		exports.qbx_core:Notify(source, logType, 'success')
		TriggerEvent('qb-log:server:CreateLog', logArea..'menu', group..Lang:t('logs.fire'), 'orange', playerFullName..Lang:t('logs.fired')..employeeFullName..' ('..organizationLabel..')', false)
	else
		exports.qbx_core:Notify(source, Lang:t('error.unable_fire'), 'error')
	end
	return nil
end)

-- Event Handlers
-- Sets up inventory stashes for all groups
AddEventHandler('onServerResourceStart', function(resourceName)
	if resourceName ~= 'ox_inventory' and resourceName ~= GetCurrentResourceName() then return end

	local data = sharedConfig.menus
	for groups, group in pairs(data) do
		local prefix = group.group == 'gang' and 'gang_' or 'boss_'
		exports.ox_inventory:RegisterStash(prefix..groups, 'Stash: '..groups, 100, 4000000, false)
	end
end)
