function Get-BinaryAddressAndNetmask {
    <#
    .SYNOPSIS
        Get binary representation of an IP and netmask
    .DESCRIPTION
        The function returns the binary representation of the address, the netmask and the broadcast address.
        A comparison can be done by checking if the value of the IP address is greater than the subnet address
        or less than the broadcast address.
    .EXAMPLE
        Get-BinaryAddressAndNetmask -sIPwithPrefixLength "192.168.45.57/32"
    .EXAMPLE
        $IP = Get-BinaryAddressAndNetmask -sIPwithPrefixLength "10.0.0.1/32"
        $Subnet = Get-BinaryAddressAndNetmask -sIPwithPrefixLength "10.0.0.0/16"
        if ($IP.IPAddress -gt $Subnet.IPAddress -and $IP.IPAddress -lt $Subnet.Broadcast) {
            Write-Host "IP address is inside subnet!"
        }
    .INPUTS
        sIPwithPrefixLength must contain the IP or subnet including the length (10.0.0.0/16)
    .OUTPUTS
        Hashtable:
            @{
                IPAddress
                Netmask
                Broadcast
            }
    #>
    param(
        # Regular expression used to match an IP was found at:
        # https://www.oreilly.com/library/view/regular-expressions-cookbook/9780596802837/ch07s16.html
        [Parameter(Mandatory=$true)]
        [ValidatePattern("^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$")]
        [string] $sIPwithPrefixLength
    )
    $Parts = $sIPwithPrefixLength -split '\/'

    $MaxValue = [uint64]::MaxValue
    $AddressSize = 64
    $IPObj = [ipaddress]::Parse($Parts[0])
    if ($IPObj.AddressFamily -eq ([System.Net.Sockets.AddressFamily]::InterNetwork)) {
        $AddressSize = 32
        $MaxValue = [uint32]::MaxValue
    }
    $IPAddressBits = (([ipaddress]::NetworkToHostOrder($IPObj.Address)) -shr $AddressSize) -band $MaxValue
    $CIDR = $MaxValue -shl ($AddressSize - $Parts[1])

    @{
        IPAddress = $IPAddressBits
        Netmask = $CIDR
        Broadcast = ($IPAddressBits -bor ($CIDR -bxor $MaxValue))
    }
}
