function Get-RandomPassword {
<#
    .Example
        $LCBaseasciicode = 97
        $LCasciicodes = $LCBaseasciicode..($LCBaseasciicode+25) | % { [char][byte]$_ }

        $UCBaseasciicode = 65
        $UCasciicodes = $UCBaseasciicode..($UCBaseasciicode+25) | % { [char][byte]$_ }
        $NumbersBaseasciicode = 48
        $Numbers = $NumbersBaseasciicode..($NumbersBaseasciicode+9)| % { [char][byte]$_ }

        $Characters = $LCasciicodes + $UCasciicodes + $Numbers + '!"-'.ToCharArray()

        Get-RandomPassword -Characters $Characters
#>
    param(
        [string[]]$Characters,
        $Length = 15
    )
    $output = [char[]]::new($Length)
    for ($i=0;$i -lt $Length;$i++) {
        $char = $Characters | Get-Random
        $output.Set($i,$char)
    }
    [string]::new($output)
}
