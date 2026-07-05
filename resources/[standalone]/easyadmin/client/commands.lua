-- ============================================================================
--  EasyAdmin — Client Commands
--  Sinister H-Town RP
-- ============================================================================

local isGuiOpen = false
local reportUiOpen = false

-- ============================================================================
--  /admin — Opens the EasyAdmin panel
-- ============================================================================
RegisterCommand(Config.Commands.admin:gsub("/", ""), function()
    TriggerServerEvent("easyadmin:server:openGui")
end, false)

RegisterKeyMapping(Config.Commands.admin:gsub("/", ""), "Open EasyAdmin Panel", "keyboard", Config.OpenKey)

-- ============================================================================
--  /report [id] [message] — Opens report UI or submits directly
-- ============================================================================
RegisterCommand(Config.Commands.report:gsub("/", ""), function(source, args, rawCommand)
    if #args < 2 then
        -- Open report UI
        reportUiOpen = true
        SetNuiFocus(true, true)
        local players = {}
        for _, pid in ipairs(GetActivePlayers()) do
            local serverId = GetPlayerServerId(pid)
            if serverId > 0 then
                players[#players + 1] = {
                    id = serverId,
                    name = GetPlayerName(pid)
                }
            end
        end
        SendNUIMessage({
            action = "openReportUi",
            players = players,
            categories = Config.Reports.categories
        })
    else
        -- Direct report via chat
        local targetId = tonumber(args[1])
        local message = ""
        for i = 2, #args do
            message = message .. args[i] .. " "
        end
        message = message:gsub("^%s*(.-)%s*$", "%1")
        TriggerServerEvent("easyadmin:server:chatReport", targetId, message)
    end
end, false)

-- ============================================================================
--  NUI Callbacks for Report UI
-- ============================================================================

RegisterNUICallback("submitReport", function(data, cb)
    local targetId = tonumber(data.targetId)
    local message = data.message or ""
    local category = data.category or "Other"

    if targetId and #message >= Config.Reports.minMessageLength then
        TriggerServerEvent("easyadmin:server:chatReport", targetId, message)
        reportUiOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "closeReportUi" })
    end
    cb("ok")
end)

RegisterNUICallback("closeReportUi", function(data, cb)
    reportUiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeReportUi" })
    cb("ok")
end)

-- ============================================================================
--  Notification System
-- ============================================================================

RegisterNetEvent("easyadmin:notify", function(message, notifyType)
    notifyType = notifyType or "info"
    SendNUIMessage({
        action = "notify",
        message = message,
        type = notifyType
    })
end)

-- ============================================================================
--  Quick Noclip Toggle via /noclip command
-- ============================================================================

RegisterCommand("noclip", function()
    TriggerServerEvent("easyadmin:server:noclip")
end, false)

-- ============================================================================
--  Quick Heal Self
-- ============================================================================

RegisterCommand("healme", function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    SendNUIMessage({
        action = "notify",
        message = "You have been healed.",
        type = "success"
    })
end, false)

-- ============================================================================
--  Quick Revive Self
-- ============================================================================

RegisterCommand("reviveme", function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, 0.0, true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    SendNUIMessage({
        action = "notify",
        message = "You have been revived.",
        type = "success"
    })
end, false)

-- ============================================================================
--  Kill Self (for testing respawn)
-- ============================================================================

RegisterCommand("killme", function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
end, false)

-- ============================================================================
--  Copy Current Coords
-- ============================================================================

RegisterCommand("coords", function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local str = string.format("vec3(%.2f, %.2f, %.2f) h: %.2f", coords.x, coords.y, coords.z, heading)
    SendNUIMessage({
        action = "copyToClipboard",
        text = str
    })
    SendNUIMessage({
        action = "notify",
        message = "Coordinates copied: " .. str,
        type = "info"
    })
end, false)
