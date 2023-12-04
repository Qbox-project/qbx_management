---@param name string
---@param type string
---@return Players[]
function FetchPlayerEntitiesByGroup(name, type)
    return MySQL.query.await("SELECT * FROM `players` WHERE ?? LIKE '%"..name.."%'", {type})
end

---@param citizenId string
---@return Player[]
function FetchPlayerEntityByCitizenId(citizenId)
    return MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {citizenId})
end
---@param citizenId string
---@param type gang | job
---@param role Gang | Job
---@return Player[]
function UpdatePlayerJob(citizenId, type, role)
    return MySQL.update.await('UPDATE players SET '..type..' = ? WHERE citizenid = ?', {json.encode(role), citizenId})
end