---@alias GroupType 'gang' | 'job'

---@param name string
---@param type GroupType
---@return {citizenid: string, grade: integer}[]
function FetchPlayersInGroup(name, type)
    return MySQL.query.await("SELECT citizenid, grade FROM player_groups WHERE `group` = ? AND `type` = ?", {name, type})
end