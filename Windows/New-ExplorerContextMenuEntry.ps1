function New-ExplorerContextMenuEntry {
    <#
    .SYNOPSIS
        Add custom contextmenu entries
    .DESCRIPTION
        Add the custom contextmenu entries that you want, without the need of admin rights.
    .EXAMPLE
        $Icon = '"C:\Program Files\Microsoft VS Code\Code.exe",0'
        $MenuText = 'Open with VS Code Test'
        $Command = "`"C:\Program Files\Microsoft VS Code\Code.exe`" `"%1`""
        
        New-ExplorerContextMenuEntry -Identifier 'VSCodeTest' -icon $Icon -MenuText $MenuText -command $Command -Class 'Directory'
        New-ExplorerContextMenuEntry -Identifier 'VSCodeTest' -icon $Icon -MenuText $MenuText -command $Command -Class 'Directory\Background'
        New-ExplorerContextMenuEntry -Identifier 'VSCodeTest' -icon $Icon -MenuText $MenuText -command $Command -Class '*'
    #>
    param(
        $Identifier,
        $icon,
        $MenuText,
        $command,
        $Class
    )

    $ClassPath = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Classes\{0}' -f $Class
    $IdentifierPath = Join-Path -Path $ClassPath -ChildPath "shell\$Identifier"
    $CommandPath = Join-Path -Path $IdentifierPath -ChildPath "command"
    Write-Host $CommandPath
    New-Item -ItemType Container -Path $CommandPath -Force
    
    New-ItemProperty -Name 'icon' -Value $Icon -PropertyType 'ExpandString' -Path $IdentifierPath
    New-ItemProperty -Name '(Default)' -Value $MenuText -PropertyType 'ExpandString' -Path $IdentifierPath
    New-ItemProperty -Name '(Default)' -Value $command -PropertyType 'ExpandString' -Path $CommandPath
}
