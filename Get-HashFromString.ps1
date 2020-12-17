function Get-HashFromString {
    param(
        [ValidateNotNullOrEmpty()]
        $String,
        [ValidateSet('ASCII','BigEndianUnicode','Default','Unicode','UTF32','UTF7','UTF8')]
        $Encoding = "Unicode",
        [ValidateSet('MD5','SHA1','SHA256','SHA384','SHA512')]
        $HashAlgorithm = "SHA1"
    )
    $_Encoding = [System.Text.Encoding]::$Encoding
    if (-not $Encoding) {
        throw "Could not find encoding '$Encoding'"
    }
    $bytes = $_Encoding.GetBytes($String);
    if ($bytes.Length -le 0) {
        throw "Nothing to hash..."
    }
    $Hasher = New-Object "System.Security.Cryptography.$($HashAlgorithm)CryptoServiceProvider"
    $Hasher.ComputeHash($bytes)
}
