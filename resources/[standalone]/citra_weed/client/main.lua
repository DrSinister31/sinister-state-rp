local config = require 'shared.config'
local menus = require 'client.menus'

local function plant(data)
    if cache.vehicle then return end
    if exports.ox_inventory:GetItemCount(config.potItem) < 1 then
        bridge.framework:notify({
            title = 'Need a Pot',
            description = "You need a pot to plant this seed",
            icon = 'fas fa-cannabis',
        }, 'warn', 6000)
        return
    end
    exports.ox_inventory:useItem(data, function(_data)
        LocalPlayer.state:set('inv_busy', true, true)
        local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0, 1.0, -1.0)
        lib.requestModel('bkr_prop_weed_plantpot_stack_01b')
        local pot = CreateObject('bkr_prop_weed_plantpot_stack_01b', coords.x, coords.y, coords.z, true, true, false)
        lib.progressCircle({
            label = 'Planting...',
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
        TriggerServerEvent('citra_weed:server:plant', vector4(coords.x, coords.y, coords.z, GetEntityHeading(cache.ped)), _data.name)
        DeleteEntity(pot)
        LocalPlayer.state:set('inv_busy', false, true)
    end)
end

exports('plant', plant)

local function deployRack(data)
    if cache.vehicle then return end
    exports.ox_inventory:useItem(data, function(_)
        local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0, 1.5, 0)
        TriggerServerEvent('citra_weed:server:deploy', vector4(coords.x, coords.y, coords.z, GetEntityHeading(cache.ped)))
    end)
end

exports('deployRack', deployRack)

local function package(data)
    if cache.vehicle and cache.seat == -1 then return end
    LocalPlayer.state:set('inv_busy', true, true)
    lib.callback('citra_weed:server:packageBranch', nil, function(packageTime)
        if not packageTime then LocalPlayer.state:set('inv_busy', false, true) return end
        lib.progressCircle({
            label = 'Packaging weed...',
            duration = packageTime * 1000,
            disable = {
                move = true,
                sprint = true,
                mouse = false,
                car = true,
                combat = true,
            },
            anim = {
                dict = 'anim@amb@business@coc@coc_unpack_cut_left@',
                clip = 'coke_cut_v1_coccutter',
            },
            canCancel = false,
        })
        LocalPlayer.state:set('inv_busy', false, true)
    end, data.slot)
end

exports('package', package)

bridge.target:addModels(config.models, {
    {
        label = 'Weed Plant',
        icon = 'fas fa-cannabis',
        require = {
            func = function(entity)
                return Entity(entity).state.citra_weed_data and not LocalPlayer.state.target_busy and not Entity(entity).state.citra_weed_harvesting
            end,
        },
        func = menus.plant,
    },
})

bridge.target:addModels('v_club_rack', {
    {
        label = 'Drying rack',
        icon = 'fas fa-cannabis',
        require = {
            func = function(entity)
                return Entity(entity).state.citra_weed_rack and not LocalPlayer.state.target_busy and not Entity(entity).state.citra_weed_harvesting
            end,
        },
        func = menus.rack,
    },
})

lib.callback.register('citra_weed:client:getOffset', function(netId, offset)
    while not NetworkDoesEntityExistWithNetworkId(netId) do Wait(10) end
    local entity = NetworkGetEntityFromNetworkId(netId)
    return GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
end)

exports.ox_inventory:displayMetadata({health = 'Health %', dryness = 'Dried %'})
