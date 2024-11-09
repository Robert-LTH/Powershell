function Write-Log {
    param(
        $Message
    )
    Write-Host "[$((Get-Date).ToString("yyyyMMddTHH:mm:ssZ"))] $Message"
}

# https://docs.microsoft.com/en-us/windows/desktop/wua_sdk/updating-the-windows-update-agent
$WURedistCAB = 'http://update.microsoft.com/redist/wuredist.cab'
$TempFileName = New-TemporaryFile
Invoke-WebRequest -Uri $WURedistCAB -UseBasicParsing -OutFile $TempFileName
$Sig = Get-AuthenticodeSignature -FilePath $TempFileName

if ($Sig.SignerCertificate.Subject -match 'O=Microsoft Corporation' -and $Sig.Status -eq 'Valid') {
    Write-Log "Signature is valid, proceed."
    $TempDirectory = "$TempFileName-dir"
    New-Item -ItemType Container -Path $TempDirectory | Out-Null
    Start-Process -NoNewWindow -Wait "expand.exe" -ArgumentList "$TempFileName $TempDirectory" | Out-Null
    $XMLFile = Get-ChildItem -Path $TempDirectory | Select-Object -First 1
    try {
        $XMLObject = [xml](Get-Content -Path $XMLFile.FullName)
        Write-Log "Created XML-object!"
    } catch {
        Write-Log "Failed to create XML-object: $_"
    }

    $Architecture = @{
        'amd64' = 'x64'
        'IA64' = 'ia64'
        'x86' = 'x86'   
    }
    
    $StandaloneRedistVersion = $XMLObject.WURedist.StandaloneRedist.Version
    Write-Log "StandaloneRedistVersion = '$StandaloneRedistVersion'"
    Write-Log "Processor architecture: $($Architecture."$($env:PROCESSOR_ARCHITECTURE)")"
    $UpdateAgentInfo = New-Object -ComObject Microsoft.Update.AgentInfo
    $ApiMajorVersion = $UpdateAgentInfo.GetInfo("ApiMajorVersion") 
    $ApiMinorVersion = $UpdateAgentInfo.GetInfo("ApiMinorVersion") 
    $ProductVersionString = $UpdateAgentInfo.GetInfo("ProductVersionString")

    $XMLObject.WURedist.StandaloneRedist.architecture | Where-Object { $_.name -eq $Architecture."$($env:PROCESSOR_ARCHITECTURE)" } | ForEach-Object {
        try { $ClientVersion = [version]::new($_.clientVersion) } catch { Write-Log "$_" }
        try { $ProductVersion = [version]::new($ProductVersionString) } catch { Write-Log "$_" }
        if ($ClientVersion -ge $ProductVersion) {
            Write-Log "ClientVersion is newer! Do stuf!"
        }
        else{
            Write-Log "Up to date!"
        }
    }


    <#
    SELECT v_R_System.Netbios_Name0, v_GS_WINDOWSUPDATEAGENTVERSIO.Version0
    FROM v_GS_WINDOWSUPDATEAGENTVERSIO
    INNER JOIN v_R_System ON v_GS_WINDOWSUPDATEAGENTVERSIO.ResourceID = v_R_System.ResourceID
    WHERE v_GS_WINDOWSUPDATEAGENTVERSIO.Version0 <> 'ISNULL'
    ORDER BY v_GS_WINDOWSUPDATEAGENTVERSIO.Version0
    #>
    Remove-Item -Force $TempFileName
    Remove-Item -Force -Recurse $TempDirectory
}
else {
    Write-Host "Failed to verify signature of '$WURedistCAB'"
}
