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