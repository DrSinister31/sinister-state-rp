-- =====================================================================
--  bcs_gunstore - server
-- =====================================================================
-- Ownable gun stores backed by the native ox_inventory shop UI.
--  * Each store is registered as an ox_inventory shop (no fixed location,
--    we handle proximity/interaction ourselves on the client).
--  * Browsing/buying uses ox_inventory's own UI. A 'buyItem' hook routes
--    the revenue into the store balance and persists stock to the DB.
--  * Admins create/edit/delete stores (CRUD). Owners manage stock, prices,
--    the store name and the blip.
-- =====================================================================

local Stores = {}        -- [id] = { ...store fields..., items = { [itemName] = {item, price, stock, metadata} } }
local StockPrices = {}   -- [itemName] = wholesale cost per unit (admin-set)

-- Wholesale cost to restock one unit of an item from the system.
local function stockPriceOf(itemName)
    return StockPrices[itemName] or Config.defaultStockPrice or 0
end

-- --------------------------------------------------------------------
--  Permissions
-- --------------------------------------------------------------------
local function hasAdmin(source)
    if isPlayerAdmin and isPlayerAdmin(source) then return true end
    if Config.adminAce and IsPlayerAceAllowed(source, Config.adminAce) then return true end
    return false
end

local function isOwner(source, store)
    if not store or not store.owner then return false end
    return getPlayerIdentifier(source) == store.owner
end

local function canManage(source, store)
    return hasAdmin(source) or isOwner(source, store)
end

-- Whether this player may conjure stock from nothing (system) vs. having to
-- supply real items from their inventory. Admins always can.
local function canStockFreely(source)
    return Config.RestockFromSystem or hasAdmin(source)
end

-- Owners pay a wholesale cost for system stock; admins restock for free.
-- Returns true if the units are paid for (or free), false if the player can't afford it.
local function chargeForStock(source, itemName, units)
    if hasAdmin(source) then return true end
    local cost = stockPriceOf(itemName) * units
    if cost <= 0 then return true end
    if GetPlayerMoney(source, Config.stockAccount) < cost then return false end
    return RemovePlayerMoney(source, cost, Config.stockAccount)
end

-- --------------------------------------------------------------------
--  Shop registration / serialization
-- --------------------------------------------------------------------
local function buildInventory(store)
    local inventory = {}
    for _, item in pairs(store.items) do
        inventory[#inventory + 1] = {
            name = item.item,
            price = item.price,
            count = item.stock,
            metadata = item.metadata,
        }
    end
    return inventory
end

local function registerStoreShop(store)
    exports.ox_inventory:RegisterShop(GetShopType(store.id), {
        name = store.name,
        inventory = buildInventory(store),
    })
end

-- Public view of a store (sent to all clients for blips/interaction).
local function publicStore(store)
    return {
        id = store.id,
        name = store.name,
        owner_name = store.owner_name,
        price = store.price,
        for_sale = store.for_sale,
        coords = store.coords,
        blip_sprite = store.blip_sprite,
        blip_color = store.blip_color,
        blip_scale = store.blip_scale,
        ped_model = store.ped_model,
    }
end

local function syncStore(store)
    TriggerClientEvent('bcs_gunstore:syncStore', -1, publicStore(store))
end

local function syncRemove(storeId)
    TriggerClientEvent('bcs_gunstore:removeStore', -1, storeId)
end

-- --------------------------------------------------------------------
--  Loading
-- --------------------------------------------------------------------
local function loadStore(row)
    local coords = json.decode(row.coords) or { x = 0, y = 0, z = 0, w = 0.0 }
    local store = {
        id = row.id,
        name = row.name,
        owner = row.owner,
        owner_name = row.owner_name,
        price = row.price,
        for_sale = row.for_sale == 1 or row.for_sale == true,
        balance = row.balance,
        coords = coords,
        blip_sprite = row.blip_sprite,
        blip_color = row.blip_color,
        blip_scale = row.blip_scale,
        ped_model = row.ped_model,
        items = {},
    }
    Stores[store.id] = store
    return store
end

