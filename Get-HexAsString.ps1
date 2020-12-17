function Get-HexAsString {
    param(
        [byte[]]$Bytes
    )
    $SB = [System.Text.StringBuilder]::new()
    $Bytes | ForEach-Object {
        $SB.Append(($_.ToString("x2"))) |Out-Null
    }
    $SB.ToString()
}
