local QBCore = exports['qbx_core']:GetCoreObject()
local storeOpen = false
local pendingCount = 0

local cart = {}

local function loadCart()
    local saved = GetResourceKvpString('sinister_store_cart')
    if saved then
        cart = json.decode(saved) or {}
    else
        cart = {}
    end
end

local function saveCart()
    SetResourceKvp('sinister_store_cart', json.encode(cart))
end

local function addToCart(name, price, category)
    if not cart[name] then
        cart[name] = { name = name, price = price, category = category, quantity = 1 }
    else
        cart[name].quantity = cart[name].quantity + 1
    end
    saveCart()
end

local function removeFromCart(name)
    cart[name] = nil
    saveCart()
end

local function clearCart()
    cart = {}
    saveCart()
end

local function getCartTotal()
    local total = 0
    for _, item in pairs(cart) do
        total = total + (item.price * item.quantity)
    end
    return total
end

local function getCartItems()
    local items = {}
    for _, item in pairs(cart) do
        items[#items + 1] = item
    end
    return items
end

RegisterNetEvent('sinister_store:client:openStore', function(packages, categories, playerInfo)
    SetNuiFocus(true, true)
    storeOpen = true
    SendNUIMessage({
        action = 'openStore',
        packages = packages,
        categories = categories,
        playerInfo = playerInfo,
        cart = getCartItems(),
        theme = Config.Theme,
        storeName = Config.StoreName,
        currency = Config.Currency,
    })
end)

RegisterNetEvent('sinister_store:client:purchaseQueued', function(data)
    SendNUIMessage({
        action = 'purchaseQueued',
        data = data,
    })
end)

RegisterNetEvent('sinister_store:client:pendingCount', function(count)
    pendingCount = count
    SendNUIMessage({
        action = 'pendingCount',
        count = count,
    })
end)

RegisterNetEvent('sinister_store:client:redeemResult', function(data)
    local newCount = pendingCount - (data.redeemed or 0)
    if newCount < 0 then newCount = 0 end
    pendingCount = newCount
    SendNUIMessage({
        action = 'redeemResult',
        data = data,
        count = newCount,
    })
end)

RegisterNetEvent('sinister_store:client:playerInfo', function(playerInfo)
    SendNUIMessage({
        action = 'playerInfo',
        playerInfo = playerInfo,
    })
end)

RegisterNUICallback('closeStore', function(data, cb)
    SetNuiFocus(false, false)
    storeOpen = false
    cb('ok')
end)

RegisterNUICallback('getPlayerInfo', function(data, cb)
    TriggerServerEvent('sinister_store:server:getPlayerInfo')
    cb('ok')
end)

RegisterNUICallback('purchaseRequest', function(data, cb)
    if not data or not data.packageName then
        cb(json.encode({ success = false, message = "Invalid request" }))
        return
    end
    TriggerServerEvent('sinister_store:server:requestPurchase', data.packageName, data)
    cb(json.encode({ success = true, message = "Purchase queued" }))
end)

RegisterNUICallback('redeemPurchases', function(data, cb)
    TriggerServerEvent('sinister_store:server:redeemPurchases')
    cb('ok')
end)

RegisterNUICallback('checkPending', function(data, cb)
    TriggerServerEvent('sinister_store:server:checkPending')
    cb('ok')
end)

RegisterNUICallback('addToCart', function(data, cb)
    if not data or not data.name then
        cb(json.encode({ success = false }))
        return
    end
    addToCart(data.name, data.price or 0, data.category or "unknown")
    SendNUIMessage({
        action = 'cartUpdated',
        cart = getCartItems(),
        total = getCartTotal(),
    })
    cb(json.encode({ success = true }))
end)

RegisterNUICallback('removeFromCart', function(data, cb)
    if not data or not data.name then
        cb(json.encode({ success = false }))
        return
    end
    removeFromCart(data.name)
    SendNUIMessage({
        action = 'cartUpdated',
        cart = getCartItems(),
        total = getCartTotal(),
    })
    cb(json.encode({ success = true }))
end)

RegisterNUICallback('clearCart', function(data, cb)
    clearCart()
    SendNUIMessage({
        action = 'cartUpdated',
        cart = getCartItems(),
        total = 0,
    })
    cb(json.encode({ success = true }))
end)

RegisterNUICallback('getCart', function(data, cb)
    cb(json.encode({ cart = getCartItems(), total = getCartTotal() }))
end)

RegisterNUICallback('checkout', function(data, cb)
    local cartItems = getCartItems()
    if #cartItems == 0 then
        cb(json.encode({ success = false, message = "Cart is empty" }))
        return
    end
    for _, item in ipairs(cartItems) do
        TriggerServerEvent('sinister_store:server:requestPurchase', item.name, item)
    end
    clearCart()
    SendNUIMessage({
        action = 'cartUpdated',
        cart = {},
        total = 0,
    })
    cb(json.encode({ success = true, message = "Checkout complete!" }))
end)

RegisterKeyMapping('buy', 'Open Sinister Store', 'keyboard', 'F6')

RegisterCommand(Config.Commands.openStore, function()
    TriggerServerEvent('sinister_store:server:openStore')
end)

CreateThread(function()
    loadCart()
    TriggerServerEvent('sinister_store:server:checkPending')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadCart()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if storeOpen then
            SetNuiFocus(false, false)
            storeOpen = false
        end
    end
end)
