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
	local player = exports.qbx_core:GetPlayer(src)
	local employee = exports.qbx_core:GetPlayerByCitizenId(target)

	if not player.PlayerData.gang.isboss then ExploitBan(src, 'FireEmployee Exploiting') return end

	if employee then
		if target ~= player.PlayerData.citizenid then
			if employee.PlayerData.gang.grade.level > player.PlayerData.gang.grade.level then exports.qbx_core:Notify(src, "You cannot fire this citizen!", "error") return end
			if employee.Functions.SetGang("none", '0') then
				TriggerEvent("qb-log:server:CreateLog", "gangmenu", "Gang Fire", "orange", player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname .. ' successfully fired ' .. employee.PlayerData.charinfo.firstname .. " " .. employee.PlayerData.charinfo.lastname .. " (" .. player.PlayerData.gang.name .. ")", false)
				exports.qbx_core:Notify(src, "Gang Member fired!", "success")
				exports.qbx_core:Notify(employee.PlayerData.source , "You have been expelled from the gang!", "error")
			else
				exports.qbx_core:Notify(src, "Error.", "error")
			end
		else
			exports.qbx_core:Notify(src, "You can\'t kick yourself out of the gang!", "error")
		end
	else
		local offlineEmployee = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {target})
		if offlineEmployee[1] then
			employee = offlineEmployee[1]
			employee.gang = json.decode(employee.gang)
			employee.charinfo = json.decode(employee.charinfo)
			if employee.gang.grade.level > player.PlayerData.gang.grade.level then exports.qbx_core:Notify(src, "You cannot fire this citizen!", "error") return end
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
			exports.qbx_core:Notify(src, "Gang member fired!", "success")
			TriggerEvent("qb-log:server:CreateLog", "gangmenu", "Gang Fire", "orange", player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname .. ' successfully fired ' .. employee.PlayerData.charinfo.firstname .. " " .. employee.PlayerData.charinfo.lastname .. " (" .. player.PlayerData.gang.name .. ")", false)
		else
			exports.qbx_core:Notify(src, "Civilian is not in city.", "error")
		end
	end
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

-- Recruit Player
RegisterNetEvent('qb-gangmenu:server:HireMember', function(recruit)
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local target = exports.qbx_core:GetPlayer(recruit)

	if not player.PlayerData.gang.isboss then ExploitBan(src, 'HireEmployee Exploiting') return end

	if target and target.Functions.SetGang(player.PlayerData.gang.name, 0) then
		exports.qbx_core:Notify(src, "You hired " .. (target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname) .. " come " .. player.PlayerData.gang.label .. "", "success")
		exports.qbx_core:Notify(target.PlayerData.source , "You have been hired as " .. player.PlayerData.gang.label .. "", "success")
		TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Recruit', 'yellow', (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname).. ' successfully recruited ' .. target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname .. ' (' .. player.PlayerData.gang.name .. ')', false)
	end
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)