RegisterNetEvent("BakiTelli_bankv2:getInfos", function (o)
    local src = source 
    local history = ExecuteSql("SELECT * FROM `debux_bankv2` WHERE identifier = '"..getidentifier(src).."'")
    Infos = {
        money = getmoney(src),
        name = getname(src),
        history = history,
    }
    TriggerClientEvent("BakiTelli_bankv2:cl:getInfos", src, Infos, o)
end)


RegisterNetEvent("BakiTelli_bankv2:Process", function (typ, amnt, trans)
    src = source 
    amnt = tonumber(amnt)
    trans = tonumber(trans)
    if typ == "deposit" then 
        if getmoney(src, "cash") >= amnt then 
            removemoney(src, amnt ,"cash")
            addmoney(src, amnt, "bank")
            nofity(src, Config.Langs["Succes"])
            AddSQL(src, typ, amnt)
        else 
            nofity(src, Config.Langs["NoMoney"])
        end
    elseif typ == "transfer" then
        if getmoney(src, "bank") >= amnt then 
            removemoney(src, amnt ,"bank")
            addmoney(trans, amnt, "bank")
            nofity(src, Config.Langs["Succes"])
            nofity(trans , Config.Langs["Transfer"])
            AddSQL(trans, typ.."added", amnt)
            AddSQL(src, typ, amnt)
        else 
            nofity(src, Config.Langs["NoMoney"])
        end
    else 
        if trans == src then nofity(src, Config.Langs["Transferme"]) else 
            if getmoney(src, "bank") >= amnt then 
                removemoney(src, amnt ,"bank")
                addmoney(src, amnt, "cash")
                AddSQL(src, typ, amnt)
                nofity(src, Config.Langs["Succes"])
            else 
                nofity(src, Config.Langs["NoMoney"])
            end
        end
    end
end)

function AddSQL(src, typ, count)
    identifier = getidentifier(src)
    ExecuteSql("INSERT INTO `debux_bankv2` (`identifier`,`typ`, `amount`) VALUES ('"..identifier.."', '"..typ.."', '"..count.."')")
end

RegisterNetEvent("BakiTelli_bankv2:AddSQL", function (typ, count)
    AddSQL(source, typ, count)
end)