# https://docs.microsoft.com/en-us/powershell/module/applocker/new-applockerpolicy?view=win10-ps
$NewPolicy = Get-Item -Path 'PATH_TO_FILES' | Get-AppLockerFileInformation | New-AppLockerPolicy -RuleNamePrefix 'SomethingUnique-' -RuleType 'Path' -User 'Administrator' -Optimize
$NewPolicy | Set-AppLockerPolicy -Merge
