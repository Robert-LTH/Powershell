<#
.SYNOPSIS
    Displays Microsoft Configuration Manager CMTrace log files
    in a readable, color-coded console format.

.DESCRIPTION
    Get-CMTraceLog reads Configuration Manager log files that use the
    CMTrace log format and presents them in a console-friendly format.

    Features:
      - Parses standard CMTrace log entries.
      - Supports multiline log messages.
      - Color-codes informational, warning, and error entries.
      - Supports tailing a log file.
      - Supports continuous monitoring similar to Get-Content -Wait.
      - Press Q while monitoring to stop following the log.
      - Can filter entries by severity.

    The function is designed primarily for Microsoft Configuration
    Manager client logs but can be used with other logs using the
    standard CMTrace format.

.PARAMETER Path
    Path to one or more CMTrace-compatible log files.

.PARAMETER Tail
    Specifies how many physical lines from the end of the file are
    initially read.

    Default: 10

.PARAMETER Wait
    Continues monitoring the file for new entries.

    Press Q to stop monitoring and return control to the caller.

.PARAMETER Type
    Filters entries by severity.

    Valid values:
      Info
      Warning
      Error

.EXAMPLE
    Get-CMTraceLog 'C:\Windows\CCM\Logs\CcmMessaging.log'

    Displays the last 10 lines of CcmMessaging.log.

.EXAMPLE
    Get-CMTraceLog 'C:\Windows\CCM\Logs\CcmMessaging.log' -Tail 100

    Displays the last 100 physical lines.

.EXAMPLE
    Get-CMTraceLog 'C:\Windows\CCM\Logs\CcmMessaging.log' -Tail 100 -Wait

    Displays the last 100 lines and continues monitoring the file.
    Press Q to return.

.EXAMPLE
    Get-CMTraceLog 'C:\Windows\CCM\Logs\AppEnforce.log' -Wait -Type Error,Warning

    Continuously displays only warnings and errors.

.EXAMPLE
    cmlog 'C:\Windows\CCM\Logs\AppEnforce.log' -Tail 50 -Wait

    Uses the cmlog alias.

.NOTES
    CMTrace log type values:

      1 = Information
      2 = Warning
      3 = Error

    Tail operates on physical lines rather than logical CMTrace entries.
    As a result, the first displayed entry can be incomplete when the
    selected tail range starts in the middle of a multiline CMTrace entry.

.LINK
    https://learn.microsoft.com/mem/configmgr/core/plan-design/hierarchy/log-files
#>

