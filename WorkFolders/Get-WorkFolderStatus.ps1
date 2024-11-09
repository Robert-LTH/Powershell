function DecodeAttributes {
    param(
        $Attributes
    )
    [Enum]::GetNames(([System.IO.FileAttributes])) | ForEach-Object {
        if ($Attributes -band ([System.IO.FileAttributes]::"$_")) {
            [Enum]::Parse(([System.IO.FileAttributes]), $_)
        }
    }
}

#[enum]::GetNames([type]([System.IO.FileAttributes]))
$WFUserRegistryPath = "Registry::HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\WorkFolders\Partnership\Microsoft.SyncShare.UserData"
if (-not $WFUserFolder) {
    $WFUserFolder = Get-ItemPropertyValue -Path $WFUserRegistryPath -Name 'LocalFolder'
}
if (Test-Path -Path $WFUserFolder -ErrorAction Ignore) {
    Get-ChildItem -Recurse -Path $WFUserFolder | % {
        if ($_.Attributes -eq 524320) {
            $State = "currently syncing"
        }
        elseif ($_.Attributes -eq 525328) {
            $State = "Pinned"
        }
        elseif ($_.Attributes -eq 525329) {
            $State = "Pinned + Read-Only"
        }
        elseif ($_.Attributes -eq 525344) {
            $State = "Pinned + Archive"
        }
        elseif ($_.Attributes -eq 5248544) {
            $State = "always OnDemand"
        }
        else {
            $State = ""
        }
        [PSCustomObject]@{
            FullName          = $_.FullName
            State             = $State
            Attributes        = $_.Attributes
            DecodedAttributes = (DecodeAttributes -Attributes $_.Attributes) -join ','
        }
    }
}
else {
    Write-Error "Configured Work Folder root does not exist!"
}
<#
    13108018 - File changed during sync

#>

$LastSyncHResult = Get-ItemPropertyValue -Path $WFUserRegistryPath -Name 'LastSyncHResult'
if ($LastSyncHResult -ne 0) {
    # Get event
    # 13108018 = Syncing?
    # 2160591627 = Sync stopped (No network connection)
    Write-Host $LastSyncHResult
    #Get-WinEvent -LogName 'Microsoft-Windows-WorkFolders/Operational' -FilterXPath "*System[(EventID=2100)]]"
}
else {
    Write-Host "All good!"
}
