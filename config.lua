Config = Config or {}

-- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true'

Config.PolyDebug = false

Config.BossMenus = {
    police = {
        vec3(448.22, -973.22, 30.69),
    },
    ambulance = {
        vec3(337.21, -592.92, 43.29),
    },
    realestate = {
        vec3(-716.11, 261.21, 84.14),
    },
    taxi = {
        vec3(894.94, -179.27, 74.7),
    },
    cardealer = {
        vec3(-27.47, -1107.13, 27.27),
    },
    mechanic = {
        vec3(-347.49, -133.32, 39.01),
    },
}

Config.BossMenuZones = {
    police = {
        { coords = vec3(447.04, -974.01, 30.44), size = vec3(0.5, 0.25, 0.4), rotation = 183.03 },
    },
    ambulance = {
        { coords = vec3(337.06, -592.88, 43.29), size = vec3(1.5, 1.5, 2.5), rotation = 155.05 },
    },
    realestate = {
        { coords = vec3(-716.11, 261.21, 84.14), size = vec3(0.0, 0.0, 0.0), rotation = 0.00 },
    },
    taxi = {
        { coords = vec3(894.94, -179.27, 74.70), size = vec3(1.5, 1.5, 2.5), rotation = 56.89 },
    },
    cardealer = {
        { coords = vec3(-30.12, -1106.30, 26.23), size = vec3(0.5, 0.25, 0.4), rotation = 321.99 },
    },
    mechanic = {
        { coords = vec3(-347.49, -133.32, 39.01), size = vec3(1.5, 1.5, 2.5), rotation = 73.32 },
    },
}

Config.GangMenus = {
    lostmc = {
        vector3(983.69, -90.92, 74.85)
    },
}

Config.GangMenuZones = {
    lostmc = {
        { coords = vector3(983.69, -90.92, 74.85), size = vec3(1.5, 1.5, 2.5), rotation = 39.68 },
    },
}

Config.GangStashes = {
    lostmc = {
        { coords = vector3(972.39, -97.98, 74.87), size = vec3(3.5, 0.8, 2.0), rotation = 44.55 }
    },
}