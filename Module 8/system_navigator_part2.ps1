$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logFile = Join-Path $scriptDir ("navigator_log_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))

function Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $line
}

function Show-Header {
    Write-Host "System Navigator - interactive (type 'help' for commands)"
    Write-Host "Log: $logFile"
}

function Get-NavigatorItems {
    param([string]$Path)
    try {
        $items = Get-ChildItem -Path $Path -Force -ErrorAction Stop
        $items | ForEach-Object {
            $type = if ($_.PSIsContainer) { "<DIR>" } else { "<FILE>" }
            Write-Output "{0,-6} {1}" -f $type, $_.Name
        }
    Log "Listed contents of $($Path)"
    } catch {
    Write-Error "Failed to list $($Path): $($_)"
    Log "ERROR listing $($Path): $($_)"
    }
}

function Start-Navigator {
    param([string]$StartLocation)

    if (-not $StartLocation) {
        $StartLocation = Read-Host "Enter a starting location (e.g. C:\\, HKLM:\\SOFTWARE)"
    }

    try {
        Set-Location -Path $StartLocation -ErrorAction Stop
    } catch {
    Write-Host "Cannot set location to '$StartLocation'. Falling back to current working directory."
    Log "Failed to set start location to $($StartLocation): $($_)"
    }

    while ($true) {
        $current = Get-Location
        Write-Host "`nCurrent Location: $current"
        $cmd = Read-Host "navigator>"
        Log "Input: $cmd"

        switch -Regex ($cmd) {
            '^help$' {
                @(
                    "help - Show this help",
                    "ls | dir - List current location",
                    "pwd - Show current location",
                    "cd <path> - Change to path (supports registry e.g. HKLM:\\)",
                    "up - Go up one directory (parent)",
                    "log - Show log file path",
                    "exit - Quit navigator"
                ) | ForEach-Object { Write-Host $_ }
            }
            '^(ls|dir)$' {
                Get-NavigatorItems -Path $current.Path
            }
            '^pwd$' {
                Write-Host $current.Path
            }
            '^log$' {
                Write-Host "Log file: $logFile"
            }
            '^exit$' {
                Log "Exit navigator"
                break
            }
            '^up$' {
                try {
                    $parent = Split-Path -Path $current.Path -Parent
                    if ($parent) { Set-Location -Path $parent; Log "Changed to parent $($parent)" } else { Write-Host "No parent for $current" }
                } catch {
                    Write-Error "Failed to go up: $($_)"; Log "ERROR going up from $($current): $($_)"
                }
            }
            '^cd\s+(.+)$' {
                $target = $Matches[1].Trim()
                try {
                    Set-Location -Path $target -ErrorAction Stop
                    Log "Changed location to $($target)"
                } catch {
                    Write-Error "Failed to change location to $($target): $($_)"
                    Log "ERROR changing to $($target): $($_)"
                }
            }
            default {
                if ($cmd -match '^\\s*$') { continue }
                Write-Host "Unknown command. Type 'help' for commands."
            }
        }
    }
}

Show-Header
Log "Navigator started"
Start-Navigator -StartLocation $args[0]
Log "Navigator finished"
Write-Host "Navigator session ended. Log saved to $($logFile)"