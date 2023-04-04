local QBCore = exports['qbx-core']:GetCoreObject()

function ExploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(id),
        QBCore.Functions.GetIdentifier(id, 'license'),
        QBCore.Functions.GetIdentifier(id, 'discord'),
        QBCore.Functions.GetIdentifier(id, 'ip'),
        reason,
        2147483647,
        'qb-management'
    })

    TriggerEvent('qb-log:server:CreateLog', 'bans', "Player Banned", 'red', string.format("%s was banned by %s for %s", GetPlayerName(id), 'qb-management', reason), true)

    DropPlayer(id, "You were permanently banned by the server for: Exploiting")
end
