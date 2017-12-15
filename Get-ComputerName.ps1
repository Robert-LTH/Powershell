function Get-ComputerName {
    # Set computername to autogenerate
    $ComputerName = '*'

    if ($ComputerName -eq '*') {
        # Get name from dns for every IP that is available on the computer and cut off the domain, avoid the 'hosts'-file
        $ComputerName = Get-NetIPAddress | Select-Object -ExpandProperty IPAddress | % { Resolve-DnsName -ErrorAction SilentlyContinue -DnsOnly -NoHostsFile -Type PTR -Name $_ | Where-Object { $_.Section -eq 'Answer' } | Select-Object -ExpandProperty NameHost | % { $_ -split '\.' | Select-Object -First 1 } } | Where-Object { $_ -notmatch 'localhost' }
    }
    if ($ComputerName -eq '*') {
        # Get the SerialNumber and Manufacturer available in BIOS
        $BIOSInfo = Get-WmiObject -ErrorAction SilentlyContinue -Namespace root\cimv2 -Class Win32_BIOS -Property SerialNumber,Manufacturer
        $SerialNumber = $BIOSInfo | Select-Object -ExpandProperty SerialNumber
        # Actual manufacturer does not fit a dnsname, replace with short name
        $Manufacturer = $BIOSInfo | Select-Object -ExpandProperty Manufacturer | % {
            $_ -replace 'Hewlett-Packard','HP' `
            -replace 'Dell Inc.','DELL' `
            -replace 'Microsoft Corporation','MS' `
            -replace 'Sony Corporation','SONY' `
            -replace 'LENOVO','LNVO'
        } | Where-Object { $_ -notmatch ' ' }
        # We need to check the length, build final name here
        $SerialNumberAndManufacturer = "$($Manufacturer)-$($SerialNumber)"
        # If we have all data and its less than the maximum length, use it
        if ($Manufacturer -and $SerialNumber -and $SerialNumberAndManufacturer.Length -le 15) {
            $ComputerName = $SerialNumberAndManufacturer
        }
    }
    # At this point we return w/e name we have
    return $ComputerName
}
