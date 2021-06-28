function Get-LDAPProperties {
    <#
    .SYNOPSIS
        Get LDAP objects with selected attributes
    .DESCRIPTION
        Query Active Directory with the need of installing Get-ADObject.
    .EXAMPLE
        $ADObjectParameters = @{
            LDAPFilter = "(&(objectClass=computer)(CN=MYCOMPUTER))"
            SearchBase = "LDAP://OU=Computers,DC=domain,DC=tld"
            Properties = @('distinguishedName')
        }

        Get-LDAPProperties @ADObjectParameters
    .EXAMPLE
        $ADObjectParameters = @{
            LDAPFilter = "(&(objectClass=computer)(CN=MYCOMPUTER))"
            SearchBase = "LDAP://OU=Computers,DC=domain,DC=tld"
            Properties = @('distinguishedName','CN')
            DirectoryVirtualListview = ([System.DirectoryServices.DirectoryVirtualListView]::new(0,10,5))
            SortOption = [System.DirectoryServices.SortOption]::new('CN',[System.DirectoryServices.SortDirection]::Ascending)
        }

        Get-LDAPProperties @ADObjectParameters
    .OUTPUTS
        An array with the selected attributes for the objects that match the filter
    .NOTES
        Only tested against Active Directory from Windows 10

        Active Directory limits the amount of returned records to 1000 and if the query results in more records you should use a DirectoryVirtualListView along with a SortOption.
    #>
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string[]]$Properties,
        # If you need a guide to write LDAPFilters, here is an excellent one: https://social.technet.microsoft.com/wiki/contents/articles/5392.active-directory-ldap-syntax-filters.aspx
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LDAPFilter,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SearchBase,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [bool] $CacheResults,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [System.DirectoryServices.SearchScope] $SearchScope,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [System.DirectoryServices.DereferenceAlias] $DereferenceAlias,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [System.DirectoryServices.ReferralChasingOption] $ReferralChasing,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [System.DirectoryServices.AuthenticationTypes] $AuthenticationTypes,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [TimeSpan] $Timeout,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(0,1000)]
        [Int32] $SizeLimit,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [bool] $Tombstone,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [System.DirectoryServices.SortOption] $SortOption,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [System.DirectoryServices.DirectoryVirtualListView] $DirectoryVirtualListview,
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [switch] $FindOne
    )
    

    # Is this really needed?
    if ($null -ne $AuthenticationTypes) {
        $SearchRoot.AuthenticationType = $AuthenticationTypes
    }

    $Searcher = New-Object DirectoryServices.DirectorySearcher
    if ([string]::IsNullOrEmpty($SearchBase)) {
        $Searcher.SearchRoot = [System.DirectoryServices.DirectoryEntry]::new()
    }
    else {
        if ($SearchBase.Substring(0,4) -ne 'LDAP') {
            $Searcher.SearchRoot = [System.DirectoryServices.DirectoryEntry]::new(("LDAP://{0}" -f $SearchBase))
        }
        else {
            $Searcher.SearchRoot = [System.DirectoryServices.DirectoryEntry]::new($SearchBase)
        }
    }

    $Searcher.Filter = $LDAPFilter
    
    $Searcher.Tombstone = $Tombstone
    $Searcher.CacheResults = $CacheResults
    if ($Properties.Length -gt 0) {
        $Searcher.PropertiesToLoad.AddRange($Properties)
    }
    if ($SizeLimit -gt 0) {
        $Searcher.SizeLimit = $SizeLimit
    }
    if ($null -ne $DirectoryVirtualListview) {
        if ($null -eq $SortOption) {
            throw "DirectoryVirtualListview requires SortOption to be specified!"
        }
        $Searcher.VirtualListView = $DirectoryVirtualListview
    }
    if ($null -ne $SortOption) {
        $Searcher.Sort = $SortOption
    }
    if ($null -ne $Timeout) {
        $Searcher.ClientTimeout = $Timeout
    }
    if ($null -ne $ReferralChasing) {
        $Searcher.ReferralChasing = $ReferralChasing
    }
    if ($null -ne $DereferenceAlias) {
        $Searcher.DerefAlias = $DereferenceAlias
    }

    if ($FindOne.IsPresent) {
        $searchResult = $Searcher.FindOne()
    }
    else {
        $searchResult = $Searcher.FindAll()
    }
    
    foreach ($sr in $searchResult) {
        $returnObj = New-Object PSObject
        if ($Properties.Length -le 0) {
            foreach ($Property in $sr.Properties.GetEnumerator()) {
                $returnObj | Add-Member -MemberType NoteProperty -Name $Property.Key -Value $Property.Value
            }
        }
        else {
            foreach ($Property in $Properties) {
                $returnObj | Add-Member -MemberType NoteProperty -Name $Property -Value ($sr.Properties[$Property] -join ',')
            }
        }
        if (($returnObj | Get-Member -MemberType NoteProperty).Count -gt 0) {
            $returnObj
        }
    }
    if ($null -ne $Searcher) {
        $Searcher.Dispose()
    }
    
    if ($null -ne $SearchRoot) {
        $SearchRoot.Dispose()
    }
    
}
