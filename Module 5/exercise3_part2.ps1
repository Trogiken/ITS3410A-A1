param(
    [int] $Days
)

Set-StrictMode -Version Latest

function Get-DatesList {
    param(
        [int] $DaysToShow
    )

    $start = Get-Date
    $direction = if ($DaysToShow -lt 0) { -1 } else { 1 }
    $count = [math]::Abs($DaysToShow)

    for ($i = 0; $i -lt $count; $i++) {
        $d = $start.AddDays($i * $direction)
        [PSCustomObject]@{
            Index = $i
            Date = $d.ToString('yyyy-MM-dd')
            DayOfWeek = $d.DayOfWeek
        }
    }
}

function Show-DatesAndLog {
    param(
        [int] $DaysToShow,
        [string] $LogFile = 'exercise3_part2_output.txt'
    )

    # Validate DaysToShow is integer (param enforces it)
    if ($DaysToShow -eq $null) {
        throw 'DaysToShow is required.'
    }

    $dates = Get-DatesList -DaysToShow $DaysToShow

    # Write to console and log file
    if (Test-Path $LogFile) { Clear-Content $LogFile }
    "Listing $DaysToShow days starting from $(Get-Date -Format yyyy-MM-dd)" | Out-File -FilePath $LogFile
    foreach ($item in $dates) {
        $line = "$($item.Date) - $($item.DayOfWeek)"
        Write-Host $line
        $line | Out-File -FilePath $LogFile -Append
    }
    "Log saved to: $LogFile" | Out-File -FilePath $LogFile -Append
    Write-Host "Log saved to: $LogFile"
}

# Prompt if not provided
if ($null -eq $Days) {
    $input = Read-Host 'Enter number of days (positive or negative integer)'
    if (-not [int]::TryParse($input, [ref] $parsed)) {
        Write-Host 'Error: please enter a valid integer.' -ForegroundColor Red
        exit 1
    }
    $Days = $parsed
}

# Call function
try {
    Show-DatesAndLog -DaysToShow $Days
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    exit 1
}
