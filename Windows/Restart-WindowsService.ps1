param (
    $ServiceName
)

$Service = Get-Service -Name $ServiceName
if ($Service) {
    Write-Host $Service.Name
    $DepServices = Get-Service -Name $ServiceName -DependentServices | Stop-Service
    try {
        $Service | Restart-Service -ErrorAction Stop -Force
    } catch {
        $ServicePID = Get-WmiObject -Class Win32_Service -Filter "Name LIKE '$ServiceName'" | Select-Object -ExpandProperty ProcessId
        Stop-Process -Id $ServicePID -Force
        Start-Service -Name $ServiceName
    }
    $DepServices | Start-Service
}
else {
    Write-Host "Service not found!"
}
