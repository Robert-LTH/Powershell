[Environment+SpecialFolder] | Get-Member -MemberType Property -Static | Select-Object -ExpandProperty Name | ForEach-Object {
    New-Object PSObject -Property @{
        Name = $_
        Path = ([Environment]::GetFolderPath($_))
    }
}
