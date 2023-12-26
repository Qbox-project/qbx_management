return {
    discordWebhook = nil, -- Replace nil with your webhook if you chose to use discord logging over ox_lib logging

    -- While the config boss menu creation still works, it is recommended to use the runtime export instead.
    menus = {
        lostmc = {
            coords = vec3(983.69, -90.92, 74.85),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'gang',
            stashSlots = 100,
            stashWeight = 4000000,
        },
        vagos = {
            coords = vec3(351.18, -2054.92, 22.09),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'gang',
            slots = 100,
            weight = 4000000,
        },
    },
}