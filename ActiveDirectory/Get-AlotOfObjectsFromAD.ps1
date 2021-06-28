. "$PSScriptRoot\Get-LDAPProperties.ps1"

function Get-AlotOfObjectsFromAD {
    $SearchSize = 1000
    $ADLimit = 1000
    $Objects = [System.Collections.ArrayList]::new()

    # If Position = 0 only last object is returned
    $Position = 1
    $PropertySplat = @{
        LDAPFilter = "(&(objectClass=computer))"
        Properties = 'distinguishedName','CN'
        # Position = 0
        #DirectoryVirtualListview = [System.DirectoryServices.DirectoryVirtualListView]::new($SearchSize,0,$Position)
        # Position = 1
        DirectoryVirtualListview = [System.DirectoryServices.DirectoryVirtualListView]::new(0,$SearchSize,$Position)
        SortOption = ([System.DirectoryServices.SortOption]::new("CN",[System.DirectoryServices.SortDirection]::Ascending))
    }
    while (($result = Get-LDAPProperties @PropertySplat)) {
        
        $result | ForEach-Object {
            $Objects.Add($_) | Out-Null
        }
        $ResultCount = ($result| Measure-Object).Count
        if ($ResultCount -eq ($SearchSize+1) -or $ResultCount -eq $ADLimit) {
            $Position = $Position + $SearchSize
            $PropertySplat.DirectoryVirtualListview = [System.DirectoryServices.DirectoryVirtualListView]::new(0,$SearchSize,$Position)
        }
        else {
            break
        }
    }

    Write-Output $Objects
}
