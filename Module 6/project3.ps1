$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptDir 'project3.log'

function Write-Action {
    param([string]$Message)
    $time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$time - $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
}

function Show-Help {
    @"
Commands:
  show                 - show current location contents
  up                   - go up one level (in filesystem or registry)
  cd <path|HK...:\>    - set new location (supports registry HKCU:\ HKLM:\, etc)
  switch               - toggle between filesystem and registry root (prompts for target)
  pwd                  - show current location
  clear                - clear screen
  help                 - show this help
  exit                 - quit script
"@ -split "`n" | ForEach-Object { Write-Host $_ }
}

function Test-RegistryPath {
    param([string]$path)
    return $path -match '^[a-zA-Z]{2,4}:\\'
}

function Get-NavContents {
    param([string]$location)
    try {
        if (Test-RegistryPath $location) {
            # Use Get-ChildItem which also works for registry providers
            Get-ChildItem -Path $location -ErrorAction Stop | ForEach-Object { Write-Host $_.Name }
        } else {
            Get-ChildItem -Path $location -Force -ErrorAction Stop | ForEach-Object { Write-Host $_.Name }
        }
        Write-Action "Showed contents of $location"
    } catch {
        Write-Host "Unable to list contents of $location : $($_.Exception.Message)"
        Write-Action "Failed to list contents of $location - $($_.Exception.Message)"
    }
}

function Set-NavLocation {
    param([string]$target)
    try {
        Set-Location -Path $target -ErrorAction Stop
        Clear-Host
        Write-Action "Changed location to: $target"
        Write-Host "Location changed to: $(Get-Location)"
        return $true
    } catch {
        Write-Host "Failed to set location to: $target : $($_.Exception.Message)"
        Write-Action "Failed to change location to: $target - $($_.Exception.Message)"
        return $false
    }
}

function Move-NavUp {
    $current = (Get-Location).Path
    try {
        if (Test-RegistryPath $current) {
            # Registry path: remove last path segment unless at root like HKCU:\
            $parts = $current -split '\\'
            if ($parts.Length -le 2) {
                Write-Host "Already at registry root: $current"
                Write-Action "Attempted to move up but already at registry root: $current"
                return
            }
            $new = ($parts[0..($parts.Length-2)] -join '\\')
            Set-Location -Path $new -ErrorAction Stop
        } else {
            Set-Location .. -ErrorAction Stop
        }
        Clear-Host
        Write-Action "Moved up to: $(Get-Location)"
        Write-Host "Moved up to: $(Get-Location)"
    } catch {
        Write-Host "Cannot move up from $current : $($_.Exception.Message)"
        Write-Action "Failed to move up from $current - $($_.Exception.Message)"
    }
}

# Starter message and ask for starting location
Write-Host "Project 3: Enhanced navigator (type 'help' for commands)"
Write-Action "Script started"

# Ask for starting location
$start = Read-Host 'Enter starting location (path or registry like HKCU:\) or press Enter to use current location'
if ($start -and $start.Trim().ToLower() -eq 'help') {
    Show-Help
    Write-Action "User requested help at start prompt"
} elseif ($start -and $start.Trim() -ne '') {
    Set-NavLocation -target $start | Out-Null
}

# Main loop
while ($true) {
    $loc = Get-Location
    Write-Host "`nCurrent location: $loc"
    $cmd = (Read-Host 'Enter command (show/up/cd/pwd/switch/clear/help/exit)').Trim()
    switch -Regex ($cmd) {
        '^show$' { Get-NavContents -location $loc.Path }
        '^up$' { Move-NavUp }
        '^cd\s+(.+)$' {
            $target = $matches[1]
            Set-NavLocation -target $target | Out-Null
        }
        '^switch$' {
            # Prompt for new type and location
            $choice = Read-Host "Switch to (fs) filesystem or (reg) registry? (fs/reg)"
            if ($choice -match '^reg$') {
                $regRoot = Read-Host 'Enter registry root (for example HKCU:\ or HKLM:\)'
                if ($regRoot) { Set-NavLocation -target $regRoot | Out-Null }
            } elseif ($choice -match '^fs$') {
                $fsRoot = Read-Host 'Enter filesystem path (for example C:\ or C:\Users)'
                if ($fsRoot) { Set-NavLocation -target $fsRoot | Out-Null }
            } else {
                Write-Host 'Unknown choice. Type fs or reg.'
            }
        }
        '^pwd$' { Write-Host (Get-Location) }
        '^clear$' { Clear-Host }
        '^help$' { Show-Help }
        '^exit$' {
            Write-Action "Script exited by user"
            break
        }
        default { Write-Host "Unknown command. Type 'help' for options." }
    }
}

Write-Host "Goodbye. Log file: $logFile"
