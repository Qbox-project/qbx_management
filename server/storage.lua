---@param groupName string
---@param group string
---@return Players[]
function FetchPlayersByGroup(groupName, group)
    return MySQL.query.await("SELECT * FROM `players` WHERE ?? LIKE '%"..groupName.."%'", {group})
end

---@param citizenId string
---@return Player[]
function FetchPlayerByCitizenId(citizenId)
    return MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {citizenId})
end

---@param column string
---@param role string
---@param citizenId string
---@return Player[]
function UpdatePlayerJob(column, role, citizenId)
    return MySQL.update.await('UPDATE players SET '..column..' = ? WHERE citizenid = ?', {role, citizenId})
end