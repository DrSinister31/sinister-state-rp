-- ============================================================================
-- SINISTER DEALERS — Server
-- Drug & weapon NPC dealer system for Sinister H-Town RP
-- ============================================================================

local recruitedDealers = {}  -- playerCitizenId -> { dealerId, zone, hiredAt }

-- ============================================================================
-- DRUG BUYING (Player buys from dealer)
-- ============================================================================

RegisterNetEvent('sinister_dealers:buyDrugs', function(drug, quantity, zone)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local drugData = Config.DrugTypes[drug]
    if not drugData then return end

    local unitPrice = math.floor(drugData.price * Config.DrugBuyMultiplier)
    local totalCost = unitPrice * quantity

    -- Check cash
    local cash = player.Functions.GetMoney('cash')
    if cash < totalCost then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Dealer',
            description = string.format('You need $%d cash. You have $%d.', totalCost, cash),
            type = 'error',
        })
        return
    end

    -- Remove cash, give drug
    player.Functions.RemoveMoney('cash', totalCost, 'drug-purchase')
    exports.ox_inventory:AddItem(src, drug, quantity)

    TriggerClientEvent('ox_lib:notify', src, {
        title = zone .. ' Dealer',
        description = string.format('Bought %dx %s for $%d', quantity, drugData.label, totalCost),
        type = 'success',
    })

    -- Police alert chance
    if math.random(100) <= Config.PoliceAlertChance then
        TriggerEvent('sinister_dealers:dispatchAlert', zone)
    end

    -- Add to criminal reputation
    exports.ox_inventory:AddItem(src, 'dirty_money', 0) -- placeholder for rep tracking
end)

-- ============================================================================
-- DRUG SELLING (Player sells to dealer)
-- ============================================================================

RegisterNetEvent('sinister_dealers:sellDrugs', function(drug, quantity, zone)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local drugData = Config.DrugTypes[drug]
    if not drugData then return end

    -- Check inventory
    local count = exports.ox_inventory:GetItemCount(src, drug)
    if count < quantity then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Dealer',
            description = string.format('You only have %dx %s.', count, drugData.label),
            type = 'error',
        })
        return
    end

    -- Remove drug, give dirty_money
    local unitPrice = math.floor(drugData.price * Config.DrugSellMultiplier)
    local totalPay = unitPrice * quantity

    if exports.ox_inventory:RemoveItem(src, drug, quantity) then
        exports.ox_inventory:AddItem(src, 'dirty_money', totalPay)
        TriggerClientEvent('ox_lib:notify', src, {
            title = zone .. ' Dealer',
            description = string.format('Sold %dx %s for $%d dirty cash', quantity, drugData.label, totalPay),
            type = 'success',
        })

        if math.random(100) <= Config.PoliceAlertChance then
            TriggerEvent('sinister_dealers:dispatchAlert', zone)
        end
    end
end)

-- ============================================================================
-- WEAPON BUYING
-- ============================================================================

RegisterNetEvent('sinister_dealers:buyWeapon', function(itemName, price, minRep)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    -- Check job blacklist
    local job = player.PlayerData.job and player.PlayerData.job.name
    if job and hasValue(Config.WeaponJobBlacklist, job) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Arms Dealer',
            description = 'I do not sell to law enforcement. Walk away.',
            type = 'error',
        })
        return
    end

    -- Reputation check for tiers
    -- For now, allow all tiers — rep system to be added later
    -- local rep = getPlayerRep(player.PlayerData.citizenid)
    -- if rep < minRep then ... end

    -- Check money
    local cash = player.Functions.GetMoney('cash')
    if cash < price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Arms Dealer',
            description = string.format('You need $%d cash. Come back when you have it.', price),
            type = 'error',
        })
        return
    end

    -- Check if weapon — enforce single copy
    if itemName:find('weapon_') then
        local hasWeapon = exports.ox_inventory:GetItemCount(src, itemName)
        if hasWeapon > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Arms Dealer',
                description = 'You already have that piece. No need for two.',
                type = 'error',
            })
            return
        end
    end

    player.Functions.RemoveMoney('cash', price, 'arms-purchase')
    exports.ox_inventory:AddItem(src, itemName, 1)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Arms Dealer',
        description = string.format('Pleasure doing business. $%d', price),
        type = 'success',
    })
end)

-- ============================================================================
-- DEALER RECRUITMENT
-- ============================================================================

