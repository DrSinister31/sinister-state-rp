return {
    debug = (GetConvar('citRa:debug', 'false') == 'true'), -- Use the convar to change this
    models = { -- In order of growth stage. The script will auto-calculate when to move to the next stage.
        'bkr_prop_weed_01_small_01b',
        'bkr_prop_weed_med_01a',
        'bkr_prop_weed_med_01b',
        'bkr_prop_weed_lrg_01a',
        'bkr_prop_weed_lrg_01b',
    },
    seedsPerMalePlant = {3, 8}, -- Will receive between X & Y female seeds from a male plant
    growTime = 7200, -- In secs
    dryTime = 600, -- In secs
    foodUse = 65, -- Percentage of food used for entire grow
    waterUse = 75, -- Percentage of water used for entire grow
    healthyPercentage = 50, -- Plants above this will continue to grow
    bagsPerPlant = 60, -- Max bags per plant (at 100% health)
    seedChance = 0.2, -- Chance of finding a seed while packaging

    -- Item config
    potItem = 'plant_tub',
    branchItem = 'weedplant_branch',
    lighterItem = 'lighter',
    waterItem = 'waterbottle',
    foodItem = 'weed_nutrition',
    rackItem = 'weedplant_rack',
    seedItems = {
        male = 'weedplant_seedm',
        female = 'weedplant_seedf',
    },
    baggyItem = 'empty_weed_bag',
    packagedItem = 'weedplant_weed',
}
