<#
.Synopsis
   Downloads the latest OneDriveSetup.exe
.DESCRIPTION
   Reads the same information as the OneDrive client and downloads any new version of it to the specified path.
.EXAMPLE
   Set-Location -Path 'C:\temp'
   Get-NewOneDriveSetup
.EXAMPLE
   Get-NewOneDriveSetup -TargetPath 'C:\temp'
.EXAMPLE
   Get-NewOneDriveSetup -TargetPath 'C:\temp' -OneDriveUpdateXMLUri 'http://www.updatedinfo.fakeurl/file.xml'
.INPUTS
   TargetPath - Final destination on the local machine
   OneDriveUpdateXMLUri - Uri of the Xml-file that contains information about OneDrive version
#>
function Get-NewOneDriveSetup {
    param(
        [string]$TargetPath = '.\OneDriveSetup.exe',
        # Url was recorded in OneDrives updatelog
        [string]$OneDriveUpdateXMLUri = 'http://g.live.com/1rewlive5skydrive/OneDriveProduction?OneDriveUpdate=a5c99134de74b369b67a57eb90a'
    )
    
    # Fetch the xml-file
    $HTTPResponse = Invoke-WebRequest -Uri $OneDriveUpdateXMLUri -UseBasicParsing
    
    # Response contains garbage in the beginning, start parsing at first '<'
    $OneDriveUpdateInfoXML = [xml]$HTTPResponse.Content.Substring(($HTTPResponse.Content.IndexOf('<')))

    # Read FileVersion property of already donwloaded exe
    $CurrentLocalVersion = Get-Item -Path '.\OneDriveSetup.exe' | Select-Object -ExpandProperty VersionInfo | Select-Object -ExpandProperty FileVersion

    # Get latest version available for dowload
    $CurrentRemoteVersion = $OneDriveUpdateInfoXML.root.update.currentversion

    # If the versions differ we need to download the new one
    if ([Version]::new($CurrentLocalVersion) -lt [Version]::new($CurrentRemoteVersion)) {
        Write-Host "New version available!"
        
        # Generate a new temporary filename
        $DownloadedOneDriveSetupPath = [System.IO.Path]::GetTempFileName()

        # Download the new exe to the temporary location
        Invoke-WebRequest -Uri $OneDriveUpdateInfoXML.root.update.binary.url -UseBasicParsing -OutFile $DownloadedOneDriveSetupPath
        
        # If the temporary file exists, go ahead
        if (Test-Path -Path $DownloadedOneDriveSetupPath) {
            # Convert the hash provided in the xml to a format we can use
            $RemoteHash = ([System.Convert]::FromBase64String($OneDriveUpdateInfoXML.root.update.binary.sha256hash) | % { ("{0:X0}" -f $_).PadLeft(2,"0") }) -join ''

            # Get the hash of the downloaded file
            $LocalHash = (Get-FileHash -Path $DownloadedOneDriveSetupPath -Algorithm SHA256).Hash

            # If the two hashes match, the download was successful
            if ($LocalHash -eq $RemoteHash) {
                Write-Host "Download was successful"

                # Replace previously downloaded exe
                Move-Item -Force -Path $DownloadedOneDriveSetupPath -Destination $TargetPath

                Write-Host "Done updating!"
            
            }
        }
    }
}
