local function showImage(imageUrl)
    SendNUIMessage({
        action = 'showImage',
        data = imageUrl
    })
    SetNuiFocus(true, true)
end

exports('showImage', showImage)
ps.exportChange('ps-ui', 'showImage', showImage)

RegisterNUICallback('closeImage', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
