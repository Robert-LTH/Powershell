function Get-ActiveDirectoryDomainSecurityIdentifier {
    param(
        [string] $Domain
    )
    if (-not [string]::IsNullOrEmpty($Domain)) {
        $Domain = $Domain.ToUpper()
    }
    [System.Security.Principal.SecurityIdentifier]::new([System.DirectoryServices.DirectoryEntry]::new($Domain).objectSid.Value,0).Value
}
