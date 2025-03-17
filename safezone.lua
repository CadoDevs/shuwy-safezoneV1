local safeZones = {
    {x = 200.0, y = -1000.0, z = 30.0, radius = 50.0} -- safezone boyutu
}

local isPlayerInSafeZone = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) 
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local inZone = false

        for _, zone in pairs(safeZones) do
            local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(zone.x, zone.y, zone.z))
            if distance < zone.radius then
                inZone = true
                break
            end
        end

        if inZone and not isPlayerInSafeZone then
            isPlayerInSafeZone = true
            TriggerEvent("SafeZone:Entered")
        elseif not inZone and isPlayerInSafeZone then
            isPlayerInSafeZone = false
            TriggerEvent("SafeZone:Exited")
        end
    end
end)

-- Safezone içinde silah kullanımı engelleme
AddEventHandler("SafeZone:Entered", function()
    NetworkSetFriendlyFireOption(false)
    SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true) -- Oyuncunun silahını kapat
    TriggerEvent("chat:addMessage", { args = { "[SafeZone]", "Bu bölge güvenli, silah kullanamazsınız!" } })
end)

AddEventHandler("SafeZone:Exited", function()
    NetworkSetFriendlyFireOption(true)
    TriggerEvent("chat:addMessage", { args = { "[SafeZone]", "Artık güvenli bölgenin dışındasınız!" } })
end)

-- hasarı ve çarpmayı engelle
AddEventHandler("gameEventTriggered", function(event, args)
    if event == "CEventNetworkEntityDamage" then
        local victim = args[1]
        if DoesEntityExist(victim) and IsEntityAPed(victim) then
            local victimCoords = GetEntityCoords(victim)
            for _, zone in pairs(safeZones) do
                if #(vector3(victimCoords.x, victimCoords.y, victimCoords.z) - vector3(zone.x, zone.y, zone.z)) < zone.radius then
                    CancelEvent()
                end
            end
        end
    elseif event == "CEventNetworkVehicleCollision" then
        CancelEvent()
    end
end)