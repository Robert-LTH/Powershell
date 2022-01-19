<#

  TODO: Fix all the stuff. Might be deleted later.

#>


$CurrentPath = "C:\Windows\PolicyDefinitions"
$File = Get-Item "$CurrentPath\AutoPlay.admx"
Write-Host $File
$ADMName = [IO.Path]::GetFileNameWithoutExtension($File.FullName)
Write-Host "Found name as '$ADMName'"
#$ADMLPath = "$(Split-Path -Path $CurrentPath -Parent)\$($Language.Name)\$ADMName.adml"
$ADMLPath = "$(Split-Path -Path $File -Parent)\sv-SE\$ADMName.adml"
Write-Host "Language resources will be fetched from '$ADMLPath'"
#$ADMLPath
#$ADMLXML = [XML](Get-Content -Path $ADMLPath -Raw)

function Get-ADMString {
    param(
        $ADMLContent,
        $Key
    )
    $DNkey = ((($Key -replace '\$\(') -replace '\)') -split '\.')[1]
    try {
        ($ADMLContent.policyDefinitionResources.resources.stringTable.string | Where-Object {$_.id -eq $DNkey} | Select-Object -ErrorAction SilentlyContinue -ExpandProperty '#text')
    } catch {
        Write-Host $key
        throw $_
    }

}

function Read-ADML {
    param(
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]$Path,
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ParameterSetName='Parameter Set 2')]
        [System.IO.FileSystemInfo]$InputObject
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Parameter Set 2') {
            
            $Path = $InputObject.FullName
        }
        if (-not (Test-Path -PathType Leaf -Path $Path)) {
            Write-Host -ForegroundColor Red "File '$Path' does not exist or it is not a file."
            break
        }
        $XML = New-Object -TypeName xml
        $XML.Load($Path)
        $XML
    }
}

function Read-ADMX {
    param(
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]$Path,
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ParameterSetName='Parameter Set 2')]
        [System.IO.FileSystemInfo]$InputObject
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Parameter Set 2') {
            
            $Path = $InputObject.FullName
        }
        if (-not (Test-Path -PathType Leaf -Path $Path)) {
            Write-Host -ForegroundColor Red "File '$Path' does not exist or it is not a file."
            break
        }
        $XML = New-Object -TypeName xml
        $XML.Load($Path)
        $XML
    }
}


Write-Host "Load XML '$ADMLPath'"
$ADMLXML = New-Object -TypeName xml
$ADMLXML.Load($ADMLPath)
Write-Host "Load XML '$($File.FullName)'"
$ADMXXML = New-Object -TypeName xml 
$ADMXXML.Load($File.FullName)

