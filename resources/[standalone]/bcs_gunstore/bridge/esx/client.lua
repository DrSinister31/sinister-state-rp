-- ESX Bridge Client
if Config.framework ~= 'esx' then return end

local ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
end)

local function getPlayerIdentifier()
    return PlayerData.identifier
end

_G.Framework = {
    GetPlayerIdentifier = getPlayerIdentifier
}
