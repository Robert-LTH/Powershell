# Had an issue where I had to control the ProcessorAffinity of a process which wasnt started with a commandline i control 


#
# Register an event filter and consumer which starts a script with the ProcessId of the newly spawned process
# (Not sure why but I didnt manage to start a new process via commandline, had to skip thru another script)
#

$ScriptPath = "Path to Script 1"
$WQLQueryProcess = 'Select * from __InstanceCreationEvent within 10 where TargetInstance ISA "Win32_Process" and TargetInstance.Name = "audiodg.exe"'

$WQLFilterProcess = New-CimInstance -ClassName __EventFilter -Namespace "root\subscription" -Property @{Name="WQLFilterProcess";
  EventNameSpace="root\cimv2";
  QueryLanguage="WQL";
  Query=$WQLQueryProcess
}

$ProcessEventConsumer = New-CimInstance -ClassName CommandLineEventConsumer -Namespace "root\subscription" -Property  @{
  ExecutablePath = "C:\windows\system32\WindowsPowershell\v1.0\powershell.exe";
  CommandLineTemplate = "`"C:\windows\system32\WindowsPowershell\v1.0\powershell.exe`" -noprofile -executionpolicy bypass -File `"$ScriptPath`" -ProcID %TargetInstance.ProcessId%"
  Name = "ProcessEventConsumer"
}

$WMIEventBindingTest = New-CimInstance -ClassName __FilterToConsumerBinding -Namespace "root\subscription" -Property @{
  Filter = [Ref] $WQLFilterProcess
  Consumer = [Ref] $ProcessEventConsumer
}


#
# Script 1
#
param(
    $ProcID
)

$PathToScript2 = "Path to second script"

Start-Process -Verb runas -filepath powershell -ArgumentList @('-noprofile','-executionpolicy','bypass','-File',$PathToScript2,'-ProcID',$ProcID)



#
# Script 2
#
param(
    $ProcID
)

# Affinity in this case is a bitmap where each bit corresponds to a core
# Check mapping of a value using: [Convert]::ToString([int]VALUE,2)
$Affinity = 20

$Proc = Get-Process -Id $ProcID
$Proc.ProcessorAffinity = $Affinity
