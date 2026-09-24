<#
.SYNOPSIS
    Provides an interactive troubleshooting menu for common
    Microsoft Configuration Manager client scenarios.

.DESCRIPTION
    Invoke-CMTroubleshoot displays common Configuration Manager
    troubleshooting scenarios and lists the client-side log files
    that are typically relevant to each scenario.

    The selected log file is displayed using Get-CMTraceLog.

    When Get-CMTraceLog is started with -Wait, press Q to return
    to the log selection menu.

    Navigation:

        Scenario list
             |
             v
        Relevant logs
             |
             v
        CMTrace log viewer
             |
           Q |
             v
        Relevant logs

    Press B from the log list to return to the scenario list.

.PARAMETER Tail
    Number of physical log lines initially displayed when opening
    a log.

    Default: 100

.EXAMPLE
    Invoke-CMTroubleshoot

    Starts the interactive troubleshooting menu.

.EXAMPLE
    cmts

    Starts the menu using the cmts alias.

.EXAMPLE
    Invoke-CMTroubleshoot -Tail 250

    Opens selected logs with the last 250 physical lines displayed.

.NOTES
    This tool focuses on client-side Configuration Manager logs.

    Some Configuration Manager logs, most notably smsts.log, can
    reside in different locations depending on the current Task
    Sequence phase. This implementation currently uses the standard
    installed-client log directory.

.LINK
    https://learn.microsoft.com/mem/configmgr/core/plan-design/hierarchy/log-files
#>

