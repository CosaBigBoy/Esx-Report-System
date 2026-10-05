local ESX = exports['es_extended']:getSharedObject()

local Reports = {}
local ReportId = 0

local function IsStaff(xPlayer)
    if not xPlayer then return false end
    return Config.StaffGroups[xPlayer.getGroup()] == true
end

local function GetReport(reportId)
    reportId = tonumber(reportId)
    if not reportId then return nil end

    for _, report in ipairs(Reports) do
        if report.id == reportId then
            return report
        end
    end

    return nil
end

local function RemoveReport(reportId)
    reportId = tonumber(reportId)

    for i, report in ipairs(Reports) do
        if report.id == reportId then
            table.remove(Reports, i)
            return report
        end
    end

    return nil
end

local function SendReportsToStaff()
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local xPlayer = ESX.GetPlayerFromId(src)

        if IsStaff(xPlayer) then
            TriggerClientEvent('advanced_reports:updateReports', src, Reports)
        end
    end
end

local function NotifyStaffNewReport(report)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local xPlayer = ESX.GetPlayerFromId(src)

        if IsStaff(xPlayer) then
            TriggerClientEvent(
                'advanced_reports:newReport',
                src,
                report
            )
        end
    end
end

RegisterCommand('report', function(source, args)
    if source <= 0 then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    if #args == 0 then
        TriggerClientEvent(
            'advanced_reports:notify',
            source,
            'Usage: /report [message]'
        )
        return
    end

    local message = table.concat(args, ' ')

    if #message > Config.MaxMessageLength then
        TriggerClientEvent(
            'advanced_reports:notify',
            source,
            'Your report is too long.'
        )
        return
    end

    ReportId = ReportId + 1

    local report = {
        id = ReportId,
        playerId = source,
        steamName = GetPlayerName(source) or 'Unknown',
        gameId = source,
        message = message,
        createdAt = os.date('%H:%M:%S'),
        claimedBy = nil
    }

    Reports[#Reports + 1] = report

    TriggerClientEvent(
        'advanced_reports:notify',
        source,
        'Your report has been sent to the staff team.'
    )

    NotifyStaffNewReport(report)
    SendReportsToStaff()
end, false)

RegisterCommand('reports', function(source)
    if source <= 0 then return end

    local xPlayer = ESX.GetPlayerFromId(source)

    if not IsStaff(xPlayer) then
        TriggerClientEvent(
            'advanced_reports:notify',
            source,
            'You do not have permission to use this command.'
        )
        return
    end

    TriggerClientEvent('advanced_reports:open', source, Reports)
end, false)

RegisterNetEvent('advanced_reports:requestReports', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not IsStaff(xPlayer) then return end

    TriggerClientEvent('advanced_reports:updateReports', src, Reports)
end)

RegisterNetEvent('advanced_reports:action', function(action, reportId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not IsStaff(xPlayer) then return end

    reportId = tonumber(reportId)
    local report = GetReport(reportId)

    if not report then
        TriggerClientEvent(
            'advanced_reports:notify',
            src,
            'This report no longer exists.'
        )
        return
    end

    if action == 'goto' then
        local target = tonumber(report.playerId)

        if not GetPlayerName(target) then
            TriggerClientEvent(
                'advanced_reports:notify',
                src,
                'The player is no longer online.'
            )
            return
        end

        TriggerClientEvent('advanced_reports:gotoPlayer', src, target)

        report.claimedBy = src
        SendReportsToStaff()

    elseif action == 'bring' then
        local target = tonumber(report.playerId)

        if not GetPlayerName(target) then
            TriggerClientEvent(
                'advanced_reports:notify',
                src,
                'The player is no longer online.'
            )
            return
        end

        TriggerClientEvent(
            'advanced_reports:bringPlayer',
            target,
            src
        )

        report.claimedBy = src
        SendReportsToStaff()

    elseif action == 'done' then
        if RemoveReport(reportId) then
            TriggerClientEvent(
                'advanced_reports:notify',
                src,
                ('Report #%s closed.'):format(reportId)
            )

            SendReportsToStaff()
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local changed = false

    for i = #Reports, 1, -1 do
        if Reports[i].playerId == src then
            table.remove(Reports, i)
            changed = true
        end
    end

    if changed then
        SendReportsToStaff()
    end
end)
