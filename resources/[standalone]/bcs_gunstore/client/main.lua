-- =====================================================================
--  bcs_gunstore - client
-- =====================================================================
local stores  = {}   -- [id] = public store data
local blips   = {}   -- [id] = blip handle
local peds    = {}   -- [id] = ped handle
local zones   = {}   -- [id] = ox_target zone id
local useTarget = false
local placing = false

-- --------------------------------------------------------------------
--  Helpers
-- --------------------------------------------------------------------
local function fmtMoney(amount)
    local formatted = tostring(math.floor(amount or 0))
    while true do
        local k
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return '$' .. formatted
end

local function notify(msg, type)
    lib.notify({ description = msg, type = type or 'inform' })
end

-- --------------------------------------------------------------------
--  Raycast placement preview (used for creating / moving a store)
-- --------------------------------------------------------------------
local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vec3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

-- Ray from the gameplay camera onto the map (flag 17 = world + objects, so
-- peds/vehicles, incl. the player and the preview ped, are ignored).
local function camRaycast(dist)
    local from = GetGameplayCamCoord()
    local dir = rotationToDirection(GetGameplayCamRot(2))
    local to = from + dir * dist
    local handle = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, 17, PlayerPedId(), 4)
    local _, hit, coords = GetShapeTestResult(handle)
    if hit == 1 then return coords end
    return to -- no surface hit: point at max range
end

-- Live preview at the crosshair. Returns { x, y, z, w } on confirm, nil on cancel.
-- If pedModel given, a transparent ped is shown; otherwise a ground marker.
local function previewPlacement(pedModel)
    if placing then return nil end
    placing = true

    local heading = GetEntityHeading(PlayerPedId())
    local model
    if pedModel and pedModel ~= '' then
        model = joaat(pedModel)
        if not lib.requestModel(model, 10000) then model = nil end
    end

    local previewPed
    lib.showTextUI(locale('placement_help'), { position = 'top-center' })

    local result
    while true do
        local coords = camRaycast(50.0)

        if model then
            if not previewPed then
                previewPed = CreatePed(0, model, coords.x, coords.y, coords.z, heading, false, false)
                SetEntityAlpha(previewPed, 150, false)
                SetEntityCollision(previewPed, false, false)
                FreezeEntityPosition(previewPed, true)
                SetEntityInvincible(previewPed, true)
                SetModelAsNoLongerNeeded(model)
            end
            SetEntityCoordsNoOffset(previewPed, coords.x, coords.y, coords.z, false, false, false)
            SetEntityHeading(previewPed, heading)
        else
            local r = (Config.targetDistance or 1.0) * 2.0
            -- ground cylinder = the interaction radius, plus a chevron above the hit
            DrawMarker(1, coords.x, coords.y, coords.z - 0.95, 0, 0, 0, 0, 0, 0,
                r, r, 1.0, 0, 200, 100, 120, false, false, 2, false, nil, nil, false)
            DrawMarker(Config.marker.type, coords.x, coords.y, coords.z + 0.75, 0, 0, 0, 0, 0, 0,
                Config.marker.size.x, Config.marker.size.y, Config.marker.size.z,
                0, 200, 100, 200, true, true, 2, false, nil, nil, false)
        end

        -- Rotate: arrow keys held, or mouse wheel stepped.
        DisableControlAction(0, 14, true) -- INPUT_WEAPON_WHEEL_NEXT
        DisableControlAction(0, 15, true) -- INPUT_WEAPON_WHEEL_PREV
        if IsControlPressed(0, 174) then heading = (heading + 2.0) % 360 end       -- left arrow
        if IsControlPressed(0, 175) then heading = (heading - 2.0) % 360 end       -- right arrow
        if IsDisabledControlJustPressed(0, 15) then heading = (heading + 15.0) % 360 end
        if IsDisabledControlJustPressed(0, 14) then heading = (heading - 15.0) % 360 end

        if IsControlJustReleased(0, 38) then            -- E = confirm
            result = { x = coords.x, y = coords.y, z = coords.z, w = heading }
            break
        elseif IsControlJustReleased(0, 177) then       -- Backspace = cancel
            break
        end

        Wait(0)
    end

    lib.hideTextUI()
    if previewPed then DeleteEntity(previewPed) end
    placing = false
    return result
end

