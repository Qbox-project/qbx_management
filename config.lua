Config = Config or {}

-- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true'

Config.BossMenus = {
    ['police'] = {
        vec3(461.45, -986.2, 30.73),
    },
    ['ambulance'] = {
        vec3(335.46, -594.52, 43.28),
    },
    ['realestate'] = {
        vec3(-716.11, 261.21, 84.14),
    },
    ['taxi'] = {
        vec3(907.24, -150.19, 74.17),
    },
    ['cardealer'] = {
        vec3(-27.47, -1107.13, 27.27),
    },
    ['mechanic'] = {
        vec3(-339.53, -156.44, 44.59),
    },
}

Config.BossMenuZones = {
    ['police'] = {
        { coords = vec3(461.45, -986.2, 30.73), length = 0.35, width = 0.45, heading = 351.0, minZ = 30.58, maxZ = 30.68 },
    },
    ['ambulance'] = {
        { coords = vec3(335.46, -594.52, 43.28), length = 1.2, width = 0.6, heading = 341.0, minZ = 43.13, maxZ = 43.73 },
    },
    ['realestate'] = {
        { coords = vec3(-716.11, 261.21, 84.14), length = 0.6, width = 1.0, heading = 25.0, minZ = 83.943, maxZ = 84.74 },
    },
    ['taxi'] = {
        { coords = vec3(907.24, -150.19, 74.17), length = 1.0, width = 3.4, heading = 327.0, minZ = 73.17, maxZ = 74.57 },
    },
    ['cardealer'] = {
        { coords = vec3(-27.47, -1107.13, 27.27), length = 2.4, width = 1.05, heading = 340.0, minZ = 27.07, maxZ = 27.67 },
    },
    ['mechanic'] = {
        { coords = vec3(-339.53, -156.44, 44.59), length = 1.15, width = 2.6, heading = 353.0, minZ = 43.59, maxZ = 44.99 },
    },
}

Config.GangMenus = {
    ['lostmc'] = {
        vec3(-341.58, -124.23, 39.01)
    },
}

Config.GangMenuZones = {
    ['lostmc'] = {
        { coords = vec3(0.0, 0.0, 0.0), length = 0.0, width = 0.0, heading = 0.0, minZ = 0.0, maxZ = 0.0 },
    },
}
