-- =====================================================================
--  bcs_gunstore - configuration
-- =====================================================================
Config = {}

-- Framework: 'auto' detects qbx / qb / esx automatically. Force one if needed.
Config.framework = 'auto' -- 'auto' | 'qbx' | 'qb' | 'esx'

-- Locale (must match a file in locales/, e.g. locales/en.json)
Config.locale = 'en'

-- Currency item used to pay for items inside the ox_inventory shop.
-- This must be a valid ox_inventory item (default ox_inventory cash item is 'money').
Config.currency = 'money'

-- Account used to BUY/own a store (the store price), and to receive withdrawals.
-- 'bank' is recommended for big purchases (qbx/qb use 'cash'/'bank', esx uses
-- 'money'/'bank' - 'bank' works on all). Withdrawals are paid to Config.withdrawAccount.
Config.purchaseAccount = 'bank'
Config.withdrawAccount = 'bank'

-- ------------------------- Interaction --------------------------------
-- Use ox_target for the store interaction. If false (or ox_target is not
-- running) a marker + keypress fallback is used instead.
Config.useTarget = true
Config.targetDistance = 2.0 -- ox_target interaction distance

-- Marker / keypress fallback (used when useTarget = false or ox_target missing)
Config.markerDistance = 2.0 -- how close before the prompt shows
Config.drawDistance = 25.0  -- how close before the marker renders
Config.interactKey = 38     -- control id for "E"
Config.marker = {
    type = 21,
    size = vec3(0.3, 0.3, 0.3),
    color = { r = 65, g = 105, b = 225, a = 120 },
    bobUpAndDown = false,
}

-- ------------------------- Admin / Editor -----------------------------
-- Command that opens the admin editor menu (CRUD for stores).
Config.adminCommand = 'gunstore'
-- Admin is resolved through the framework bridge (isPlayerAdmin). You can also
-- grant the ACE permission below to allow the command/editor.
Config.adminAce = 'bcs_gunstore.admin'

-- ------------------------- Store defaults -----------------------------
Config.defaultStorePrice = 50000 -- default purchase price when creating a store
Config.maxStock = 10000          -- max stock an owner can set per item
Config.maxItemPrice = 10000000   -- safety cap on item price
Config.allowResale = false       -- if true, buying an owned store pays the previous owner

-- Owner can sell their store back to the system. Refund = store price * this
-- percent (0.5 = 50% back). Paid to Config.purchaseAccount. Set to 0 to disable
-- the payout, or Config.allowOwnerSell = false to hide the option entirely.
Config.allowOwnerSell = true
Config.resellPercent = 0.5

-- How owners replenish stock.
--   false (default) -> restocking pulls the real items out of the owner's
--                      ox_inventory (they must already own the weapons/ammo).
--                      Owners cannot type an arbitrary stock number.
--   true            -> "easy mode": owners can set/restock stock numbers freely
--                      from the system (no items consumed).
-- Admins can always set stock freely regardless of this setting.
Config.RestockFromSystem = true

-- When RestockFromSystem is on, owners PAY a wholesale "stock price" per unit
-- when restocking from the system (so stock isn't free). Admins set these prices
-- per item in /gunstore -> "Stock prices" (stored in the DB, shared by all stores).
-- This default applies to any item that has no admin-set price yet. Admins always
-- restock for free. Has no effect when RestockFromSystem = false (items pulled
-- from the owner's own inventory instead).
Config.defaultStockPrice = 100      -- fallback wholesale cost per unit
Config.stockAccount = 'bank'        -- account owners pay restock costs from

-- Internal ox_inventory shop id prefix (must be unique on your server)
Config.shopPrefix = 'bcs_gunstore_'

-- Default blip for newly created stores
Config.blip = {
    sprite = 110,
    color = 2,
    scale = 0.8,
}

-- Optional ped spawned at each store (set ped_model per store, or a global default here).
-- Leave nil to disable peds entirely.
Config.defaultPed = nil -- e.g. 's_m_y_ammucity_01'

-- Optional whitelist of items an owner is allowed to stock. nil = allow any
-- valid ox_inventory item. Useful to lock a store to weapons/ammo only.
Config.allowedItems = nil
-- Example:
-- Config.allowedItems = {
--     'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_SMG', 'WEAPON_CARBINERIFLE',
--     'ammo-9', 'ammo-rifle', 'ammo-shotgun',
-- }

-- Items pre-loaded (with 0 stock) into a store when an admin creates it, so the
-- owner has a starting catalogue to set prices/stock on. Set to {} to disable.
Config.starterStock = {
    { item = 'WEAPON_PISTOL',       price = 1000 },
    { item = 'WEAPON_COMBATPISTOL', price = 1500 },
    { item = 'WEAPON_SMG',          price = 3000 },
    { item = 'WEAPON_CARBINERIFLE', price = 4000 },
    { item = 'ammo-9',              price = 5 },
    { item = 'ammo-rifle',          price = 8 },
}
