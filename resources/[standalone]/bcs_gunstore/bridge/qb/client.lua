-- QB Bridge Client
if Config.framework ~= 'qb' then return end

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

local function getPlayerIdentifier()
    return PlayerData.citizenid
end

_G.Framework = {
    GetPlayerIdentifier = getPlayerIdentifier
}