-- --------------------------------------------------------------------
--  Entity creation (blip / ped / target)
-- --------------------------------------------------------------------
local function createBlip(store)
    local c = store.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, store.blip_sprite or 110)
    SetBlipColour(blip, store.blip_color or 2)
    SetBlipScale(blip, (store.blip_scale or 0.8) + 0.0)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(store.name or 'Gun Store')
    EndTextCommandSetBlipName(blip)
    blips[store.id] = blip
end

local function createPed(store)
    if not store.ped_model then return end
    CreateThread(function()
        local model = joaat(store.ped_model)
        lib.requestModel(model, 10000)
        local c = store.coords
        local ped = CreatePed(0, model, c.x, c.y, c.z, c.w or 0.0, false, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetModelAsNoLongerNeeded(model)
        peds[store.id] = ped

        -- When targeting is on, the ped itself is the interaction point.
        if useTarget then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'bcs_gunstore_' .. store.id,
                    icon = 'fas fa-gun',
                    label = store.name,
                    distance = Config.targetDistance,
                    onSelect = function() OpenStoreMenu(store.id) end,
                },
            })
        end
    end)
end

local function createTarget(store)
    if not useTarget then return end
    if store.ped_model then return end  -- ped carries its own target (see createPed)
    local c = store.coords
    zones[store.id] = exports.ox_target:addSphereZone({
        coords = vec3(c.x, c.y, c.z),
        radius = Config.targetDistance,
        debug = false,
        options = {
            {
                name = 'bcs_gunstore_' .. store.id,
                icon = 'fas fa-gun',
                label = store.name,
                distance = Config.targetDistance,
                onSelect = function() OpenStoreMenu(store.id) end,
            },
        },
    })
end

local function createStoreEntities(store)
    createBlip(store)
    createPed(store)
    createTarget(store)
end

local function destroyStoreEntities(id)
    if blips[id] then RemoveBlip(blips[id]); blips[id] = nil end
    if peds[id] then
        if useTarget then exports.ox_target:removeLocalEntity(peds[id]) end
        DeleteEntity(peds[id]); peds[id] = nil
    end
    if zones[id] and useTarget then exports.ox_target:removeZone(zones[id]); zones[id] = nil end
end

local function refreshStore(id)
    destroyStoreEntities(id)
    if stores[id] then createStoreEntities(stores[id]) end
end

-- --------------------------------------------------------------------
--  Marker / keypress fallback (when ox_target is disabled/unavailable)
-- --------------------------------------------------------------------
local function startMarkerThread()
    CreateThread(function()
        local textShown = false
        while true do
            local sleep = 1000
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            local nearId

            for id, store in pairs(stores) do
                local c = store.coords
                local dist = #(pcoords - vec3(c.x, c.y, c.z))
                if dist < Config.drawDistance then
                    sleep = 0
                    DrawMarker(Config.marker.type, c.x, c.y, c.z - 0.95, 0, 0, 0, 0, 0, 0,
                        Config.marker.size.x, Config.marker.size.y, Config.marker.size.z,
                        Config.marker.color.r, Config.marker.color.g, Config.marker.color.b, Config.marker.color.a,
                        Config.marker.bobUpAndDown, false, 2, false, nil, nil, false)
                    if dist < Config.markerDistance then nearId = id end
                end
            end

            if nearId then
                if not textShown then
                    lib.showTextUI(('[E] %s'):format(stores[nearId].name), { position = 'right-center' })
                    textShown = true
                end
                if IsControlJustReleased(0, Config.interactKey) then
                    OpenStoreMenu(nearId)
                end
            elseif textShown then
                lib.hideTextUI()
                textShown = false
            end

            Wait(sleep)
        end
    end)
end

-- --------------------------------------------------------------------
--  Owner / admin: manage menus
-- --------------------------------------------------------------------
local function withdrawBalance(storeId)
    local input = lib.inputDialog(locale('manage_withdraw'), {
        { type = 'number', label = locale('input_amount'), min = 1, required = true },
    })
    if not input then return end
    local ok, msg, balance = lib.callback.await('bcs_gunstore:withdraw', false, storeId, input[1])
    notify(msg, ok and 'success' or 'error')
    if ok then OpenManageMenu(storeId) end
end

