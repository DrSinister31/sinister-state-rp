-- ESX Bridge Server

if Config.framework ~= 'esx' then return end

ESX = exports['es_extended']:getSharedObject()

function getPlayerIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then return xPlayer.identifier end
    return nil
end

function isPlayerAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.getGroup() == 'admin'
    end
    return false
end

local function isCashAccount(account)
    return account == nil or account == 'cash' or account == 'money'
end

function GetPlayerMoney(source, account)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    if isCashAccount(account) then return xPlayer.getMoney() end
    local acc = xPlayer.getAccount(account)
    return acc and acc.money or 0
end

function RemovePlayerMoney(source, amount, account)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    if isCashAccount(account) then
        if xPlayer.getMoney() >= amount then
            xPlayer.removeMoney(amount)
            return true
        end
        return false
    end
    local acc = xPlayer.getAccount(account)
    if acc and acc.money >= amount then
        xPlayer.removeAccountMoney(account, amount)
        return true
    end
    return false
end

function AddPlayerMoney(source, amount, account)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    if isCashAccount(account) then
        xPlayer.addMoney(amount)
    else
        xPlayer.addAccountMoney(account, amount)
    end
    return true
end

function GetPlayerByIdentifier(identifier)
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and xPlayer.identifier == identifier then
            return playerId
        end
    end
    return nil
end

function GetPlayerLicense(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        for _, identifier in pairs(GetPlayerIdentifiers(source)) do
            if identifier:sub(1, 8) == "license:" then
                return identifier
            end
        end
    end
    return nil
end

function getPlayerName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.getName()
    end
    return GetPlayerName(source) or 'Unknown'
end