$ADMXXML | Select-Object -ExpandProperty policyDefinitions | Select-Object -ExpandProperty policies | ForEach-Object {
    Write-Host "Starting to process '$ADMName'"
    $_.policy | ForEach-Object {
        $CurrentPolicy = $_
        if ($CurrentPolicy.Class -eq 'User') {
            $RegHive = 'HKEY_CURRENT_USER'
        }
        else {
            $RegHive = 'HKEY_LOCAL_MACHINE'
        }

        $DNKey = $CurrentPolicy.Attributes.GetNamedItem("displayName")."#text"
        if ([string]::IsNullOrEmpty($DNKey)) { $DNKey = $CurrentPolicy.displayName }
        $CPDisplayName = Get-ADMString -ADMLContent $ADMLXML -Key $DNKey
        <#
        # How to present the policy
        $PKey = $CurrentPolicy.Attributes.GetNamedItem("presentation")."#text"
        if ([string]::IsNullOrEmpty($PKey)) { $DNKey = $CurrentPolicy.presentation }
        $CPPresentation = Get-ADMPresentation -ADMLContent $ADMLXML -Key $PKey
        #>
        # Write-Host ("DisplayName length: {0}" -f $CPDisplayName.Length)
        # if ($CPDisplayName.Length -gt 150) {
        #     $CPDisplayName = "{0}..." -f $CPDisplayName.Substring(0,150)
        # } 
        Write-Host "Processing '$CPDisplayName'"
        $CurrentIsRequired = $false
        if ('elements' -in $CurrentPolicy.ChildNodes.Name) {
            $CurrentPolicy.elements.ChildNodes | ForEach-Object {
                $CurrentElement = $_
                $ValueName = $CurrentElement.valueName
                # Write-Host ("ValueName length: {0}" -f $CurrentElement.valueName.Length)
                if ($CurrentElement.valueName.Length -gt 150) {
                    $ValueName = "{0}..." -f $CurrentElement.valueName.Substring(0,150)
                }
                #$CurrentElement.GetType()
                if ($CurrentElement.required) {
                    $CurrentIsRequired = $CurrentElement.required
                }
                switch ($CurrentElement.Name) {
                    'list' {
                        #"{0} - {1} - {2}" -f $_.id,$_.key,$_.valuePrefix
                        $ItemName = Get-ADMString -ADMLContent $ADMLXML -key $_.displayName
                        $ValueName = $CurrentPolicy.name
                        # if ($CurrentElement.valueName.Length -gt 200) {
                        #     $ValueName = "{0}..." -f $CurrentElement.valueName.Substring(0,200)
                        # }
                        
                        $CIName = "$CPDisplayName - $ValueName = List"
                         #Write-Host ("{0}: {1}" -f $CIName,$CIName.Length)
                         Write-Host $RegHive,$CurrentElement.valueName,$ItemName,$ItemValue
                        # if ($CIName -notin $CIList.LocalizedDisplayName) {
                            
                        #     $NewCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                        #     $NewCI | Move-CMObject -FolderPath $DestinationFolder
                        #     $NewCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType String -ExpectedValue "" -Hive $RegHive -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$ValueName = $ItemName ($ItemValue)" -Name $ValueName -ValueName '1'
                        # }
                    }
                    'enum' {
                        $CurrentElement.item | ForEach-Object {
                            if ($_.value.decimal.value) {
                                #$_.value.decimal.value | ForEach-Object {
                                    $ItemValue = $_.value.decimal.value
                                    # "{0}_{1}_{2} = {3}" -f $CPDisplayName,$CurrentElement.valueName,$CurrentIsRequired,$ItemValue
                                    # if ($ItemValue -gt 100) {
                                    #     $ItemValue = "{0}..." -f $ItemValue.Substring(0,100)
                                    # }

                                    
                                    $ItemName = Get-ADMString -ADMLContent $ADMLXML -key $_.displayName
                                    # Write-Host $ItemName
                                    # $ValueName = $CurrentElement.valueName
                                    if ($ItemName.Length -gt 75) {
                                        $ItemName = "{0}..." -f $ItemName.Substring(0,75)
                                    }
                                    
                                    
                                    $CIName = "$CPDisplayName - $ValueName = $ItemName ($ItemValue)"
                                    #Write-Host ("{0}: {1}" -f $CIName,$CIName.Length)
                                    Write-Host $RegHive,$CurrentElement.valueName,$ItemName,$ItemValue
                                    # if ($CIName -notin $CIList.LocalizedDisplayName) {
                                        
                                    #     $NewCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                                    #     $NewCI | Move-CMObject -FolderPath $DestinationFolder
                                    #     $NewCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType Integer -ExpectedValue $ItemValue -Hive $RegHive -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentElement.valueName) = $ItemName ($ItemValue)" -Name $CurrentElement.valueName -ValueName $CurrentElement.valueName
                                    # }
                                #}
                            }
                            elseif (-not ([string]::IsNullOrEmpty($_.value.string))) {
                                #$_.value.string | ForEach-Object {
                                    $ItemValue = $_.value.string
                                    #"{0}_{1}_{2} = {3}" -f $CPDisplayName,$CurrentElement.valueName,$CurrentIsRequired,$_
                                    $ItemName = Get-ADMString -ADMLContent $ADMLXML -key $_.displayName
                                    # $ValueName = $CurrentElement.valueName
                                    # if ($CurrentElement.valueName.Length -gt 200) {
                                    #     $ValueName = "{0}..." -f $CurrentElement.valueName.Substring(0,200)
                                    # }
                                    
                                    $CIName = "$CPDisplayName - $ValueName = $ItemName ($ItemValue)"
                                    Write-Host $RegHive,$CurrentElement.valueName,$ItemName,$ItemValue
                                    #Write-Host ("{0}: {1}" -f $CIName,$CIName.Length)

                                    # if ($CIName -notin $CIList.LocalizedDisplayName) {
                                        
                                    #     $NewCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                                    #     $NewCI | Move-CMObject -FolderPath $DestinationFolder
                                    #     $NewCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType String -ExpectedValue $ItemValue -Hive $RegHive -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentElement.valueName) = $ItemName ($ItemValue)" -Name $CurrentElement.valueName -ValueName $CurrentElement.valueName
                                    # }
                                #}
                            }
                        }
                    }
                    'decimal' {
                        # $ValueName = $CurrentElement.valueName
                        # if ($CurrentElement.valueName.Length -gt 200) {
                        #     $ValueName = "{0}..." -f $CurrentElement.valueName.Substring(0,200)
                        # }
                        
                        $CIName = "$CPDisplayName - $ValueName = $($CurrentElement.minValue) (max $($CurrentElement.maxValue))"
                        #Write-Host $CIName
                        Write-Host $RegHive,$CurrentElement.valueName,$ItemName,$ItemValue
                        # if ($CIName -notin $CIList.LocalizedDisplayName) {
                            
                        #     $NewCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList -Description "min $($CurrentElement.minValue) max $($CurrentElement.maxValue)"
                        #     $NewCI | Move-CMObject -FolderPath $DestinationFolder
                        #     if (-not $CurrentElement.minValue) {
                        #         $ExpectedValue = 0
                        #     }
                        #     else {
                        #         $ExpectedValue = $CurrentElement.minValue
                        #     }
                        #     $NewCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType Integer -ExpectedValue $ExpectedValue -Hive LocalMachine -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentElement.valueName) = $($CurrentElement.minValue)" -Name $CurrentElement.valueName -ValueName $CurrentElement.valueName
                        # }
                        #"{0}_{1}_{2} (min {3} max {4})" -f $CPDisplayName,$CurrentElement.valueName,$CurrentIsRequired,$CurrentElement.minValue,$CurrentElement.maxValue
                    }
                    'text' {
                        $maxLength = 0
                        if ($CurrentElement.maxLength) {
                            $maxLength = $CurrentElement.maxLength
                        }
                        # $ValueName = $CurrentElement.valueName
                        # if ($CurrentElement.valueName.Length -gt 200) {
                        #     $ValueName = "{0}..." -f $CurrentElement.valueName.Substring(0,200)
                        # }
                        $CIName = "$CPDisplayName - $ValueName = ''"
                        Write-Host $CIName
                        # if ($CIName -notin $CIList.LocalizedDisplayName) {
                            
                        #     $NewCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList -Description "String max length: $maxLength"
                        #     $NewCI | Move-CMObject -FolderPath $DestinationFolder
                        #     $NewCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType String -ExpectedValue ' ' -Hive LocalMachine -Is64Bit -KeyName $CurrentPolicy.key -NoncomplianceSeverity Critical -RuleName "$($CurrentElement.valueName) = ' '" -Name $CurrentElement.valueName -ValueName $CurrentElement.valueName
                        # }
                        #"{0}_{1}_{2} (max {3})" -f $CPDisplayName,$CurrentElement.valueName,$CurrentIsRequired,$maxLength
                    }
                    'boolean' {
                        $CIName = "$CPDisplayName - $ValueName = 1"
                        # if ($CIName -notin $CIList.LocalizedDisplayName) {
                        #     $NewEnabledCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                        #     $NewEnabledCI | Move-CMObject -FolderPath $DestinationFolder
                        #     $NewEnabledCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType Integer -ExpectedValue '1' -Hive LocalMachine -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentElement.valueName) = 1" -Name $CurrentElement.valueName -ValueName $CurrentElement.valueName
                        # }
                        $CIName = "$CPDisplayName - $ValueName = 0"
                        # if ($CIName -notin $CIList.LocalizedDisplayName) {
                        #     $NewDisabledCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                        #     $NewDisabledCI | Move-CMObject -FolderPath $DestinationFolder
                        #     $NewDisabledCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType Integer -ExpectedValue '0' -Hive LocalMachine -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentElement.valueName) = 0" -Name $CurrentElement.valueName -ValueName $CurrentElement.valueName

                        # }
                        #$CurrentElement
                        "{0}_{1}_{2}" -f $CPDisplayName,$CurrentElement.valueName,$CurrentIsRequired
                    }
                    
                    default {
                        # Write-host $CurrentElement.OuterXML
                        # Write-Host $CurrentElement.Name
                        #$CurrentElement
                        #"DEF"
                    }
                }
            }
        }
        else {
            if ($null -ne $CurrentPolicy.key) {
                #$CurrentPolicy.ChildNodes | Where-Object { $_.Name -eq 'enabledValue' } | ForEach-Object {
                    $CIName = "$CPDisplayName - $($CurrentPolicy.valueName) = Enabled ($($CurrentPolicy.enabledValue.decimal.value))"
                    # if ($CIName -notin $CIList.LocalizedDisplayName) {
                    #     $NewEnabledCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                    #     $NewEnabledCI | Move-CMObject -FolderPath $DestinationFolder
                    #     $NewEnabledCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType Integer -ExpectedValue $CurrentPolicy.enabledValue.decimal.value -Hive LocalMachine -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentPolicy.valueName) = 1" -Name "$($CurrentPolicy.valueName)" -ValueName "$($CurrentPolicy.valueName)"
                    # }
                    $CIName
                #}
                #$CurrentPolicy.ChildNodes | Where-Object { $_.Name -eq 'disabledValue' } | ForEach-Object {
                    $CIName = "$CPDisplayName - $($CurrentPolicy.valueName) = Disabled ($($CurrentPolicy.disabledValue.decimal.value))"
                    # if ($CIName -notin $CIList.LocalizedDisplayName) {
                    #     $NewDisabledCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                    #     $NewDisabledCI | Move-CMObject -FolderPath $DestinationFolder
                    #     $KeyValueParameters = @{
                    #         ExpressionOperator = 'IsEquals'
                    #         ValueRule = $true
                    #         DataType = 'Integer'
                    #         ExpectedValue = $CurrentPolicy.disabledValue.decimal.value
                    #         Hive = 'LocalMachine'
                    #         Is64Bit = $true
                    #         KeyName = $CurrentPolicy.key
                    #         RemediateDword = $true
                    #         NoncomplianceSeverity = 'Critical' 
                    #         RuleName = "$($CurrentPolicy.valueName) = 0"
                    #         ValueName = $CurrentPolicy.valueName
                    #         Name = $CurrentPolicy.valueName
                    #     }
                    #     Write-Host $CurrentPolicy.valueName
                    #     $NewDisabledCI | Add-CMComplianceSettingRegistryKeyValue @KeyValueParameters
                    # }
                    $CIName
                #}
                #Start-Sleep -Seconds 60
            }
            else {
                Write-Warning $CurrentPolicy
            }
        }
    }
}
