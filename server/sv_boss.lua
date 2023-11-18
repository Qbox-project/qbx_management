local jobs = exports.qbx_core:GetJobs()

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
	local player = exports.qbx_core:GetPlayer(src)
	local employee = exports.qbx_core:GetPlayerByCitizenId(target)

	if not player.PlayerData.job.isboss then ExploitBan(src, 'FireEmployee Exploiting') return end

	if employee then
		if target ~= player.PlayerData.citizenid then
			if employee.PlayerData.job.grade.level > player.PlayerData.job.grade.level then exports.qbx_core:Notify(src, "You cannot fire this citizen!", "error") return end
			if employee.Functions.SetJob("unemployed", 0) then
				TriggerEvent("qb-log:server:CreateLog", "bossmenu", "Job Fire", "red", player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname .. ' successfully fired ' .. employee.PlayerData.charinfo.firstname .. " " .. employee.PlayerData.charinfo.lastname .. " (" .. player.PlayerData.job.name .. ")", false)
				exports.qbx_core:Notify(src, "Employee fired!", "success")
				exports.qbx_core:Notify(employee.PlayerData.source , "You have been fired! Good luck.", "error")
			else
				exports.qbx_core:Notify(src, "Error..", "error")
			end
		else
			exports.qbx_core:Notify(src, "You can\'t fire yourself", "error")
		end
	else
		local offlineEmployee = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { target })
		if offlineEmployee[1] then
			employee = offlineEmployee[1]
			employee.job = json.decode(employee.job)
			employee.charinfo = json.decode(employee.charinfo)
			if employee.job.grade.level > player.PlayerData.job.grade.level then exports.qbx_core:Notify(src, "You cannot fire this citizen!", "error") return end
			local job = {}
			job.name = "unemployed"
			job.label = "Civilian"
			job.payment = jobs[job.name].grades[0].payment or 500
			job.onduty = true
			job.isboss = false
			job.grade = {}
			job.grade.name = nil
			job.grade.level = 0
			MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(job), target })
			exports.qbx_core:Notify(src, "Employee fired!", "success")
			TriggerEvent("qb-log:server:CreateLog", "bossmenu", "Job Fire", "red", player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname .. ' successfully fired ' .. employee.charinfo.firstname .. " " .. employee.charinfo.lastname .. " (" .. player.PlayerData.job.name .. ")", false)
		else
			exports.qbx_core:Notify(src, "Civilian not in city.", "error")
		end
	end
	TriggerClientEvent('qb-bossmenu:client:OpenMenu', src)
end)

-- Recruit Player
RegisterNetEvent('qb-bossmenu:server:HireEmployee', function(recruit)
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local target = exports.qbx_core:GetPlayer(recruit)

	if not player.PlayerData.job.isboss then ExploitBan(src, 'HireEmployee Exploiting') return end

	if target and target.Functions.SetJob(player.PlayerData.job.name, 0) then
		exports.qbx_core:Notify(src, "You hired " .. (target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname) .. " come " .. player.PlayerData.job.label .. "", "success")
		exports.qbx_core:Notify(target.PlayerData.source , "You were hired as " .. player.PlayerData.job.label .. "", "success")
		TriggerEvent('qb-log:server:CreateLog', 'bossmenu', 'Recruit', "lightgreen", (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname).. " successfully recruited " .. (target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname) .. ' (' .. player.PlayerData.job.name .. ')', false)
	end
	TriggerClientEvent('qb-bossmenu:client:OpenMenu', src)
end)
