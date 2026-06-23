Import-Module WebAdministration

$SiteName   = "Default Web Site"
$HostName   = "host.domain.tld"
$Port       = 443
$Thumbprint = "‎DEADBEEF"

# Rensa thumbprint från osynliga tecken och mellanslag
$Thumbprint = ($Thumbprint -replace '[^a-fA-F0-9]', '').ToUpperInvariant()

# Kontrollera att certifikatet finns i LocalMachine\My
$Cert = Get-Item "Cert:\LocalMachine\My\$Thumbprint"

# Skapa HTTPS-binding i IIS
New-WebBinding `
    -Name $SiteName `
    -Protocol https `
    -IPAddress "*" `
    -Port $Port `
    -HostHeader $HostName `
    -SslFlags 1

# Koppla certifikatet till bindingen
$BindingPath = "IIS:\SslBindings\!$Port!$HostName"

if (Test-Path $BindingPath) {
    Remove-Item $BindingPath
}

New-Item `
    -Path $BindingPath `
    -Thumbprint $Thumbprint `
    -SSLFlags 1
