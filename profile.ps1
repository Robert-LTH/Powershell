function Get-IsAdminCharacter {
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        "$ColorThree#"
    }
    else {
        "$ColorThree`$$ColorReset"
    }
}

# I am not the author of this function and i can't find the source :(
Function Update-WindowTitle {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'Add')]
        [string]$AdditionalTitle,
 
        [Parameter(ParameterSetName = 'Reset')]
        [switch]$Reset
    ) # End Param.
 
    If (-Not(Get-Variable -Name OriginalTitle -Scope Global -ErrorAction SilentlyContinue)) {
        New-Variable -Name OriginalTitle -Value $Host.UI.RawUI.WindowTitle -Option Constant -Scope Global
    } # End If.
 
    If ($AdditionalTitle) {
        $Host.UI.RawUI.WindowTitle = "$OriginalTitle | $AdditionalTitle"
    } ElseIf ($Reset) {
        $Host.UI.RawUI.WindowTitle = $OriginalTitle
    } # End If-Else.
} # End Function: Update-WindowTitle.

function prompt {
    $ESC = [char]27

    $ColorReset = "$ESC[0m"
    
    $ColorOne = "$ESC[38;2;224;192;68m"
    $ColorTwo = "$ESC[38;2;211;208;203m"
    $ColorThree = "$ESC[38;2;88;123;127m"
    $ColorFour = "$ESC[38;2;35;196;255m"
    $ColorFive = "$ESC[38;2;189;212;231m"
    $ColorDisabled = "$ESC[38;2;140;140;140m"
    $ColorEnabled = "$ESC[38;2;102;204;0m"

    $MyPrompt = "`n"    
    $MyPrompt += "$ColorOne[$ColorReset"
    $LocationProvider = "$($ExecutionContext.SessionState.Path.CurrentLocation.Provider -replace 'Microsoft.PowerShell.Core\\')"
    $LocationPath = "$($ExecutionContext.SessionState.Path.CurrentLocation.Path -replace ([regex]::Escape("$($ExecutionContext.SessionState.Path.CurrentLocation.Provider)::")))"
    $totallength = ($LocationProvider.Length + $LocationPath.Length + 2)
    $Message = " $($Host.UI.RawUI.WindowTitle) "
    $RestLength = $totallength - ($Message.Length)
    $leftside = [Math]::Floor($RestLength / 2)
    $MyPrompt += '-' * $leftside
    $MyPrompt += $Message
    $MyPrompt += '-' * ($RestLength - $leftside)
    $MyPrompt += "$ColorOne]`n"
    $MyPrompt += "$ColorOne[$ColorReset"
    $MyPrompt += "$ColorTwo$LocationProvider::$ColorFour$LocationPath"
    $MyPrompt += "$ColorOne]`n["
    $MyPrompt += "$ColorThree$((Get-Date -Format 'HH:mm:ss'))"
    $MyPrompt += "$ColorOne]["
    $MyPrompt += "$ColorFive$(if ($env:USERDOMAIN) {"$env:USERDOMAIN\"})$($env:USERNAME)"
    $MyPrompt += "$ColorOne]$ColorThree@$ColorOne["
    $MyPrompt += "$ColorFive$($env:COMPUTERNAME)"
    $MyPrompt += "$ColorOne]"
    if ($DebugPreference -eq 'Continue') {
        $MyPrompt += "$ColorOne["
        $MyPrompt += "$($ColorEnabled)Debug"
        $MyPrompt += "$ColorOne]"
    }
    else {
        $MyPrompt += "$ColorOne["
        $MyPrompt += "$($ColorDisabled)Debug"
        $MyPrompt += "$ColorOne]"
    }
    if ($InformationPreference -eq 'Continue') {
        $MyPrompt += "$ColorOne["
        $MyPrompt += "$($ColorEnabled)Information"
        $MyPrompt += "$ColorOne]"
    }
    else {
        $MyPrompt += "$ColorOne["
        $MyPrompt += "$($ColorDisabled)Information"
        $MyPrompt += "$ColorOne]"
    }
    if ($ProgressPreference -eq 'Continue') {
        $MyPrompt += "$ColorOne["
        $MyPrompt += "$($ColorEnabled)Progress"
        $MyPrompt += "$ColorOne]"
    }
    else {
        $MyPrompt += "$ColorOne["
        $MyPrompt += "$($ColorDisabled)Progress"
        $MyPrompt += "$ColorOne]"
    }
    if ($ErrorActionPreference -eq 'Continue') {
        $MyPrompt += "$ColorOne["
        $MyPrompt += "$($ColorEnabled)ErrorAction"
        $MyPrompt += "$ColorOne]"
    }
    else {
        $MyPrompt += "$ColorOne["
        $MyPrompt += "$($ColorDisabled)ErrorAction"
        $MyPrompt += "$ColorOne]"
    }
    $MyPrompt += "`n$ColorOne$(Get-IsAdminCharacter)$ColorReset$('>' * ($nestedPromptLevel + 1))"
    $MyPrompt
}
