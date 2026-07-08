-- =====================================================================
--  bcs_gunstore - shared init (runs before client/server scripts)
-- =====================================================================

-- Resolve the framework before any bridge file runs.
if not Config.framework or Config.framework == 'auto' then
    if GetResourceState('qbx_core') == 'started' then
        Config.framework = 'qbx'
    elseif GetResourceState('es_extended') == 'started' then
        Config.framework = 'esx'
    elseif GetResourceState('qb-core') == 'started' then
        Config.framework = 'qb'
    else
        Config.framework = 'qbx' -- sensible default; override in config.lua if needed
        print('^3[bcs_gunstore]^0 Could not auto-detect a framework, defaulting to "qbx". Set Config.framework manually if this is wrong.')
    end
end

-- Load ox_lib locale (reads locales/<lang>.json based on Config.locale / convar).
if Config.locale then
    lib.locale(Config.locale)
else
    lib.locale()
end

-- Helper used in a couple of places to build the ox_inventory shop id for a store.
function GetShopType(storeId)
    return Config.shopPrefix .. storeId
end
