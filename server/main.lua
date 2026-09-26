lib.versionCheck('Qbox-project/qbx_management')
if not lib.checkDependency('qbx_core', '1.18.0', true) then error() return end
if not lib.checkDependency('ox_lib', '3.13.0', true) then error() return end

local config = require 'config.server'
local logger = require '@qbx_core.modules.logger'
local storage = require 'server.storage'
local managementEnabled = (GetConvar('qbx:enableGroupManagement', 'false') == 'true')
local JOBS = exports.qbx_core:GetJobs()
local GANGS = exports.qbx_core:GetGangs()
local playersClockedIn = {}
local menus = {}
local ready = false
local validGroupTypes = { job = true, gang = true }

---@param player Player?
---@param groupType any
---@return table?
local function getPlayerGroup(player, groupType)
    if not player or type(groupType) ~= 'string' or not validGroupTypes[groupType] then return end
    return player.PlayerData[groupType]
end

---Initialize storage, menus & managed groups
local function init()
    storage.createActivityTable()

    for groupName, menuData in pairs(config.menus) do
        if type(menuData) == "table" and not menuData.coords then
            for i = 1, #menuData do
                local menuInfo = menuData[i]
                ---@diagnostic disable-next-line: inject-field
                menuInfo.groupName = groupName
                menus[#menus + 1] = menuInfo
            end
        else
            ---@diagnostic disable-next-line: inject-field
            menuData.groupName = groupName
            menus[#menus + 1] = menuData
        end
    end

    storage.cleanupActivity()

    if not managementEnabled then return end
    storage.createGroupsTable()

    local managedJobs = storage.fetchJobs()
    local managedGangs = storage.fetchGangs()

    exports.qbx_core:CreateJobs(managedJobs)
    exports.qbx_core:CreateGangs(managedGangs)

    ready = true
end

---Build group menu
---@param groupName string
---@param groupType GroupType
---@return table
local function getMenuEntries(groupName, groupType)
    local menuEntries = {}

    local groupEntries = exports.qbx_core:GetGroupMembers(groupName, groupType)
    for i = 1, #groupEntries do
        local citizenid = groupEntries[i].citizenid
        local grade = groupEntries[i].grade
        local player = exports.qbx_core:GetPlayerByCitizenId(citizenid) or exports.qbx_core:GetOfflinePlayer(citizenid)
        local namePrefix = player.Offline and '❌ ' or '🟢 '
        local playerActivityData = groupType == 'job' and storage.getPlayerActivityData(citizenid, groupName) or nil
        local playerClockData = playersClockedIn[player.PlayerData.source]
        local playerLastCheckIn = playerClockData and os.date(config.formatDateTime, playerClockData.time) or playerActivityData?.last_checkin
        menuEntries[#menuEntries + 1] = {
            cid = citizenid,
            grade = grade,
            name = namePrefix..player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname,
            onduty = player.PlayerData.job.onduty and not player.Offline,
            hours = playerActivityData?.hours,
            last_checkin = playerLastCheckIn
        }
    end

    return menuEntries
end

-- Get a list of employees for a given group.
---@param groupName string Name of job/gang to get employees of
---@param groupType GroupType
---@return table?
lib.callback.register('qbx_management:server:getEmployees', function(source, groupName, groupType)
    local player = exports.qbx_core:GetPlayer(source)
    local group = getPlayerGroup(player, groupType)
    if not group or not group.isboss or group.name ~= groupName then return end

    local menuEntries = getMenuEntries(groupName, groupType)
    table.sort(menuEntries, function(a, b)
        return a.grade > b.grade
    end)

    logger.log({
        source = source,
        event = 'qbx_management:server:getEmployees',
        message = locale('logs.retrieved_employees', groupName, groupType),
        webhook = config.discordWebhook
    })

    return menuEntries
end)

-- Callback for updating the grade information of online players
---@param source number
---@param citizenId string CitizenId of player who is being promoted/demoted
---@param oldGrade integer Old grade number of target employee
---@param newGrade integer New grade number of target employee
---@param groupType GroupType
lib.callback.register('qbx_management:server:updateGrade', function(source, citizenId, _, newGrade, groupType)
    local player = exports.qbx_core:GetPlayer(source)
    local group = getPlayerGroup(player, groupType)
    if not group or not group.isboss or type(citizenId) ~= 'string' or math.type(newGrade) ~= 'integer' or newGrade < 0 then return end

    local employee = exports.qbx_core:GetPlayerByCitizenId(citizenId)
    local employeeData = employee or exports.qbx_core:GetOfflinePlayer(citizenId)
    if not employeeData then return end

    local groupName = group.name
    local gradeLevel = group.grade.level
    local employeeGroups = employeeData.PlayerData[groupType == 'job' and 'jobs' or 'gangs']
    local employeeGrade = employeeGroups and employeeGroups[groupName]
    local groupDefinition = groupType == 'job' and JOBS[groupName] or GANGS[groupName]

    if employeeGrade == nil or not groupDefinition?.grades[newGrade] then return end

    if player.PlayerData.citizenid == citizenId then
        exports.qbx_core:Notify(source, locale('error.cant_promote_self'), 'error')
        return
    end

    if employeeGrade >= gradeLevel or newGrade >= gradeLevel then
        exports.qbx_core:Notify(source, locale('error.cant_promote'), 'error')
        return
    end

    if groupType == 'job' then
        local success, errorResult = exports.qbx_core:AddPlayerToJob(citizenId, groupName, newGrade)
        assert(success, errorResult?.message)
    else
        local success, errorResult = exports.qbx_core:AddPlayerToGang(citizenId, groupName, newGrade)
        assert(success, errorResult?.message)
    end

    if employee then
        local gradeName = groupDefinition.grades[newGrade].name
        exports.qbx_core:Notify(employee.PlayerData.source, locale('success.promoted_to')..gradeName..'.', 'success')
    end
    exports.qbx_core:Notify(source, locale('success.promoted'), 'success')

    logger.log({
        source = source,
        event = 'qbx_management:server:updateGrade',
        message = locale('logs.updated_grade', citizenId, employeeGrade, newGrade, groupName, groupType),
        webhook = config.discordWebhook
    })
end)

-- Callback to hire online player as employee of a given group
---@param employee integer Server ID of target employee to be hired
---@param groupType GroupType
lib.callback.register('qbx_management:server:hireEmployee', function(source, employee, groupType)
    local player = exports.qbx_core:GetPlayer(source)
    local group = getPlayerGroup(player, groupType)
    if not group or not group.isboss or math.type(employee) ~= 'integer' then return end

    local target = exports.qbx_core:GetPlayer(employee)

    if not target then
        exports.qbx_core:Notify(source, locale('error.not_around'), 'error')
        return
    end

    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(employee))) > 10.0 then
        exports.qbx_core:Notify(source, locale('error.too_far'), 'error')
        return
    end

    local groupName = group.name
    local logArea = groupType == 'gang' and 'Gang' or 'Boss'
    local playerFullName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
    local targetFullName = target.PlayerData.charinfo.firstname..' '..target.PlayerData.charinfo.lastname
    local organizationLabel = group.label
    local targetAgreed = lib.callback.await('qbx_management:client:confirmHire', employee, playerFullName, organizationLabel)

    if targetAgreed ~= 'confirm' then
        exports.qbx_core:Notify(source, locale('error.hire_declined'), 'error')
        return
    end

    player = exports.qbx_core:GetPlayer(source)
    target = exports.qbx_core:GetPlayer(employee)
    local currentGroup = getPlayerGroup(player, groupType)
    if not currentGroup or not currentGroup.isboss or currentGroup.name ~= groupName or not target
        or GetPlayerRoutingBucket(source) ~= GetPlayerRoutingBucket(employee)
        or #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(employee))) > 10.0 then return end

    if groupType == 'job' then
        local success, errorResult = exports.qbx_core:AddPlayerToJob(target.PlayerData.citizenid, groupName, 0)
        assert(success, errorResult?.message)
        success, errorResult = exports.qbx_core:SetPlayerPrimaryJob(target.PlayerData.citizenid, groupName)
        assert(success, errorResult?.message)
    else
        local success, errorResult = exports.qbx_core:AddPlayerToGang(target.PlayerData.citizenid, groupName, 0)
        assert(success, errorResult?.message)
        success, errorResult = exports.qbx_core:SetPlayerPrimaryGang(target.PlayerData.citizenid, groupName)
        assert(success, errorResult?.message)
    end

    exports.qbx_core:Notify(source, locale('success.hired_into', targetFullName, organizationLabel), 'success')
    exports.qbx_core:Notify(target.PlayerData.source, locale('success.hired_to')..organizationLabel, 'success')

    logger.log({
        source = source,
        event = 'qbx_management:server:hireEmployee',
        message = locale('logs.hired_employee', logArea, playerFullName, targetFullName, organizationLabel, 0),
        webhook = config.discordWebhook
    })
end)

