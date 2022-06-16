<#
.SYNOPSIS
    Find the Nth weekday of a given month and year.
.DESCRIPTION
    Returns a datetime object that represents the day that matches the given parameters.
.EXAMPLE
    PS C:\> Get-NthDayofMonth
    The default will to return the second tuesday of the current month.
.EXAMPLE
    PS C:\> $DateNow = Get-Date
    PS C:\> Get-NthDayofMonth -Month ($DateNow.Month - 1)
    Return the second tuesday of last month
.PARAMETER Year
    Sets which year to find the day in.
.PARAMETER Month
    Sets which month to find the day in.
.PARAMETER DayOfWeek
    Defines the day of the week to find.
.PARAMETER NthDay
    Defines the interval of the day to find.
.OUTPUTS
    Datetime
#>
function Get-NthDayofMonth {
    [CmdletBinding()]
    [OutputType([DateTime])]
    param(
        [ValidateRange(1,9999)]
        [Int] $Year = ([DateTime]::Today).Year,
        [ValidateRange(1,12)]
        [Int] $Month = ([DateTime]::Today).Month,
        [System.DayOfWeek] $DayOfWeek = [System.DayOfWeek]::Tuesday,
        [ValidateRange(1,5)]
        [Int] $NthDay = 2
    )
    process {
        $Parameters = @{
            # the value to subtract needs to be tuned. Needs to be > 1 and < 2.
            Day = ((7*$NthDay))-2
        }

        if ($Parameters.Day -ge [DateTime]::DaysInMonth($Year,$Month)) {
            $Parameters.Day = [DateTime]::DaysInMonth($Year,$Month)
        }
        if ($Year) {
            $Parameters.Add('Year',$Year)
        }
        if ($Month) {
            $Parameters.Add('Month',$Month)
        }
        
        $Date = Get-Date @Parameters
        $Date.AddDays($DayOfWeek-$Date.DayOfWeek) | Where-Object { $_.Month -eq $Month }
    }
}