CreateThread(function()
    local stores = MySQL.query.await('SELECT * FROM bcs_gunstore_stores') or {}
    for _, row in ipairs(stores) do
        loadStore(row)
    end

    local items = MySQL.query.await('SELECT * FROM bcs_gunstore_items') or {}
    for _, row in ipairs(items) do
        local store = Stores[row.store_id]
        if store then
            store.items[row.item] = {
                item = row.item,
                price = row.price,
                stock = row.stock,
                metadata = row.metadata and json.decode(row.metadata) or nil,
            }
        end
    end

    local prices = MySQL.query.await('SELECT * FROM bcs_gunstore_stock_prices') or {}
    for _, row in ipairs(prices) do
        StockPrices[row.item] = row.price
    end

    for _, store in pairs(Stores) do
        registerStoreShop(store)
    end

    print(('^2[bcs_gunstore]^0 Loaded %s store(s).'):format(#stores))
end)

-- --------------------------------------------------------------------
--  ox_inventory purchase hook -> route revenue + persist stock
-- --------------------------------------------------------------------
exports.ox_inventory:registerHook('buyItem', function(payload)
    local shopType = payload.shopType
    if type(shopType) ~= 'string' or shopType:sub(1, #Config.shopPrefix) ~= Config.shopPrefix then
        return -- not one of our stores, allow the purchase normally
    end

    local storeId = tonumber(shopType:sub(#Config.shopPrefix + 1))
    local store = storeId and Stores[storeId]
    if not store then return false end

    local item = store.items[payload.itemName]
    if not item then return false end

    if item.stock < payload.count then
        return false -- out of stock (safety net; ox_inventory also checks)
    end

    item.stock = item.stock - payload.count
    store.balance = store.balance + payload.totalPrice

    MySQL.update('UPDATE bcs_gunstore_items SET stock = ? WHERE store_id = ? AND item = ?',
        { item.stock, storeId, payload.itemName })
    MySQL.update('UPDATE bcs_gunstore_stores SET balance = ? WHERE id = ?',
        { store.balance, storeId })

    return true
end)

-- --------------------------------------------------------------------
--  Read callbacks
-- --------------------------------------------------------------------
lib.callback.register('bcs_gunstore:getStores', function(source)
    local list = {}
    for _, store in pairs(Stores) do
        list[#list + 1] = publicStore(store)
    end
    return list
end)

-- Context for the interaction menu (what options this player should see).
lib.callback.register('bcs_gunstore:getStoreContext', function(source, storeId)
    local store = Stores[storeId]
    if not store then return nil end

    local admin = hasAdmin(source)
    local owner = isOwner(source, store)

    return {
        id = store.id,
        name = store.name,
        owner_name = store.owner_name,
        isAdmin = admin,
        isOwner = owner,
        canManage = admin or owner,
        for_sale = store.for_sale and not store.owner,
        price = store.price,
        balance = (admin or owner) and store.balance or nil,
    }
end)

-- Full management data (items + meta). Managers only.
lib.callback.register('bcs_gunstore:getManageData', function(source, storeId)
    local store = Stores[storeId]
    if not store or not canManage(source, store) then return nil end

    local items = {}
    for _, item in pairs(store.items) do
        local oxItem = exports.ox_inventory:Items(item.item)
        items[#items + 1] = {
            item = item.item,
            label = (oxItem and oxItem.label) or item.item,
            price = item.price,
            stock = item.stock,
            stockPrice = stockPriceOf(item.item),
        }
    end
    table.sort(items, function(a, b) return a.label < b.label end)

    return {
        id = store.id,
        name = store.name,
        balance = store.balance,
        price = store.price,
        blip_sprite = store.blip_sprite,
        blip_color = store.blip_color,
        blip_scale = store.blip_scale,
        freeStock = canStockFreely(source),
        payForStock = canStockFreely(source) and not hasAdmin(source),
        isOwner = isOwner(source, store),
        canSell = Config.allowOwnerSell and isOwner(source, store) or false,
        resellValue = math.floor((store.price or 0) * (Config.resellPercent or 0)),
        items = items,
    }
end)

-- --------------------------------------------------------------------
--  Buying a store
-- --------------------------------------------------------------------
lib.callback.register('bcs_gunstore:buyStore', function(source, storeId)
    local store = Stores[storeId]
    if not store then return false, locale('store_not_found') end
    if store.owner then return false, locale('store_owned_already') end
    if not store.for_sale then return false, locale('store_not_for_sale') end

    if GetPlayerMoney(source, Config.purchaseAccount) < store.price then
        return false, locale('not_enough_money')
    end
    if not RemovePlayerMoney(source, store.price, Config.purchaseAccount) then
        return false, locale('not_enough_money')
    end

    store.owner = getPlayerIdentifier(source)
    store.owner_name = getPlayerName(source)
    store.for_sale = false

    MySQL.update('UPDATE bcs_gunstore_stores SET owner = ?, owner_name = ?, for_sale = 0 WHERE id = ?',
        { store.owner, store.owner_name, storeId })

    syncStore(store)
    return true, locale('store_purchased', store.name)
end)

-- Owner sells their store back to the system for a configured % of the price.
lib.callback.register('bcs_gunstore:sellStore', function(source, storeId)
    if not Config.allowOwnerSell then return false, locale('no_permission') end
    local store = Stores[storeId]
    if not store then return false, locale('store_not_found') end
    if not isOwner(source, store) then return false, locale('no_permission') end

    local refund = math.floor((store.price or 0) * (Config.resellPercent or 0))

    store.owner = nil
    store.owner_name = nil
    store.for_sale = true

    MySQL.update('UPDATE bcs_gunstore_stores SET owner = NULL, owner_name = NULL, for_sale = 1 WHERE id = ?', { storeId })

    if refund > 0 then AddPlayerMoney(source, refund, Config.purchaseAccount) end

    syncStore(store)
    return true, locale('store_sold_back', refund)
end)

-- --------------------------------------------------------------------
--  Owner / admin: store info (name + blip)
-- --------------------------------------------------------------------
lib.callback.register('bcs_gunstore:setStoreInfo', function(source, storeId, data)
    local store = Stores[storeId]
    if not store or not canManage(source, store) then return false, locale('no_permission') end

    store.name = (data.name and data.name ~= '' and data.name:sub(1, 64)) or store.name
    store.blip_sprite = tonumber(data.blip_sprite) or store.blip_sprite
    store.blip_color = tonumber(data.blip_color) or store.blip_color
    store.blip_scale = tonumber(data.blip_scale) or store.blip_scale

    MySQL.update('UPDATE bcs_gunstore_stores SET name = ?, blip_sprite = ?, blip_color = ?, blip_scale = ? WHERE id = ?',
        { store.name, store.blip_sprite, store.blip_color, store.blip_scale, storeId })

    registerStoreShop(store) -- refresh shop label
    syncStore(store)         -- refresh blip name/color for everyone
    return true, locale('store_updated')
end)

-- --------------------------------------------------------------------
--  Owner / admin: stock & pricing
-- --------------------------------------------------------------------
local function itemAllowed(itemName)
    if not Config.allowedItems then return true end
    for _, allowed in ipairs(Config.allowedItems) do
        if allowed == itemName then return true end
    end
    return false
end

-- Items an owner is allowed to list. With an allowedItems whitelist we use that;
-- otherwise we accept weapons (WEAPON_*) and ammo (ammo*).
local function isSellable(itemName)
    if Config.allowedItems then return itemAllowed(itemName) end
    local lower = itemName:lower()
    return lower:find('^weapon_') ~= nil or lower:find('^ammo') ~= nil
end

-- Returns the weapons/ammo currently in the manager's own inventory so they can
-- pick what to list instead of typing item names.
lib.callback.register('bcs_gunstore:getInventoryItems', function(source, storeId)
    local store = Stores[storeId]
    if not store or not canManage(source, store) then return nil end

    local invItems = exports.ox_inventory:GetInventoryItems(source) or {}
    local counts = {}
    for _, slot in pairs(invItems) do
        if slot and slot.name and isSellable(slot.name) then
            counts[slot.name] = (counts[slot.name] or 0) + (slot.count or 1)
        end
    end

    local list = {}
    for name, count in pairs(counts) do
        local oxItem = exports.ox_inventory:Items(name)
        local existing = store.items[name]
        list[#list + 1] = {
            item = name,
            label = (oxItem and oxItem.label) or name,
            count = count,
            inStore = existing ~= nil,
            price = existing and existing.price or nil,
            stock = existing and existing.stock or nil,
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end)

lib.callback.register('bcs_gunstore:setItem', function(source, storeId, itemName, price, stock)
    local store = Stores[storeId]
    if not store or not canManage(source, store) then return false, locale('no_permission') end

    itemName = itemName and itemName:gsub('%s+', '')
    if not itemName or itemName == '' then return false, locale('invalid_item') end
    if not itemAllowed(itemName) then return false, locale('item_not_allowed') end

    -- validate against ox_inventory items
    local oxItem = exports.ox_inventory:Items(itemName)
    if not oxItem then return false, locale('invalid_item') end

    price = math.max(0, math.min(tonumber(price) or 0, Config.maxItemPrice))
    stock = math.max(0, math.min(tonumber(stock) or 0, Config.maxStock))

    local existing = store.items[itemName]

    -- Owners can't set stock numbers directly unless RestockFromSystem is on;
    -- they must add stock through restock (which pulls from their inventory).
    if not canStockFreely(source) then
        stock = existing and existing.stock or 0
    else
        -- Setting a higher stock number is system stock: owner pays for the
        -- added units (admins are free).
        local delta = stock - (existing and existing.stock or 0)
        if delta > 0 and not chargeForStock(source, itemName, delta) then
            return false, locale('not_enough_money')
        end
    end

    if existing then
        existing.price = price
        existing.stock = stock
        MySQL.update('UPDATE bcs_gunstore_items SET price = ?, stock = ? WHERE store_id = ? AND item = ?',
            { price, stock, storeId, itemName })
    else
        store.items[itemName] = { item = itemName, price = price, stock = stock }
        MySQL.insert('INSERT INTO bcs_gunstore_items (store_id, item, price, stock) VALUES (?, ?, ?, ?)',
            { storeId, itemName, price, stock })
    end

    registerStoreShop(store)
    return true, locale('item_saved')
end)

lib.callback.register('bcs_gunstore:restockItem', function(source, storeId, itemName, amount)
    local store = Stores[storeId]
    if not store or not canManage(source, store) then return false, locale('no_permission') end

    local item = store.items[itemName]
    if not item then return false, locale('invalid_item') end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, locale('invalid_amount') end

    -- respect the per-item stock cap; only ever add what fits
    local addable = math.min(amount, Config.maxStock - item.stock)
    if addable <= 0 then return false, locale('stock_full') end

    if not canStockFreely(source) then
        -- pull the real items out of the owner's inventory
        local have = exports.ox_inventory:GetItemCount(source, itemName)
        if have < addable then
            return false, locale('not_enough_items', addable, have)
        end
        if not exports.ox_inventory:RemoveItem(source, itemName, addable) then
            return false, locale('error_generic')
        end
    elseif not chargeForStock(source, itemName, addable) then
        -- system stock: owner pays the wholesale price (admins are free)
        return false, locale('not_enough_money')
    end

    item.stock = item.stock + addable

    MySQL.update('UPDATE bcs_gunstore_items SET stock = ? WHERE store_id = ? AND item = ?',
        { item.stock, storeId, itemName })

    registerStoreShop(store)
    return true, locale('restock_success', addable)
end)

lib.callback.register('bcs_gunstore:removeItem', function(source, storeId, itemName)
    local store = Stores[storeId]
    if not store or not canManage(source, store) then return false, locale('no_permission') end
    if not store.items[itemName] then return false, locale('invalid_item') end

    store.items[itemName] = nil
    MySQL.update('DELETE FROM bcs_gunstore_items WHERE store_id = ? AND item = ?', { storeId, itemName })

    registerStoreShop(store)
    return true, locale('item_removed')
end)

-- --------------------------------------------------------------------
--  Owner: withdraw balance
-- --------------------------------------------------------------------
lib.callback.register('bcs_gunstore:withdraw', function(source, storeId, amount)
    local store = Stores[storeId]
    if not store or not canManage(source, store) then return false, locale('no_permission') end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, locale('invalid_amount') end
    if amount > store.balance then return false, locale('not_enough_balance') end

    if not AddPlayerMoney(source, amount, Config.withdrawAccount) then return false, locale('error_generic') end

    store.balance = store.balance - amount
    MySQL.update('UPDATE bcs_gunstore_stores SET balance = ? WHERE id = ?', { store.balance, storeId })

    return true, locale('withdraw_success', amount), store.balance
end)

-- --------------------------------------------------------------------
--  Admin: create / update / delete / set owner
-- --------------------------------------------------------------------
lib.callback.register('bcs_gunstore:createStore', function(source, data)
    if not hasAdmin(source) then return false, locale('no_permission') end
    if not data or not data.coords then return false, locale('error_generic') end

    local name = (data.name and data.name ~= '' and data.name:sub(1, 64)) or 'Gun Store'
    local price = tonumber(data.price) or Config.defaultStorePrice
    local coords = { x = data.coords.x + 0.0, y = data.coords.y + 0.0, z = data.coords.z + 0.0, w = (data.coords.w or 0.0) + 0.0 }
    local sprite = tonumber(data.blip_sprite) or Config.blip.sprite
    local color = tonumber(data.blip_color) or Config.blip.color
    local scale = tonumber(data.blip_scale) or Config.blip.scale
    local pedModel = (data.ped_model and data.ped_model ~= '' and data.ped_model) or Config.defaultPed

    local insertId = MySQL.insert.await(
        'INSERT INTO bcs_gunstore_stores (name, price, for_sale, coords, blip_sprite, blip_color, blip_scale, ped_model) VALUES (?, ?, 1, ?, ?, ?, ?, ?)',
        { name, price, json.encode(coords), sprite, color, scale, pedModel })

    if not insertId then return false, locale('error_generic') end

    local store = {
        id = insertId, name = name, owner = nil, owner_name = nil,
        price = price, for_sale = true, balance = 0, coords = coords,
        blip_sprite = sprite, blip_color = color, blip_scale = scale,
        ped_model = pedModel, items = {},
    }
    Stores[insertId] = store

    -- seed starter stock
    for _, entry in ipairs(Config.starterStock or {}) do
        if exports.ox_inventory:Items(entry.item) then
            store.items[entry.item] = { item = entry.item, price = entry.price or 0, stock = 0 }
            MySQL.insert('INSERT INTO bcs_gunstore_items (store_id, item, price, stock) VALUES (?, ?, ?, 0)',
                { insertId, entry.item, entry.price or 0 })
        end
    end

    registerStoreShop(store)
    syncStore(store)
    return true, locale('store_created', name), insertId
end)

lib.callback.register('bcs_gunstore:updateStore', function(source, storeId, data)
    if not hasAdmin(source) then return false, locale('no_permission') end
    local store = Stores[storeId]
    if not store then return false, locale('store_not_found') end

    if data.name and data.name ~= '' then store.name = data.name:sub(1, 64) end
    if data.price ~= nil then store.price = tonumber(data.price) or store.price end
    if data.for_sale ~= nil then store.for_sale = data.for_sale and true or false end
    if data.ped_model ~= nil then store.ped_model = (data.ped_model ~= '' and data.ped_model) or nil end
    if data.blip_sprite then store.blip_sprite = tonumber(data.blip_sprite) or store.blip_sprite end
    if data.blip_color then store.blip_color = tonumber(data.blip_color) or store.blip_color end
    if data.blip_scale then store.blip_scale = tonumber(data.blip_scale) or store.blip_scale end
    if data.coords then
        store.coords = { x = data.coords.x + 0.0, y = data.coords.y + 0.0, z = data.coords.z + 0.0, w = (data.coords.w or 0.0) + 0.0 }
    end

    MySQL.update('UPDATE bcs_gunstore_stores SET name = ?, price = ?, for_sale = ?, ped_model = ?, coords = ?, blip_sprite = ?, blip_color = ?, blip_scale = ? WHERE id = ?',
        { store.name, store.price, store.for_sale and 1 or 0, store.ped_model, json.encode(store.coords), store.blip_sprite, store.blip_color, store.blip_scale, storeId })

    registerStoreShop(store)
    syncStore(store)
    return true, locale('store_updated')
end)

lib.callback.register('bcs_gunstore:setOwner', function(source, storeId, targetId)
    if not hasAdmin(source) then return false, locale('no_permission') end
    local store = Stores[storeId]
    if not store then return false, locale('store_not_found') end

    if targetId == nil or targetId == 0 then
        -- clear ownership, put back up for sale
        store.owner = nil
        store.owner_name = nil
        store.for_sale = true
        MySQL.update('UPDATE bcs_gunstore_stores SET owner = NULL, owner_name = NULL, for_sale = 1 WHERE id = ?', { storeId })
        syncStore(store)
        return true, locale('owner_cleared')
    end

    targetId = tonumber(targetId)
    local identifier = getPlayerIdentifier(targetId)
    if not identifier then return false, locale('player_not_found') end

    store.owner = identifier
    store.owner_name = getPlayerName(targetId)
    store.for_sale = false
    MySQL.update('UPDATE bcs_gunstore_stores SET owner = ?, owner_name = ?, for_sale = 0 WHERE id = ?',
        { store.owner, store.owner_name, storeId })

    syncStore(store)
    return true, locale('owner_set', store.owner_name)
end)

lib.callback.register('bcs_gunstore:deleteStore', function(source, storeId)
    if not hasAdmin(source) then return false, locale('no_permission') end
    local store = Stores[storeId]
    if not store then return false, locale('store_not_found') end

    Stores[storeId] = nil
    MySQL.update('DELETE FROM bcs_gunstore_stores WHERE id = ?', { storeId }) -- items cascade

    syncRemove(storeId)
    return true, locale('store_deleted')
end)

-- --------------------------------------------------------------------
--  Admin: global wholesale stock prices
-- --------------------------------------------------------------------
-- The full catalogue of items an admin may price: everything currently listed in
-- any store, the starter stock, an allowedItems whitelist, plus anything already
-- priced.
lib.callback.register('bcs_gunstore:getStockPrices', function(source)
    if not hasAdmin(source) then return nil end

    local seen = {}
    local function add(itemName)
        if itemName and itemName ~= '' then seen[itemName] = true end
    end

    for _, store in pairs(Stores) do
        for itemName in pairs(store.items) do add(itemName) end
    end
    for _, entry in ipairs(Config.starterStock or {}) do add(entry.item) end
    for _, itemName in ipairs(Config.allowedItems or {}) do add(itemName) end
    for itemName in pairs(StockPrices) do add(itemName) end

    local list = {}
    for itemName in pairs(seen) do
        local oxItem = exports.ox_inventory:Items(itemName)
        list[#list + 1] = {
            item = itemName,
            label = (oxItem and oxItem.label) or itemName,
            price = stockPriceOf(itemName),
            isSet = StockPrices[itemName] ~= nil,
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return { default = Config.defaultStockPrice or 0, items = list }
end)

lib.callback.register('bcs_gunstore:setStockPrice', function(source, itemName, price)
    if not hasAdmin(source) then return false, locale('no_permission') end

    itemName = itemName and itemName:gsub('%s+', '')
    if not itemName or itemName == '' then return false, locale('invalid_item') end
    if not exports.ox_inventory:Items(itemName) then return false, locale('invalid_item') end

    price = math.max(0, math.min(tonumber(price) or 0, Config.maxItemPrice))
    StockPrices[itemName] = price

    MySQL.prepare('INSERT INTO bcs_gunstore_stock_prices (item, price) VALUES (?, ?) ON DUPLICATE KEY UPDATE price = ?',
        { itemName, price, price })

    return true, locale('stock_price_saved')
end)

-- Used by the client editor to know if the player may open it.
lib.callback.register('bcs_gunstore:isAdmin', function(source)
    return hasAdmin(source)
end)
