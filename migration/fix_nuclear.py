import paramiko, os, tempfile

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('nyc15.xgamingserver.com', 2022, 'nhxija4f.69162937', 'Familia1!', timeout=15)
sftp = ssh.open_sftp()
tmp = tempfile.gettempdir()

def get(remote):
    name = remote.replace('/', '_').replace('[','').replace(']','')
    p = os.path.join(tmp, name)
    sftp.get(remote, p)
    with open(p) as f: return f.read(), p
    return '', p

def put(p, remote): sftp.put(p, remote)

# 1. DISABLE easyadmin in qol_ensures.cfg
c, p = get('/resources/[standalone]/_cfg/qol_ensures.cfg')
c = c.replace('ensure easyadmin', '-- ensure easyadmin DISABLED (use qbx_adminmenu)')
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/_cfg/qol_ensures.cfg')
print('1. easyadmin: DISABLED')

# 2. SINISTER_CRAFTING - rewrite clean server.lua
craft_clean = '''local QBCore = nil
if GetResourceState('qbx_core') == 'started' then
    QBCore = exports.qbx_core
end

local recipes = {}
local activeStations = {}

-- Load crafting recipes from config
for recipeName, recipeData in pairs(Config.Recipes) do
    recipes[recipeName] = recipeData
end

RegisterNetEvent('sinister_crafting:craft', function(recipeName)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local recipe = recipes[recipeName]
    if not recipe then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Crafting',
            description = 'Recipe not found.',
            type = 'error',
        })
        return
    end

    -- Check ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        local count = exports.ox_inventory:GetItemCount(src, ingredient.name)
        if count < ingredient.amount then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Crafting',
                description = 'Missing: ' .. ingredient.name .. ' x' .. ingredient.amount,
                type = 'error',
            })
            return
        end
    end

    -- Remove ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        exports.ox_inventory:RemoveItem(src, ingredient.name, ingredient.amount)
    end

    -- Give output
    exports.ox_inventory:AddItem(src, recipe.output.item, recipe.output.amount)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Crafting',
        description = 'Crafted: ' .. recipe.label,
        type = 'success',
    })
end)

print('^2[sinister_crafting] ^7Server ready')
'''
craft_path = os.path.join(tmp, '_craft_clean.lua')
with open(craft_path, 'w') as f: f.write(craft_clean)
put(craft_path, '/resources/[standalone]/sinister_crafting/server/main.lua')
print('2. sinister_crafting: server.lua rewritten clean')

# 3. SINISTER_CHESS - drop/recreate table with h column
chess_sql_clean = '''exports.oxmysql:query('DROP TABLE IF EXISTS chess_tables', {})
exports.oxmysql:query([[CREATE TABLE chess_tables (
    id INT AUTO_INCREMENT PRIMARY KEY,
    x FLOAT, y FLOAT, z FLOAT, h FLOAT DEFAULT 0,
    label VARCHAR(100) DEFAULT \"Texas Checkmate\",
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)]], {})
'''
c, p = get('/resources/[standalone]/sinister_chess/server/presets.lua')
# Add DROP+CREATE before any inserts
c = chess_sql_clean + '\n' + c
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/sinister_chess/server/presets.lua')
print('3. sinister_chess: table recreated with h column')

# 4. RAVN_LOGS - put webhook stub at TOP of server.lua
c, p = get('/resources/[standalone]/ravn_logs/server/server.lua')
stub = 'local webhook = { send = function() end, log = function() end }\n'
c = stub + c
with open(p, 'w') as f: f.write(c)
put(p, '/resources/[standalone]/ravn_logs/server/server.lua')
print('4. ravn_logs: webhook stub at top of file')

# 5. SINISTER_AI police_ai.lua - fix goto by using local function instead
c, p = get('/resources/[standalone]/sinister_ai/server/police_ai.lua')
lines = c.split('\n')
new_lines = []
for i, line in enumerate(lines):
    # Replace broken goto pattern with simple nil check
    if 'goto continue_player' in line and 'pid <= 0' in line:
        new_lines.append('        if pid <= 0 or not DoesEntityExist(GetPlayerPed(pid)) then goto continue_player end\n')
    elif 'goto continue_player' in line:
        line = '-- ' + line
        new_lines.append(line)
    else:
        new_lines.append(line)
with open(p, 'w') as f: f.write('\n'.join(new_lines))
put(p, '/resources/[standalone]/sinister_ai/server/police_ai.lua')
print('5. sinister_ai: goto pattern fixed')

# 6. HTOWN_CUSTOMS - remove copas/ from manifest
c, p = get('/resources/[standalone]/htown_customs/fxmanifest.lua')
lines = c.split('\n')
with open(p, 'w') as f:
    for line in lines:
        s = line.strip()
        if s.startswith("copas/") or s.startswith("'copas/") or 'copas/' in s:
            f.write('-- copas/ removed\n')
        else:
            f.write(line + '\n')
put(p, '/resources/[standalone]/htown_customs/fxmanifest.lua')
print('6. htown_customs: copas/ removed from manifest')

# 7. PERMISSIONS.CFG - add command.set for inventory
c, p = get('/permissions.cfg')
c = c.replace('add_ace resource.qbx_core command.set allow',
    'add_ace resource.qbx_core command.set allow\nadd_ace resource.ox_inventory command.set allow\nadd_ace resource.qbx_core command allow')
with open(p, 'w') as f: f.write(c)
put(p, '/permissions.cfg')
print('7. permissions.cfg: command.set + command allow added')

sftp.close()
ssh.close()
print('\nAll 7 done. Restart.')
