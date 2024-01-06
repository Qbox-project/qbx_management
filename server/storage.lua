---@alias GroupType 'gang' | 'job'

---Fetches DB Player Entities by Group
---@param name string
---@param type GroupType
---@return table[]
function FetchPlayerEntitiesByGroup(name, type)
    local chars = {}
    local result = MySQL.query.await("SELECT citizenid, charinfo, gang, job FROM `players` WHERE JSON_VALUE("..type..", '$.name') = ?", {name})
    for i = 1, #result do
        chars[i] = result[i]
        chars[i].charinfo = json.decode(result[i].charinfo)
        chars[i].job = result[i].job and json.decode(result[i].job)
        chars[i].gang = result[i].gang and json.decode(result[i].gang)
    end

    return chars
end

---Fetches DB Player Entity by CitizenId
---@param citizenId string
---@return table[]
function FetchPlayerEntityByCitizenId(citizenId)
    return MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', {citizenId})
end

---Updates DB Player Entity
---@param citizenId string
---@param type GroupType
---@param role Gang | Job
---@return table[]
function UpdatePlayerJob(citizenId, type, role)
    return MySQL.update.await('UPDATE players SET '..type..' = ? WHERE citizenid = ?', {json.encode(role), citizenId})
end