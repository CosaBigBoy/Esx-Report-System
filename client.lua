local reportsOpen = false

-- F7 by default.
-- The player can change this key from:
-- Settings -> Key Bindings -> FiveM -> Advanced Reports
RegisterCommand('+advanced_reports', function()
    TriggerServerEvent('advanced_reports:requestReports')

    SetNuiFocus(true, true)
    reportsOpen = true

    SendNUIMessage({
        action = 'open'
    })
end, false)

RegisterCommand('-advanced_reports', function()
end, false)

RegisterKeyMapping(
    '+advanced_reports',
    'Open Advanced Reports',
    'keyboard',
    Config.DefaultKey or 'F7'
)

local function Notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('advanced_reports:notify', function(message)
    Notify(message)
end)

RegisterNetEvent('advanced_reports:newReport', function(report)
    if Config.NewReportNotify then
        Notify(
            ('~r~NEW REPORT~s~  #%s | %s [%s]'):format(
                report.id,
                report.steamName,
                report.gameId
            )
        )
    end

    if Config.NewReportSound then
        SendNUIMessage({
            action = 'newReportSound'
        })
    end
end)

RegisterNetEvent('advanced_reports:open', function(reports)
    reportsOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        reports = reports or {}
    })
end)

RegisterNetEvent('advanced_reports:updateReports', function(reports)
    if not reportsOpen then
        return
    end

    SendNUIMessage({
        action = 'update',
        reports = reports or {}
    })
end)

RegisterNetEvent('advanced_reports:gotoPlayer', function(target)
    local targetPlayer = GetPlayerFromServerId(target)

    if targetPlayer == -1 then
        Notify('Player not found.')
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)

    if not DoesEntityExist(targetPed) then
        Notify('Player entity not found.')
        return
    end

    local coords = GetEntityCoords(targetPed)

    SetEntityCoords(
        PlayerPedId(),
        coords.x,
        coords.y,
        coords.z + 1.0,
        false,
        false,
        false,
        false
    )

    Notify(('Teleported to player [%s].'):format(target))
end)

RegisterNetEvent('advanced_reports:bringPlayer', function(staffSource)
    local staffPlayer = GetPlayerFromServerId(staffSource)

    if staffPlayer == -1 then
        Notify('Staff player not found.')
        return
    end

    local staffPed = GetPlayerPed(staffPlayer)

    if not DoesEntityExist(staffPed) then
        Notify('Staff entity not found.')
        return
    end

    local coords = GetEntityCoords(staffPed)

    SetEntityCoords(
        PlayerPedId(),
        coords.x,
        coords.y,
        coords.z + 1.0,
        false,
        false,
        false,
        false
    )
end)

RegisterNUICallback('close', function(_, cb)
    reportsOpen = false

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    cb({ ok = true })
end)

RegisterNUICallback('action', function(data, cb)
    if not data then
        cb({ ok = false })
        return
    end

    local action = data.action
    local reportId = tonumber(data.reportId)

    if not action or not reportId then
        cb({ ok = false })
        return
    end

    if action ~= 'goto'
        and action ~= 'bring'
        and action ~= 'done' then
        cb({ ok = false })
        return
    end

    TriggerServerEvent(
        'advanced_reports:action',
        action,
        reportId
    )

    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if reportsOpen then
            Wait(0)

            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
        else
            Wait(500)
        end
    end
end)
