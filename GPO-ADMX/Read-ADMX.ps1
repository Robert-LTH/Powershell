<#

  TODO: Fix all the stuff. Might be deleted later.

#>
$CurrentPath = "C:\Windows\PolicyDefinitions"
Get-ChildItem -Path $CurrentPath -File | Out-GridView -PassThru | ForEach-Object {
    $File = Get-Item $_.FullName
}
Write-Host $File
$ADMName = [IO.Path]::GetFileNameWithoutExtension($File.FullName)
Write-Host "Found name as '$ADMName'"
#$ADMLPath = "$(Split-Path -Path $CurrentPath -Parent)\$($Language.Name)\$ADMName.adml"
$Language = Get-UICulture

function Get-ADMString {
    param(
        $ADMLContent,
        $Key
    )
    #if (-not $ADMLContent) {
        #$ADMLContent = [xml](Get-Content -Path "C:\temp\test\PolicyDefinitions\$($Language.Name)\$ADMName.adml" -raw)
    #}
    #$key
    #$ADMLContent.policyDefinitionResources.resources.stringTable.string
    #$ADMLContent.policyDefinitionResources.resources.presentationTable.presentation

    #$key = 'IgnoreDefaultList_Name'
    #Write-Information "$key"
    $DNkey = ((($Key -replace '\$\(') -replace '\)') -split '\.')[1]
    try {
        ($ADMLContent.policyDefinitionResources.resources.stringTable.string | Where-Object {$_.id -eq $DNkey} | Select-Object -ErrorAction SilentlyContinue -ExpandProperty '#text')
    } catch {
        Write-Host $key
        throw $_
    }

}

function Get-ADMPresentation {
    param(
        $ADMLContent,
        $key,
        $RefId
    )
    # if (-not $ADMLContent) {
    #     $ADMLContent = [xml](Get-Content -Path "C:\temp\test\PolicyDefinitions\$($Language.Name)\$ADMName.adml" -raw)
    # }
    #$key
    #$ADMLContent.policyDefinitionResources.resources.stringTable.string
    #$ADMLContent.policyDefinitionResources.resources.presentationTable.presentation

    #$key = 'IgnoreDefaultList_Name'
    $Pkey = ((($Key -replace '\$\(') -replace '\)') -split '\.')[1]
    $Nodes = $ADMLContent.policyDefinitionResources.resources.presentationTable.presentation | ? {$_.id -eq $Pkey} | % { $_.ChildNodes }
    if (-not [string]::IsNullOrEmpty($RefId)) {
        $Node = $Nodes | Where-Object { $RefId -eq $_.refId }
        $Node.PreviousSibling."#text"
    }
    else{
        $Nodes
    }

}


#$ADMLPath
#$ADMLXML = [XML](Get-Content -Path $ADMLPath -Raw)
try {
    $ADMLPath = "$(Split-Path -Path $File -Parent)\$($Language.Name)\$ADMName.adml"
    Write-Host "Language resources will be fetched from '$ADMLPath'"
    Write-Host "Load XML '$ADMLPath'"
    $ADMLXML = New-Object -TypeName xml
    $ADMLXML.Load($ADMLPath)
} catch {
    $ADMLPath = "$(Split-Path -Path $File -Parent)\en-US\$ADMName.adml"
    Write-Host "Language resources will be fetched from '$ADMLPath'"
    Write-Host "Load XML '$ADMLPath'"
    $ADMLXML = New-Object -TypeName xml
    $ADMLXML.Load($ADMLPath)
}
Write-Host "Load XML '$($File.FullName)'"
$ADMXXML = New-Object -TypeName xml
$ADMXXML.Load($File.FullName)

$Category = [PSCustomObject] @{
    Name = Get-ADMString -ADMLContent $ADMLXML -Key $ADMXXML.policyDefinitions.categories.category.displayName
    Description = Get-ADMString -ADMLContent $ADMLXML -Key $ADMXXML.policyDefinitions.categories.category.explainText
    Parent = $ADMXXML.policyDefinitions.categories.category.parentCategory.ref
}

