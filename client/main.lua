local sharedConfig = require 'config.shared'
local JOBS = exports.qbx_core:GetJobs()
local GANGS = exports.qbx_core:GetGangs()
local isLoggedIn = LocalPlayer.state.isLoggedIn

-- Finds nearby players and returns a table of server ids
---@return table
local function findPlayers()
    local closePlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 10, false)
    for _, v in pairs(closePlayers) do
        v.id = GetPlayerServerId(v.id)
    end
	return lib.callback.await('qbx_management:server:getPlayers', false, closePlayers)
end

-- Presents a menu to manage a specific employee including changing grade or firing them
---@param player table Player data for managing a specific employee
---@param groupName string Name of job/gang of employee being managed
---@param groupType 'job'|'gang'
local function manageEmployee(player, groupName, groupType)
    local employeeMenu = {}
    local employeeLoop = groupType == 'gang' and GANGS[groupName].grades or JOBS[groupName].grades
    for groupGrade, gradeTitle in pairs(employeeLoop) do
        employeeMenu[#employeeMenu + 1] = {
            title = gradeTitle.name,
            description = Lang:t('menu.grade')..groupGrade,
            onSelect = function()
                lib.callback.await('qbx_management:server:updateGrade', false, player.cid, tonumber(groupGrade), groupType)
                OpenBossMenu(groupType)
            end,
        }
    end

    employeeMenu[#employeeMenu + 1] = {
        title = groupType == 'gang' and Lang:t('menu.expel_gang') or Lang:t('menu.fire_employee'),
        icon = 'fa-solid fa-user-large-slash',
        onSelect = function()
            lib.callback.await('qbx_management:server:fireEmployee', false, player.cid, groupType)
            OpenBossMenu(groupType)
        end,
    }

    lib.registerContext({
        id = 'memberMenu',
        title = player.name,
        menu = 'memberListMenu',
        options = employeeMenu,
    })

    lib.showContext('memberMenu')
end

-- Presents a menu of employees the work for a job or gang.
-- Allows selection of an employee to perform further actions
---@param groupType 'job'|'gang'
local function employeeList(groupType)
    local employeesMenu = {}
    local groupName = QBX.PlayerData[groupType].name
    local employees = lib.callback.await('qbx_management:server:getEmployees', false, groupName, groupType)
    for _, employee in pairs(employees) do
        employeesMenu[#employeesMenu + 1] = {
            title = employee.name,
            description = employee.grade.name,
            onSelect = function()
                manageEmployee(employee, groupName, groupType)
            end,
        }
    end
    
    lib.registerContext({
        id = 'memberListMenu',
        title = groupType == 'gang' and Lang:t('menu.manage_gang') or Lang:t('menu.manage_employees'),
        menu = 'openBossMenu',
        options = employeesMenu,
    })

    lib.showContext('memberListMenu')
end

-- Presents a list of possible employees to hire for a job or gang.
---@param groupType 'job'|'gang'
local function showHireMenu(groupType)
    local hireMenu = {}
    local players = findPlayers()
    local hireName = QBX.PlayerData[groupType].name
    for _, player in pairs(players) do
        if player[groupType].name ~= hireName then
            hireMenu[#hireMenu + 1] = {
                title = player.name,
                description = Lang:t('menu.citizen_id')..player.citizenid..' - '..Lang:t('menu.id')..player.source,
                onSelect = function()
                    lib.callback.await('qbx_management:server:hireEmployee', false, player.source, groupType)
                    OpenBossMenu(groupType)
                end,
            }
        end
    end

    lib.registerContext({
        id = 'hireMenu',
        title = groupType == 'gang' and Lang:t('menu.hire_gang') or Lang:t('menu.hire_employees'),
        menu = 'openBossMenu',
        options = hireMenu,
    })

    lib.showContext('hireMenu')
end

-- Opens main boss menu changing function based on the group provided.
---@param groupType 'job'|'gang'
function OpenBossMenu(groupType)
    if not QBX.PlayerData[groupType].name or not QBX.PlayerData[groupType].isboss then return end

    local bossMenu = {
        {
            title = groupType == 'gang' and Lang:t('menu.manage_gang') or Lang:t('menu.manage_employees'),
            description = groupType == 'gang' and Lang:t('menu.check_gang') or Lang:t('menu.check_employee'),
            icon = 'fa-solid fa-list',
            onSelect = function()
                employeeList(groupType)
            end,
        },
        {
            title = 'Hire Employees',
            description = groupType == 'gang' and Lang:t('menu.hire_gang') or Lang:t('menu.hire_civilians'),
            icon = 'fa-solid fa-hand-holding',
            onSelect = function()
                showHireMenu(groupType)
            end,
        },
        {
            title = 'Storage Access',
            description = groupType == 'gang' and Lang:t('menu.gang_storage') or Lang:t('menu.business_storage'),
            icon = 'fa-solid fa-box-open',
            onSelect = function()
                local stash = (groupType == 'gang' and 'gang_' or 'boss_')..QBX.PlayerData[groupType].name
                exports.ox_inventory:openInventory('stash', stash)
            end,
        },
    }

    lib.registerContext({
        id = 'openBossMenu',
        title = groupType == 'gang' and string.upper(QBX.PlayerData.gang.label) or string.upper(QBX.PlayerData.job.label),
        options = bossMenu,
    })
    lib.showContext('openBossMenu')
end

local function createBossZones()
    if sharedConfig.useTarget then
        for groups, group in pairs(sharedConfig.menus) do
            exports.ox_target:addBoxZone({
                coords = group.coords,
                size = group.size,
                rotation = group.rotation,
                debug = sharedConfig.debugPoly,
                options = {
                    {
                        name = groups..'_menu',
                        icon = 'fa-solid fa-right-to-bracket',
                        label = group.group == 'gang' and Lang:t('menu.gang_menu') or Lang:t('menu.boss_menu'),
                        groups = groups,
                        onSelect = function()
                            OpenBossMenu(group.group)
                        end
                    }
                }
            })
        end
    else
        for groups, group in pairs(sharedConfig.menus) do
            lib.zones.box({
                coords = group.coords,
                rotation = group.rotation,
                size = group.size,
                debug = sharedConfig.debugPoly,
                onEnter = function()
                    if groups == QBX.PlayerData[group.group].name and QBX.PlayerData[group.group].isboss then
                        lib.showTextUI(group.group == 'gang' and Lang:t('menu.gang_management') or Lang:t('menu.boss_management'))
                    end
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
                inside = function()
                    if IsControlJustPressed(0, 51) then -- E
                        if groups == QBX.PlayerData[group.group].name and QBX.PlayerData[group.group].isboss then
                            OpenBossMenu(group.group)
                            lib.hideTextUI()
                        end
                    end
                end
            })
        end
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    createBossZones()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
end)

CreateThread(function()
    if not isLoggedIn then return end
    createBossZones()
end)