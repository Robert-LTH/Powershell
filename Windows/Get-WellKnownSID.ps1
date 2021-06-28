function Get-WellKnownSID {
    <#
        .SYNOPSIS
            Get the SID of a wellknown SID by supplying the name of the SID
        .EXAMPLE
            Get-WellKnownSID -WellKnownSidType 'WorldSid'
        .INPUTS
            $WellKnownSidType - One of System.Security.Principal.WellKnownSidType
            $DomainSID - If needed then this is the SID of the domain the WellKnownSidType belongs to
        .OUTPUTS
            String with the SID
        .NOTES
            The following list needs DomainSID:
                'AccountAdministratorSid'
                'AccountGuestSid'
                'AccountKrbtgtSid'
                'AccountDomainAdminsSid'
                'AccountDomainUsersSid'
                'AccountDomainGuestsSid'
                'AccountComputersSid'
                'AccountControllersSid'
                'AccountCertAdminsSid'
                'AccountSchemaAdminsSid'
                'AccountEnterpriseAdminsSid'
                'AccountPolicyAdminsSid'
                'AccountRasAndIasServersSid'

            More info: https://docs.microsoft.com/en-us/dotnet/api/system.security.principal.securityidentifier
    #>
    param(
        [System.Security.Principal.WellKnownSidType]$WellKnownSidType,
        [System.Security.Principal.SecurityIdentifier]$DomainSID = $null
    )
    [System.Security.Principal.SecurityIdentifier]::new($WellKnownSidType,$DomainSID).Value
}
