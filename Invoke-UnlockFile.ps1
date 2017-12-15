<#
.Synopsis
   Take ownership and grant full access to current user.
.DESCRIPTION
   Take ownership and grant full access to current user. This is needed when accessing "protected" files in the system.
.EXAMPLE
   $InfoNeededWhenLockingFile = Invoke-UnlockFile -Path 'Path to file'
.INPUTS
   Path is the path to the file to handle
.OUTPUTS
   Outputs a PSObject containing OriginalOwner and ACLPath which contains the path to the file where the original ACL was stored.
#>
function Invoke-UnlockFile {
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    begin {

        If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {
            Write-Error "You need to run as admin!"
        }

        $SystemRoot = [Environment]::GetFolderPath("System")
        
        function Get-TemporaryFilename {
            $TempFileName = [System.IO.Path]::GetTempFileName()
            #Remove-Item -Path $TempFileName -Force -ErrorAction Stop
            Write-Output $TempFileName
        }
        $BaseParameters = @{
            ErrorAction = 'SilentlyContinue'
            NoNewWindow = $true
            Wait = $true
            Passthru = $true
        }
        $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    }
    process {
        $OriginalOwner = Get-Acl -Path $Path | Select-Object -ExpandProperty Owner
        $OriginalACLPath = Get-TemporaryFilename
        $TakeownProc = Start-Process @BaseParameters -FilePath "$SystemRoot\takeown.exe" -ArgumentList "/f $Path"
        if ($TakeownProc.ExitCode -ne 0) {
            Write-Error "Failed to take ownership of '$Path' ($SystemRoot\takeown.exe exitcode '$($TakeownProc.ExitCode)')"
        }
        
        # Save the old ACL, to avoid leaving records in the ACL when we are done
        $ACLSaveProc = Start-Process @BaseParameters -FilePath "$SystemRoot\icacls.exe" -ArgumentList "$Path /save $OriginalACLPath"
        if ($ACLSaveProc.ExitCode -ne 0) {
            # We failed, Restore owner
            $SetownProc = Start-Process @BaseParameters -FilePath "$SystemRoot\icacls.exe" -ArgumentList "$Path /setowner `"$OriginalOwner`""
            if ($SetownProc.ExitCode -ne 0) {
                Write-Error "Could not restore owner to '$OriginalOwner'!"
            }
            Write-Error "Failed to save original ACL of '$Path' ($SystemRoot\icacls.exe exitcode '$($ACLSaveProc.ExitCode)')"
        }

        
        # Add current user with Full Control
        $GrantProc = Start-Process @BaseParameters -FilePath "$SystemRoot\icacls.exe" -ArgumentList "$Path /Grant $($CurrentUser):(F)"
        if ($GrantProc.ExitCode -ne 0) {
            # We failed, Restore owner
            $SetownProc = Start-Process @BaseParameters -FilePath "$SystemRoot\icacls.exe" -ArgumentList "$Path /setowner `"$OriginalOwner`""
            if ($SetownProc.ExitCode -ne 0) {
                Write-Error "Could not restore owner to '$OriginalOwner'!"
            }
            Write-Error "Failed to grant access for '$CurrentUser' to '$Path' ($SystemRoot\icacls.exe exitcode '$($GrantProc.ExitCode)')"
        }
    }
    end {
        if ($OriginalOwner -and $OriginalACLPath) {
            $return = New-Object psobject
            $return | Add-Member -NotePropertyName OriginalOwner -NotePropertyValue $OriginalOwner
            $return | Add-Member -NotePropertyName ACLPath -NotePropertyValue $OriginalACLPath
            $return
        }
    }
}
