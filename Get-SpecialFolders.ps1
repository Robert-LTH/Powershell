begin {
    $FolderNames = [Environment+SpecialFolder] | Get-Member -MemberType Property -Static | Select-Object -ExpandProperty Name
}
process{
    $FolderNames | ForEach-Object {
        New-Object PSObject -Property @{
            Name = $_
            Path = ([Environment]::GetFolderPath($_))
        }
    }
}
