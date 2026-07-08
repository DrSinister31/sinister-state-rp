AddEventHandler("playerJoining", function()
    local jsonData = LoadResourceFile(GetCurrentResourceName(), "./whitelist/data/data.json")
    local luaData = json.decode(jsonData)
    for k, v in pairs(luaData) do
        if GetPlayerIdentifiers(source)[1] == luaData[k].steamid then
            print(luaData[k].steamid)
            TriggerClientEvent("getHero", source, luaData[k].hero)
            print("Player "..GetPlayerName(source).." is joining with whitelist!")
        end
    end
end)

function IsPlayerActive(id)
    local a = false
    for k, v in pairs(GetPlayers()) do
        if tonumber(v) == tonumber(id) then
            a = true
        end
    end
    if a then
        return true
    else
        return false
    end
end


RegisterServerEvent("phormalist_superheroes:addHero")
AddEventHandler("phormalist_superheroes:addHero", function(targetId, heroName)
    if heroName == "electricman" or heroName == "exploder" or heroName == "invisibleman" or heroName == "quickster" or heroName == "superboy" then
        if IsPlayerActive(targetId) then
            if IsPlayerAceAllowed(source, "Hero-Permissons") == false then
                TriggerClientEvent("chatMessage", source, "You don't have rights to perform this action!")
            else
                local b = {false, nil}
                local n = heroName
                local jsonData = LoadResourceFile(GetCurrentResourceName(), "./whitelist/data/data.json")
                local luaData = json.decode(jsonData)
                for k, v in pairs(luaData) do
                    if GetPlayerIdentifiers(targetId)[1] == luaData[k].steamid then
                        b = {true, luaData[k].hero}
                    end
                end
                if b[1] then
                    TriggerClientEvent("chatMessage", source, "Player "..GetPlayerName(targetId).." already has a hero!")
                else
                    TriggerClientEvent("chatMessage", source, "Player "..GetPlayerName(targetId).." is now "..n.."!")
                    TriggerClientEvent("chatMessage", targetId, "You have been promoted by "..GetPlayerName(source))
                    table.insert(luaData, {steamid = GetPlayerIdentifiers(targetId)[1], hero = n})
                    SaveResourceFile(GetCurrentResourceName(), "./whitelist/data/data.json", json.encode(luaData), -1)
                end
            end
        else
            TriggerClientEvent("chatMessage", source, "The id "..targetId.." is not online!")
        end
    else
        TriggerClientEvent("chatMessage", source, "Invalid Hero Name!")
    end
end)

RegisterServerEvent("phormalist_superheroes:promoteHero")
AddEventHandler("phormalist_superheroes:promoteHero", function(targetId, heroName)
    if heroName == "electricman" or heroName == "exploder" or heroName == "invisibleman" or heroName == "quickster" or heroName == "superboy" or heroName == "vigilante" then
        if IsPlayerActive(targetId) then
            if IsPlayerAceAllowed(source, "Hero-Permissons") == false then
                TriggerClientEvent("chatMessage", source, "You don't have rights to perform this action!")
            else
            local b = {false, nil}
            local n = heroName
            local jsonData = LoadResourceFile(GetCurrentResourceName(), "./whitelist/data/data.json")
            local luaData = json.decode(jsonData)
            for k, v in pairs(luaData) do
                if GetPlayerIdentifiers(targetId)[1] == luaData[k].steamid then
                    b = {true, luaData[k].hero, index = k}
                end
            end
            if b[1] then
                TriggerClientEvent("chatMessage", source, "Player "..GetPlayerName(targetId).." is now "..n.."!")
                TriggerClientEvent("chatMessage", targetId, "You have been promoted by "..GetPlayerName(source).." to "..n)
                table.remove(luaData, b[3])
                table.insert(luaData, {steamid = GetPlayerIdentifiers(targetId)[1], hero = n})
                SaveResourceFile(GetCurrentResourceName(), "./whitelist/data/data.json", json.encode(luaData), -1)
            else
                TriggerClientEvent("chatMessage", source, "Player "..GetPlayerName(targetId).." doesn't have a hero!")
            end
        end
            else
                TriggerClientEvent("chatMessage", source, "The id "..targetId.." is not online!")
            end
        else
            TriggerClientEvent("chatMessage", source, "Invalid Hero Name!")
        end
end)