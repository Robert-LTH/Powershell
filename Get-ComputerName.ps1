 function Main {
    # Module 'DnsClient' can be found in 'C:\windows\system32\WindowsPowershell\v1.0\Modules'
    # Simply copy the whole DnsClient-folder to a package and then run this script to set OSDComputerName according to the function Get-ComputerName
    Import-Module ".\DnsClient\DnsClient.psd1"
    try {
        $tsenv = New-Object -ComObject "Microsoft.SMS.TSEnvironment"
        $tsenv.Value("OSDComputerName") = Get-ComputerName
        Write-Host "Current value of OSDComputerName: '$($tsenv.Value("OSDComputerName"))'"
    } catch [System.Runtime.InteropServices.COMException] {
        Write-Host "Failed to init TSEnvironment"
    }
    if (-not $tsenv) {
        Get-ComputerName
    }

}

function Get-LUNetIPAddress {
    # This will run in WinPE, if adapter is DHCPEnabled and it has an IP we return the IP(s) of the adapter
    Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Property IPAddress -Filter "DHCPEnabled = TRUE" | ? { ($_.IPAddress).Count -ge 1 } | Select-Object -ExpandProperty IPAddress
}

function Get-ComputerName {
    # Get name from dns for every IP that is available on the computer and cut off the domain, avoid the 'hosts'-file
    $ComputerName = Get-LUNetIPAddress | ForEach-Object {
        Resolve-DnsName -ErrorAction SilentlyContinue -DnsOnly -NoHostsFile -Type PTR -Name $_ | Where-Object { $_.Section -eq 'Answer' } | Select-Object -ExpandProperty NameHost | ForEach-Object {
            $_ -split '\.' | Select-Object -First 1 
        }
    } | Where-Object {
        if ($_ -notmatch 'localhost') {
            $_
        }
    }

    if (-not $ComputerName) {
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
        } | Where-Object { $_ -notmatch ' ' } # Add all characters that can not be part of computername
        # We need to check the length, build final name here
        $SerialNumberAndManufacturer = "$($Manufacturer)$($SerialNumber)"
        # If we have all data and its less than the maximum length, use it
        if ($Manufacturer -and $SerialNumber -and $SerialNumberAndManufacturer.Length -le 15) {
            $ComputerName = $SerialNumberAndManufacturer
        }
    }
    # At this point we return w/e name we have
    return $ComputerName
}

Main