$ADMXXML | Select-Object -ExpandProperty policyDefinitions | Select-Object -ExpandProperty policies | Select-Object -ExpandProperty policy | ForEach-Object {
    $CurrentPolicy = $_

    if ($CurrentPolicy.Class -eq 'User') {
        $RegHive = 'HKEY_CURRENT_USER'
    }
    else {
        $RegHive = 'HKEY_LOCAL_MACHINE'
    }
    [PSCustomObject] @{
        Type = "GPO"
        Path = "Categories"
        ValueName = ""
        DisplayName = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentPolicy.displayName
        Value = ""
        MinValue = ""
        MaxValue = ""
        Description = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentPolicy.explainText
        DataType = ""
        DataLength = ""
    }
    
    # $_.Name
    # $_.parentCategory
    # Get-ADMString -ADMLContent $ADMLXML -Key $_.displayName
    # Get-ADMString -ADMLContent $ADMLXML -Key $_.explainText
    # $_.Key
    # $_.ValueName
    # $_.enabledValue
    $EnabledElement = $_.GetElementsByTagName("enabledValue")
    $EnabledList = $_.GetElementsByTagName("enabledList")
    $DisabledElement = $_.GetElementsByTagName("disabledValue")
    $DisabledList = $_.GetElementsByTagName("disabledList")
    $CPElements = $CurrentPolicy.GetElementsByTagName("elements")
    if ($CPElements.Count -le 0 -and $EnabledElement.Count -le 0 -and $DisabledElement.Count -le 0 -and $EnabledList.Count -le 0 -and $DisabledList.Count -le 0) {
        [PSCustomObject] @{
            Type = "Registry+-"
            Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
            ValueName = $CurrentPolicy.valueName
            DisplayName = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentPolicy.displayName
            Value = ""
            MinValue = 0
            MaxValue = 1
            Description = "" # Get-ADMString -ADMLContent $ADMLXML -Key $CurrentPolicy.explainText
            DataType = "boolean"
            DataLength = ""
        }
    }
    #else {
    #    $GPO
    #}
    if ($EnabledElement.Count -gt 0 -and $DisabledElement.Count -gt 0) {
        switch ($EnabledElement.FirstChild.Name){
            'decimal' {
                $EnabledValue = $EnabledElement.FirstChild.Value
                $DataLength = $EnabledValue
            }
            'string' {
                $EnabledValue = $EnabledElement.FirstChild.InnerText
                $DataLength = ""
            }
            default {
                Write-Warning "Unknown type: $_"
                $EnabledValue = "Unknown"
            }
        }
        switch ($DisabledElement.FirstChild.Name){
            'decimal' {
                $DisabledValue = $DisabledElement.FirstChild.Value
            }
            'string' {
                $DisabledValue = $DisabledElement.FirstChild.InnerText
            }
            default {
                Write-Warning "Unknown type: $_"
                $DisabledValue = "Unknown"
            }
        }
        
        if ($_.LocalName -ne 'policy') {
            $Description = Get-ADMString -ADMLContent $ADMLXML -key $_.explainText
        }

        [PSCustomObject] @{
            Type = "Registry"
            Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
            ValueName = $CurrentPolicy.valueName
            DisplayName = Get-ADMString -ADMLContent $ADMLXML -key $_.displayName
            Value = ""
            MinValue = $DisabledValue
            MaxValue = $EnabledValue
            Description = "" #$Description
            DataType = "EnableDisable"
            DataLength = $DataLength
        }
    }
    elseif ($EnabledList.Count -gt 0 -and $DisabledList.Count -gt 0) {
        $obj = [PSCustomObject] @{
            Type = ""
            Path = ""
            ValueName = ""
            DisplayName = ""
            Value = ""
            MinValue = ""
            MaxValue = ""
            Description = ""
            DataType = ""
            DataLength = 0
            
        }
        #Write-Host "enabledList: $_"
        $EnabledList.GetElementsByTagName("item") | ForEach-Object {
            $CurrentNode = $_
            if ($null -ne $_.id) {
                $obj.DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.Attributes.GetNamedItem("presentation").Value | Select-Object -ExpandProperty "#text"
            }
            else {
                $obj.DisplayName = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentPolicy.displayName
            }
            #[PSCustomObject] @{
                $obj.Type = "RegistryEL"
                $obj.Path = "{0}\{1}" -f $RegHive,$CurrentNode.Key
                $obj.ValueName = $CurrentNode.valueName
                #$obj.DisplayName = $DisplayName
                $obj.Value = ""
                $obj.MinValue = $DisabledList.GetElementsByTagName("item") | Where-Object { $_.key -eq $CurrentNode.Key -and $_.valueName -eq $CurrentNode.valueName } | Select-Object -ExpandProperty FirstChild |Select-Object -ExpandProperty FirstChild | Select-Object -ExpandProperty value
                $obj.MaxValue = $_.FirstChild.FirstChild.value
                $obj.Description = ""
                $obj.DataType = $_.FirstChild.FirstChild.Name
                $obj.DataLength = 0
                
            #}
            $obj
        }
        #$DisabledList.GetElementsByTagName("item")
        # | ForEach-Object {
        #     $CurrentNode = $_
        #     if ($null -ne $_.id) {
        #         $DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.Attributes.GetNamedItem("presentation").Value | Select-Object -ExpandProperty "#text"
        #     }
        #     else {
        #         $DisplayName = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentPolicy.displayName
        #     }
        #     [PSCustomObject] @{
        #         Type = "Registry+"
        #         Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.Key
        #         ValueName = $CurrentNode.valueName
        #         DisplayName = $DisplayName
        #         Value = $_.FirstChild.FirstChild.value
        #         MinValue = ""
        #         MaxValue = ""
        #         Description = ""
        #         DataType = $_.FirstChild.FirstChild.Name
        #         DataLength = 0
                
        #     }
        # }
    }
    # 'disabledList' {
    #     Write-Host "disabledList: $_"
    # }
    if ($CPElements.Count -gt 0) {
        $CPElements.ChildNodes | ForEach-Object {
            $CurrentNode = $_
            if ([string]::IsNullOrEmpty($_.Name)) { return }
            switch ($_.Name) {
                'decimal' {
                    # <decimal id="RepositoryTimeout" valueName="SyncTimeoutInMilliseconds" required="true" minValue="2000" maxValue="40000000" />
                    [PSCustomObject] @{
                        Type = "Registry+++"
                        Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.Key
                        ValueName = $CurrentNode.valueName
                        DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.presentation | Where-Object { $CurrentNode.id -eq $_.refId } | Select-Object -ExpandProperty '#text'
                        Value = "" # $CurrentNode.Attributes.GetNamedItem("minValue")."#text"
                        MinValue = $CurrentNode.Attributes.GetNamedItem("minValue")."#text"
                        MaxValue = $CurrentNode.Attributes.GetNamedItem("maxValue")."#text"
                        Description = ""
                        DataType = $_
                        DataLength = 0
                    }
                    #Write-Host "decimal"
                }
                'enum' {
                    # Fixed options
                    # DisplayName + Value
                    $CurrentNode.GetElementsByTagName("item") | ForEach-Object {
                        $CurrentItem = $_
                        if (-not [string]::IsNullOrEmpty($CurrentItem.Name)) {
                            $DisplayName = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentItem.displayName
                        }
                        elseif ($null -ne $CurrentNode.Attributes.GetNamedItem("id")) {
                            try {
                                $DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.presentation | Where-Object { $CurrentNode.id -eq $_.refId } | Select-Object -ExpandProperty '#text'
                                #$DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.Attributes.GetNamedItem("presentation").Value | Select-Object -ExpandProperty "#text"
                            } catch {
                                $DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.Attributes.GetNamedItem("presentation").Value
                            }

                        }
                        else {
                            $DisplayName = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentNode.displayName
                        }
                        if (-not $CurrentItem.Name.Equals('#comment')) {
                            [PSCustomObject] @{
                                Type = "Registry+"
                                Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.Key
                                ValueName = $CurrentNode.valueName
                                DisplayName = $DisplayName
                                Value = $CurrentItem.value.FirstChild.value
                                MinValue = $CurrentNode.Attributes.GetNamedItem("minValue")."#text"
                                MaxValue = $CurrentNode.Attributes.GetNamedItem("maxValue")."#text"
                                Description = ""
                                DataType = $CurrentItem.value.FirstChild.name
                                DataLength = 0
                                
                            }
                        }
                    }
                }
                'list' {
                    if ($null -ne  $CurrentNode.ValueName) {
                        $ValueName = $CurrentNode.ValueName
                        $Type = "text"
                    }
                    else {
                        $ValueName = ""
                        $Type = "List"
                    }
                    [PSCustomObject] @{
                        Type = $Type
                        Path = "{0}\{1}" -f $RegHive,$CurrentNode.Key
                        ValueName = $ValueName
                        DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.presentation | Where-Object { $CurrentNode.id -eq $_.refId } | Select-Object -ExpandProperty '#text'
                        Value = $_.FirstChild.FirstChild."#text"
                        MinValue = $CurrentNode.Attributes.GetNamedItem("minValue")."#text"
                        MaxValue = $CurrentNode.Attributes.GetNamedItem("maxValue")."#text"
                        DataType = 'List'
                        DataLength = 0
                        Description = ""
                    }
                }
                'text' {
                    # Fritext input
                    [PSCustomObject] @{
                        Type = "text"
                        Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.Key
                        ValueName = $CurrentNode.valueName
                        DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.presentation | Where-Object { $CurrentNode.id -eq $_.refId } | Select-Object -ExpandProperty 'label'
                        Value = $CurrentNode.Value
                        MinValue = ""
                        MaxValue = ""
                        DataType = 'string'
                        DataLength = 0
                        Description = ""
                    }

                }
                'multiText' {
                    $DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.presentation -RefId $CurrentNode.Id
                    [PSCustomObject] @{
                        Type = "multiText"
                        Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.Key
                        ValueName = $CurrentNode.valueName
                        DisplayName = $DisplayName
                        Value = ""
                        MinValue = ""
                        MaxValue = ""
                        DataType = 'string'
                        DataLength = 0
                        Description = ""
                    }
                }
                'boolean' {
                    [PSCustomObject] @{
                        Type = "boolean"
                        Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.Key
                        ValueName = $CurrentNode.valueName
                        DisplayName = Get-ADMPresentation -ADMLContent $ADMLXML -key $CurrentPolicy.presentation | Where-Object { $CurrentNode.id -eq $_.refId } | Select-Object -ExpandProperty '#text'
                        Value = 0
                        MinValue = 0
                        MaxValue = 1
                        DataType = 'boolean'
                        DataLength = 0
                        Description = ""
                    }
                }
                default {
                    Write-Warning ("Unknown type: {0}" -f $_)
                }
            }
        }
        
    }
    # elseif ($CPElements.Count -le 0 -and $EnabledElement.Count -le 0 -and $DisabledElement.Count -le 0 -and $EnabledList.Count -le 0 -and $DisabledList.Count -le 0) {
    #     Write-host "bla"
    #     [PSCustomObject] @{
    #         Type = "boolean"
    #         Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.Key
    #         ValueName = $CurrentNode.valueName
    #         DisplayName = Get-ADMString -ADMLContent $ADMLXML -Key $_.
    #         Value = 0
    #         MinValue = 0
    #         MaxValue = 1
    #         DataType = 'boolean'
    #         DataLength = 0
    #         Description = ""
    #     }
    # }
    #$_.Attributes.GetNamedItem("name")
    #name="EnableModuleLogging" class="Both" displayName="$(string.EnableModuleLogging)" explainText="$(string.EnableModuleLogging_Explain)" presentation="$(presentation.EnableModuleLogging)" key="Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging" valueName="EnableModuleLogging">
} | Out-GridView
return
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

        $CategoryInfo = [PSCustomObject] @{
            Name = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentPolicy.displayName
            Description = Get-ADMString -ADMLContent $ADMLXML -Key $CurrentPolicy.explainText
            Parent = $CurrentPolicy.parentCategory.ref
        }
        #$CategoryInfo

        $MainSetting = [PSCustomObject] @{
            Type = "GPO"
            Description = Get-ADMString -ADMLContent $ADMLXML -key $CurrentPolicy.Attributes.GetNamedItem("explainText")."#text"
            Name = $CPDisplayName
        }
        Write-Host "$($MainSetting.Name)"
        <#
        # How to present the policy
        $PKey = $CurrentPolicy.Attributes.GetNamedItem("presentation")."#text"
        if ([string]::IsNullOrEmpty($PKey)) { $DNKey = $CurrentPolicy.presentation }
        $CPPresentation = Get-ADMPresentation -ADMLContent $ADMLXML -Key $PKey
        #>

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
                        $ItemName = Get-ADMString -ADMLContent $ADMLXML -key $CurrentElement.displayName
                        if (-not $ItemName) {
                            $ItemName = "ItemName"
                        }
                        [PSCustomObject] @{
                            Type = "Registry"
                            Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
                            ValueName = $CurrentElement.valueName
                            Name = $ItemName
                            Value = $CurrentPolicy.name
                        }
                    }
                    'enum' {
                        $CurrentElement.item | ForEach-Object {
                            if ($_.value.decimal.value) {
                                $ItemName = Get-ADMString -ADMLContent $ADMLXML -key $_.displayName
                                
                                # if ($ItemName.Length -gt 75) {
                                #     $ItemName = "{0}..." -f $ItemName.Substring(0,75)
                                # }
                                [PSCustomObject] @{
                                    Type = "Registry"
                                    Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
                                    ValueName = $CurrentElement.valueName
                                    Name = $ItemName
                                    Value = $_.value.decimal.value
                                    DataType = "Integer"
                                    DataLength = 10
                                }
                            }
                            elseif (-not ([string]::IsNullOrEmpty($_.value.string))) {
                                $ItemValue = $_.value.string
                                $ItemName = Get-ADMString -ADMLContent $ADMLXML -key $_.displayName
                                
                                [PSCustomObject] @{
                                    Type = "Registry"
                                    Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
                                    ValueName = $CurrentElement.valueName
                                    Name = $ItemName
                                    Value = $ItemValue
                                    Description = Get-ADMString -ADMLContent $ADMLXML -key $_.explainText
                                    DataType = "String"
                                    DataLength = 50
                                }
                            }
                        }
                    }
                    'decimal' {
                        
                        [PSCustomObject] @{
                            Type = "Registry"
                            Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
                            ValueName = $CurrentElement.valueName
                            Name = $ItemName
                            Value = $ItemValue
                            Description = Get-ADMString -ADMLContent $ADMLXML -key $_.explainText
                            DataType = "Integer"
                            DataLength = 1
                        }
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
                        # $CIName = "$CPDisplayName - $ValueName = 1"
                        # if ($CIName -notin $CIList.LocalizedDisplayName) {
                        #     $NewEnabledCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                        #     $NewEnabledCI | Move-CMObject -FolderPath $DestinationFolder
                        #     $NewEnabledCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType Integer -ExpectedValue '1' -Hive LocalMachine -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentElement.valueName) = 1" -Name $CurrentElement.valueName -ValueName $CurrentElement.valueName
                        # }
                        # $CIName = "$CPDisplayName - $ValueName = 0"
                        # if ($CIName -notin $CIList.LocalizedDisplayName) {
                        #     $NewDisabledCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                        #     $NewDisabledCI | Move-CMObject -FolderPath $DestinationFolder
                        #     $NewDisabledCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType Integer -ExpectedValue '0' -Hive LocalMachine -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentElement.valueName) = 0" -Name $CurrentElement.valueName -ValueName $CurrentElement.valueName

                        # }
                        #$CurrentElement
                        Write-Host ("{0}_{1}_{2}" -f $CPDisplayName,$CurrentElement.valueName,$CurrentIsRequired)
                        [PSCustomObject] @{
                            Type = "Registry"
                            Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
                            ValueName = $CurrentElement.valueName
                            Name = $ItemName
                            Value = $ItemValue
                            Description = Get-ADMString -ADMLContent $ADMLXML -key $_.explainText
                            DataType = "Boolean"
                            DataLength = 1
                        }
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
        elseif (-not [string]::IsNullOrEmpty($CurrentPolicy.disabledValue.decimal.value) -or -not [string]::IsNullOrEmpty($CurrentPolicy.enabledValue.decimal.value)) {
            [PSCustomObject] @{
                Type = "Registry-"
                Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
                ValueName = $CurrentPolicy.valueName
                Name = Get-ADMString -ADMLContent $ADMLXML -key $_.displayName
                Value = $CurrentPolicy.disabledValue.decimal.value
                Description = Get-ADMString -ADMLContent $ADMLXML -key $_.explainText
                DataType = "EnableDisable"
                DataLength = $CurrentPolicy.enabledValue.decimal.value
            }
        }
        else {
            if ($null -ne $CurrentPolicy.key) {
                #$CurrentPolicy.ChildNodes | Where-Object { $_.Name -eq 'enabledValue' } | ForEach-Object {
                    # $ItemValue = $CurrentPolicy.disabledValue.decimal.value
                    # if ($null -ne $CurrentPolicy.enabledValue.decimal.value) {
                    #     $ItemValue = $CurrentPolicy.enabledValue.decimal.value
                    # }
                    # if ($null -ne $CurrentPolicy.disabledValue.decimal.value) {
                    #     $ItemValue = $CurrentPolicy.disabledValue.decimal.value
                    # }
                    [PSCustomObject] @{
                        Type = "Registry"
                        Path = "{0}\{1}" -f $RegHive,$CurrentPolicy.key
                        ValueName = $CurrentPolicy.valueName
                        Name = Get-ADMString -ADMLContent $ADMLXML -key $_.displayName
                        Value = $CurrentPolicy.disabledValue.decimal.value
                        Description = Get-ADMString -ADMLContent $ADMLXML -key $_.explainText
                        DataType = "EnableDisable"
                        DataLength = $CurrentPolicy.enabledValue.decimal.value
                    }
                    #$CIName = "$CPDisplayName - $($CurrentPolicy.valueName) = Enabled ($($CurrentPolicy.enabledValue.decimal.value))"
                    # if ($CIName -notin $CIList.LocalizedDisplayName) {
                    #     $NewEnabledCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                    #     $NewEnabledCI | Move-CMObject -FolderPath $DestinationFolder
                    #     $NewEnabledCI | Add-CMComplianceSettingRegistryKeyValue -ExpressionOperator IsEquals -ValueRule -DataType Integer -ExpectedValue $CurrentPolicy.enabledValue.decimal.value -Hive LocalMachine -Is64Bit -KeyName $CurrentPolicy.key -RemediateDword $true -NoncomplianceSeverity Critical -RuleName "$($CurrentPolicy.valueName) = 1" -Name "$($CurrentPolicy.valueName)" -ValueName "$($CurrentPolicy.valueName)"
                    # }
                    #$CIName
                #}
                #$CurrentPolicy.ChildNodes | Where-Object { $_.Name -eq 'disabledValue' } | ForEach-Object {
                    #$CIName = "$CPDisplayName - $($CurrentPolicy.valueName) = Disabled ($($CurrentPolicy.disabledValue.decimal.value))"
                    # if ($CIName -notin $CIList.LocalizedDisplayName) {
                    #     $NewDisabledCI=New-CMConfigurationItem -Name $CIName -CreationType WindowsOS -Category $CategoryList
                    #     $NewDisabledCI | Move-CMObject -FolderPath $DestinationFolder
                    #     $KeyValueParameters = [PSCustomObject] @{
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
                    #$CIName
                #}
                #Start-Sleep -Seconds 60
            }
            else {
                Write-Warning $CurrentPolicy
            }
        }
    }
} | Out-GridView -Title $Category.Name
