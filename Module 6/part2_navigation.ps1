$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptDir 'part2_navigation.log'

function Write-Action {
	param([string]$Message)
	$time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
	"$time - $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
}

Write-Host "Part 2: Simple navigator (type 'help' for commands)"
Write-Action "Script started"

# Ask for starting location
$start = Read-Host 'Enter starting location (path or registry like HKCU:\)'
# If the user asked for help at the prompt, show help and keep current location
if ($start -and $start.Trim().ToLower() -eq 'help') {
	Show-Help
	Write-Action "User requested help at start prompt"
} elseif ($start -and $start.Trim() -ne '') {
	try {
		Set-Location -Path $start -ErrorAction Stop
		Write-Action "Set starting location to: $start"
	} catch {
		Write-Host "Failed to set location. Using current location instead."
		Write-Action "Failed to set starting location: $start. Using current location: $(Get-Location)"
	}
}

function Show-Help {
	"Commands:`n show     - show current location contents`n up       - go up one level`n cd <path> - set new location`n pwd      - show current location`n exit     - quit script`n help     - show this help" | Write-Host
}

:mainLoop
while ($true) {
	$loc = Get-Location
	Write-Host "`nCurrent location: $loc"
	$cmd = (Read-Host 'Enter command (show/up/cd/pwd/help/exit)').Trim()
	switch -Regex ($cmd) {
		'^show$' {
			Write-Host "Contents of $($loc):`n"
			try {
				Get-ChildItem -Force | ForEach-Object { Write-Host $_.Name }
				Write-Action "Showed contents of $loc"
			} catch {
				Write-Host "Unable to list contents of $loc"
				Write-Action "Failed to list contents of $loc"
			}
		}
		'^up$' {
			try {
				Set-Location ..
				Write-Action "Moved up to: $(Get-Location)"
			} catch {
				Write-Host "Cannot move up from $loc"
				Write-Action "Failed to move up from $loc"
			}
		}
		'^cd\s+(.+)$' {
			$target = $matches[1]
			try {
				Set-Location -Path $target -ErrorAction Stop
				Write-Action "Changed location to: $target"
			} catch {
				Write-Host "Failed to set location to: $target"
				Write-Action "Failed to change location to: $target"
			}
		}
		'^pwd$' {
			Write-Host (Get-Location)
		}
		'^help$' { Show-Help }
		'^exit$' {
			Write-Action "Script exited by user"
			break
		}
		default { Write-Host "Unknown command. Type 'help' for options." }
	}
}

Write-Host "Goodbye. Log file: $logFile"

