QBCore = exports['qbx-core']:GetCoreObject()
Accounts = {}

---@param id number
---@param reason string
function ExploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(id),
        QBCore.Functions.GetIdentifier(id, 'license'),
        QBCore.Functions.GetIdentifier(id, 'discord'),
        QBCore.Functions.GetIdentifier(id, 'ip'),
        reason,
        2147483647,
        'qb-management'
    })

    TriggerEvent('qb-log:server:CreateLog', 'bans', "Player Banned", 'red', string.format("%s was banned by %s for %s", GetPlayerName(id), 'qb-management', reason), true)

    DropPlayer(id, "You were permanently banned by the server for: Exploiting")
end

---@param account string
---@return number
function GetAccount(account)
	return exports['Renewed-Banking']:getAccountMoney(account) or 0
end

exports('GetAccount', GetAccount)
exports('GetGangAccount', GetAccount)

---@param account string
---@param amount number
function AddMoney(account, amount)
	if not Accounts[account] then
		Accounts[account] = 0
	end

	Accounts[account] += amount
	exports['Renewed-Banking']:addAccountMoney(account, amount)
end

---@param account string
---@param amount number
---@return boolean
function RemoveMoney(account, amount)

	if amount <= 0 then return false end
    if not Accounts[account] then
        Accounts[account] = 0
    end

    local isRemoved = false

    if Accounts[account] >= amount then
        Accounts[account] -= amount
        isRemoved = true
    end

	exports['Renewed-Banking']:removeAccountMoney(account, amount)
	return isRemoved
end

MySQL.ready(function ()
	local funds = MySQL.query.await('SELECT job_name, amount FROM management_funds')
	if not funds then return end

	for i = 1, #funds do
		local v = funds[i]
		Accounts[v.job_name] = v.amount
	end
end)

---@param src number
---@param amount number
---@param pDataType 'job'|'gang'
---@param type 'boss'|'gang'
---@param reason string
---@return boolean success
---@return Player? player populated if successful
---@return string? accountName populated if successful
function WithdrawMoney(src, amount, pDataType, type, reason)
	local player = QBCore.Functions.GetPlayer(src)

	if not player.PlayerData[pDataType].isboss then ExploitBan(src, 'withdrawMoney Exploiting') return false end

	local account = player.PlayerData[pDataType].name
	if RemoveMoney(account, amount, type) then
        player.Functions.AddMoney("cash", amount, reason)
		TriggerClientEvent('QBCore:Notify', src, "You have withdrawn: $" ..amount, "success")
        return true, player, account
	else
		TriggerClientEvent('QBCore:Notify', src, "You dont have enough money in the account!", "error")
        return false, player, account
    end
end

---@param src number
---@param amount number
---@param pDataType 'job'|'gang'
---@param type 'boss'|'gang'
---@return boolean success
---@return Player? player populated if successful
---@return string? accountName populated if successful
function DepositMoney(src, amount, pDataType, type)
	local player = QBCore.Functions.GetPlayer(src)

	if not player.PlayerData[pDataType].isboss then ExploitBan(src, 'depositMoney Exploiting') return false end

	if player.Functions.RemoveMoney("cash", amount) then
		local account = player.PlayerData[pDataType].name
		AddMoney(account, amount, type)
		TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Deposit Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. account .. ')', false)
		TriggerClientEvent('QBCore:Notify', src, "You have deposited: $" ..amount, "success")
        return true, player, account
	else
		TriggerClientEvent('QBCore:Notify', src, "You dont have enough money to add!", "error")
        return false, player, account
    end
end

---@param src number
---@param accountName string
---@param type 'job'|'gang'
---@return table?
function GetEmployees(src, accountName, type)
	local player = QBCore.Functions.GetPlayer(src)

	if not player.PlayerData[type].isboss then ExploitBan(src, 'GetEmployees Exploiting') return end

	local employees = {}
	local players = MySQL.query.await("SELECT * FROM `players` WHERE ?? LIKE '%".. accountName .."%'", {type})
	if not players then return {} end
	for _, value in pairs(players) do
		local isOnline = QBCore.Functions.GetPlayerByCitizenId(value.citizenid)

		if isOnline then
			employees[#employees + 1] = {
			empSource = isOnline.PlayerData.citizenid,
			grade = isOnline.PlayerData[type].grade,
			isboss = isOnline.PlayerData[type].isboss,
			name = '🟢 ' .. isOnline.PlayerData.charinfo.firstname .. ' ' .. isOnline.PlayerData.charinfo.lastname
			}
		else
			employees[#employees + 1] = {
			empSource = value.citizenid,
			grade =  json.decode(value[type]).grade,
			isboss = json.decode(value[type]).isboss,
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
---@param data {cid: string, grade: integer, gradename: string}
---@param type 'job'|'gang'
function UpdateGrade(src, data, type)
	local player = QBCore.Functions.GetPlayer(src)
	local employee = QBCore.Functions.GetPlayerByCitizenId(data.cid)

	if not player.PlayerData[type].isboss then ExploitBan(src, 'GradeUpdate Exploiting') return end
	if data.grade > player.PlayerData[type].grade.level then TriggerClientEvent('QBCore:Notify', src, "You cannot promote to this rank!", "error") return end

	if not employee then
        TriggerClientEvent('QBCore:Notify', src, "Civilian is not in city.", "error")
        return
    end

    local success
    if type == 'gang' then
        success = employee.Functions.SetGang(player.PlayerData[type].name, data.grade)
    else
        success = employee.Functions.SetJob(player.PlayerData[type].name, data.grade)
    end

    if success then
        TriggerClientEvent('QBCore:Notify', src, "Successfully promoted!", "success")
        TriggerClientEvent('QBCore:Notify', employee.PlayerData.source, "You have been promoted to " ..data.gradename..".", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Grade does not exist.", "error")
    end
end

---@param src number
---@return table
function GetPlayers(src)
	local players = {}
	local playerPed = GetPlayerPed(src)
	local pCoords = GetEntityCoords(playerPed)
	for _, v in pairs(QBCore.Functions.GetPlayers()) do
		local targetped = GetPlayerPed(v)
		local tCoords = GetEntityCoords(targetped)
		local dist = #(pCoords - tCoords)
		if playerPed ~= targetped and dist < 10 then
			local ped = QBCore.Functions.GetPlayer(tonumber(v))
			players[#players + 1] = {
				id = v,
				coords = GetEntityCoords(targetped),
				name = ped.PlayerData.charinfo.firstname .. " " .. ped.PlayerData.charinfo.lastname,
				citizenid = ped.PlayerData.citizenid,
				sources = GetPlayerPed(ped.PlayerData.source),
				sourceplayer = ped.PlayerData.source
			}
		end
	end

	table.sort(players, function(a, b)
		return a.name < b.name
	end)

	return players
end

AddEventHandler('onServerResourceStart', function(resourceName)
	if resourceName ~= 'ox_inventory' and resourceName ~= GetCurrentResourceName() then return end

	local data = Config.UseTarget and Config.BossMenuZones or Config.BossMenus
	for k in pairs(data) do
		exports.ox_inventory:RegisterStash('boss_' .. k, "Stash: " .. k, 100, 4000000, false)
	end

	data = Config.UseTarget and Config.GangMenuZones or Config.GangMenus
	for k in pairs(data) do
		exports.ox_inventory:RegisterStash('gang_' .. k, "Stash: " .. k, 100, 4000000, false)
	end
end)
