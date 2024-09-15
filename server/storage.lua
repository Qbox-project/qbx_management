local config = require 'config.server'

MySQL.query('DELETE FROM `player_jobs_activity` WHERE `last_checkout` < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 31 DAY)) OR `last_checkout` IS NULL')

---Fast implementation for tracking activity hours for now, might need runtime tracking and storing once per day instead per onduty.
---@param citizenid string
---@param job string
function onPlayerCheckIn(citizenid, job)
	MySQL.insert("INSERT INTO `player_jobs_activity` (`citizenid`, `job`, `last_checkin`) VALUES (?, ?, ?)", { citizenid, job, os.time() })
end

---@param citizenid string
---@param job string
function onPlayerCheckOut(citizenid, job)
	MySQL.update('UPDATE `player_jobs_activity` SET `last_checkout` = ? WHERE `citizenid` = ? AND `last_checkout` IS NULL AND `job` = ? ORDER BY `id` DESC LIMIT 1', { os.time(), citizenid, job })
end

---@param citizenid string
---@param job string
---@return table?
function getPlayerActivityData(citizenid, job)
	local result = MySQL.single.await('SELECT `last_checkin`, sum(last_checkout-last_checkin) as `seconds` FROM `player_jobs_activity` WHERE `citizenid` = ? AND `job` = ? GROUP BY `citizenid`', { citizenid, job })
	return result and { hours = string.format("%.2f", tonumber(result.seconds)/3600), last_checkin = os.date(config.formatDateTime, result.last_checkin) } or { hours = 0, last_checkin = 'N/A' }
end