# http://www.msierrors.com/drivers/dpinst-exit-codes-explained/

function Get-DPInstExitCodeInformation {
    param(
        [string]$ExitCode
    )

    $DPInstInfo = New-Object psobject @{
        PackageInstallationFailure = $false
        RebootRequired = $false
        <#
        OperationStatus = 0
        DriversInstalled = 0
        DriversCopiedToDriverStore = 0
        DriversNotInstalled = 0
        #>
    }

    # Parse the number as a HexNumber and store it as UInt32 because the highest bit indicates a package install failure.
    $ExitCodeUInt32 = [UInt32]::Parse($ExitCode,([System.Globalization.NumberStyles]::HexNumber))
    # The highest 8 bytes tells us how it went and if we need to reboot afterwards
    $DPInstInfo.OperationStatus = (($ExitCodeUInt32 -band 0xFF000000) -shr 24)
    # Number of driver packages that could not be installed - This should always be zero
    $DPInstInfo.DriversNotInstalled = (($ExitCodeUInt32 -band 0x00FF0000) -shr 16)
    # Number of driver packages that have been copied to the driver store but haven’t been installed on a device
    $DPInstInfo.DriversCopiedToDriverStore = (($ExitCodeUInt32 -band 0x0000FF00) -shr 8)
    # Number of driver packages that have been installed on a device
    $DPInstInfo.DriversInstalled = (($ExitCodeUInt32 -band 0x000000FF))


    Switch ($DPInstInfo.OperationStatus) {
        0x80 {
            $DPInstInfo.PackageInstallationFailure = $true
        }
        0x40 {
            $DPInstInfo.RebootRequired = $true
        }
    }

    $DPInstInfo
}