RegisterNetEvent('sinister_dealers:recruitDealer', function(dealerId, zone)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local cid = player.PlayerData.citizenid

    -- Check max dealers
    local currentCount = 0
    for _, d in pairs(recruitedDealers) do
        if d.citizenid == cid then currentCount = currentCount + 1 end
    end
    if currentCount >= Config.MaxDealersPerPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Recruitment',
            description = string.format('You already have %d dealers. Max is %d.', currentCount, Config.MaxDealersPerPlayer),
            type = 'error',
        })
        return
    end

    -- Check cash
    local cash = player.Functions.GetMoney('cash')
    if cash < Config.DealerRecruitCost then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Recruitment',
            description = string.format('You need $%d to recruit. You have $%d.', Config.DealerRecruitCost, cash),
            type = 'error',
        })
        return
    end

    player.Functions.RemoveMoney('cash', Config.DealerRecruitCost, 'dealer-recruitment')

    recruitedDealers[dealerId] = {
        citizenid = cid,
        zone = zone,
        hiredAt = os.time(),
    }

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Recruitment',
        description = string.format('Dealer recruited in %s. Collects $%d/day.', zone, Config.DealerDailyWage),
        type = 'success',
    })
end)

-- ============================================================================
-- DISPATCH ALERT
-- ============================================================================

RegisterNetEvent('sinister_dealers:dispatchAlert', function(zone)
    -- Alert online LEO players
    local players = GetPlayers()
    for _, pid in ipairs(players) do
        local p = exports.qbx_core:GetPlayer(pid)
        if p and p.PlayerData.job then
            local jobType = p.PlayerData.job.type
            if jobType == 'leo' and p.PlayerData.job.onduty then
                TriggerClientEvent('ox_lib:notify', pid, {
                    title = 'Dispatch',
                    description = string.format('Suspicious activity reported — %s area.', zone),
                    type = 'inform',
                    duration = 8000,
                })
            end
        end
    end
end)

-- ============================================================================
-- DEALER PAYROLL (runs daily via Kronus or server restart)
-- ============================================================================

local function processDealerPayroll()
    local payouts = {}
    for dealerId, data in pairs(recruitedDealers) do
        if not payouts[data.citizenid] then
            payouts[data.citizenid] = { count = 0, zones = {} }
        end
        payouts[data.citizenid].count = payouts[data.citizenid].count + 1
        payouts[data.citizenid].zones[#payouts[data.citizenid].zones + 1] = data.zone
    end

    for cid, payout in pairs(payouts) do
        local totalPay = payout.count * Config.DealerDailyWage
        -- Use dirty_money since it's drug income
        local src = nil
        local players = GetPlayers()
        for _, pid in ipairs(players) do
            local p = exports.qbx_core:GetPlayer(pid)
            if p and p.PlayerData.citizenid == cid then
                src = pid
                break
            end
        end
        if src then
            exports.ox_inventory:AddItem(src, 'dirty_money', totalPay)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Dealer Network',
                description = string.format('%d dealers collected $%d in %s', payout.count, totalPay, table.concat(payout.zones, ', ')),
                type = 'inform',
                duration = 10000,
            })
        end
    end
end

-- Run payroll every 30 minutes
Citizen.CreateThread(function()
    while true do
        Wait(1800000) -- 30 min
        processDealerPayroll()
    end
end)

-- ============================================================================
-- COMMANDS
-- ============================================================================

RegisterCommand('dealers', function(source)
    local src = source
    if src <= 0 then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local cid = player.PlayerData.citizenid
    local myDealers = {}
    for dealerId, data in pairs(recruitedDealers) do
        if data.citizenid == cid then
            myDealers[#myDealers + 1] = data.zone
        end
    end

    if #myDealers == 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Dealer Network',
            description = 'You have no dealers. Find them on the streets to recruit.',
            type = 'inform',
        })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = string.format('Dealer Network (%d)', #myDealers),
        description = 'Territories: ' .. table.concat(myDealers, ', '),
        type = 'inform',
        duration = 10000,
    })
end, false)

function hasValue(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        print('^2[sinister_dealers] ^7Server ready — drug & weapon economy active')
        print('^2[sinister_dealers] ^7Street dealers: ' .. #Config.StreetDealerLocations)
        print('^2[sinister_dealers] ^7Gun dealers: ' .. #Config.GunDealerLocations)
        print('^2[sinister_dealers] ^7Drug types: ' .. tablelength(Config.DrugTypes))
    end
end)

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end
