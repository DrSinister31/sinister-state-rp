local config = require 'shared.config'

local function getIconColour(percentage)
    return (percentage > 75) and 'rgba(53, 163, 75, 0.8)' or (percentage > 50) and 'rgba(217, 211, 42, 0.8)' or 'rgba(175, 16, 16, 0.93)'
end

local function plant(entity)
    local status = Entity(entity).state.citra_weed_data
    lib.registerContext({
        id = 'citra_weed_status',
        title = 'Weed Plant Status',
        options = {
            {
                title = 'Growth Percentage',
                progress = status.percentage,
                description = ("%.2f%%"):format(status.percentage),
                icon = 'fas fa-seedling',
                iconColor = ('rgba(16, 176, 41, %.2f)'):format(status.percentage / 100),
            },
            {
                title = 'Plant Health',
                progress = status.health,
                description = ("%.2f%%"):format(status.health),
                icon = 'fas fa-heart',
                iconColor = getIconColour(status.health),
            },
            {
                title = 'Food',
                progress = status.food,
                description = ("%.2f%%"):format(status.food),
                icon = 'fas fa-wheat-awn-circle-exclamation',
                iconColor = getIconColour(status.food),
                onSelect = function()
                    if exports.ox_inventory:GetItemCount(config.foodItem) < 1 then
                        bridge.framework:notify({
                            title = 'Need Fertilizer',
                            description = 'You need fertilizer',
                            icon = 'fas fa-cannabis',
                        }, 'warn', 5000)
                        return
                    elseif status.health <= 0 then
                        bridge.framework:notify({
                            title = 'Dead',
                            description = "This plant is dead",
                            icon = 'fas fa-skull-crossbones',
                        }, 'error', 6000)
                        return
                    end
                    LocalPlayer.state:set('target_busy', true)
                    TriggerServerEvent('citra_weed:server:feed', status.id)
                    lib.progressCircle({
                        label = 'Feeding...',
                        duration = 10000,
                        disable = {
                            move = true,
                            sprint = true,
                            mouse = false,
                            car = true,
                            combat = true,
                        },
                        anim = {
                            dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@',
                            clip = 'weed_spraybottle_crouch_spraying_01_inspector',
                        },
                        canCancel = false,
                    })
                    LocalPlayer.state:set('target_busy', false)
                end,
            },
            {
                title = 'Water',
                progress = status.water,
                description = ("%.2f%%"):format(status.water),
                icon = 'fas fa-droplet',
                iconColor = getIconColour(status.water),
                onSelect = function()
                    if exports.ox_inventory:GetItemCount(config.waterItem) < 1 then
                        bridge.framework:notify({
                            title = 'Need Water',
                            description = 'You need a bottle of water',
                            icon = 'fas fa-cannabis',
                        }, 'warn', 5000)
                        return
                    elseif status.health <= 0 then
                        bridge.framework:notify({
                            title = 'Dead',
                            description = "This plant is dead",
                            icon = 'fas fa-skull-crossbones',
                        }, 'error', 6000)
                        return
                    end
                    LocalPlayer.state:set('target_busy', true)
                    TriggerServerEvent('citra_weed:server:water', status.id)
                    lib.progressCircle({
                        label = 'Watering...',
                        duration = 10000,
                        disable = {
                            move = true,
                            sprint = true,
                            mouse = false,
                            car = true,
                            combat = true,
                        },
                        anim = {
                            dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@',
                            clip = 'weed_spraybottle_crouch_spraying_02_inspector',
                        },
                        canCancel = false,
                    })
                    LocalPlayer.state:set('target_busy', false)
                end,
            },
            {
                title = 'Gender',
                description = (status.gender == 0 and 'Female' or 'Male'),
                icon = 'fas fa-' .. (status.gender == 0 and 'venus' or 'mars'),
                iconColor = status.gender == 0 and 'rgba(220, 17, 122, 0.61)' or 'rgba(18, 154, 219, 0.73)',
            },
            {
                title = 'Harvest',
                disabled = (status.percentage < 100),
                description = "Harvest crop",
                icon = 'fas fa-person-digging',
                onSelect = function()
                    if Entity(entity).state.citra_weed_harvesting then return end
                    LocalPlayer.state:set('target_busy', true)
                    Entity(entity).state:set('citra_weed_harvesting', true, true)
                    lib.progressCircle({
                        label = 'Harvesting...',
                        duration = 30000,
                        disable = {
                            move = true,
                            sprint = true,
                            mouse = false,
                            car = true,
                            combat = true,
                        },
                        anim = {
                            dict = 'amb@world_human_gardener_plant@male@idle_a',
                            clip = 'idle_a',
                        },
                        canCancel = false,
                    })
                    TriggerServerEvent('citra_weed:server:harvest', status.id)
                    LocalPlayer.state:set('target_busy', false)
                end,
            },
            {
                title = 'Burn down',
                disabled = (exports.ox_inventory:GetItemCount(config.lighterItem) < 1),
                description = "Burn crop down",
                icon = 'fas fa-fire',
                onSelect = function()
                    if Entity(entity).state.citra_weed_harvesting then return end
                    LocalPlayer.state:set('target_busy', true)
                    Entity(entity).state:set('citra_weed_harvesting', true, true)
                    lib.progressCircle({
                        label = 'Burning plant...',
                        duration = 10000,
                        disable = {
                            move = true,
                            sprint = true,
                            mouse = false,
                            car = true,
                            combat = true,
                        },
                        anim = {
                            dict = 'amb@world_human_gardener_plant@male@idle_a',
                            clip = 'idle_a',
                        },
                        canCancel = false,
                    })
                    TriggerServerEvent('citra_weed:server:burn', status.id)
                    LocalPlayer.state:set('target_busy', false)
                end,
            },
        },
    })

    lib.showContext('citra_weed_status')
