$TaskActionWorkingDirectory = 'C:\windows\system32'
$TaskActionCommand = 'C:\windows\notepad.exe'
$TaskActionArgument = ''
# https://support.microsoft.com/sv-se/help/243330/well-known-security-identifiers-in-windows-operating-systems
$sPrincipal = New-ScheduledTaskPrincipal -RunLevel Limited -ProcessTokenSidType Default -GroupId 'S-1-5-32-545'
$sSettings = New-ScheduledTaskSettingsSet -Compatibility Win8
$sActions = New-ScheduledTaskAction -WorkingDirectory $TaskActionWorkingDirectory -Execute $TaskActionCommand -Argument $TaskActionArgument
$sTriggers = New-ScheduledTaskTrigger -AtLogOn
$sTask = New-ScheduledTask -Action $sActions -Settings $sSettings -Trigger $sTriggers -Principal $sPrincipal
$sTask.Author = ""
Register-ScheduledTask -InputObject $sTask -TaskName "All users task"
