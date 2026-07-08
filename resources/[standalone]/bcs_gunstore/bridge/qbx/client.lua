-- QBX Bridge Client
if Config.framework ~= 'qbx' then return end
QBX = exports['qbx_core']

while QBX:GetPlayerData().job == nil do
    Wait(100)
end

PlayerData = QBX:GetPlayerData()

RegisterNetEvent('QBX:Client:OnPlayerLoaded', function()
    PlayerData = QBX:GetPlayerData()
end)

RegisterNetEvent('QBX:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

local function getPlayerIdentifier()
    return PlayerData.citizenid
end

_G.Framework = {
    GetPlayerIdentifier = getPlayerIdentifier
}
