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
# SIG # Begin signature block
# MIIFnQYJKoZIhvcNAQcCoIIFjjCCBYoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZ6zEnfGg4VpEoDiut4COdOoT
# uwagggMzMIIDLzCCAhegAwIBAgIQG0s8nYRyi79Pl/APrYg+JDANBgkqhkiG9w0B
# AQsFADAfMR0wGwYDVQQDDBRpdHMzNDEwLXNpZ25pbmctbm9haDAeFw0yNTEwMTQw
# MTM2MTVaFw0yNjEwMTQwMTU2MTVaMB8xHTAbBgNVBAMMFGl0czM0MTAtc2lnbmlu
# Zy1ub2FoMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxxmsFxMkST9y
# mY0c2ZT+DJux76xfQR1slTlym91hJNAfxOyFSntaTjJYU4BW+pvPDPJ3tOTouPwy
# eSB9ngxs21ttNPHMz+QKxNPSl3vdDXoH8Av7y029pWj30vqnD5qsOUzFHxHirIhv
# esZ8GXPxl5OZubj6/OdxUnISGdj/zxo5kWF5syM0tAofl0CnyjPTthjjUWnJ/3xg
# 7TNJ7au5iJgJKZuRuo9ILje40KXBzT7NCotDDpIyZhQZ6if1/fBbScgEFGwJDskU
# mpQKOX0hhY6XZqCAMXKl8faMo/+1N7yrW9nT74qh4vOY4GCvfEAGibFACJ4wKNUI
# +2dtDN6dkQIDAQABo2cwZTAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwHwYDVR0RBBgwFoIUaXRzMzQxMC1zaWduaW5nLW5vYWgwHQYDVR0OBBYE
# FKFeOfo0fulTrGME2g1om5IiuSe5MA0GCSqGSIb3DQEBCwUAA4IBAQC4wGL/U8QM
# 5LPJXyJ9m+W0kCDBjTtbfM/ISUWCQG66hQg7qXpM0z2aBihHYYwEQCjA3jI6aMeI
# SbP9x1alen5aGj6hK14vSt2X3pCfhrixI+lth3IfXi15ooS8JLUBxBOeJY/OlMFI
# WXLkBhhDXxvsysTk7uGoGyvTBlNxTJgEvFWc7ULgkLHlSvGN8CCkoqwtGmueCht5
# kZ89Vz2Bzq77oomXVdherybGwUKmvb3e5W9pvisMIJaUSAMNUZpsGqYJvfu9Y0gl
# PB0oCIiYirb7//tojMigFjldvcSILTx3O7q12CA92xlRFj/LujR9VgR5Jjbt5T3E
# aTc3aEZhUirAMYIB1DCCAdACAQEwMzAfMR0wGwYDVQQDDBRpdHMzNDEwLXNpZ25p
# bmctbm9haAIQG0s8nYRyi79Pl/APrYg+JDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUkPjCAHKN
# dlqtkAwZ9JU6EfZTOM0wDQYJKoZIhvcNAQEBBQAEggEAxOE09n7UVpzA9lrGbwOa
# /lIOfhT+ojKjE0x/QJ6pZCrpUqfOq/NRLb3Tle8EqNDzMA9mvLESMKelAcQhMFK3
# DETGF26mGBkYkuZhdlsaO4IlFDtFy6ZPlbUxgjF4gp+0gzAvvOifqLqlPaXCM6z0
# GipKP06q5wSpkBMBolN60mEAuxhEKWlLl9PEPABcBTdMcn0TpKrS0NcnBGofqVnR
# nTo0cSlovPFpVlF9iASJ1Rrg5pWdorl4z8eSCzUfYOL3q0oflCnAq+Vak85lxnOL
# 7H+YvpMfoP1bjnfIyJqfxeBAbDrD7qc8Hns5dzsSvZxiaNvix0wprRuYyRBTc7uf
# oQ==
# SIG # End signature block
