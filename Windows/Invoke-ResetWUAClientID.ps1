$WUAService = Get-Service -Name wuauserv
$RegPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate'
$WUAService | Stop-Service
Remove-ItemProperty -ErrorAction Continue -Path $RegPath -Name 'PingID'
Remove-ItemProperty -ErrorAction Continue -Path $RegPath -Name 'AccountDomainSid'
Remove-ItemProperty -ErrorAction Continue -Path $RegPath -Name 'SusClientId'
Remove-ItemProperty -ErrorAction Continue -Path $RegPath -Name 'SusClientIDValidation'
$WUAService | Start-Service
Start-Process -FilePath 'C:\windows\System32\wuauclt.exe' -ArgumentList '/resetauthorization /detectnow'
