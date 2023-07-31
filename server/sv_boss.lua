local function addMoney(account, amount)
	AddMoney(account, amount)
end

exports('AddMoney', addMoney)

local function removeMoney(account, amount)
	return RemoveMoney(account, amount)
end

exports('RemoveMoney', removeMoney)

RegisterNetEvent("qb-bossmenu:server:withdrawMoney", function(amount)
	local src = source
	local success, player, account = WithdrawMoney(src, amount, 'job', 'boss', 'Boss menu withdraw')
	if not success then return end

	TriggerEvent('qb-log:server:CreateLog', 'bossmenu', 'Withdraw Money', "blue", player?.PlayerData.name.. "Withdrawal $" .. amount .. ' (' .. account .. ')', false)
	TriggerClientEvent('qb-bossmenu:client:OpenMenu', src)
end)

RegisterNetEvent("qb-bossmenu:server:depositMoney", function(amount)
	local src = source
	local success, player, account = DepositMoney(src, amount, 'job', 'boss')
	if not success then return end

	TriggerEvent('qb-log:server:CreateLog', 'bossmenu', 'Deposit Money', "blue", player?.PlayerData.name.. "Deposit $" .. amount .. ' (' .. account .. ')', false)
	TriggerClientEvent('qb-bossmenu:client:OpenMenu', src)
end)

lib.callback.register('qb-bossmenu:server:GetAccount', function(_, jobName)
	return GetAccount(jobName)
end)

-- Get Employees
lib.callback.register('qb-bossmenu:server:GetEmployees', function(source, jobname)
	local src = source
	return GetEmployees(src, jobname, 'job')
end)

-- Grade Change
RegisterNetEvent('qb-bossmenu:server:GradeUpdate', function(data)
	local src = source
	UpdateGrade(src, data, 'job')
	TriggerClientEvent('qb-bossmenu:client:OpenMenu', src)
end)

-- Fire Employee
RegisterNetEvent('qb-bossmenu:server:FireEmployee', function(target)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Employee = QBCore.Functions.GetPlayerByCitizenId(target)

	if not Player.PlayerData.job.isboss then ExploitBan(src, 'FireEmployee Exploiting') return end

	if Employee then
		if target ~= Player.PlayerData.citizenid then
			if Employee.PlayerData.job.grade.level > Player.PlayerData.job.grade.level then TriggerClientEvent('QBCore:Notify', src, "You cannot fire this citizen!", "error") return end
			if Employee.Functions.SetJob("unemployed", 0) then
				TriggerEvent("qb-log:server:CreateLog", "bossmenu", "Job Fire", "red", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.job.name .. ")", false)
				TriggerClientEvent('QBCore:Notify', src, "Employee fired!", "success")
				TriggerClientEvent('QBCore:Notify', Employee.PlayerData.source , "You have been fired! Good luck.", "error")
			else
				TriggerClientEvent('QBCore:Notify', src, "Error..", "error")
			end
		else
			TriggerClientEvent('QBCore:Notify', src, "You can\'t fire yourself", "error")
		end
	else
		local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { target })
		if player[1] then
			Employee = player[1]
			Employee.job = json.decode(Employee.job)
			if Employee.job.grade.level > Player.PlayerData.job.grade.level then TriggerClientEvent('QBCore:Notify', src, "You cannot fire this citizen!", "error") return end
			local job = {}
			job.name = "unemployed"
			job.label = "Unemployed"
			job.payment = QBCore.Shared.Jobs[job.name].grades['0'].payment or 500
			job.onduty = true
			job.isboss = false
			job.grade = {}
			job.grade.name = nil
			job.grade.level = 0
			MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(job), target })
			TriggerClientEvent('QBCore:Notify', src, "Employee fired!", "success")
			TriggerEvent("qb-log:server:CreateLog", "bossmenu", "Job Fire", "red", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.job.name .. ")", false)
		else
			TriggerClientEvent('QBCore:Notify', src, "Civilian not in city.", "error")
		end
	end
	TriggerClientEvent('qb-bossmenu:client:OpenMenu', src)
end)

-- Recruit Player
RegisterNetEvent('qb-bossmenu:server:HireEmployee', function(recruit)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Target = QBCore.Functions.GetPlayer(recruit)

	if not Player.PlayerData.job.isboss then ExploitBan(src, 'HireEmployee Exploiting') return end

	if Target and Target.Functions.SetJob(Player.PlayerData.job.name, 0) then
		TriggerClientEvent('QBCore:Notify', src, "You hired " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. " come " .. Player.PlayerData.job.label .. "", "success")
		TriggerClientEvent('QBCore:Notify', Target.PlayerData.source , "You were hired as " .. Player.PlayerData.job.label .. "", "success")
		TriggerEvent('qb-log:server:CreateLog', 'bossmenu', 'Recruit', "lightgreen", (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname).. " successfully recruited " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' (' .. Player.PlayerData.job.name .. ')', false)
	end
	TriggerClientEvent('qb-bossmenu:client:OpenMenu', src)
end)

-- Get closest player sv
lib.callback.register('qb-bossmenu:getplayers', function(source)
	local src = source
	return GetPlayers(src)
end)
