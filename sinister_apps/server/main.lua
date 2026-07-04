local SUPABASE_URL = "https://yqfzaugbrwoluhkddcsh.supabase.co"
local SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxZnphdWdicndvbHVoa2RkY3NoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MzEwMTE1MSwiZXhwIjoyMDk4Njc3MTUxfQ.cEVcfQnn3jBCeGKxASH7rP3--gl_KefEiktXQeNCZsc"

RegisterNetEvent("sinister_apps:open", function(appName)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if appName == "banking" then
        TriggerClientEvent("sinister_apps:openNui", src, "banking", {
            citizenid = player.PlayerData.citizenid
        })
    elseif appName == "browser" then
        TriggerClientEvent("sinister_apps:openNui", src, "browser", {})
    elseif appName == "syntok" then
        TriggerClientEvent("sinister_apps:openNui", src, "syntok", {
            supabaseUrl = SUPABASE_URL,
            supabaseKey = SUPABASE_KEY
        })
    end
end)

print("^2[sinister_apps] ^7Server ready")
