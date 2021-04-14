function Get-MEMCMHardwareID {
    [OutputType([String])]
    $SystemEnclosureInformation = Get-CimInstance -Namespace "root/cimv2" -ClassName "Win32_SystemEnclosure"
    
    $SystemEnclosureChassisType = $SystemEnclosureInformation | Select-Object -ExpandProperty "ChassisTypes"
    if (Get-IsChassisTypeLaptop -ChassisType $SystemEnclosureChassisType) {
        $MacAddress = "<Not used on laptop>"
    }
    else {
        $MacAddress = Get-CimInstance -Namespace "root/cimv2" -Query "SELECT Index, MACAddress FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True" | Select-Object -First 1 -ExpandProperty MacAddress
    }

    $SystemEnclosureSerialNumber = $SystemEnclosureInformation | Select-Object -ExpandProperty "SerialNumber"
    
    if ($SystemEnclosureSerialNumber -eq 'None' -or 31 -in $SystemEnclosureChassisType -or 13 -in $SystemEnclosureChassisType) {
        $SystemEnclosureSerialNumber = $null
    }
    
    $SystemEnclosureSMBIOSAssetTag = $SystemEnclosureInformation | Select-Object -ExpandProperty "SMBIOSAssetTag"
    if ($SystemEnclosureSMBIOSAssetTag -eq 'No Asset Tag' -or 13 -in $SystemEnclosureChassisType) {
        $SystemEnclosureSMBIOSAssetTag = $null
    }
    
    $BaseBoardSerialNumber = Get-CimInstance -Namespace "root/cimv2" -ClassName "Win32_BaseBoard" | Select-Object -ExpandProperty "SerialNumber"
    $BIOSSerialNumber = Get-CimInstance -Namespace "root/cimv2" -ClassName "Win32_BIOS" | Select-Object -ExpandProperty "SerialNumber"
    

    $HashBytes = Get-HashFromString -String ("{0}!{1}!{2}!{3}!{4}" -f $SystemEnclosureSerialNumber,$SystemEnclosureSMBIOSAssetTag,$BaseBoardSerialNumber,$BIOSSerialNumber,$MacAddress)
    $HashString = Get-HexAsString -Bytes $HashBytes

    "2:$HashString"
}
