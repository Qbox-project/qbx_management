---@alias GroupType 'gang' | 'job'

---Fetches DB Player Entities by Group
---@param name string
---@param type GroupType
---@return table[]
function FetchPlayerEntitiesByGroup(name, type)
    local chars = {}
    local result = MySQL.query.await("SELECT citizenid, grade FROM player_groups WHERE `group` = ? AND `type` = ?", {name, type})
    for i = 1, #result do
        chars[i] = result[i]
        chars[i].charinfo = json.decode(result[i].charinfo)
    end

    return chars
end