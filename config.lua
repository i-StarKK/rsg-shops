Config = {}

Config.ShopkeeperSettings = {
    enableRespawn = true,
    respawnTime = 300,
    interactionDistance = 2.5,
    debugMode = true,
}

Config.ShopkeeperModels = {
    general = "player_zero",
}

Config.ShopkeeperAnimations = {
    "WORLD_HUMAN_STAND_WAITING",
    "WORLD_HUMAN_STAND_IMPATIENT",
    "WORLD_HUMAN_STAND_MOBILE",
    "WORLD_HUMAN_STAND_IMPATIENT_FACILITY",
    "WORLD_HUMAN_STAND_WAITING_FACILITY",
    "WORLD_HUMAN_STAND_MOBILE_FACILITY"
}

Config.Shops = {
    {
        name = "Valentine General Store",
        coords = vector4(-323.96, 803.45, 117.88, 277.69),
        pedCoords = vector4(-323.96, 803.45, 117.88, 277.69),
        pedModel = Config.ShopkeeperModels.general,
        items = {
            { name = "bread", label = "Bread", price = 2, image = "consumable_bread_roll.png" },
            { name = "water", label = "Water", price = 1, image = "consumable_water_filtered.png" },
            { name = "bandage", label = "Bandage", price = 3, image = "bandage.png" }
        }
    },
    {
        name = "Saint Denis General Store",
        coords = vector4(2639.76, -1224.53, 53.38, 91.06),
        pedCoords = vector4(2639.76, -1224.53, 53.38, 91.06),
        pedModel = Config.ShopkeeperModels.general,
        items = {
            { name = "bread", label = "Bread", price = 2, image = "consumable_bread_roll.png" },
            { name = "water", label = "Water", price = 1, image = "consumable_water_filtered.png" },
            { name = "bandage", label = "Bandage", price = 3, image = "bandage.png" }
        }
    },
    {
        name = "Rhodes General Store",
        coords = vector4(1329.73, -1294.24, 77.02, 66.23),
        pedCoords = vector4(1329.73, -1294.24, 77.02, 66.23),
        pedModel = Config.ShopkeeperModels.general,
        items = {
            { name = "bread", label = "Bread", price = 2, image = "consumable_bread_roll.png" },
            { name = "water", label = "Water", price = 1, image = "consumable_water_filtered.png" },
            { name = "bandage", label = "Bandage", price = 3, image = "bandage.png" }
        }
    },
    {
        name = "Black Water General Store",
        coords = vector4(-786.05, -1322.17, 43.88, 181.78),
        pedCoords = vector4(-786.05, -1322.17, 43.88, 181.78),
        pedModel = Config.ShopkeeperModels.general,
        items = {
            { name = "bread", label = "Bread", price = 2, image = "consumable_bread_roll.png" },
            { name = "water", label = "Water", price = 1, image = "consumable_water_filtered.png" },
            { name = "bandage", label = "Bandage", price = 3, image = "bandage.png" }
        }
    },
    {
        name = "Armadillo General Store",
        coords = vector4(-3687.35, -2623.49, -13.43, 267.52),
        pedCoords = vector4(-3687.35, -2623.49, -13.43, 267.52),
        pedModel = Config.ShopkeeperModels.general,
        items = {
            { name = "bread", label = "Bread", price = 2, image = "consumable_bread_roll.png" },
            { name = "water", label = "Water", price = 1, image = "consumable_water_filtered.png" },
            { name = "bandage", label = "Bandage", price = 3, image = "bandage.png" }
        }
    },
    {
        name = "Tumbleweed General Store",
        coords = vector4(-5485.88, -2937.96, -0.4, 123.15),
        pedCoords = vector4(-5485.88, -2937.96, -0.4, 123.15),
        pedModel = Config.ShopkeeperModels.general,
        items = {
            { name = "bread", label = "Bread", price = 2, image = "consumable_bread_roll.png" },
            { name = "water", label = "Water", price = 1, image = "consumable_water_filtered.png" },
            { name = "bandage", label = "Bandage", price = 3, image = "bandage.png" }
        }
    },
    {
        name = "Strawberry General Store",
        coords = vector4(-1789.65, -388.01, 160.33, 54.94),
        pedCoords = vector4(-1789.65, -388.01, 160.33, 54.94),
        pedModel = Config.ShopkeeperModels.general,
        items = {
            { name = "bread", label = "Bread", price = 2, image = "consumable_bread_roll.png" },
            { name = "water", label = "Water", price = 1, image = "consumable_water_filtered.png" },
            { name = "bandage", label = "Bandage", price = 3, image = "bandage.png" }
        }
    },
    {
        name = "Annesburg General Store",
        coords = vector4(2931.17, 1365.88, 45.2, 253.41),
        pedCoords = vector4(2931.17, 1365.88, 45.2, 253.41),
        pedModel = Config.ShopkeeperModels.general,
        items = {
            { name = "bread", label = "Bread", price = 2, image = "consumable_bread_roll.png" },
            { name = "water", label = "Water", price = 1, image = "consumable_water_filtered.png" },
            { name = "bandage", label = "Bandage", price = 3, image = "bandage.png" }
        }
    }
}


Config.PaymentMethods = {
    {name = "cash", label = "Cash"},
    {name = "bank", label = "Bank"}
}