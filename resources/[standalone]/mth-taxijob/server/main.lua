local ox_inventory = exports.ox_inventory

RegisterNetEvent('mth9f2m7d4k8s1x6r5c0h3j:w4n7b2p9d5m6kA8Q', function()
    local src = source

    if math.random(100) <= Config.NoPayChance then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Locales.taxi_job,
            description = Locales.no_pay,
            type = 'error'
        })
        return
    end

    local amount = math.random(Config.MinPay, Config.MaxPay)
    ox_inventory:AddItem(src, 'money', amount)

    TriggerClientEvent('ox_lib:notify', src, {
        title = Locales.taxi_job,
        description = Locales.paid .. amount,
        type = 'success'
    })
end)
