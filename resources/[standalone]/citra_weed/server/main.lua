local config = require 'shared.config'
local db = require 'server.db'
local const = require 'server.const'
local plants, racks, objMap = {}, {}, {}

local function getPlantById(id)
    for i = 1, #plants do
        if plants[i]?.id == id then return plants[i] end
    end
end

local function getRackByNetId(netId)
    for i = 1, #racks do
        if racks[i]?.netId == netId then return racks[i] end
    end
end

local function getModel(plant)
    for i = 1, #objMap do
        if objMap[i].maxPercent > plant.percentage then return objMap[i].model end
    end
    return config.models[#config.models]
end

local function spawnPlant(plant)
    local model = getModel(plant)
    local entity = CreateObject(model, plant.coords.x, plant.coords.y, plant.coords.z - 10.0, true, true, false)
    CreateThread(function()
        while not DoesEntityExist(entity) do Wait(1) end
        plant.netId = NetworkGetNetworkIdFromEntity(entity)
        Entity(entity).state:set('citra_weed_data', plant, true)
        FreezeEntityPosition(entity, true)
        SetEntityCoords(entity, plant.coords.x, plant.coords.y, plant.coords.z, false, false, false, false)
    end)
end

local function spawnRack(coords)
    local entity = CreateObject('v_club_rack', coords.x, coords.y, coords.z, true, true, false)
    while not DoesEntityExist(entity) do Wait(10) end
    FreezeEntityPosition(entity, true)
    SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(entity, coords.w)
    return entity
end

local function spawnBranch(coords)
    local branchEnt = CreateObject('bkr_prop_weed_drying_01a', coords.x, coords.y, coords.z, true, true, false)
    while not DoesEntityExist(branchEnt) do Wait(10) end
    FreezeEntityPosition(branchEnt, true)
    SetEntityCoords(branchEnt, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(branchEnt, coords.w - 90.0)
    return branchEnt
end

local function cachePlants()
    plants = {}
    local result = db.getAll()
    for i = 1, #result do
        local data = json.decode(result[i].data)
        local plant = {
            id = result[i].id,
            coords = vector4(data.coords.x, data.coords.y, data.coords.z, data.coords.w),
            planted = data.planted,
            water = data.water,
            food = data.food,
            health = data.health,
            percentage = data.percentage,
            gender = data.gender,
        }
        plant.model = getModel(plant)
        plants[#plants+1] = plant
    end
end

local function deletePlant(plant, completely)
    local entity = NetworkGetEntityFromNetworkId(plant.netId)
    if DoesEntityExist(entity) then DeleteEntity(entity) end
    if not completely then return end
    db.delete(plant.id)
    plant.deleted = true
end

local function deleteBranch(src, branch)
    local success = exports.ox_inventory:AddItem(src, config.branchItem, 1, {
        dryness = math.floor(branch.dryness),
        health = branch.health
    }, nil)
    if not success then
        bridge.framework:notify({
            label = 'Full Pockets',
            description = "There wasn't enough room in your inventory",
            icon = 'fas fa-cannabis',
        }, 'warn', 7500)
        return false
    end
    DeleteEntity(NetworkGetEntityFromNetworkId(branch.netId))
    return true
end

local function init()
    db.init()
    local percent = 100 / #config.models
    for i = 1, #config.models do
        objMap[i] = {
            model = config.models[i],
            maxPercent = percent * i,
        }
    end
    cachePlants()
    Wait(1000)
    for i = 1, #plants do spawnPlant(plants[i]) end
    racks = json.decode(GetResourceKvpString('weed_racks') or '[]')
    for i = 1, #racks do
        local entity = spawnRack(racks[i].coords)
        racks[i].netId = NetworkGetNetworkIdFromEntity(entity)
        for j = 1, 6 do
            local branch = racks[i].branches[j]
            if not branch then goto next end
            local branchEnt = spawnBranch(branch.coords)
            branch.netId = NetworkGetNetworkIdFromEntity(branchEnt)
            ::next::
        end
        Entity(entity).state:set('citra_weed_rack', racks[i], true)
    end
    SetResourceKvp('weed_racks', '[]')
end

lib.callback.register('citra_weed:server:packageBranch', function(source, slot)
    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item or item.name ~= config.branchItem then return false end
    local amount = math.floor((item.metadata.health / 100) * config.bagsPerPlant)
    if item.metadata.dryness < 100 then
        bridge.framework:notify(source, {
            title = 'Not Dry',
            description = "Your branches must be completely dry to process them",
            icon = 'fas fa-cannabis',
        }, 'warn', 10000)
        return false
    elseif exports.ox_inventory:GetItemCount(source, config.baggyItem) < amount then
        bridge.framework:notify(source, {
            title = 'Not Enough Baggies',
            description = "You need at least " .. amount .. " baggies",
            icon = 'fas fa-cannabis',
        }, 'warn', 10000)
        return false
    elseif exports.ox_inventory:CanCarryAmount(source, config.packagedItem) < amount then
        bridge.framework:notify(source, {
            title = 'Not Enough Room',
            description = "You can't carry " .. amount .. " bags of weed",
            icon = 'fas fa-cannabis',
        }, 'warn', 10000)
        return false
    end
    exports.ox_inventory:RemoveItem(source, item.name, 1, nil, slot)
    CreateThread(function()
        while amount > 0 do
            Wait(2000)
            local procAmount = math.min(amount, 5)
            if exports.ox_inventory:RemoveItem(source, config.baggyItem, procAmount) then
                exports.ox_inventory:AddItem(source, config.packagedItem, procAmount)
                if math.random() <= config.seedChance then
                    bridge.framework:notify(source, {
                        title = 'You found a seed!',
                        description = "There was a seed hiding away in some bud",
                        icon = 'fas fa-cannabis',
                    }, 'success', 5000)
                    exports.ox_inventory:AddItem(source, config.seedItems.female, 1)
                end
            else
                bridge.framework:notify({
                    title = 'No Baggies',
                    description = "You ran out of baggies",
                    icon = 'fas fa-cannabis',
                }, 'warn', 7500)
                break
            end
            amount -= procAmount
        end
    end)
    return math.ceil((amount / 5) * 2)
end)

RegisterNetEvent('citra_weed:server:plant', function(coords, item)
    local src = source --[[ @as integer ]]
    if #(GetEntityCoords(GetPlayerPed(src)) - coords.xyz) > 10.0 then return end
    exports.ox_inventory:RemoveItem(src, config.potItem, 1)
    local plant = {
        coords = coords,
        planted = os.time(),
        water = config.healthyPercentage + (const.perTick.water * 5),
        food = config.healthyPercentage + (const.perTick.food * 5),
        health = 100,
        percentage = 0,
        gender = (item == config.seedItems.female and 0 or 1),
    }
    plant.id = db.new(plant)
    spawnPlant(plant)
    plants[#plants+1] = plant
    bridge.framework:notify(src, {
        title = 'Planted',
        description = 'Your weedplant has been planted',
        icon = 'fas fa-cannabis',
    }, 'success', 7000)
end)

RegisterNetEvent('citra_weed:server:harvest', function(id)
    local src = source --[[ @as integer ]]
    local plant = getPlantById(id)
    if not plant or #(GetEntityCoords(GetPlayerPed(src)) - plant.coords.xyz) > 6.0 or plant.percentage < 100 then return end
    local item = plant.gender == 0 and config.branchItem or config.seedItems.female
    local qty = plant.gender == 0 and 1 or math.random(config.seedsPerMalePlant[1], config.seedsPerMalePlant[2])
    if not exports.ox_inventory:AddItem(src, item, qty, { health = math.floor(plant.health), dryness = 0 }) then
        bridge.framework:notify(src, {
            title = 'Full Pockets',
            description = "There wasn't enough room in your inventory",
            icon = 'fas fa-cannabis',
        }, 'warn', 7500)
        return
    end
    deletePlant(plant, true)
    if math.random() > 0.5 then
        exports.ox_inventory:AddItem(src, config.potItem, 1)
    else
        bridge.framework:notify(src, {
            title = 'Broken Pot',
            description = "The pot broke your pot!",
            icon = 'fas fa-cannabis',
        }, 'warn', 6000)
    end
end)

RegisterNetEvent('citra_weed:server:burn', function(id)
    local src = source --[[ @as integer ]]
    local plant = getPlantById(id)
    if not plant or #(GetEntityCoords(GetPlayerPed(src)) - plant.coords.xyz) > 6.0 then return end
    if exports.ox_inventory:GetItemCount(src, config.lighterItem) < 1 then
        bridge.framework:notify({
            title = 'No Lighter',
            description = "You need a lighter to burn down a plant",
            icon = 'fas fa-cannabis',
        }, 'warn, 7500')
        return
    end
    deletePlant(plant, true)
end)

RegisterNetEvent('citra_weed:server:feed', function(id)
    local src = source --[[ @as integer ]]
    local plant = getPlantById(id)
    if not plant or #(GetEntityCoords(GetPlayerPed(src)) - plant.coords.xyz) > 6.0 or not exports.ox_inventory:RemoveItem(src, config.foodItem, 1) then return end
    plant.food = 100
    Entity(NetworkGetEntityFromNetworkId(plant.netId)).state:set('citra_weed_data', plant, true)
end)

RegisterNetEvent('citra_weed:server:water', function(id)
    local src = source --[[ @as integer ]]
    local plant = getPlantById(id)
    if not plant or #(GetEntityCoords(GetPlayerPed(src)) - plant.coords.xyz) > 6.0 or not exports.ox_inventory:RemoveItem(src, config.waterItem, 1) then return end
    plant.water = 100
    Entity(NetworkGetEntityFromNetworkId(plant.netId)).state:set('citra_weed_data', plant, true)
end)

RegisterNetEvent('citra_weed:server:deploy', function(coords)
    local src = source --[[ @as integer ]]
    if #(GetEntityCoords(GetPlayerPed(src)) - coords.xyz) > 6.0 then return end
    local entity = spawnRack(coords)
    local rack = {
        netId = NetworkGetNetworkIdFromEntity(entity),
        coords = coords,
        branches = {},
    }
    Entity(entity).state:set('citra_weed_rack', rack, true)
    racks[#racks+1] = rack
end)

RegisterNetEvent('citra_weed:server:removeRack', function(netId)
    local src = source --[[ @as integer ]]
    local status = getRackByNetId(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not status or #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(entity)) > 6.0 then return end
    for i = 1, 6 do
        if not status.branches[i] then goto next end
        if not deleteBranch(src, status.branches[i]) then return end
        Entity(entity).state:set('citra_weed_rack', status, true)
        status.branches[i] = nil
        ::next::
    end
    exports.ox_inventory:AddItem(src, config.rackItem, 1, nil, nil, function(success)
        if not success then
            bridge.framework:notify({
                label = 'Full Pockets',
                description = "There wasn't enough room in your inventory",
                icon = 'fas fa-cannabis',
            }, 'warn', 7500)
            return
        end
        DeleteEntity(entity)
    end)
end)

RegisterNetEvent('citra_weed:server:addBranch', function(netId, ind, slot)
    local src = source --[[ @as integer ]]
    local entity = NetworkGetEntityFromNetworkId(netId)
    local status = getRackByNetId(netId)
    if not entity or status?.branches?[ind] or #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(entity)) > 6.0 then return end
    local item = exports.ox_inventory:GetSlot(src, slot)
    if not item or item.name ~= config.branchItem then
        bridge.framework:notify(src, {
            label = 'No Branch',
            description = "You don't have a branch on you",
            icon = 'fas fa-cannabis',
        }, 'warn', 7500)
        return
    end
    exports.ox_inventory:RemoveItem(src, config.branchItem, 1, nil, item.slot)
    local coords = lib.callback.await('citra_weed:client:getOffset', src, netId, const.rackOffsets[ind])
    coords = vector4(coords.x, coords.y, coords.z, status.coords.w - 90.0)
    local branchEnt = spawnBranch(coords)
    status.branches[ind] = {
        dryness = item.metadata.dryness or 0,
        health = item.metadata.health,
        netId = NetworkGetNetworkIdFromEntity(branchEnt),
        coords = coords,
    }
    Entity(entity).state:set('citra_weed_rack', status, true)
end)

RegisterNetEvent('citra_weed:server:removeBranch', function(netId, ind)
    local src = source --[[ @as integer ]]
    local entity = NetworkGetEntityFromNetworkId(netId)
    local status = getRackByNetId(netId)
    if not entity or not status?.branches?[ind] or #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(entity)) > 6.0 then return end
    if not deleteBranch(src, status.branches[ind]) then return end
    status.branches[ind] = nil
    Entity(entity).state:set('citra_weed_rack', status, true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    for i = 1, #plants do
        db.save(plants[i])
        deletePlant(plants[i])
    end
    SetResourceKvp('weed_racks', json.encode(racks))
    for i = 1, #racks do
        local branches = racks[i].branches
        for j = 1, #branches do
            DeleteEntity(NetworkGetEntityFromNetworkId(branches[j]?.netId))
        end
        DeleteEntity(NetworkGetEntityFromNetworkId(racks[i]?.netId))
    end
end)

CreateThread(function()
    while true do
        Wait(const.tickTime * 1000)
        for i = 1, #plants do
            if not plants[i] then goto next
            elseif plants[i].deleted then
                local entity = NetworkGetEntityFromNetworkId(plants[i].netId)
                if DoesEntityExist(entity) then DeleteEntity(entity) end
                plants[i] = nil
                goto next
            elseif plants[i].health > 0 and plants[i].percentage < 100 then
                plants[i].water = math.max(plants[i].water - const.perTick.water, 0)
                plants[i].food = math.max(plants[i].food - const.perTick.food, 0)
                if math.min(plants[i].food, plants[i].water) <= 0 then
                    plants[i].health = 0
                elseif math.min(plants[i].food, plants[i].water) < config.healthyPercentage then
                    plants[i].health = math.max(plants[i].health - 1, 0)
                else
                    local newPercent = math.floor((plants[i].percentage + ((const.tickTime / config.growTime) * 100)) * 100) / 100
                    plants[i].percentage = math.min(newPercent, 100)
                end
            elseif plants[i].health > 0 then
                plants[i].health -= 0.01
            end
            local newModel = getModel(plants[i])
            if newModel ~= plants[i].model then
                deletePlant(plants[i])
                spawnPlant(plants[i])
                plants[i].model = newModel
            end
            Entity(NetworkGetEntityFromNetworkId(plants[i].netId)).state:set('citra_weed_data', plants[i], true)
            db.save(plants[i])
            ::next::
        end
    end
end)

CreateThread(function()
    while true do
        for i = 1, #racks do
            for j = 1, 6 do
                local branch = racks[i].branches[j]
                if branch and branch.dryness < 100 then
                    branch.dryness = math.min(branch.dryness + const.perTick.dry, 100)
                end
            end
            Entity(NetworkGetEntityFromNetworkId(racks[i].netId)).state:set('citra_weed_rack', racks[i], true)
        end
        Wait(const.tickTime * 1000)
    end
end)

init()
