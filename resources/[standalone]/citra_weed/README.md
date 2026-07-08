## citra_weed - A weed planting, harvesting, & processing system for FiveM
This resources provides a system that allows players to plant, harvest, and process weed on your FiveM server.

![Preview](https://share.citra.live/i/mlgg5.png)

<details>
<summary>Screenshots</summary>

![Items](https://share.citra.live/i/0bpg9.png)

![Male Plant](https://share.citra.live/i/gm0d5.png)

![Female Plant](https://share.citra.live/i/sw0ns.png)

![Fully Grown](https://share.citra.live/i/fb8sh.png)

![Harvest](https://share.citra.live/i/es8ps.png)

![Branch w/ Broken Pot](https://share.citra.live/i/kqdt3.png)

![Branch](https://share.citra.live/i/ucdda.png)

![Male Harvest](https://share.citra.live/i/mmhwb.png)

![Drying Rack](https://share.citra.live/i/443p9.png)

![Drying Rack Menu](https://share.citra.live/i/c6o8h.png)

![Branch Menu](https://share.citra.live/i/7p446.png)

![Drying Rack Menu Partially Full](https://share.citra.live/i/93c8o.png)

![Drying Rack Full](https://share.citra.live/i/2earo.png)

![Drying Rack Almost Done](https://share.citra.live/i/8btkb.png)

![Branches](https://share.citra.live/i/f3rv5.png)

![Processing](https://share.citra.live/i/m8im8.png)

</details>

### Dependencies
- [citra_bridge](https://github.com/citRaTTV/citra_bridge)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)

### Setup
1. Ensure items exist & configure your inventory system to call the proper exports on item use.

<details>
<summary>ox_inventory example</summary>

#### data/items.lua

```lua
    ["weedplant_seedf"] = {
        label = "Female Weed Seed",
        weight = 0,
        stack = true,
        close = true,
        description = "Female Weed Seed",
        client = {
            image = "weedplant_seed.png",
            export = 'citra_weed.plant',
        }
    },
    ["weedplant_seedm"] = {
        label = "Male Weed Seed",
        weight = 0,
        stack = true,
        close = false,
        description = "Male Weed Seed",
        client = {
            image = "weedplant_seed.png",
            export = 'citra_weed.plant',
        }
    },
    ["weedplant_rack"] = {
        label = "Drying Rack",
        weight = 50000,
        stack = false,
        close = true,
        description = "A large drying rack",
        client = {
            export = 'citra_weed.deployRack',
        },
    },
    ["lighter"] = {
        label = "Lighter",
        weight = 0,
        stack = true,
        close = true,
        description = "On new years eve a nice fire to stand next to",
        client = {
            image = "lighter.png",
        }
    },
    ["plant_tub"] = {
        label = "Plant Tub",
        weight = 1000,
        stack = true,
        close = false,
        description = "Pot for planting plants",
        client = {
            image = "plant_tub.png",
        }
    },
    ["waterbottle"] = {
        label = "Water",
        weight = 500,
        stack = true,
        close = true,
        description = "For all the thirsty people out there",
        client = {
            image = "water_bottle.png",
        }
    },
    ["weed_nutrition"] = {
        label = "Plant Fertilizer",
        weight = 2000,
        stack = true,
        close = true,
        description = "Plant nutrition",
        client = {
            image = "weed_nutrition.png",
        }
    },
    ["empty_weed_bag"] = {
        label = "Empty Weed Bag",
        weight = 0,
        stack = true,
        close = true,
        description = "A small empty bag",
        client = {
            image = "weed_baggy_empty.png",
        }
    },
    ["weedplant_weed"] = {
        label = "Homegrown 2g",
        weight = 100,
        stack = true,
        close = false,
        description = "Weed ready for the streets",
        client = {
            image = "weedplant_weed.png",
        }
    },
```
</details>

2. Tune `shared/config.lua` to your liking.
