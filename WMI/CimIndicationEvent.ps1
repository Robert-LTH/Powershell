Register-CimIndicationEvent -SourceIdentifier "ProcessStopped" -Query "SELECT * FROM Win32_ProcessStopTrace WHERE ProcessName = 'notepad.exe'" -Action { $_ | gm }
Get-Event -SourceIdentifier "ProcessStopped"
UnRegister-Event -SourceIdentifier "ProcessStopped"