function Get-CMTraceLog {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$Tail = 10,

        [Alias('Follow')]
        [switch]$Wait,

        [ValidateSet('Info', 'Warning', 'Error')]
        [string[]]$Type
    )

    begin {

        function Write-CMTraceEntry {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [AllowEmptyString()]
                [string]$Entry
            )

            if ([string]::IsNullOrWhiteSpace($Entry)) {
                return
            }

            $pattern = @'
(?s)^<!\[LOG\[(?<Message>.*?)\]LOG\]!><time="(?<Time>.*?)"\s+date="(?<Date>.*?)"\s+component="(?<Component>.*?)"\s+context="(?<Context>.*?)"\s+type="(?<Type>\d+)"\s+thread="(?<Thread>.*?)"\s+file="(?<File>.*?)">$
'@

            if ($Entry -notmatch $pattern) {
                Write-Host $Entry -ForegroundColor DarkGray
                return
            }

            $message   = $Matches.Message
            $time      = $Matches.Time
            $date      = $Matches.Date
            $component = $Matches.Component
            $logType   = [int]$Matches.Type

            $typeName = switch ($logType) {
                1 { 'Info' }
                2 { 'Warning' }
                3 { 'Error' }
                default { 'Unknown' }
            }

            if ($Type -and $typeName -notin $Type) {
                return
            }

            # CMTrace timestamps can contain an offset such as:
            # 09:37:46.500-120
            $displayTime = $time -replace '([+-]\d+)$', ''
            $timestamp   = "$date $displayTime"

            $color = switch ($logType) {
                1 { 'Gray' }
                2 { 'Yellow' }
                3 { 'Red' }
                default { 'DarkGray' }
            }

            Write-Host '[' -NoNewline -ForegroundColor DarkGray
            Write-Host $timestamp -NoNewline -ForegroundColor DarkGray
            Write-Host '] ' -NoNewline -ForegroundColor DarkGray

            Write-Host '[' -NoNewline -ForegroundColor DarkGray
            Write-Host $component -NoNewline -ForegroundColor Cyan
            Write-Host '] ' -NoNewline -ForegroundColor DarkGray

            $messageLines = $message -split '\r?\n'

            if ($messageLines.Count -eq 0) {
                return
            }

            Write-Host $messageLines[0] -ForegroundColor $color

            for ($i = 1; $i -lt $messageLines.Count; $i++) {
                Write-Host ('    ' + $messageLines[$i]) -ForegroundColor $color
            }
        }


        function Write-CMTraceLines {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [AllowEmptyCollection()]
                [AllowEmptyString()]
                [string[]]$Lines,

                [Parameter(Mandatory)]
                [ref]$Buffer,

                [Parameter(Mandatory)]
                [ref]$InEntry
            )

            foreach ($line in $Lines) {

                # Empty lines outside a CMTrace entry have no useful
                # metadata and can safely be ignored.
                if ([string]::IsNullOrEmpty($line) -and -not $InEntry.Value) {
                    continue
                }

                # Start of a new CMTrace entry.
                if ($line -match '^<!\[LOG\[') {

                    # If the previous entry never received a valid ending,
                    # output it before starting the new entry.
                    if ($InEntry.Value -and $null -ne $Buffer.Value) {
                        Write-CMTraceEntry -Entry $Buffer.Value
                    }

                    $Buffer.Value  = $line
                    $InEntry.Value = $true
                }
                elseif ($InEntry.Value) {

                    # Preserve newlines inside multiline CMTrace messages.
                    $Buffer.Value += [Environment]::NewLine + $line
                }
                else {

                    # Output non-CMTrace content rather than silently
                    # discarding it.
                    if (-not [string]::IsNullOrWhiteSpace($line)) {
                        Write-Host $line -ForegroundColor DarkGray
                    }

                    continue
                }

                # A complete CMTrace entry ends with its metadata block.
                if (
                    $InEntry.Value -and
                    $Buffer.Value -match '\]LOG\]!><time=".*?"\s+date=".*?"\s+component=".*?"\s+context=".*?"\s+type="\d+"\s+thread=".*?"\s+file=".*?">$'
                ) {
                    Write-CMTraceEntry -Entry $Buffer.Value

                    $Buffer.Value  = $null
                    $InEntry.Value = $false
                }
            }
        }
    }

    process {

        foreach ($logPath in $Path) {

            if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) {
                Write-Error "Log file not found: $logPath"
                continue
            }

            $resolvedPath = (Resolve-Path -LiteralPath $logPath).Path

            $buffer  = $null
            $inEntry = $false

            # Force the result into an array so empty, single-line and
            # multiline files are handled consistently.
            $initialLines = @(
                Get-Content -LiteralPath $resolvedPath -Tail $Tail
            )

            Write-CMTraceLines `
                -Lines $initialLines `
                -Buffer ([ref]$buffer) `
                -InEntry ([ref]$inEntry)

            if (-not $Wait) {

                if ($inEntry -and $null -ne $buffer) {
                    Write-CMTraceEntry -Entry $buffer
                }

                continue
            }

            Write-Host
            Write-Host 'Press Q to stop following the log.' -ForegroundColor DarkGray
            Write-Host

            $fileInfo = Get-Item -LiteralPath $resolvedPath
            $position = $fileInfo.Length

            $stream = [System.IO.FileStream]::new(
                $resolvedPath,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite
            )

            try {

                $null = $stream.Seek(
                    $position,
                    [System.IO.SeekOrigin]::Begin
                )

                $reader = [System.IO.StreamReader]::new($stream)

                try {

                    while ($true) {

                        if ([Console]::KeyAvailable) {

                            $key = [Console]::ReadKey($true)

                            if ($key.Key -eq [ConsoleKey]::Q) {
                                break
                            }
                        }

                        $newLines = [System.Collections.Generic.List[string]]::new()

                        while (-not $reader.EndOfStream) {
                            $newLines.Add($reader.ReadLine())
                        }

                        if ($newLines.Count -gt 0) {

                            Write-CMTraceLines `
                                -Lines @($newLines) `
                                -Buffer ([ref]$buffer) `
                                -InEntry ([ref]$inEntry)
                        }

                        Start-Sleep -Milliseconds 200
                    }
                }
                finally {
                    $reader.Dispose()
                }
            }
            finally {
                $stream.Dispose()
            }
        }
    }
}


if (-not (Get-Alias -Name cmlog -ErrorAction SilentlyContinue)) {
    Set-Alias -Name cmlog -Value Get-CMTraceLog
}
