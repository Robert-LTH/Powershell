function Write-DebouncedLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath,

        [int]$IntervalSeconds = 3,

        [string]$Name = 'Default',

        [string]$Separator = [Environment]::NewLine
    )

    begin {
        if ([string]::IsNullOrWhiteSpace($Name)) {
            $bufferName = 'Default'
        }
        else {
            $bufferName = $Name
        }

        if ($null -eq $script:DebouncedLogBuffers) {
            $script:DebouncedLogBuffers = @{}
        }

        if ($null -eq $script:DebouncedLogBufferLock) {
            $script:DebouncedLogBufferLock = [object]::new()
        }

        $resolvedLogPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($LogPath)
        $logDirectory = [System.IO.Path]::GetDirectoryName($resolvedLogPath)

        if ($logDirectory -and -not [System.IO.Directory]::Exists($logDirectory)) {
            [System.IO.Directory]::CreateDirectory($logDirectory) | Out-Null
        }
    }

    process {
    [System.Threading.Monitor]::Enter($script:DebouncedLogBufferLock)

    try {
        if ([string]::IsNullOrWhiteSpace($bufferName)) {
            $bufferName = 'Default'
        }

        $expectedQueueType = [System.Collections.Concurrent.ConcurrentQueue[string]]

        $queueExists = $script:DebouncedLogBuffers.ContainsKey($bufferName)

        if ($queueExists) {
            $queue = $script:DebouncedLogBuffers[$bufferName]
        }
        else {
            $queue = $null
        }

        if ($null -eq $queue -or $queue -isnot $expectedQueueType) {
            $queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
            $script:DebouncedLogBuffers[$bufferName] = $queue
        }

        if ($null -eq $queue) {
            throw [System.InvalidOperationException]::new(
                "Debounced log queue '$bufferName' could not be initialized."
            )
        }

        if ($queue -isnot $expectedQueueType) {
            throw [System.InvalidOperationException]::new(
                "Debounced log queue '$bufferName' has invalid type '$($queue.GetType().FullName)'. Expected ConcurrentQueue[string]."
            )
        }
    }
    finally {
        [System.Threading.Monitor]::Exit($script:DebouncedLogBufferLock)
    }

    $queue.Enqueue($Text)

    Restart-ScriptTimer `
        -Name "DebouncedLog.$bufferName" `
        -IntervalSeconds $IntervalSeconds `
        -Once `
        -MessageData @{
            Queue      = $queue
            BufferName = $bufferName
            LogPath    = $resolvedLogPath
            Separator  = $Separator
        } `
        -Action {
            param($Data)

            if ($null -eq $Data.Queue) {
                throw [System.InvalidOperationException]::new(
                    "Timer action received a null queue for '$($Data.BufferName)'."
                )
            }

            $items = [System.Collections.Generic.List[string]]::new()
            $item = $null

            while ($Data.Queue.TryDequeue([ref]$item)) {
                $items.Add($item)
                $item = $null
            }

            if ($items.Count -eq 0) {
                return
            }

            $output = $items -join $Data.Separator

            [Console]::WriteLine($output)

            [System.IO.File]::AppendAllText(
                $Data.LogPath,
                $output + [Environment]::NewLine,
                [System.Text.Encoding]::UTF8
            )
        } | Out-Null
    }
}
