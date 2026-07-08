local config = require 'shared.config'
local tickTime = 60

return {
    tickTime = tickTime,
    perTick = {
        food = (config.foodUse / config.growTime) * tickTime,
        water = (config.waterUse / config.growTime) * tickTime,
        dry = (100 / config.dryTime) * tickTime,
    },
    rackOffsets = {
        vector3(-0.75, 0, 0.58),
        vector3(-0.45, 0, 0.58),
        vector3(-0.15, 0, 0.58),
        vector3(0.15, 0, 0.58),
        vector3(0.45, 0, 0.58),
        vector3(0.75, 0, 0.58),
    },
}