local function editStoreInfo(storeId, data)
    local input = lib.inputDialog(locale('manage_edit_info'), {
        { type = 'input',  label = locale('input_name'),        default = data.name, required = true, max = 64 },
        { type = 'number', label = locale('input_blip_sprite'), default = data.blip_sprite },
        { type = 'number', label = locale('input_blip_color'),  default = data.blip_color },
        { type = 'number', label = locale('input_blip_scale'),  default = data.blip_scale, step = 0.1 },
    })
    if not input then return end
    local ok, msg = lib.callback.await('bcs_gunstore:setStoreInfo', false, storeId, {
        name = input[1], blip_sprite = input[2], blip_color = input[3], blip_scale = input[4],
    })
    notify(msg, ok and 'success' or 'error')
    if ok then OpenManageMenu(storeId) end
end

-- Price/stock dialog for a known item (item identity comes from selection or an
-- existing listing - owners never type item names).
local function editItem(storeId, freeStock, itemName, label, existing)
    local fields = {
        { type = 'number', label = locale('input_price'), default = existing and existing.price or 0, min = 0, required = true },
    }
    -- Only allow typing a stock number when free (system) stocking is enabled.
    if freeStock then
        fields[#fields + 1] = { type = 'number', label = locale('input_stock'), default = existing and existing.stock or 0, min = 0, required = true }
    end

    local input = lib.inputDialog(('%s — %s'):format(existing and locale('manage_edit_item') or locale('manage_add_item'), label or itemName), fields)
    if not input then return end

    local ok, msg = lib.callback.await('bcs_gunstore:setItem', false, storeId, itemName, input[1], input[2])
    notify(msg, ok and 'success' or 'error')
    if ok then OpenStockMenu(storeId) end
end

-- Free-stock users (admins / RestockFromSystem) may also type an item by name,
-- so they can list items they aren't personally carrying.
local function manualAddItem(storeId, freeStock)
    local fields = {
        { type = 'input',  label = locale('input_item'),  required = true },
        { type = 'number', label = locale('input_price'), default = 0, min = 0, required = true },
    }
    if freeStock then
        fields[#fields + 1] = { type = 'number', label = locale('input_stock'), default = 0, min = 0, required = true }
    end

    local input = lib.inputDialog(locale('manage_add_item'), fields)
    if not input then return end

    local ok, msg = lib.callback.await('bcs_gunstore:setItem', false, storeId, input[1], input[2], input[3])
    notify(msg, ok and 'success' or 'error')
    if ok then OpenStockMenu(storeId) end
end

-- Pick a weapon/ammo from the player's own inventory to list in the store.
local function addItemFromInventory(storeId, freeStock)
    local list = lib.callback.await('bcs_gunstore:getInventoryItems', false, storeId)
    if not list then return notify(locale('no_permission'), 'error') end

    local options = {}
    if freeStock then
        options[#options + 1] = { title = locale('manual_add'), description = locale('manual_add_desc'), icon = 'keyboard',
            onSelect = function() manualAddItem(storeId, freeStock) end }
    end
    if #list == 0 and not freeStock then return notify(locale('no_sellable_items'), 'error') end
    for _, entry in ipairs(list) do
        options[#options + 1] = {
            title = entry.label,
            description = locale('inv_count', entry.count) .. (entry.inStore and (' • ' .. locale('already_listed')) or ''),
            onSelect = function()
                editItem(storeId, freeStock, entry.item, entry.label, entry.inStore and { price = entry.price, stock = entry.stock } or nil)
            end,
        }
    end

    lib.registerContext({
        id = 'bcs_gunstore_invpick',
        title = locale('manage_add_item'),
        menu = 'bcs_gunstore_stock',
        options = options,
    })
    lib.showContext('bcs_gunstore_invpick')
end

local function itemActions(storeId, freeStock, item, payForStock)
    local restockDesc = not freeStock and locale('restock_from_inv_desc')
        or (payForStock and locale('restock_cost_desc', fmtMoney(item.stockPrice or 0)) or nil)

    lib.registerContext({
        id = 'bcs_gunstore_item',
        title = item.label or item.item,
        menu = 'bcs_gunstore_stock',
        options = {
            { title = locale('item_edit'),    description = ('%s | %s'):format(fmtMoney(item.price), locale('stock_label', item.stock)),
              icon = 'pen', onSelect = function() editItem(storeId, freeStock, item.item, item.label, item) end },
            { title = locale('item_restock'), description = restockDesc, icon = 'boxes-stacked', onSelect = function()
                local input = lib.inputDialog(locale('item_restock'), {
                    { type = 'number', label = locale('input_amount'), description = restockDesc, min = 1, required = true },
                })
                if not input then return end
                local ok, msg = lib.callback.await('bcs_gunstore:restockItem', false, storeId, item.item, input[1])
                notify(msg, ok and 'success' or 'error')
                OpenStockMenu(storeId)
            end },
            { title = locale('item_remove'), icon = 'trash', onSelect = function()
                local ok, msg = lib.callback.await('bcs_gunstore:removeItem', false, storeId, item.item)
                notify(msg, ok and 'success' or 'error')
                OpenStockMenu(storeId)
            end },
        },
    })
    lib.showContext('bcs_gunstore_item')
end

function OpenStockMenu(storeId)
    local data = lib.callback.await('bcs_gunstore:getManageData', false, storeId)
    if not data then return notify(locale('no_permission'), 'error') end

    local freeStock = data.freeStock
    local payForStock = data.payForStock
    local options = {
        { title = locale('manage_add_item'), description = locale('manage_add_item_desc'), icon = 'plus',
          onSelect = function() addItemFromInventory(storeId, freeStock) end },
    }
    for _, item in ipairs(data.items) do
        options[#options + 1] = {
            title = item.label or item.item,
            description = ('%s | %s'):format(fmtMoney(item.price), locale('stock_label', item.stock)),
            onSelect = function() itemActions(storeId, freeStock, item, payForStock) end,
        }
    end

    lib.registerContext({
        id = 'bcs_gunstore_stock',
        title = locale('manage_stock'),
        menu = 'bcs_gunstore_manage',
        options = options,
    })
    lib.showContext('bcs_gunstore_stock')
end

function OpenManageMenu(storeId)
    local data = lib.callback.await('bcs_gunstore:getManageData', false, storeId)
    if not data then return notify(locale('no_permission'), 'error') end

    local options = {
        { title = locale('manage_stock'),    description = locale('manage_stock_desc'),    icon = 'warehouse',
          onSelect = function() OpenStockMenu(storeId) end },
        { title = locale('manage_edit_info'), description = locale('manage_edit_info_desc'), icon = 'pen-to-square',
          onSelect = function() editStoreInfo(storeId, data) end },
        { title = locale('manage_balance', fmtMoney(data.balance)), description = locale('manage_withdraw_desc'), icon = 'sack-dollar',
          onSelect = function() withdrawBalance(storeId) end },
    }

    if data.canSell then
        options[#options + 1] = {
            title = locale('manage_sell', fmtMoney(data.resellValue)),
            description = locale('manage_sell_desc'),
            icon = 'building-circle-xmark', iconColor = 'red',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = locale('manage_sell_title'),
                    content = locale('manage_sell_confirm', data.name, fmtMoney(data.resellValue)),
                    centered = true, cancel = true,
                })
                if confirm ~= 'confirm' then return end
                local ok, msg = lib.callback.await('bcs_gunstore:sellStore', false, storeId)
                notify(msg, ok and 'success' or 'error')
            end,
        }
    end

    lib.registerContext({
        id = 'bcs_gunstore_manage',
        title = locale('manage_title', data.name),
        options = options,
    })
    lib.showContext('bcs_gunstore_manage')
