-- Sinister Clock-In — Client
local activeNodes = {}
local inNodeRange = false
local currentNodeId = nil

RegisterNetEvent("sinister_clockin:receiveNodes", function(nodes)
    for _, point in ipairs(activeNodes) do
        point:remove()
    end
    activeNodes = {}

    for _, node in ipairs(nodes) do
        local coords = node.coords
        local point = lib.points.new({
            coords = vec3(coords.x, coords.y, coords.z),
            distance = node.radius or 15.0,
        })

        function point:onEnter()
            inNodeRange = true
            currentNodeId = node.id
            lib.showTextUI("[E] Clock In | [H] Clock Out\n" .. (node.label or "Facility"))
        end

        function point:onExit()
            inNodeRange = false
            currentNodeId = nil
            lib.hideTextUI()
        end

        function point:nearby()
            if inNodeRange then
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent("sinister_clockin:clockIn", node.id)
                elseif IsControlJustPressed(0, 74) then
                    TriggerServerEvent("sinister_clockin:clockOut")
                end
            end
        end

        activeNodes[#activeNodes + 1] = point
    end
end)

AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    TriggerServerEvent("sinister_clockin:requestNodes")
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        TriggerServerEvent("sinister_clockin:requestNodes")
    end
end)

print("^2[sinister_clockin] ^7Client ready")
