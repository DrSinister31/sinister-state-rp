local streetDealers = {}
local gunDealers = {}
local rivalDealers = {}

-- ============================================================================
-- NPC SPAWNING
-- ============================================================================

local function spawnPed(model, coords)
    local hash = GetHashKey(model)
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(0) end
    end
    local ped = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, coords.w, true, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(hash)
    return ped
end

local function spawnStreetDealers()
    for i, loc in ipairs(Config.StreetDealerLocations) do
        local model = Config.DealerPeds[(i % #Config.DealerPeds) + 1]
        local ped = spawnPed(model, loc.coords)
        streetDealers[#streetDealers + 1] = {
            ped = ped,
            location = loc,
            id = i,
            hasRival = false,
        }
    end
end

local function spawnGunDealers()
    for i, loc in ipairs(Config.GunDealerLocations) do
        local ped = spawnPed('g_m_y_mexgoose_01', loc.coords)
        gunDealers[#gunDealers + 1] = {
            ped = ped,
            location = loc,
            id = i,
        }
    end
end

local function spawnRivalDealer(location)
    local offsetX = math.random(-10, 10)
    local offsetY = math.random(-10, 10)
    local coords = vec4(location.coords.x + offsetX, location.coords.y + offsetY, location.coords.z, 0.0)

    local ped = spawnPed('g_m_y_salvagoon_01', coords)
    SetPedAsEnemy(ped, true)
    GiveWeaponToPed(ped, GetHashKey('weapon_pistol'), 100, false, true)
    SetPedCombatAttributes(ped, 46, true)

    rivalDealers[#rivalDealers + 1] = {
        ped = ped,
        dealerId = location.id,
    }
end

-- ============================================================================
-- DRUG DEALER MENUS
-- ============================================================================

local function openDrugBuyMenu(dealerId)
    local dealer = streetDealers[dealerId]
    if not dealer then return end

    local options = {}
    for drug, data in pairs(Config.DrugTypes) do
        local price = math.floor(data.price * Config.DrugBuyMultiplier)
        options[#options + 1] = {
            title = data.label,
            description = string.format('%s Buy: $%d each', data.emoji, price),
            icon = 'cart-shopping',
            onSelect = function()
                local input = lib.inputDialog('Buy ' .. data.label, {
                    { type = 'number', label = 'Quantity', default = 1, min = 1, max = 50 }
                })
                if input and input[1] then
                    TriggerServerEvent('sinister_dealers:buyDrugs', drug, input[1], dealer.location.zone)
                end
            end,
        }
    end

    lib.registerContext({
        id = 'drug_buy_menu',
        title = 'H-Town Dealer — Buy',
        options = options,
    })
    lib.showContext('drug_buy_menu')
end

local function openDrugSellMenu(dealerId)
    local dealer = streetDealers[dealerId]
    if not dealer then return end

    local options = {}
    for drug, data in pairs(Config.DrugTypes) do
        local price = math.floor(data.price * Config.DrugSellMultiplier)
        options[#options + 1] = {
            title = data.label,
            description = string.format('%s Sell: $%d each', data.emoji, price),
            icon = 'cash-register',
            onSelect = function()
                local input = lib.inputDialog('Sell ' .. data.label, {
                    { type = 'number', label = 'Quantity', default = 1, min = 1, max = 100 }
                })
                if input and input[1] then
                    TriggerServerEvent('sinister_dealers:sellDrugs', drug, input[1], dealer.location.zone)
                end
            end,
        }
    end

    lib.registerContext({
        id = 'drug_sell_menu',
        title = 'H-Town Dealer — Sell',
        options = options,
    })
    lib.showContext('drug_sell_menu')
end

local function openDealerRecruitMenu(dealerId)
    local dealer = streetDealers[dealerId]
    if not dealer then return end

    lib.registerContext({
        id = 'dealer_recruit_menu',
        title = 'Recruit Dealer — $' .. Config.DealerRecruitCost,
        options = {
            {
                title = 'Hire This Dealer',
                description = string.format('Cost: $%d | Territory: %s', Config.DealerRecruitCost, dealer.location.zone),
                icon = 'handshake',
                onSelect = function()
                    TriggerServerEvent('sinister_dealers:recruitDealer', dealerId, dealer.location.zone)
                end,
            },
        },
    })
    lib.showContext('dealer_recruit_menu')
end

-- ============================================================================
-- GUN DEALER MENUS
-- ============================================================================

local function openGunDealerMenu(dealerId)
    local options = {}
    for tierName, tier in pairs(Config.WeaponTiers) do
        options[#options + 1] = {
            title = tierName,
            description = string.format('Rep Required: %d', tier.minRep),
            icon = 'gun',
            metadata = { tier = tier, tierName = tierName },
            onSelect = function(args)
                openGunTierMenu(dealerId, args.metadata.tierName, args.metadata.tier)
            end,
        }
    end

    lib.registerContext({
        id = 'gun_dealer_menu',
        title = 'Texas Arsenal',
        options = options,
    })
    lib.showContext('gun_dealer_menu')
end

local function openGunTierMenu(dealerId, tierName, tier)
    local options = {}
    for _, item in ipairs(tier.items) do
        options[#options + 1] = {
            title = item.label,
            description = string.format('$%d — %s', item.price, tierName),
            icon = 'cart-shopping',
            onSelect = function()
                local qty = 1
                if item.name:find('ammo') then qty = 1 end
                TriggerServerEvent('sinister_dealers:buyWeapon', item.name, item.price, tier.minRep)
            end,
        }
    end

    lib.registerContext({
        id = 'gun_tier_menu',
        title = tierName,
        menu = 'gun_dealer_menu',
        options = options,
    })
    lib.showContext('gun_tier_menu')
end

-- ============================================================================
-- TARGET SETUP
-- ============================================================================

local function setupTargets()
    if not Config.UseTarget then return end

    -- Street dealers
    for _, dealer in ipairs(streetDealers) do
        exports.ox_target:addLocalEntity(dealer.ped, {
            {
                name = 'drug_buy',
                label = 'Buy Drugs',
                icon = 'fa-solid fa-cannabis',
                onSelect = function() openDrugBuyMenu(dealer.id) end,
            },
            {
                name = 'drug_sell',
                label = 'Sell Drugs',
                icon = 'fa-solid fa-money-bill-wave',
                onSelect = function() openDrugSellMenu(dealer.id) end,
            },
            {
                name = 'dealer_recruit',
                label = 'Recruit Dealer',
                icon = 'fa-solid fa-handshake',
                onSelect = function() openDealerRecruitMenu(dealer.id) end,
            },
        })
    end

    -- Gun dealers
    for _, dealer in ipairs(gunDealers) do
        exports.ox_target:addLocalEntity(dealer.ped, {
            {
                name = 'gun_buy',
                label = 'Browse Arsenal',
                icon = 'fa-solid fa-gun',
                onSelect = function() openGunDealerMenu(dealer.id) end,
            },
        })
    end
end

-- ============================================================================
-- RIVAL DEALER LOGIC
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Check every 60 seconds
        for _, dealer in ipairs(streetDealers) do
            if not dealer.hasRival and math.random(100) <= Config.RivalSpawnChance then
                spawnRivalDealer(dealer.location)
                dealer.hasRival = true
            end
        end

        -- Clean up dead rivals
        for i = #rivalDealers, 1, -1 do
            local rival = rivalDealers[i]
            if not DoesEntityExist(rival.ped) or IsPedDeadOrDying(rival.ped, true) then
                local dealer = streetDealers[rival.dealerId]
                if dealer then dealer.hasRival = false end
                table.remove(rivalDealers, i)
            end
        end
    end
end)

-- Police alert on drug deal
RegisterNetEvent('sinister_dealers:policeAlert', function(zone)
    -- Alert nearby LEO players
    TriggerServerEvent('sinister_dealers:dispatchAlert', zone)
end)

-- ============================================================================
-- INIT
-- ============================================================================

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        spawnStreetDealers()
        spawnGunDealers()
        Wait(1000)
        setupTargets()
        print('^2[sinister_dealers] ^7Drug & weapon dealers spawned in H-Town')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, d in ipairs(streetDealers) do
            if DoesEntityExist(d.ped) then DeleteEntity(d.ped) end
        end
        for _, d in ipairs(gunDealers) do
            if DoesEntityExist(d.ped) then DeleteEntity(d.ped) end
        end
        for _, r in ipairs(rivalDealers) do
            if DoesEntityExist(r.ped) then DeleteEntity(r.ped) end
        end
    end
end)
