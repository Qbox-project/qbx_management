return {
    discordWebhook = nil, -- Replace nil with your webhook if you chose to use discord logging over ox_lib logging

    -- While the config boss menu creation still works, it is recommended to use the runtime export instead.
    ---@alias GroupName string

    ---@class ZoneInfo
    ---@field coords vec3 coordinates of the zone
    ---@field size vec3 size of the zone
    ---@field rotation number rotation of the zone
    ---@field type GroupType

    ---@type table<GroupName, ZoneInfo>
    menus = {
        lostmc = {
            coords = vec3(983.69, -90.92, 74.85),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'gang',
        },
        vagos = {
            coords = vec3(351.18, -2054.92, 22.09),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'gang',
        },
    },
}