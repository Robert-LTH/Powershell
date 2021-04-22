function Get-DotNETFramework45Version {
    # https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#query-the-registry-using-code
    $DotNetFullPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"

    if (-not (Test-Path -Path $DotNetFullPath)) {
        Write-Host "DotNET Version is below 4.5"
    }

    $DotNetRelease = Get-ItemPropertyValue -Path $DotNetFullPath -Name 'Release'

    if ($DotNetRelease -eq '528040' -or $DotNetRelease -eq '528372' -or $DotNetRelease -eq '528049') {
        return [Version]::new("4.8")
    }
    if ($DotNetRelease -eq '461808' -or $DotNetRelease -eq '461814') {
        return [Version]::new("4.7.2")
    }
    if ($DotNetRelease -eq '461308' -or $DotNetRelease -eq '461310') {
        return [Version]::new("4.7.1")
    }
    if ($DotNetRelease -eq '460798' -or $DotNetRelease -eq '460805') {
        return [Version]::new("4.7")
    }
    if ($DotNetRelease -eq '394802' -or $DotNetRelease -eq '394806') {
        return [Version]::new("4.6.2")
    }
    if ($DotNetRelease -eq '394271' -or $DotNetRelease -eq '394254') {
        return [Version]::new("4.6.1")
    }
    if ($DotNetRelease -eq '393295') {
        return [Version]::new("4.6")
    }
    if ($DotNetRelease -eq '379893') {
        return [Version]::new("4.5.2")
    }
    if ($DotNetRelease -eq '378758') {
        return [Version]::new("4.5.1")
    }
    if ($DotNetRelease -eq '378389') {
        return [Version]::new("4.5")
    }
    throw "DotNET Framework >= 4.5 is not installed!"
}
