$Vm = Get-VM -VMName "Windows 11 Test"
$Vm | Set-VMFirmware -BootOrder $Vm.NetworkAdapters[0] 
$Vm | Start-VM
