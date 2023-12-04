---@param groupName string
---@param group string
---@return Players[]
function FetchPlayerEntitiesByGroup(groupName, group)
    return MySQL.query.await("SELECT * FROM `players` WHERE ?? LIKE '%"..groupName.."%'", {group})
end

---@param citizenId string
---@return Player[]
function FetchPlayerEntityByCitizenId(citizenId)
    return MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {citizenId})
end
---@param citizenId string
---@param column gang | job
---@param role string
---@return Player[]
function UpdatePlayerJob(citizenId, column, role)
    return MySQL.update.await('UPDATE players SET '..column..' = ? WHERE citizenid = ?', {json.encode(role), citizenId})
end