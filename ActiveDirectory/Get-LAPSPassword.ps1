. "$PSScriptRoot\Get-LDAPProperties.ps1"
function Get-LAPSPassword {
    param(
        $ComputerName
    )
    $ADObjectParameters = @{
        LDAPFilter = "(&(objectClass=computer)(CN={0}))" -f $ComputerName
        Properties = @('ms-Mcs-AdmPwd','ms-Mcs-AdmPwdExpirationTime')
        SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        FindOne = $true
    }

    Get-LDAPProperties @ADObjectParameters | ForEach-Object {
        $_ | Add-Member ExpirationTime ([datetime]::FromFileTime($_.'ms-Mcs-AdmPwdExpirationTime'))
        $_
    }
    
}