end

-- --------------------------------------------------------------------
--  Admin: per-store edit menu
-- --------------------------------------------------------------------
function OpenAdminStoreMenu(storeId)
    local store = stores[storeId]
    if not store then return end

    lib.registerContext({
        id = 'bcs_gunstore_admin_store',
        title = locale('admin_edit_title', store.name),
        options = {
            { title = locale('admin_edit_settings'), icon = 'sliders', onSelect = function()
                local input = lib.inputDialog(locale('admin_edit_settings'), {
                    { type = 'input',   label = locale('input_name'),  default = store.name, required = true, max = 64 },
                    { type = 'number',  label = locale('input_price'), default = store.price, min = 0 },
                    { type = 'checkbox', label = locale('input_for_sale'), checked = store.for_sale },
                    { type = 'input',   label = locale('input_ped_model'), description = locale('input_ped_model_desc'), default = store.ped_model },
                    { type = 'number',  label = locale('input_blip_sprite'), default = store.blip_sprite },
                    { type = 'number',  label = locale('input_blip_color'),  default = store.blip_color },
                    { type = 'number',  label = locale('input_blip_scale'),  default = store.blip_scale, step = 0.1 },
                })
                if not input then return end
                local ok, msg = lib.callback.await('bcs_gunstore:updateStore', false, storeId, {
                    name = input[1], price = input[2], for_sale = input[3],
                    ped_model = input[4] or '',
                    blip_sprite = input[5], blip_color = input[6], blip_scale = input[7],
                })
                notify(msg, ok and 'success' or 'error')
            end },
            { title = locale('admin_manage_stock'), icon = 'warehouse', onSelect = function() OpenStockMenu(storeId) end },
            { title = locale('admin_move'), icon = 'location-dot', onSelect = function()
                local coords = previewPlacement(store.ped_model)
                if not coords then return notify(locale('placement_cancelled'), 'inform') end
                local ok, msg = lib.callback.await('bcs_gunstore:updateStore', false, storeId, {
                    coords = coords,
                })
                notify(msg, ok and 'success' or 'error')
            end },
            { title = locale('admin_set_owner'), icon = 'user-tag', onSelect = function()
                local input = lib.inputDialog(locale('admin_set_owner'), {
                    { type = 'number', label = locale('input_server_id'), description = locale('input_server_id_desc'), required = true },
                })
                if not input then return end
                local ok, msg = lib.callback.await('bcs_gunstore:setOwner', false, storeId, input[1])
                notify(msg, ok and 'success' or 'error')
            end },
            { title = locale('admin_clear_owner'), icon = 'user-slash', onSelect = function()
                local ok, msg = lib.callback.await('bcs_gunstore:setOwner', false, storeId, 0)
                notify(msg, ok and 'success' or 'error')
            end },
            { title = locale('admin_delete'), icon = 'trash', iconColor = 'red', onSelect = function()
                local confirm = lib.alertDialog({
                    header = locale('admin_delete'),
                    content = locale('admin_delete_confirm', store.name),
                    centered = true, cancel = true,
                })
                if confirm ~= 'confirm' then return end
                local ok, msg = lib.callback.await('bcs_gunstore:deleteStore', false, storeId)
                notify(msg, ok and 'success' or 'error')
            end },
        },
    })
    lib.showContext('bcs_gunstore_admin_store')