end

local function rack(entity)
    local status = Entity(entity).state.citra_weed_rack
    local items = exports.ox_inventory:GetSlotsWithItem(config.branchItem)
    local ind
    if items then
        local branchOpts = {}
        for i = 1, #items do
            branchOpts[#branchOpts+1] = {
                title = 'Branch',
                progress = items[i].metadata.dryness,
                icon = 'fas fa-cannabis',
                iconColor = getIconColour(items[i].metadata.dryness),
                onSelect = function()
                    TriggerServerEvent('citra_weed:server:addBranch', status.netId, ind, items[i].slot)
                    SetTimeout(500, function()
                        rack(entity)
                    end)
                end,
            }
        end
        lib.registerContext({
            id = 'citra_weed_branches',
            title = 'Branches',
            menu = 'citra_weed_rack',
            options = branchOpts,
        })
    end
    local options = {}
    for i = 1, 6 do
        options[i] = {
            title = status.branches[i] and 'Branch ' .. i or 'Empty',
            progress = status.branches[i]?.dryness,
            description = status.branches[i] and ("%.2f%%"):format(status.branches[i].dryness) or 'Hang a branch',
            metadata = {
                {
                    label = 'Action',
                    value = (status.branches[i] and 'Remove branch' or 'Hang a branch'),
                }
            },
            icon = status.branches[i] and 'fas fa-cannabis' or 'fas fa-ban',
            iconColor = status.branches[i] and getIconColour(status.branches[i].dryness),
            onSelect = function()
                if status.branches[i] then
                    TriggerServerEvent('citra_weed:server:removeBranch', status.netId, i)
                    SetTimeout(500, function()
                        rack(entity)
                    end)
                elseif items and #items > 0 then
                    ind = i
                    lib.showContext('citra_weed_branches')
                else
                    bridge.framework:notify({
                        title = 'No Branches',
                        description = "You have no branches",
                        icon = 'fas fa-cannabis',
                    }, 'warn', 5000)
                end
            end,
        }
    end
    options[#options+1] = {
        title = 'Pick up',
        description = "Collect rack and branches",
        icon = 'fas fa-hand',
        onSelect = function()
            TriggerServerEvent('citra_weed:server:removeRack', status.netId)
        end,
    }
    lib.registerContext({
        id = 'citra_weed_rack',
        title = 'Drying Rack',
        options = options
    })
    lib.showContext('citra_weed_rack')
end

return {
    plant = plant,
    rack = rack,
}
