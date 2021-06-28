function Convert-SizeString {
    param(
        [System.Decimal]$Size,
        [string]$InputFormat,
        [int]$decimals = 2,
        [string]$OutputFormat,
        [Parameter(Mandatory=$true,ParameterSetName='BinaryPrefix')]
        [switch]$BinaryPrefix,
        [Parameter(Mandatory=$true,ParameterSetName='DecimalPrefix')]
        [switch]$DecimalPrefix
    )
    if ($BinaryPrefix.IsPresent) {
        $Formats = @('B','KB','MB','GB','TB','PB')
        $DivideBy = 1024
    }
    elseif ($DecimalPrefix.IsPresent) {
        $Formats = @('Bi','KiBi','MiBi','GiBi','TiBi','PiBi')
        $DivideBy = 1000
    }
    
    $Start = $Formats.IndexOf($InputFormat)
    if (-not $OutputFormat) {
        $End = $Formats.Count - 1 
    }
    else {
        $End = $Formats.IndexOf($OutputFormat)
    }

    if ($Start -lt 0 -or $End -lt 0) {
        Write-Host "Input or Output format not valid.`nAvailable formats: $($Formats -join ',')"
        break
    }
    
    if ($End -gt $Start) {
        [System.Decimal]$value = [System.Decimal](1.0 / [math]::Pow(10.0,[System.Decimal]$decimals))
        for ($i=$Start;$Size -ge $Value;$i++) {
            $LesserSize = ($Size / $DivideBy)
            if ($LesserSize -gt $value) {
                $Size = $LesserSize
                Write-Debug $Size
                if ($End -eq $i) {
                    break
                }
            }
            else {
                $End = $i
                break
            }
        }
    }
    elseif ($End -lt $Start) {
        for ($i=$Start;$Size -lt [System.Decimal]::MaxValue;$i--) {
            $NextMultiplication = $Size * $DivideBy
            if ($NextMultiplication -lt [System.Decimal]::MaxValue) {
                if ($End -eq $i) {
                    break
                }
                $Size = $NextMultiplication
            }
            else {
                $End = $i
                break
            }
        }
    }
    "$([math]::Round($Size,$decimals)) $($Formats[$End])"
}
