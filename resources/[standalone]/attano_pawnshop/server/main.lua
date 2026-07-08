local ESX = exports['es_extended']:getSharedObject()

lib.callback.register('attano_pawnshop:getItems', function(source)
    local items = {}

    for itemName, data in pairs(Config.Items) do
        local count = exports.ox_inventory:GetItemCount(source, itemName) or 0

        if count > 0 then
            items[#items+1] = {
                item = itemName,
                label = data.label,
                count = count,
                price = data.price,
                total = count * data.price,
                image = ('https://cfx-nui-ox_inventory/web/images/%s.png'):format(itemName)
            }
        end
    end

    return items
end)

lib.callback.register('attano_pawnshop:sellItem', function(source, itemName)
    local itemData = Config.Items[itemName]
    if not itemData then return false, 'Invalid item.' end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return false, 'Could not find player.'
    end

    local count = exports.ox_inventory:GetItemCount(source, itemName) or 0
    if count < 1 then return false, 'Nothing to sell.' end

    local payout = count * itemData.price

    local removed = exports.ox_inventory:RemoveItem(source, itemName, count)
    if not removed then
        return false, 'Failed to remove items.'
    end

    xPlayer.addMoney(payout)
    return true, ('Sold %sx %s for $%s'):format(count, itemData.label, payout)
end)


-- Food Export 

exports.ox_inventory:registerHook('usingItem', function(payload)
	local durability = payload.item.metadata?.durability

	if durability and durability <= 0 then
		TriggerClientEvent('ox_lib:notify', payload.source, {
			type = 'error',
			description = 'This food is spoiled!'
		})

		return false
	end

	return true
end)