function Invoke-CMTroubleshoot {
    [CmdletBinding()]
    param(
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Tail = 100
    )

    if (-not (Get-Command Get-CMTraceLog -ErrorAction SilentlyContinue)) {
        throw 'Get-CMTraceLog is not available. Load Get-CMTraceLog.ps1 before running this function.'
    }

    $ccmLogPath      = Join-Path $env:WINDIR 'CCM\Logs'
    $ccmSetupLogPath = Join-Path $env:WINDIR 'ccmsetup\Logs'

    $scenarios = [ordered]@{

        'Client installation' = @(
            @{
                Log         = 'ccmsetup.log'
                Path        = $ccmSetupLogPath
                Description = 'Configuration Manager client installation and upgrade'
            }
            @{
                Log         = 'client.msi.log'
                Path        = $ccmSetupLogPath
                Description = 'Windows Installer operations during client installation'
            }
        )

        'Client registration and certificates' = @(
            @{
                Log         = 'ClientIDManagerStartup.log'
                Path        = $ccmLogPath
                Description = 'Client registration, client GUID and certificate selection'
            }
            @{
                Log         = 'CertificateMaintenance.log'
                Path        = $ccmLogPath
                Description = 'Client certificate maintenance'
            }
            @{
                Log         = 'CcmMessaging.log'
                Path        = $ccmLogPath
                Description = 'Client communication with Configuration Manager'
            }
            @{
                Log         = 'LocationServices.log'
                Path        = $ccmLogPath
                Description = 'Management Point, Distribution Point and site discovery'
            }
        )

        'Policy' = @(
            @{
                Log         = 'PolicyAgent.log'
                Path        = $ccmLogPath
                Description = 'Policy requests and policy processing'
            }
            @{
                Log         = 'PolicyEvaluator.log'
                Path        = $ccmLogPath
                Description = 'Policy evaluation'
            }
            @{
                Log         = 'PolicyAgentProvider.log'
                Path        = $ccmLogPath
                Description = 'Policy data stored through the client WMI provider'
            }
            @{
                Log         = 'CcmMessaging.log'
                Path        = $ccmLogPath
                Description = 'Communication used when retrieving policy'
            }
        )

        'Application installation' = @(
            @{
                Log         = 'AppDiscovery.log'
                Path        = $ccmLogPath
                Description = 'Application detection methods'
            }
            @{
                Log         = 'AppIntentEval.log'
                Path        = $ccmLogPath
                Description = 'Application requirements, dependencies and deployment intent'
            }
            @{
                Log         = 'AppEnforce.log'
                Path        = $ccmLogPath
                Description = 'Application installation and uninstall operations'
            }
            @{
                Log         = 'CAS.log'
                Path        = $ccmLogPath
                Description = 'Content Access Service'
            }
            @{
                Log         = 'ContentTransferManager.log'
                Path        = $ccmLogPath
                Description = 'Content transfer management'
            }
            @{
                Log         = 'DataTransferService.log'
                Path        = $ccmLogPath
                Description = 'BITS and content downloads'
            }
        )

        'Packages and programs' = @(
            @{
                Log         = 'execmgr.log'
                Path        = $ccmLogPath
                Description = 'Package and program execution'
            }
            @{
                Log         = 'CAS.log'
                Path        = $ccmLogPath
                Description = 'Content location and access'
            }
            @{
                Log         = 'ContentTransferManager.log'
                Path        = $ccmLogPath
                Description = 'Content transfer management'
            }
            @{
                Log         = 'DataTransferService.log'
                Path        = $ccmLogPath
                Description = 'BITS and content downloads'
            }
        )

        'Content and Distribution Point' = @(
            @{
                Log         = 'CAS.log'
                Path        = $ccmLogPath
                Description = 'Content location and client cache'
            }
            @{
                Log         = 'ContentTransferManager.log'
                Path        = $ccmLogPath
                Description = 'Content transfer management'
            }
            @{
                Log         = 'DataTransferService.log'
                Path        = $ccmLogPath
                Description = 'BITS and content downloads'
            }
            @{
                Log         = 'LocationServices.log'
                Path        = $ccmLogPath
                Description = 'Distribution Point selection'
            }
        )

        'Software Updates' = @(
            @{
                Log         = 'WUAHandler.log'
                Path        = $ccmLogPath
                Description = 'Windows Update Agent operations and scan results'
            }
            @{
                Log         = 'UpdatesDeployment.log'
                Path        = $ccmLogPath
                Description = 'Software Update deployment and enforcement'
            }
            @{
                Log         = 'UpdatesHandler.log'
                Path        = $ccmLogPath
                Description = 'Software Update installation'
            }
            @{
                Log         = 'ScanAgent.log'
                Path        = $ccmLogPath
                Description = 'Software Update scan initiation'
            }
            @{
                Log         = 'LocationServices.log'
                Path        = $ccmLogPath
                Description = 'Software Update Point location'
            }
        )

        'Task Sequence' = @(
            @{
                Log         = 'smsts.log'
                Path        = $ccmLogPath
                Description = 'Task Sequence execution'
            }
        )

        'Hardware Inventory' = @(
            @{
                Log         = 'InventoryAgent.log'
                Path        = $ccmLogPath
                Description = 'Hardware inventory processing'
            }
        )

        'Discovery Data / Heartbeat' = @(
            @{
                Log         = 'InventoryAgent.log'
                Path        = $ccmLogPath
                Description = 'Heartbeat Discovery DDR creation'
            }
        )

        'Compliance Settings' = @(
            @{
                Log         = 'CIAgent.log'
                Path        = $ccmLogPath
                Description = 'Configuration Item processing'
            }
            @{
                Log         = 'DCMAgent.log'
                Path        = $ccmLogPath
                Description = 'Compliance evaluation'
            }
            @{
                Log         = 'DcmWmiProvider.log'
                Path        = $ccmLogPath
                Description = 'Compliance Settings WMI provider'
            }
        )

        'Client health and repair' = @(
            @{
                Log         = 'CcmEval.log'
                Path        = $ccmLogPath
                Description = 'Configuration Manager client health evaluation'
            }
            @{
                Log         = 'CcmRepair.log'
                Path        = $ccmLogPath
                Description = 'Configuration Manager client repair'
            }
            @{
                Log         = 'CcmExec.log'
                Path        = $ccmLogPath
                Description = 'SMS Agent Host service'
            }
        )

        'Management Point communication' = @(
            @{
                Log         = 'CcmMessaging.log'
                Path        = $ccmLogPath
                Description = 'HTTP and HTTPS communication with Configuration Manager'
            }
            @{
                Log         = 'LocationServices.log'
                Path        = $ccmLogPath
                Description = 'Management Point discovery'
            }
            @{
                Log         = 'ClientLocation.log'
                Path        = $ccmLogPath
                Description = 'Client site assignment'
            }
        )

        'Boundary / Site Assignment' = @(
            @{
                Log         = 'LocationServices.log'
                Path        = $ccmLogPath
                Description = 'Boundary Groups and site system location'
            }
            @{
                Log         = 'ClientLocation.log'
                Path        = $ccmLogPath
                Description = 'Client site assignment'
            }
        )

        'Software Center' = @(
            @{
                Log         = 'SCClient.log'
                Path        = $ccmLogPath
                Description = 'Software Center user interface'
            }
            @{
                Log         = 'CCMSDKProvider.log'
                Path        = $ccmLogPath
                Description = 'Client SDK operations used by Software Center'
            }
            @{
                Log         = 'AppIntentEval.log'
                Path        = $ccmLogPath
                Description = 'Application deployment state evaluation'
            }
        )

        'Cache' = @(
            @{
                Log         = 'CAS.log'
                Path        = $ccmLogPath
                Description = 'Client cache and content handling'
            }
            @{
                Log         = 'ContentTransferManager.log'
                Path        = $ccmLogPath
                Description = 'Content transfer into the client cache'
            }
        )
    }


    while ($true) {

        Clear-Host

        Write-Host 'Configuration Manager Troubleshooting' -ForegroundColor Cyan
        Write-Host '====================================='
        Write-Host

        $scenarioNames = @($scenarios.Keys)

        for ($i = 0; $i -lt $scenarioNames.Count; $i++) {
            Write-Host ('[{0,2}] {1}' -f ($i + 1), $scenarioNames[$i])
        }

        Write-Host
        Write-Host '[ Q] Quit'
        Write-Host

        $selection = Read-Host 'Select scenario'

        if ($selection -match '^[Qq]$') {
            return
        }

        if (
            $selection -notmatch '^\d+$' -or
            [int]$selection -lt 1 -or
            [int]$selection -gt $scenarioNames.Count
        ) {
            continue
        }

        $scenarioName = $scenarioNames[[int]$selection - 1]
        $logs = @($scenarios[$scenarioName])


        while ($true) {

            Clear-Host

            Write-Host $scenarioName -ForegroundColor Cyan
            Write-Host ('=' * $scenarioName.Length)
            Write-Host

            for ($i = 0; $i -lt $logs.Count; $i++) {

                $item     = $logs[$i]
                $fullPath = Join-Path $item.Path $item.Log

                if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                    $status      = 'Available'
                    $statusColor = 'Green'
                }
                else {
                    $status      = 'Missing'
                    $statusColor = 'DarkGray'
                }

                Write-Host ('[{0,2}] ' -f ($i + 1)) -NoNewline

                Write-Host (
                    '{0,-32}' -f $item.Log
                ) -NoNewline -ForegroundColor Yellow

                Write-Host (
                    ' [{0}]' -f $status
                ) -ForegroundColor $statusColor

                Write-Host (
                    '     {0}' -f $item.Description
                ) -ForegroundColor DarkGray
            }

            Write-Host
            Write-Host '[ B] Back'
            Write-Host '[ Q] Quit'
            Write-Host

            $logSelection = Read-Host 'Select log'

            if ($logSelection -match '^[Qq]$') {
                return
            }

            if ($logSelection -match '^[Bb]$') {
                break
            }

            if (
                $logSelection -notmatch '^\d+$' -or
                [int]$logSelection -lt 1 -or
                [int]$logSelection -gt $logs.Count
            ) {
                continue
            }

            $selectedLog = $logs[[int]$logSelection - 1]
            $fullPath    = Join-Path $selectedLog.Path $selectedLog.Log

            Clear-Host

            Write-Host "Scenario : $scenarioName" -ForegroundColor DarkGray
            Write-Host "Log      : $($selectedLog.Log)" -ForegroundColor Cyan
            Write-Host "Path     : $fullPath" -ForegroundColor DarkGray
            Write-Host

            if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {

                Write-Warning "Log file not found: $fullPath"

                Write-Host
                $null = Read-Host 'Press Enter to return'

                continue
            }

            Get-CMTraceLog `
                -Path $fullPath `
                -Tail $Tail `
                -Wait

            # Get-CMTraceLog returns when Q is pressed.
            # Execution continues here and the current log menu is
            # displayed again.
        }
    }
}


if (-not (Get-Alias -Name cmts -ErrorAction SilentlyContinue)) {
    Set-Alias -Name cmts -Value Invoke-CMTroubleshoot
}
