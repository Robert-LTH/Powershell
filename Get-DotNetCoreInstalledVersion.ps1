function Get-DotNetCoreInstalledVersion {
    param(
        [string[]] $ExePath = @("C:\Program Files\dotnet\dotnet.exe","C:\Program Files (x86)\dotnet\dotnet.exe"),
        [ValidateSet("runtimes", "sdks")]
        [string] $Type
    )
    $Arguments = "--list-{0}" -f $Type
    $ExePath | ForEach-Object {
        if (-not (Test-Path -ErrorAction SilentlyContinue -Path $_)) {
            Write-Error "Executable does not exist: '$_'"
        }
        else {
            $TemporaryFile = New-TemporaryFile
            $proc = Start-Process -FilePath $_ -ArgumentList $Arguments -Wait -NoNewWindow -RedirectStandardOutput $TemporaryFile -PassThru
            if ($proc.ExitCode -eq 0) {
                Get-Content -Path $TemporaryFile | ForEach-Object {
                    $_ | Select-string -Pattern '(?<name>[a-zA-Z\.]+) (?<version>[0-9\.]+) \[(?<path>[a-zA-Z0-9\-\\:\.\(\) ]+)\]' | ForEach-Object {
                        @{
                            Version = $_.Matches.Groups | Where-Object { $_.Name -eq 'version' } | Select-Object -ExpandProperty Value
                            Name = $_.Matches.Groups | Where-Object { $_.Name -eq 'name' } | Select-Object -ExpandProperty Value
                            Path = $_.Matches.Groups | Where-Object { $_.Name -eq 'path' } | Select-Object -ExpandProperty Value
                        }
                    }
                }
            }
            $TemporaryFile | Remove-Item
        }
    }
}
