# WITHIN 10 - Polls every 10 seconds, process needs to be open for up to 10 seconds for it to be "caught" by the filter
$WQLQuery = 'Select * from __InstanceCreationEvent within 10 where TargetInstance ISA "Win32_Process" and TargetInstance.Name = "update.exe"'

$WMIFilterInstance = New-CimInstance -ClassName __EventFilter -Namespace "root\subscription" -Property @{Name="myFilter";
    EventNameSpace="root\cimv2";
    QueryLanguage="WQL";
    Query=$WQLQuery
}

# Remove eventfilter instance
Get-CimInstance -ClassName __EventFilter -Namespace "root\subscription" -Filter "Name = 'myFilter'" | Remove-CimInstance

# Create an event consumer
$WMIEventConsumer = New-CimInstance -ClassName CommandLineEventConsumer -Namespace "root\subscription" -Property  @{
    ExecutablePath = "C:\windows\system32\WindowsPowershell\v1.0\powershell.exe";
    CommandLineTemplate = "`"C:\windows\system32\WindowsPowershell\v1.0\powershell.exe`" -executionpolicy bypass -file C:\temp\test.ps1"
    Name = "WMIEventConsumer"
} #Category is never really used but can have any value and basically meant to provide more information about the event

# Remove an event consumer
Get-CimInstance -ClassName CommandLineEventConsumer -Namespace "root\subscription" | ? { $_.Name -eq 'WMIEventConsumer' } | Remove-CimInstance


# $WMIEventConsumer = New-CimInstance -ClassName NTEventLogEventConsumer -Namespace "rootsubscription" -Property  @{Name="USBLogging";
# EventId = [uint32] 1; EventType = [uint32] 4; #EventType can have following values; Error 1, FailureAudit 16, Information 4, SuccesAudit 8, Warning 2
# SourceName="PowerShell-Script-Log"; Category= [uint16] 1000 } #Category is never really used but can have any value and basically meant to provide more information about the event

# Create an event binding
$WMIEventBinding = New-CimInstance -ClassName __FilterToConsumerBinding -Namespace "root\subscription" -Property @{
    Filter = [Ref] $WMIFilterInstance;
    Consumer = [Ref] $WMIEventConsumer
}

# Remove an event binding
Get-CimInstance -ClassName __FilterToConsumerBinding -Namespace "root\subscription" | ? { $_.Consumer.Name -eq $WMIEventConsumer.Name } | Remove-CimInstance
