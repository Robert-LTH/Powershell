<#
.Synopsis
   Set original owner and restore ACL
.DESCRIPTION
   Set original owner and restore ACL
.EXAMPLE
   Invoke-LockFile -Path 'Path to file' -OriginalInfo $InfoSavedWhenUnlockingFile
.INPUTS
   Path is the path to the file to handle
.OUTPUTS
   Outputs a PSObject containing OriginalOwner and ACLPath which contains the path to the file where the original ACL was stored.
#>
function Invoke-LockFile {
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [psobject]$OriginalInfo
    )
    begin {
        
        If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {
            Write-Error "You need to run as admin!"
        }

        $SystemRoot = [Environment]::GetFolderPath("System")
        $Owner = $OriginalInfo.OriginalOwner
        if ($Owner -eq $null) {
            $Owner = $NewOwner
            if ($Owner -eq $null) {
                $Owner = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            }
        }
        $OriginalACLPath = $OriginalInfo.ACLPath
        $BaseParameters = @{
            ErrorAction = 'SilentlyContinue'
            NoNewWindow = $true
            Wait = $true
            Passthru = $true
        }
    }
    process {
        # Restore owner, this needs to be done before restoring the ACL as the old ACL does not allow us to do this
        $SetownerProc = Start-Process @BaseParameters -FilePath "$SystemRoot\icacls.exe" -ArgumentList "$Path /setowner `"$Owner`""
        if ($SetownerProc.ExitCode -ne 0) {
            Write-Error "Failed to set old owner ($Owner) on '$Path' ($SystemRoot\icacls.exe exitcode '$($GrantProc.ExitCode)')"
        }

        # Restore the old ACL to make sure we dont leave any traces behind
        $RestoreACLProc = Start-Process @BaseParameters -FilePath "$SystemRoot\icacls.exe" -ArgumentList "$(Split-Path -Path $Path -Parent) /restore $OriginalACLPath"
        if ($RestoreACLProc.ExitCode -ne 0) {
            Write-Error "Failed to restore old acl $OriginalACLPath on '$Path' ($SystemRoot\icacls.exe exitcode '$($GrantProc.ExitCode)')"
        }
    }
}
