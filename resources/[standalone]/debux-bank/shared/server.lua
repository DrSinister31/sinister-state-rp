-------------------------------- 

getFramework = function()
    if Config.Framework == "esx" then
        return exports['es_extended']:getSharedObject(), "esx"
    elseif Config.Framework == "qb" then
        return exports["qb-core"]:GetCoreObject(), "qb"
    elseif Config.Framework == "auto" then
        if GetResourceState('qb-core') == 'started' then
            return exports["qb-core"]:GetCoreObject(), "qb"
        elseif GetResourceState('es_extended') == 'started' then
            return exports['es_extended']:getSharedObject(), "esx"
        end
    end
end

------------------------------------------------------------------------------------

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --

------------------------------------------------------------------------------------

local Framework, frameworkName = getFramework()

-------------------------------- 

getPlayer = function(source)
    local src = tonumber(source)
    if frameworkName == "esx" then
        return Framework.GetPlayerFromId(src)
    else
        return Framework.Functions.GetPlayer(src)
    end
end

-------------------------------- 

getmoney = function(source, typ)
    local src = source
    local Player = getPlayer(src)
    if typ == "cash" then
        if frameworkName == "esx" then
            return Player.getAccount("money").money
        else
            return Player.PlayerData.money["cash"]
        end
    else 
        if frameworkName == "esx" then
            return Player.getAccount("bank").money
        else
            return Player.PlayerData.money["bank"]
        end
    end
end


-------------------------------- 


-- give money function
addmoney = function(source,amount, typ)
    local Player = getPlayer(source)
    if frameworkName == "esx" then
        if typ == "cash" then 
            Player.addAccountMoney("money", amount)
        else
            Player.addAccountMoney("bank", amount)
        end
    else
        if typ == "cash" then 
            Player.Functions.AddMoney("cash", amount)
        else
            Player.Functions.AddMoney("bank", amount)
        end
    end
end

-------------------------------- 

removemoney = function(source,money, typ)
    local src = source  
    local Player = getPlayer(src)
    if typ == "cash" then

        if frameworkName == "esx" then
            Player.removeMoney(money)
        else
            Player.Functions.RemoveMoney("cash", money)
        end
    else 
        if frameworkName == "esx" then
            Player.removeAccountMoney("bank", money)
        else
            Player.Functions.RemoveMoney("bank", money)
        end
    end
end

-------------------------------- 

nofity = function(src,text)
    if frameworkName == "esx" then
        TriggerClientEvent("esx:showNotification", src, text)
    elseif frameworkName == "qb" then
        TriggerClientEvent('QBCore:Notify', src, text)
    end
end

-------------------------------- 


getidentifier = function(source)
    local src = source
    local Player = getPlayer(src)
    if frameworkName == "esx" then
        return Player.identifier
    else
        return Player.PlayerData.citizenid
    end
end

-------------------------------- 

getname = function(source)
    local src = source
    local Player = getPlayer(src)
    if frameworkName == "esx" then
        return Player.getName()
    else
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end
end

------------------------------------------------------------------------------------

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --

------------------------------------------------------------------------------------

function ExecuteSql(query)
    local IsBusy = true
    local result = nil
    if Config.Mysql == "oxmysql" then
        if MySQL == nil then
            exports.oxmysql:execute(query, function(data)
                result = data
                IsBusy = false
            end)
            -------------------------------- 
        else
            MySQL.query(query, {}, function(data)
                result = data
                IsBusy = false
            end)
        end
        -------------------------------- 
    elseif Config.Mysql == "ghmattimysql" then
        exports.ghmattimysql:execute(query, {}, function(data)
            result = data
            IsBusy = false
        end)
    elseif Config.Mysql == "mysql-async" then   
        MySQL.Async.fetchAll(query, {}, function(data)
            result = data
            IsBusy = false
        end)
        -------------------------------- 
    end
    while IsBusy do
        Citizen.Wait(0)
    end
    return result
end

------------------------------------------------------------------------------------

------------------------------------------------------------------------------------

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --

------------------------------------------------------------------------------------