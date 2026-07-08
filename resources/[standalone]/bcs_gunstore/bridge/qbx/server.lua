-- QBX Bridge Server

if Config.framework ~= 'qbx' then return end

function getPlayerIdentifier(source)
    local Player = exports['qbx_core']:GetPlayer(source)
    if Player then return Player.PlayerData.citizenid end
    return nil
end

function isPlayerAdmin(source)
    local Player = exports['qbx_core']:GetPlayer(source)
    if Player then
        return false
    end
    return false
end

function GetPlayerMoney(source, account)
    local Player = exports['qbx_core']:GetPlayer(source)
    if Player then
        return Player.Functions.GetMoney(account or 'cash')
    end
    return 0
end

function RemovePlayerMoney(source, amount, account)
    account = account or 'cash'
    local Player = exports['qbx_core']:GetPlayer(source)
    if Player and Player.Functions.GetMoney(account) >= amount then
        Player.Functions.RemoveMoney(account, amount, 'bcs_gunstore')
        return true
    end
    return false
end

function AddPlayerMoney(source, amount, account)
    account = account or 'cash'
    local Player = exports['qbx_core']:GetPlayer(source)
    if Player then
        Player.Functions.AddMoney(account, amount, 'bcs_gunstore')
        return true
    end
    return false
end

function GetPlayerByIdentifier(identifier)
    local players = exports['qbx_core']:GetQBPlayers()
    for _, Player in pairs(players) do
        if Player.PlayerData.citizenid == identifier then
            return Player.PlayerData.source
        end
    end
    return nil
end

function GetPlayerLicense(source)
    local Player = exports['qbx_core']:GetPlayer(source)
    if Player then
        return exports['qbx_core']:GetIdentifier(source, 'license')
    end
    return nil
end

function getPlayerName(source)
    local Player = exports['qbx_core']:GetPlayer(source)
    if Player then
        local ci = Player.PlayerData.charinfo
        return ('%s %s'):format(ci.firstname, ci.lastname)
    end
    return GetPlayerName(source) or 'Unknown'
end
