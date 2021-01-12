function Get-RemoteCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(1,65535)]
        [int]$Port
    )
    process {
        $TcpClient = New-Object Net.Sockets.TcpClient $ComputerName,$Port
        if ($TcpClient) {
            $TcpClient.SendTimeout = 5000
            $TcpClient.ReceiveTimeout = 5000
            $SslStream = New-Object Net.Security.SslStream $TcpClient.GetStream(), $true, ([System.Net.Security.RemoteCertificateValidationCallback]{ $true })
            if ($SslStream) {
                $SslStream.ReadTimeout = 5000
                $SslStream.WriteTimeout = 5000
                if ($PSVersionTable.PSVersion.Major -eq 7) {
                    $SslClientAuthenticationOptions = [System.Net.Security.SslClientAuthenticationOptions]::new()
                    $SslClientAuthenticationOptions.CertificateRevocationCheckMode = 'NoCheck'
                    $SslClientAuthenticationOptions.TargetHost = $ComputerName
                    $SslClientAuthenticationOptions.EnabledSslProtocols = [System.Security.Authentication.SslProtocols]::Default
                    $SslStream.AuthenticateAsClient($SslClientAuthenticationOptions)
                }
                else {
                    $SslStream.AuthenticateAsClient($ComputerName)
                }
                if ($SslStream.IsAuthenticated) {
                    New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $SslStream.RemoteCertificate
                }
                $SslStream.Dispose()
            }
            else {
                throw "Failed to create SslStream"
            }
            $TcpClient.Dispose()
        }
        else {
            throw "Failed to create a TcpClient"
        }
    }
}
