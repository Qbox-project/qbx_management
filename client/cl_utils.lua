function comma_value(amount)
    local numChanged

    repeat
        amount, numChanged = string.gsub(amount, '^(-?%d+)(%d%d%d)', '%1,%2')
    until numChanged == 0

    return amount
end

---@return table
function FindPlayers()
	local playerCoords = GetEntityCoords(cache.ped)
    local closePlayers = {}
    for _, v in pairs(GetPlayersFromCoords(playerCoords, 10)) do
        closePlayers[#closePlayers+1] = GetPlayerServerId(v)
    end
	return lib.callback.await('qb-bossmenu:getplayers', false, closePlayers)
end

