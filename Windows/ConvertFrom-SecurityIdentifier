function ConvertFrom-SecurityIdentifier {
    param(
        $SecurityIdentifier
    )
    [System.Security.Principal.SecurityIdentifier]::new($SecurityIdentifier).Translate([System.Security.Principal.NTAccount]).Value
}
