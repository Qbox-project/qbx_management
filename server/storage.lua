local config = require 'config.server'

MySQL.query('DELETE FROM `player_jobs_activity` WHERE `last_checkout` < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 31 DAY)) OR `last_checkout` IS NULL')

function OnPlayerCheckOut(clockInPayload)
    local checkOutTime = os.time()
    local checkInTime = clockInPayload.time
    if (checkOutTime - checkInTime) / 60 < config.minOnDutyLogTimeMinutes then
        return
    end

    MySQL.insert("INSERT INTO `player_jobs_activity` (`citizenid`, `job`, `last_checkin`, `last_checkout`) VALUES (?, ?, ?, ?)", {
        clockInPayload.citizenid,
        clockInPayload.job,
        checkInTime,
        checkOutTime,
    })
end

---@param citizenid string
---@param job string
---@return table?
function GetPlayerActivityData(citizenid, job)
	local result = MySQL.single.await('SELECT `last_checkin`, sum(last_checkout-last_checkin) as `seconds` FROM `player_jobs_activity` WHERE `citizenid` = ? AND `job` = ? GROUP BY `citizenid`', { citizenid, job })
	return result and { hours = string.format("%.2f", tonumber(result.seconds)/3600), last_checkin = os.date(config.formatDateTime, result.last_checkin) } or { hours = 0, last_checkin = 'N/A' }
end