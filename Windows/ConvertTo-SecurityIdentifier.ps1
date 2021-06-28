function ConvertTo-SecurityIdentifier {
    param(
        [string] $Domain,
        [string] $Username
    )
    if (-not [string]::IsNullOrEmpty($Domain)) {
        [System.Security.Principal.NTAccount]::new($Domain,$Username).Translate([System.Security.Principal.SecurityIdentifier]).Value
    }
    else {
        [System.Security.Principal.NTAccount]::new($Username).Translate([System.Security.Principal.SecurityIdentifier]).Value
    }
}