end

local function openAdminList()
    local options = {}
    for id, store in pairs(stores) do
        options[#options + 1] = {
            title = store.name,
            description = store.owner_name and locale('owner_label', store.owner_name) or locale('unowned'),
            onSelect = function() OpenAdminStoreMenu(id) end,
        }
    end
    if #options == 0 then
        options[1] = { title = locale('admin_no_stores'), disabled = true }
    end
    lib.registerContext({ id = 'bcs_gunstore_admin_list', title = locale('admin_list_title'), menu = 'bcs_gunstore_admin', options = options })
    lib.showContext('bcs_gunstore_admin_list')
end

-- --------------------------------------------------------------------
--  Admin: placement editor (create a new store)
-- --------------------------------------------------------------------
-- Ask for store details first (so the ped model is known), then place it live
-- with the raycast preview.
local function startPlacement()
    if placing then return end

    local input = lib.inputDialog(locale('admin_create'), {
        { type = 'input',  label = locale('input_name'),  default = 'Gun Store', required = true, max = 64 },
        { type = 'number', label = locale('input_price'), default = Config.defaultStorePrice, min = 0 },
        { type = 'number', label = locale('input_blip_sprite'), default = Config.blip.sprite },
        { type = 'number', label = locale('input_blip_color'),  default = Config.blip.color },
        { type = 'number', label = locale('input_blip_scale'),  default = Config.blip.scale, step = 0.1 },
        { type = 'input',  label = locale('input_ped_model'), description = locale('input_ped_model_desc') },
    })
    if not input then return end

    local coords = previewPlacement(input[6])
    if not coords then return notify(locale('placement_cancelled'), 'inform') end

    local ok, msg = lib.callback.await('bcs_gunstore:createStore', false, {
        name = input[1], price = input[2], coords = coords,
        blip_sprite = input[3], blip_color = input[4], blip_scale = input[5],
        ped_model = input[6],
    })
    notify(msg, ok and 'success' or 'error')
end

