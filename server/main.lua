lib.versionCheck('Qbox-project/qbx_management')
if not lib.checkDependency('qbx_core', '1.7.0', true) then error() return end
if not lib.checkDependency('ox_lib', '3.13.0', true) then error() return end

local config = require 'config.server'
local logger = require '@qbx_core.modules.logger'
local JOBS = exports.qbx_core:GetJobs()
local GANGS = exports.qbx_core:GetGangs()
local menus = {}

for groupName, menuInfo in pairs(config.menus) do
	menuInfo.groupName = groupName
	menus[#menus + 1] = menuInfo
end

local function getMenuEntries(groupName, groupType)
	local menuEntries = {}

    local groupEntries = FetchPlayersInGroup(groupName, groupType)
    for i = 1, #groupEntries do
        local citizenid = groupEntries[i].citizenid
        local grade = groupEntries[i].grade
        local player = exports.qbx_core:GetPlayerByCitizenId(citizenid) or exports.qbx_core:GetOfflinePlayer(citizenid)
        local namePrefix = player.Offline and '❌ ' or '🟢 '
        menuEntries[#menuEntries + 1] = {
            cid = citizenid,
			grade = grade,
			name = namePrefix..player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
        }
    end

	return menuEntries
end

-- Get a list of employees for a given group. Currently uses MySQL queries to return offline players.
-- Once an export is available to reliably return offline players this can rewriten.
---@param groupName string Name of job/gang to get employees of
---@param groupType GroupType
---@return table?
lib.callback.register('qbx_management:server:getEmployees', function(source, groupName, groupType)
	local player = exports.qbx_core:GetPlayer(source)
	if not player.PlayerData[groupType].isboss then return end

	local menuEntries = getMenuEntries(groupName, groupType)
    table.sort(menuEntries, function(a, b)
		return a.grade > b.grade
	end)

	return menuEntries
end)

-- Callback for updating the grade information of online players
---@param citizenId string CitizenId of player who is being promoted/demoted
---@param grade integer Grade number target for target employee
---@param groupType GroupType
lib.callback.register('qbx_management:server:updateGrade', function(source, citizenId, oldGrade, newGrade, groupType)
	local player = exports.qbx_core:GetPlayer(source)
	local employee = exports.qbx_core:GetPlayerByCitizenId(citizenId)
	local jobName = player.PlayerData[groupType].name
	local gradeLevel = player.PlayerData[groupType].grade.level

	if not player.PlayerData[groupType].isboss then return end

	if player.PlayerData.citizenid == citizenId then
		exports.qbx_core:Notify(source, locale('error.cant_promote_self'), 'error')
		return
	end

	if oldGrade >= gradeLevel or newGrade >= gradeLevel then
		exports.qbx_core:Notify(source, locale('error.cant_promote'), 'error')
		return
	end

    if groupType == 'job' then
        exports.qbx_core:AddPlayerToJob(citizenId, jobName, newGrade)
    else
        exports.qbx_core:AddPlayerToGang(citizenId, jobName, newGrade)
    end

    if employee then
	    local gradeName = groupType == 'gang' and GANGS[jobName].grades[newGrade].name or JOBS[jobName].grades[newGrade].name
        exports.qbx_core:Notify(employee.PlayerData.source, locale('success.promoted_to')..gradeName..'.', 'success')
    end
    exports.qbx_core:Notify(source, locale('success.promoted'), 'success')
end)

-- Callback to hire online player as employee of a given group
---@param employee integer Server ID of target employee to be hired
---@param groupType GroupType
lib.callback.register('qbx_management:server:hireEmployee', function(source, employee, groupType)
	local player = exports.qbx_core:GetPlayer(source)
	local target = exports.qbx_core:GetPlayer(employee)

    if not player.PlayerData[groupType].isboss then return end

    if not target then
        exports.qbx_core:Notify(source, locale('error.not_around'), 'error')
        return
    end

	local groupName = player.PlayerData[groupType].name
	local logArea = groupType == 'gang' and 'Gang' or 'Boss'

    if groupType == 'job' then
        exports.qbx_core:AddPlayerToJob(target.PlayerData.citizenid, groupName, 0)
        exports.qbx_core:SetPlayerPrimaryJob(target.PlayerData.citizenid, groupName)
    else
        exports.qbx_core:AddPlayerToGang(target.PlayerData.citizenid, groupName, 0)
        exports.qbx_core:SetPlayerPrimaryGang(target.PlayerData.citizenid, groupName)
    end

    local playerFullName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
    local targetFullName = target.PlayerData.charinfo.firstname..' '..target.PlayerData.charinfo.lastname
    local organizationLabel = player.PlayerData[groupType].label
    exports.qbx_core:Notify(source, locale('success.hired_into', targetFullName, organizationLabel), 'success')
    exports.qbx_core:Notify(target.PlayerData.source, locale('success.hired_to')..organizationLabel, 'success')
    logger.log({source = 'qbx_management', event = 'hireEmployee', message = string.format('%s | %s hired %s into %s at grade %s', logArea, playerFullName, targetFullName, organizationLabel, 0), webhook = config.discordWebhook})
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


---@param employeeCitizenId string
---@param boss Player
---@param groupName string
---@param groupType GroupType
---@return boolean success
local function fireEmployee(employeeCitizenId, boss, groupName, groupType)
    local employee = exports.qbx_core:GetPlayerByCitizenId(employeeCitizenId) or exports.qbx_core:GetOfflinePlayer(employeeCitizenId)
    if employee.PlayerData.citizenid == boss.PlayerData.citizenid then
		local message = groupType == 'gang' and locale('error.kick_yourself') or locale('error.fire_yourself')
		exports.qbx_core:Notify(boss.PlayerData.source, message, 'error')
		return false
	end
    if not employee then
		exports.qbx_core:Notify(boss.PlayerData.source, locale('error.person_doesnt_exist'), 'error')
		return false
	end

    local employeeGrade = groupType == 'job' and employee.PlayerData.jobs?[groupName] or employee.PlayerData.gangs?[groupName]
    local bossGrade = groupType == 'job' and boss.PlayerData.jobs?[groupName] or boss.PlayerData.gangs?[groupName]
    if employeeGrade >= bossGrade then
		exports.qbx_core:Notify(boss.PlayerData.source, locale('error.fire_boss'), 'error')
		return false
	end

	if groupType == 'job' then
        exports.qbx_core:RemovePlayerFromJob(employee.PlayerData.citizenid, groupName)
	else
        exports.qbx_core:RemovePlayerFromGang(employee.PlayerData.citizenid, groupName)
	end

    if not employee.Offline then
        local message = groupType == 'gang' and locale('error.you_gang_fired', GANGS[groupName].label) or locale('error.you_job_fired', JOBS[groupName].label)
		exports.qbx_core:Notify(employee.PlayerData.source, message, 'error')
    end

    return true
end

-- Callback for firing a player from a given society.
---@param employee string citizenid of employee to be fired
---@param groupType GroupType
lib.callback.register('qbx_management:server:fireEmployee', function(source, employee, groupType)
	local player = exports.qbx_core:GetPlayer(source)
	local firedEmployee = exports.qbx_core:GetPlayerByCitizenId(employee) or exports.qbx_core:GetOfflinePlayer(employee)
	local playerFullName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
	local organizationLabel = player.PlayerData[groupType].label

	if not player.PlayerData[groupType].isboss then return end
    if not firedEmployee then lib.print.error("not able to find player with citizenid", employee) return end
    local success = fireEmployee(employee, player, player.PlayerData[groupType].name, groupType)
    local employeeFullName = firedEmployee.PlayerData.charinfo.firstname..' '..firedEmployee.PlayerData.charinfo.lastname

	if success then
		local logArea = groupType == 'gang' and 'Gang' or 'Boss'
		local logType = groupType == 'gang' and locale('error.gang_fired') or locale('error.job_fired')
		exports.qbx_core:Notify(source, logType, 'success')
		logger.log({source = 'qbx_management', event = 'fireEmployee', message = string.format('%s | %s fired %s from %s', logArea, playerFullName, employeeFullName, organizationLabel), webhook = config.discordWebhook})
	else
		exports.qbx_core:Notify(source, locale('error.unable_fire'), 'error')
	end
end)

lib.callback.register('qbx_management:server:getBossMenus', function()
	return menus
end)

---Creates a boss zone for the specified group
---@class MenuInfo
---@field groupName string Name of the group
---@field type GroupType Type of group
---@field coords vector3 Coordinates of the zone
---@field size? vector3 uses vec3(1.5, 1.5, 1.5) if not set
---@field rotation? number uses 0.0 if not set

---@param menuInfo MenuInfo
local function registerBossMenu(menuInfo)
    menus[#menus + 1] = menuInfo
	TriggerClientEvent('qbx_management:client:bossMenuRegistered', -1, menuInfo)
end

exports('RegisterBossMenu', registerBossMenu)
