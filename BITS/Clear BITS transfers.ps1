# Try to clear bits transfers and if it fails, force it by removing bits db
try {
    Get-BitsTransfer -ErrorAction Stop -AllUsers | Remove-BitsTransfer -ErrorAction Stop
} catch {
    Get-Service BITS | Stop-Service
    Remove-Item 'C:\ProgramData\Microsoft\Network\Downloader\*'
    Get-Service BITS | Start-Service
}