-- --------------------------------------------------------------------
--  Admin: global wholesale stock prices
-- --------------------------------------------------------------------
local function openStockPriceMenu()
    local data = lib.callback.await('bcs_gunstore:getStockPrices', false)
    if not data then return notify(locale('no_permission'), 'error') end

    local options = {}
    for _, entry in ipairs(data.items) do
        options[#options + 1] = {
            title = entry.label,
            description = locale('stock_price_label', fmtMoney(entry.price))
                .. (entry.isSet and '' or (' • ' .. locale('stock_price_default'))),
            icon = 'tag',
            onSelect = function()
                local input = lib.inputDialog(entry.label, {
                    { type = 'number', label = locale('input_stock_price'), description = locale('input_stock_price_desc'),
                      default = entry.price, min = 0, required = true },
                })
                if not input then return end
                local ok, msg = lib.callback.await('bcs_gunstore:setStockPrice', false, entry.item, input[1])
                notify(msg, ok and 'success' or 'error')
                openStockPriceMenu()
            end,
        }
    end
    if #options == 0 then
        options[1] = { title = locale('stock_price_none'), disabled = true }
    end

    lib.registerContext({
        id = 'bcs_gunstore_stock_prices',
        title = locale('admin_stock_prices'),
        menu = 'bcs_gunstore_admin',
        options = options,
    })
    lib.showContext('bcs_gunstore_stock_prices')
end

local function openAdminMenu()
    lib.registerContext({
        id = 'bcs_gunstore_admin',
        title = locale('admin_menu_title'),
        options = {
            { title = locale('admin_create'), description = locale('admin_create_desc'), icon = 'plus', onSelect = startPlacement },
            { title = locale('admin_list_title'), description = locale('admin_list_desc'), icon = 'list', onSelect = openAdminList },
            { title = locale('admin_stock_prices'), description = locale('admin_stock_prices_desc'), icon = 'tags', onSelect = openStockPriceMenu },
        },
    })
    lib.showContext('bcs_gunstore_admin')
end

-- --------------------------------------------------------------------
--  Main interaction menu (shown when interacting with a store)
-- --------------------------------------------------------------------
function OpenStoreMenu(storeId)
    local ctx = lib.callback.await('bcs_gunstore:getStoreContext', false, storeId)
    if not ctx then return end

    local options = {
        { title = locale('menu_browse'), description = locale('menu_browse_desc'), icon = 'magnifying-glass',
          onSelect = function() exports.ox_inventory:openInventory('shop', { type = GetShopType(storeId) }) end },
    }

    if ctx.for_sale then
        options[#options + 1] = {
            title = locale('menu_buy_store', fmtMoney(ctx.price)),
            description = locale('menu_buy_store_desc'),
            icon = 'cart-shopping',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = locale('menu_buy_store_title'),
                    content = locale('menu_buy_store_confirm', ctx.name, fmtMoney(ctx.price)),
                    centered = true, cancel = true,
                })
                if confirm ~= 'confirm' then return end
                local ok, msg = lib.callback.await('bcs_gunstore:buyStore', false, storeId)
                notify(msg, ok and 'success' or 'error')
            end,
        }
    end

    if ctx.canManage then
        options[#options + 1] = { title = locale('menu_manage'), description = locale('menu_manage_desc'), icon = 'user-gear',
            onSelect = function() OpenManageMenu(storeId) end }
    end

    if ctx.isAdmin then
        options[#options + 1] = { title = locale('menu_admin_edit'), description = locale('menu_admin_edit_desc'), icon = 'screwdriver-wrench',
            onSelect = function() OpenAdminStoreMenu(storeId) end }
    end

    local title = ctx.name
    if ctx.owner_name then
        title = ('%s — %s'):format(ctx.name, locale('owner_label', ctx.owner_name))
    end

    lib.registerContext({ id = 'bcs_gunstore_main', title = title, options = options })
    lib.showContext('bcs_gunstore_main')
end

-- --------------------------------------------------------------------
--  Net sync
-- --------------------------------------------------------------------
RegisterNetEvent('bcs_gunstore:syncStore', function(store)
    stores[store.id] = store
    refreshStore(store.id)
end)

RegisterNetEvent('bcs_gunstore:removeStore', function(id)
    destroyStoreEntities(id)
    stores[id] = nil
end)

-- --------------------------------------------------------------------
--  Command + bootstrap
-- --------------------------------------------------------------------
RegisterCommand(Config.adminCommand, function()
    local isAdmin = lib.callback.await('bcs_gunstore:isAdmin', false)
    if not isAdmin then return notify(locale('no_permission'), 'error') end
    openAdminMenu()
end, false)

CreateThread(function()
    useTarget = Config.useTarget and GetResourceState('ox_target') == 'started'

    local list = lib.callback.await('bcs_gunstore:getStores', false) or {}
    for _, store in ipairs(list) do
        stores[store.id] = store
        createStoreEntities(store)
    end

    if not useTarget then
        startMarkerThread()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(stores) do
        destroyStoreEntities(id)
    end
end)
