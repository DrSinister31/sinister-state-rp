-- QB Bridge Server

if Config.framework ~= 'qb' then return end

QBCore = exports['qb-core']:GetCoreObject()

function getPlayerIdentifier(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then return Player.PlayerData.citizenid end
    return nil
end

function isPlayerAdmin(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.permission == 'admin' or Player.PlayerData.permission == 'god'
    end
    return false
end

function GetPlayerMoney(source, account)
    account = account or 'cash'
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.money[account] or 0
    end
    return 0
end

function RemovePlayerMoney(source, amount, account)
    account = account or 'cash'
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and (Player.PlayerData.money[account] or 0) >= amount then
        Player.Functions.RemoveMoney(account, amount, 'bcs_gunstore')
        return true
    end
    return false
end

function AddPlayerMoney(source, amount, account)
    account = account or 'cash'
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        Player.Functions.AddMoney(account, amount, 'bcs_gunstore')
        return true
    end
    return false
end

function GetPlayerByIdentifier(identifier)
    local players = QBCore.Functions.GetPlayers()
    for _, player in pairs(players) do
        local Player = QBCore.Functions.GetPlayer(player)
        if Player and Player.PlayerData.citizenid == identifier then
            return player
        end
    end
    return nil
end

function GetPlayerLicense(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return QBCore.Functions.GetIdentifier(source, 'license')
    end
    return nil
end

function getPlayerName(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local ci = Player.PlayerData.charinfo
        return ('%s %s'):format(ci.firstname, ci.lastname)
    end
    return GetPlayerName(source) or 'Unknown'
end
