local sharedConfig = require 'config.shared'
local jobs = exports.qbx_core:GetJobs()
local gangs = exports.qbx_core:GetGangs()
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
---@param group 'job'|'gang'
local function manageEmployee(player, groupName, group)
    local employeeMenu = {}
    local employeeLoop = group == 'gang' and gangs[groupName].grades or jobs[groupName].grades
    for groupGrade, gradeTitle in pairs(employeeLoop) do
        employeeMenu[#employeeMenu + 1] = {
            title = gradeTitle.name,
            description = 'Grade: ' .. groupGrade,
            onSelect = function()
                lib.callback.await('qbx_management:server:updateGrade', false, player.cid, tonumber(groupGrade), group)
                OpenBossMenu(group)
            end,
        }
    end

    employeeMenu[#employeeMenu + 1] = {
        title = group == 'gang' and 'Expel Gang Member' or 'Fire Employee',
        icon = 'fa-solid fa-user-large-slash',
        onSelect = function()
            lib.callback.await('qbx_management:server:fireEmployee', false, player.cid, group)
            OpenBossMenu(group)
        end,
    }

    employeeMenu[#employeeMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        onSelect = function()
            OpenBossMenu(group)
        end
    }

    lib.registerContext({
        id = 'qbx_management_open_Member',
        title = 'Manage ' .. player.name .. ' - ' .. string.upper(QBX.PlayerData[group].label),
        options = employeeMenu,
    })

    lib.showContext('qbx_management_open_Member')
end

-- Presents a menu of employees the work for a job or gang.
-- Allows selection of an employee to perform further actions
---@param group 'job'|'gang'
local function employeeList(group)
    local employeesMenu = {}
    local groupName = QBX.PlayerData[group].name
    local employees = lib.callback.await('qbx_management:server:getEmployees', false, groupName, group)
    for _, employee in pairs(employees) do
        employeesMenu[#employeesMenu + 1] = {
            title = employee.name,
            description = employee.grade.name,
            onSelect = function()
                manageEmployee(employee, groupName, group)
            end,
        }
    end
    
    employeesMenu[#employeesMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        onSelect = function()
            OpenBossMenu(group)
        end
    }
    
    lib.registerContext({
        id = 'qbx_management_open_Manage',
        title = group == 'gang' and 'Manage Gang Members - ' .. string.upper(QBX.PlayerData.gang.label) or 'Manage Employees - ' .. string.upper(QBX.PlayerData.job.label),
        options = employeesMenu,
    })

    lib.showContext('qbx_management_open_Manage')
end

-- Presents a list of possible employees to hire for a job or gang.
---@param group 'job'|'gang'
local function showHireMenu(group)
    local hireMenu = {}
    local players = findPlayers()
    local hireName = QBX.PlayerData[group].name
    for _, player in pairs(players) do
        if player[group].name ~= hireName then
            hireMenu[#hireMenu + 1] = {
                title = player.name,
                description = 'Citizen ID: ' .. player.citizenid .. ' - ID: ' .. player.source,
                onSelect = function()
                    lib.callback.await('qbx_management:server:hireEmployee', false, player.source, group)
                    OpenBossMenu(group)
                end,
            }
        end
    end

    hireMenu[#hireMenu + 1] = {
        title = 'Return',
        icon = 'fa-solid fa-angle-left',
        onSelect = function()
            OpenBossMenu(group)
        end
    }

    lib.registerContext({
        id = 'qbx_management_open_Hire',
        title = group == 'gang' and 'Hire Gang Members - ' .. string.upper(QBX.PlayerData.gang.label) or 'Hire Employees - ' .. string.upper(QBX.PlayerData.job.label),
        options = hireMenu,
    })

    lib.showContext('qbx_management_open_Hire')
end

-- Opens main boss menu changing function based on the group provided.
---@param group 'job'|'gang'
function OpenBossMenu(group)
    if not QBX.PlayerData[group].name or not QBX.PlayerData[group].isboss then return end

    local bossMenu = {
        {
            title = group == 'gang' and 'Manage Gang Members' or 'Manage Employees',
            description = group == 'gang' and 'Recruit or Fire Gang Members' or 'Check your Employees List',
            icon = 'fa-solid fa-list',
            onSelect = function()
                employeeList(group)
            end,
        },
        {
            title = 'Hire Employees',
            description = group == 'gang' and 'Hire Gang Members' or 'Hire Nearby Civilians',
            icon = 'fa-solid fa-hand-holding',
            onSelect = function()
                showHireMenu(group)
            end,
        },
        {
            title = 'Storage Access',
            description = group == 'gang' and 'Open Gang Stash' or 'Open Business Storage',
            icon = 'fa-solid fa-box-open',
            onSelect = function()
                local stash = (group == 'gang' and 'gang_' or 'boss_')..QBX.PlayerData[group].name
                exports.ox_inventory:openInventory('stash', stash)
            end,
        },
    }

    lib.registerContext({
        id = 'qbx_management_open_BossMenu',
        title = group == 'gang' and 'Gang Management - ' .. string.upper(QBX.PlayerData.gang.label) or 'Boss Menu - ' .. string.upper(QBX.PlayerData.job.label),
        options = bossMenu,
    })
    lib.showContext('qbx_management_open_BossMenu')
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
                        label = group.group == 'gang' and 'Gang Menu' or 'Boss Menu',
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
                        lib.showTextUI(group.group == 'gang' and '[E] - Open Gang Management' or '[E] - Open Boss Management')
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