function Get-InstalledWin32Application {
    $UninstallRegPath = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    $UninstallRegPath | ForEach-Object {
        $Bitness = if ($_ -match 'Wow6432Node') { "x86" } else { "x64" }
        Get-ChildItem -Path $_ | Where-Object { -not [string]::IsNullOrEmpty($_.GetValue("DisplayVersion")) -and -not [string]::IsNullOrEmpty($_.GetValue("DisplayName")) } | ForEach-Object {
            try {
                $Version = [System.Version]::Parse($_.GetValue("DisplayVersion"))
            } catch { $Version = $_.GetValue("DisplayVersion") }
            @{
                Name = $_.GetValue("DisplayName")
                Version = $Version
                Bitness = $Bitness
            }
        }
    }
}
