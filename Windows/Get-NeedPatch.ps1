function Get-NeedPatch {
        param(
            [int] $MaxDaysAfterPatchTuesday = 0
        )
        $RuntimeDate = Get-Date
        Write-Information ("Runtime date: {0}" -f $RuntimeDate)
        $LastPatchDate = Get-HotFix | Sort-Object -ErrorAction Ignore -Property InstalledOn | Select-Object -ErrorAction Ignore -Last 1 -ExpandProperty InstalledOn
        Write-Host ("Date of last installed hotfix: {0}" -f $LastPatchDate)
        Write-Debug ("Days since last patch: {0}" -f (Get-Date).Subtract($LastPatchDate).Days)
        
        $ThisMonthPatchTuesday = Get-NthDayofMonth
        Write-Information ("This months patch tuesday: {0}" -f $ThisMonthPatchTuesday)

        $LastMonthPatchTuesday = (Get-NthDayofMonth -Month $ThisMonthPatchTuesday.AddMonths(-1).Month)
        $SkippedLastMonthsPatches = $LastMonthPatchTuesday -gt $LastPatchDate
        Write-Information ("Last months patch tuesday: {0}" -f $LastMonthPatchTuesday)
        Write-Information ("Skipped last months patches: {0}" -f $SkippedLastMonthsPatches)
        
        $DaysSincePatchTuesday = $RuntimeDate.Subtract($ThisMonthPatchTuesday).Days
        Write-Debug ("Days that have passed since this months patch tuesday: {0}" -f $DaysSincePatchTuesday)

        $TotalDaysBetweenPatchTuesdays = [System.Math]::Floor($ThisMonthPatchTuesday.Subtract($LastMonthPatchTuesday).Days)
        Write-Debug ("Days between the tuesdays: {0}" -f $TotalDaysBetweenPatchTuesdays)

        if ($SkippedLastMonthsPatches) {
            return $true
        }
        elseif ($DaysSincePatchTuesday -gt $MaxDaysAfterPatchTuesday) {
            Write-Information ("Days since patch tuesday ({0}) is greater than specified MaxDaysAfterPatchTuesday ({1})" -f $DaysSincePatchTuesday, $MaxDaysAfterPatchTuesday)
            return $true
        }
        return $false
    }