-- Returns playerdata for a given table of player server ids.
---@param closePlayers table Table of player data for possible hiring
---@return table
lib.callback.register('qbx_management:server:getPlayers', function(source, closePlayers)
    local requester = exports.qbx_core:GetPlayer(source)
    if not requester or not (requester.PlayerData.job.isboss or requester.PlayerData.gang.isboss) or type(closePlayers) ~= 'table' then return {} end

    local players = {}
    local requesterCoords = GetEntityCoords(GetPlayerPed(source))
    for i = 1, math.min(#closePlayers, 64) do
        local playerId = closePlayers[i]?.id
        local player = math.type(playerId) == 'integer' and exports.qbx_core:GetPlayer(playerId)
        if player and GetPlayerRoutingBucket(source) == GetPlayerRoutingBucket(playerId) and #(requesterCoords - GetEntityCoords(GetPlayerPed(playerId))) <= 10.0 then
            players[#players + 1] = {
                id = playerId,
                name = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname,
                citizenid = player.PlayerData.citizenid,
                job = player.PlayerData.job,
                gang = player.PlayerData.gang,
                source = player.PlayerData.source
            }
        end
    end

    table.sort(players, function(a, b)
        return a.name < b.name
    end)

    logger.log({
        source = 'qbx_management',
        event = 'qbx_management:server:getPlayers',
        message = locale('logs.retrieved_players'),
        webhook = config.discordWebhook
    })

    return players
end)


---@param employeeCitizenId string
---@diagnostic disable-next-line: undefined-doc-name
---@param boss Player | table
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
        local success, errorResult = exports.qbx_core:RemovePlayerFromJob(employee.PlayerData.citizenid, groupName)
        assert(success, errorResult?.message)
    else
        local success, errorResult = exports.qbx_core:RemovePlayerFromGang(employee.PlayerData.citizenid, groupName)
        assert(success, errorResult?.message)
    end

    if not employee.Offline then
        local message = groupType == 'gang' and locale('error.you_gang_fired', GANGS[groupName].label) or locale('error.you_job_fired', JOBS[groupName].label)
        exports.qbx_core:Notify(employee.PlayerData.source, message, 'error')
    end

    logger.log({
        source = boss.PlayerData.source,
        event = 'qbx_management:server:fireEmployee',
        message = locale('logs.fired_employee', employeeCitizenId, groupName, groupType),
        webhook = config.discordWebhook
    })

    return true
end

-- Callback for firing a player from a given society.
---@param employee string citizenid of employee to be fired
---@param groupType GroupType
lib.callback.register('qbx_management:server:fireEmployee', function(source, employee, groupType)
    local player = exports.qbx_core:GetPlayer(source)
    local group = getPlayerGroup(player, groupType)
    if not group or not group.isboss or type(employee) ~= 'string' then return end

    local firedEmployee = exports.qbx_core:GetPlayerByCitizenId(employee) or exports.qbx_core:GetOfflinePlayer(employee)
    local playerFullName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
    local organizationLabel = group.label

    if not firedEmployee then lib.print.error("not able to find player with citizenid", employee) return end

    local success = fireEmployee(employee, player, group.name, groupType)
    local employeeFullName = firedEmployee.PlayerData.charinfo.firstname..' '..firedEmployee.PlayerData.charinfo.lastname

    if success then
        local logArea = groupType == 'gang' and 'Gang' or 'Boss'
        local logType = groupType == 'gang' and locale('error.gang_fired') or locale('error.job_fired')
        exports.qbx_core:Notify(source, logType, 'success')
        logger.log({
            source = source,
            event = 'qbx_management:server:fireEmployee',
            message = locale('logs.fired_employee_success', logArea, playerFullName, employeeFullName, organizationLabel),
            webhook = config.discordWebhook
        })
    else
        exports.qbx_core:Notify(source, locale('error.unable_fire'), 'error')
    end
end)

lib.callback.register('qbx_management:server:getBossMenus', function()
    logger.log({
        source = 'qbx_management',
        event = 'qbx_management:server:getBossMenus',
        message = locale('logs.retrieved_boss_menus'),
        webhook = config.discordWebhook
    })
    return menus
end)

---Callback for updating a job/gang grade
---@param source integer
---@param groupType GroupType
---@param grade integer
---@param gradeData JobGradeData|GangGradeData
lib.callback.register('qbx_management:server:modifyGrade', function(source, groupType, grade, gradeData)
    if not managementEnabled then return end
    local player = exports.qbx_core:GetPlayer(source)
    local playerGroup = getPlayerGroup(player, groupType)
    if not playerGroup or not playerGroup.isboss or math.type(grade) ~= 'integer' or grade < 0 or playerGroup.grade.level <= grade or type(gradeData) ~= 'table' then
        lib.print.error("User attempted to update grade without permission. Possible exploit: ", player?.PlayerData.citizenid or source)
        return
    end
    local groupName = playerGroup.name
    local group = groupType == 'job' and JOBS[groupName] or GANGS[groupName]
    if not (group and group.grades[grade]) then return end

    if type(gradeData.name) ~= 'string' or #gradeData.name < 1 or #gradeData.name > 50 then return end
    local sanitizedGrade = lib.table.deepclone(group.grades[grade])
    sanitizedGrade.name = gradeData.name
    if groupType == 'job' then
        if type(gradeData.payment) ~= 'number' or gradeData.payment ~= gradeData.payment or gradeData.payment < 0 or gradeData.payment > 100000 then return end
        sanitizedGrade.payment = math.floor(gradeData.payment)
        sanitizedGrade.isboss = gradeData.isboss == true
        sanitizedGrade.bankAuth = gradeData.bankAuth == true
    end

    if groupType == 'job' then
        exports.qbx_core:UpsertJobGrade(groupName, grade, sanitizedGrade)
    else
        exports.qbx_core:UpsertGangGrade(groupName, grade, sanitizedGrade)
    end

    exports.qbx_core:Notify(source, locale('grade.success'), 'success')
end)

---Creates a boss zone for the specified group
---@param menuInfo MenuInfo
local function registerBossMenu(menuInfo)
    menus[#menus + 1] = menuInfo
    TriggerClientEvent('qbx_management:client:bossMenuRegistered', -1, menuInfo)
    logger.log({
        source = 'qbx_management',
        event = 'qbx_management:server:registerBossMenu',
        message = locale('logs.registered_boss_menu', menuInfo.groupName),
        webhook = config.discordWebhook
    })
end

exports('RegisterBossMenu', registerBossMenu)

---@param source number
---@param citizenid string
---@param job string
local function doPlayerCheckIn(source, citizenid, job)
    playersClockedIn[source] = { citizenid = citizenid, job = job, time = os.time() }
    logger.log({
        source = source,
        event = 'qbx_management:server:doPlayerCheckIn',
        message = locale('logs.player_checkin', citizenid, job),
        webhook = config.discordWebhook
    })
end

---@param source number
local function onPlayerUnload(source)
    if playersClockedIn[source] then
        storage.onPlayerCheckOut(playersClockedIn[source])
        playersClockedIn[source] = nil
        logger.log({
            source = source,
            event = 'qbx_management:server:onPlayerUnload',
            message = locale('logs.player_unload', source),
            webhook = config.discordWebhook
        })
    end
end

---@param source number
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local player = exports.qbx_core:GetPlayer(source)
    if player == nil then return end
    if player.PlayerData.job.onduty then
        doPlayerCheckIn(player.PlayerData.source, player.PlayerData.citizenid, player.PlayerData.job.name)
    end
end)

---@param source number
---@param job table?
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    if playersClockedIn[source] then
        onPlayerUnload(source)
    end
    local player = exports.qbx_core:GetPlayer(source)
    if player == nil then return end
    if player.PlayerData.job.onduty then
        doPlayerCheckIn(player.PlayerData.source, player.PlayerData.citizenid, job.name)
    end
end)

---Receive job updates from core
---@param jobName string
---@param job Job
AddEventHandler('qbx_core:server:onJobUpdate', function(jobName, job)
    JOBS[jobName] = job
    if not (managementEnabled and ready) then return end
    storage.updateGroup(jobName, 'job', job)
end)

---Receive gang updates from core
---@param gangName string
---@param gang Gang
AddEventHandler('qbx_core:server:onGangUpdate', function(gangName, gang)
    GANGS[gangName] = gang
    if not (managementEnabled and ready) then return end
    storage.updateGroup(gangName, 'gang', gang)
end)

---@param source number
---@param duty boolean
AddEventHandler('QBCore:Server:SetDuty', function(source, duty)
    local player = exports.qbx_core:GetPlayer(source)
    if player == nil then return end
    if duty then
        doPlayerCheckIn(player.PlayerData.source, player.PlayerData.citizenid, player.PlayerData.job.name)
    else
        onPlayerUnload(player.PlayerData.source)
    end
end)

---@param source number
AddEventHandler('QBCore:Server:OnPlayerUnload', function()
    onPlayerUnload(source)
end)

---@param source number
AddEventHandler('playerDropped', function()
    onPlayerUnload(source)
end)

init()
