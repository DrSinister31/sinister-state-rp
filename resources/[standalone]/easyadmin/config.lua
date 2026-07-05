-- ============================================================================
--  EasyAdmin Configuration for Sinister H-Town RP
--  Replaces qbx_adminmenu
-- ============================================================================
--
--  SETUP INSTRUCTIONS:
--  1. Run this in txAdmin or permissions.cfg:
--     add_principal identifier.discord:1370770707507708047 group.admin
--  2. Add to server.cfg:
--     ensure easyadmin
--  3. Ensure oxmysql is installed and started before easyadmin
-- ============================================================================

Config = Config or {}

Config.ServerName = "Sinister H-Town RP"
Config.PrimaryColor = "#BF5700"
Config.SecondaryColor = "#FF8C42"
Config.AccentColor = "#FF6B1A"
Config.BackgroundColor = "#0F0F0F"
Config.SurfaceColor = "#1A1A1A"
Config.BorderColor = "#2A2A2A"
Config.TextColor = "#E0E0E0"
Config.MutedTextColor = "#888888"

Config.OpenKey = "F1"

-- ============================================================================
--  ACE Permissions
--  group.admin   — full access to all features
--  group.moderator — kick, mute, teleport, freeze, reports (no bans/settings)
-- ============================================================================
Config.Permissions = {
    admin = {
        ace = "group.admin",
        canKick = true,
        canBan = true,
        canPermBan = true,
        canUnban = true,
        canMute = true,
        canTeleport = true,
        canSlap = true,
        canFreeze = true,
        canScreenshot = true,
        canRevive = true,
        canHeal = true,
        canNoclip = true,
        canAnnounce = true,
        canBanlist = true,
        canViewReports = true,
        canResolveReports = true,
        canManageResources = true,
        canEditServerConfig = true,
        canEditPermissions = true,
        canViewAllPlayers = true,
    },
    moderator = {
        ace = "group.moderator",
        canKick = true,
        canBan = false,
        canPermBan = false,
        canUnban = false,
        canMute = true,
        canTeleport = true,
        canSlap = false,
        canFreeze = true,
        canScreenshot = false,
        canRevive = false,
        canHeal = false,
        canNoclip = false,
        canAnnounce = false,
        canBanlist = false,
        canViewReports = true,
        canResolveReports = true,
        canManageResources = false,
        canEditServerConfig = false,
        canEditPermissions = false,
        canViewAllPlayers = true,
    }
}

Config.OwnerDiscord = "discord:1370770707507708047"
Config.OwnerIdentifier = "identifier.discord:1370770707507708047"

-- ============================================================================
--  Database Configuration (MariaDB via oxmysql)
-- ============================================================================
Config.Database = {
    host = "91.99.71.34",
    port = 3307,
    user = "u10208_WO0ajxNA1S",
    password = "y6fpxyrazMV!!J.F0sdQvGbZ",
    database = "s10208_Sinister",
    banTable = "easyadmin_bans",
    reportTable = "easyadmin_reports"
}

-- ============================================================================
--  Ban System Configuration
-- ============================================================================
Config.BanSystem = {
    checkOnJoin = true,
    checkIP = true,
    checkIdentifiers = true,
    identifiers = {
        "discord",
        "steam",
        "license",
        "license2",
        "xbl",
        "live",
        "fivem"
    },
    defaultBanReason = "Violation of Sinister H-Town RP rules.",
    banMessageTitle = "You are banned from Sinister H-Town RP",
    tempBanMessageTitle = "You are temporarily banned from Sinister H-Town RP",
    permaBanMessageTitle = "You are permanently banned from Sinister H-Town RP",
    evasionDetection = true,
    evasionAction = "ban",
    evasionDuration = 0
}

-- ============================================================================
--  Report System Configuration
-- ============================================================================
Config.Reports = {
    cooldown = 60,
    minMessageLength = 10,
    maxMessageLength = 500,
    notifyAdmins = true,
    allowedPlayersPerReport = 1,
    categories = {
        "Cheating/Exploiting",
        "Harassment",
        "RDM/VDM",
        "FailRP",
        "Metagaming",
        "Powergaming",
        "Exploits/Bugs",
        "Other"
    }
}

-- ============================================================================
--  Commands Configuration
-- ============================================================================
Config.Commands = {
    admin = "/admin",
    report = "/report",
    kick = "/kick",
    ban = "/ban",
    unban = "/unban",
    mute = "/mute",
    tp = "/tp",
    bring = "/bring",
    goto = "/goto",
    slap = "/slap",
    freeze = "/freeze",
    screenshot = "/screenshot",
    revive = "/revive",
    heal = "/heal",
    noclip = "/noclip",
    announce = "/announce",
    players = "/players"
}

-- ============================================================================
--  NUI Settings
-- ============================================================================
Config.NUI = {
    enableTransitions = true,
    transitionDuration = 300,
    enableSounds = true,
    enableNotifications = true,
    notificationDuration = 5000,
    maxNotifications = 5,
    progressBarEnabled = false,
    pollInterval = 3000
}

-- ============================================================================
--  Screenshot Settings
-- ============================================================================
Config.Screenshots = {
    enabled = true,
    maxSize = "2048x2048",
    quality = 80,
    timeout = 10000
}

-- ============================================================================
--  Resource Management
-- ============================================================================
Config.Resources = {
    protectedResources = {
        "easyadmin",
        "oxmysql",
        "ox_core",
        "qb-core",
        "monitor",
        "sessionmanager"
    },
    allowRestart = true,
    allowStop = true,
    allowStart = true
}

-- ============================================================================
--  Logging
-- ============================================================================
Config.Logging = {
    enabled = true,
    logKicks = true,
    logBans = true,
    logMutes = true,
    logReports = true,
    logTeleports = true,
    logFreezes = true,
    logScreenshots = true,
    logResourceActions = true,
    logPermissionChanges = true,
    webhookURL = ""
}
