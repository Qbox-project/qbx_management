local function AddGangMoney(account, amount)
	AddMoney(account, amount)
end

exports('AddGangMoney', AddGangMoney)

local function RemoveGangMoney(account, amount)
	return RemoveMoney(account, amount)
end

exports('RemoveGangMoney', RemoveGangMoney)

RegisterNetEvent("qb-gangmenu:server:withdrawMoney", function(amount)
	local src = source
	local success, player, account = WithdrawMoney(src, amount, 'gang', 'gang', 'Gang menu withdraw')
	if not success then return end
	
	TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Withdraw Money', 'yellow', player?.PlayerData.charinfo.firstname .. ' ' .. player?.PlayerData.charinfo.lastname .. ' successfully withdrew $' .. amount .. ' (' .. account .. ')', false)
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

RegisterNetEvent("qb-gangmenu:server:depositMoney", function(amount)
	local src = source
	local success, player, account = DepositMoney(src, amount, 'gang', 'gang')
	if not success then return end

	TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Deposit Money', 'yellow', player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. account .. ')', false)
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

lib.callback.register('qb-gangmenu:server:GetAccount', function(_, gangName)
	return GetAccount(gangName)
end)

-- Get Employees
lib.callback.register('qb-gangmenu:server:GetEmployees', function(source, gangname)
	local src = source
	return GetEmployees(src, gangname, 'gang')
end)

-- Grade Change
RegisterNetEvent('qb-gangmenu:server:GradeUpdate', function(data)
	local src = source
	UpdateGrade(src, data, 'gang')
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

-- Fire Member
RegisterNetEvent('qb-gangmenu:server:FireMember', function(target)
	local src = source
	local Player = exports.qbx_core:GetPlayer(src)
	local Employee = exports.qbx_core:GetPlayerByCitizenId(target)

	if not Player.PlayerData.gang.isboss then ExploitBan(src, 'FireEmployee Exploiting') return end

	if Employee then
		if target ~= Player.PlayerData.citizenid then
			if Employee.PlayerData.gang.grade.level > Player.PlayerData.gang.grade.level then TriggerClientEvent('QBCore:Notify', src, "You cannot fire this citizen!", "error") return end
			if Employee.Functions.SetGang("none", '0') then
				TriggerEvent("qb-log:server:CreateLog", "gangmenu", "Gang Fire", "orange", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.gang.name .. ")", false)
				TriggerClientEvent('QBCore:Notify', src, "Gang Member fired!", "success")
				TriggerClientEvent('QBCore:Notify', Employee.PlayerData.source , "You have been expelled from the gang!", "error")
			else
				TriggerClientEvent('QBCore:Notify', src, "Error.", "error")
			end
		else
			TriggerClientEvent('QBCore:Notify', src, "You can\'t kick yourself out of the gang!", "error")
		end
	else
		local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {target})
		if player[1] then
			Employee = player[1]
			Employee.gang = json.decode(Employee.gang)
			if Employee.gang.grade.level > Player.PlayerData.gang.grade.level then TriggerClientEvent('QBCore:Notify', src, "You cannot fire this citizen!", "error") return end
			local gang = {}
			gang.name = "none"
			gang.label = "No Affiliation"
			gang.payment = 0
			gang.onduty = true
			gang.isboss = false
			gang.grade = {}
			gang.grade.name = nil
			gang.grade.level = 0
			MySQL.update('UPDATE players SET gang = ? WHERE citizenid = ?', {json.encode(gang), target})
			TriggerClientEvent('QBCore:Notify', src, "Gang member fired!", "success")
			TriggerEvent("qb-log:server:CreateLog", "gangmenu", "Gang Fire", "orange", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.gang.name .. ")", false)
		else
			TriggerClientEvent('QBCore:Notify', src, "Civilian is not in city.", "error")
		end
	end
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

-- Recruit Player
RegisterNetEvent('qb-gangmenu:server:HireMember', function(recruit)
	local src = source
	local Player = exports.qbx_core:GetPlayer(src)
	local Target = exports.qbx_core:GetPlayer(recruit)

	if not Player.PlayerData.gang.isboss then ExploitBan(src, 'HireEmployee Exploiting') return end

	if Target and Target.Functions.SetGang(Player.PlayerData.gang.name, 0) then
		TriggerClientEvent('QBCore:Notify', src, "You hired " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. " come " .. Player.PlayerData.gang.label .. "", "success")
		TriggerClientEvent('QBCore:Notify', Target.PlayerData.source , "You have been hired as " .. Player.PlayerData.gang.label .. "", "success")
		TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Recruit', 'yellow', (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname).. ' successfully recruited ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' (' .. Player.PlayerData.gang.name .. ')', false)
	end
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

-- Get closest player sv
lib.callback.register('qb-gangmenu:getplayers', function(source)
	local src = source
	return GetPlayers(src)
end)
