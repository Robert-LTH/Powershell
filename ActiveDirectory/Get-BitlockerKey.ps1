. "$PSScriptRoot\Get-LDAPProperties.ps1"

function Get-BitlockerKey {
    param(
        $ComputerName
    )
    $ADObjectParameters = @{
        LDAPFilter = "(&(objectClass=computer)(CN={0}))" -f $ComputerName
        Properties = @('distinguishedName')
    }

    Get-LDAPProperties @ADObjectParameters | ForEach-Object -Process {
        $RIObjectParameters = @{
            LDAPFilter = "(&(objectClass=msFVE-RecoveryInformation))"
            SearchBase = $_.distinguishedName
            Properties = @('MSFVE-RecoveryPassword', 'modifyTimeStamp')
        }
        Get-LDAPProperties @RIObjectParameters
    }
}
