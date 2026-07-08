Config = {}


--[[ Pawn Shop Coordinates & Ped model. To create a new location, add 

    {
        coords = vec3(412.35, 314.62, 103.02), -- Location of pawn shop NPC
        heading = 250.0, -- Way the NPC is facing
        ped = 's_m_m_highsec_01' -- NPC Model
    },
    
    to the top of Config.PawnShop, under the add here comment. If the NPC is facing the wall, change the "heading".]]

Config.PawnShop = {
    -- Add new location here
    
    {
        coords = vec3(412.35, 314.62, 103.02), -- Location of pawn shop NPC
        heading = 250.0, -- Way the NPC is facing
        ped = 's_m_m_highsec_01' -- NPC Model
    },

    {
        coords = vec3(182.30, -1319.37, 29.32),
        heading = 250.0,
        ped = 's_m_m_highsec_01'
    },

    {
        coords = vec3(1655.19, 4874.50, 42.04),
        heading = 250.0,
        ped = 's_m_m_highsec_01'
    },

    {
        coords = vec3(-265.82, 236.72, 90.57),
        heading = 250.0,
        ped = 's_m_m_highsec_01'
    },

    {
        coords = vec3(1160.13, 2701.66, 38.18),
        heading = 250.0,
        ped = 's_m_m_highsec_01'
    },

    {
        coords = vec3(-782.35, -608.94, 30.28),
        heading = 250.0,
        ped = 's_m_m_highsec_01'
    },

    {
        coords = vec3(1930.16, 3721.54, 32.82),
        heading = 250.0,
        ped = 's_m_m_highsec_01'
    },

    {
        coords = vec3(-1459.49, -413.65, 35.75),
        heading = 90.0, -- adjust this so the ped faces correctly
        ped = 's_m_m_highsec_01'
    }
}


--[[ Items you can sell to the Pawn shop. To add a new item, copy 

gold_ring = { label = 'Gold Chain', price = 100 },

and replace "gold_ring" with your item name, label "Gold Ring" with the item name, and the price with the sell price.]] 

Config.Items = {

    gold_ring = { label = 'Gold Ring', price = 100 },
    gold_earring = { label = 'Gold Earrings', price = 200 },
    goldchain = { label = 'Gold Chain', price = 250 },
    attano_watch = { label = 'Italian Attano Watch', price = 600 },

    emerald_earring = { label = 'Emerald Earrings', price = 400 },
    diamond_earring = { label = 'Diamond Earrings', price = 600 },
    sapphire_earring = { label = 'Sapphire Earrings', price = 450 },
    

    emerald_ring = { label = 'Emerald Ring', price = 425 },
    sapphire_ring = { label = 'Sapphire Ring', price = 500 },
    diamond_ring = { label = 'Diamond Ring', price = 600 },

    goldbar = { label = 'Gold Bar', price = 600 },
    diamond = { label = 'Diamond', price = 300 },

    metal_sheets = { label = 'Metal Sheets', price = 120 },
    metal_scrap = { label = 'Metal Scrap', price = 60 },
    copper_wires = { label = 'Copper Wires', price = 150 },
    fabric = { label = 'Fabric', price = 35 },

    copper = { label = 'Copper', price = 100 }

}

-- Blip on the Map
Config.Blip = {
    enabled = true, -- True for on, false for off
    sprite = 605, -- Blip ID, Find new IDs on google.
    colour = 2, -- Color of the blip
    scale = 0.8, -- How large the blip is
    label = 'Pawn Shop' -- name of the blip on the map
}
