function Save-CertificateFromSignedFile {
    param(
        $FilePath,
        $OutFile
    )
    $Certificate = Get-AuthenticodeSignature -FilePath $FilePath | Select-Object -ExpandProperty SignerCertificate
    [System.IO.File]::WriteAllBytes($OutFile,$Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
}
