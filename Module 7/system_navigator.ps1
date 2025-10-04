$logFile = "c:\Users\noah\VsCode\ITS3410A-A1\Module 7\system_navigator_log.txt"
$startTime = Get-Date
Add-Content -Path $logFile -Value "=== System Navigator Script Started at $startTime ==="

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

function Clear-ScreenAndLog {
    Clear-Host
    Write-Log "Screen cleared"
}

function Show-EventLogs {
    Clear-ScreenAndLog
    Write-Log "Displaying Event Logs information"
    
    Write-Host "EVENT LOGS"
    Write-Host ""
    
    try {
        $eventLogs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | 
                    Select-Object LogName, RecordCount | 
                    Sort-Object RecordCount -Descending
        
        Write-Host "Event Logs (sorted by Record Count):"
        $eventLogs | Format-Table -AutoSize
        
        Write-Log "Successfully displayed $($eventLogs.Count) event logs"
    }
    catch {
        $errorMsg = "Error retrieving event logs: $($_.Exception.Message)"
        Write-Log $errorMsg
        Write-Host $errorMsg
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Processes {
    Clear-ScreenAndLog
    Write-Log "Displaying Processes information"
    
    Write-Host "PROCESSES"
    Write-Host ""
    
    try {
        Write-Host "Processes (including owner information):"
        
        try {
            $processes = Get-Process -IncludeUserName -ErrorAction Stop | 
                        Sort-Object CPU -Descending
            
            $processes | Format-Table Name, Id, CPU, UserName, ProcessName -AutoSize
            Write-Log "Successfully displayed $($processes.Count) processes with owner information"
        }
        catch {
            Write-Host "Note: Running without elevated privileges - owner information not available for all processes"
            Write-Log "Elevated privileges not available - showing processes without full owner info"
            
            $processes = Get-Process | Sort-Object CPU -Descending
            $processes | Format-Table Name, Id, CPU, ProcessName -AutoSize
            Write-Log "Successfully displayed $($processes.Count) processes (limited owner information)"
        }
    }
    catch {
        $errorMsg = "Error retrieving processes: $($_.Exception.Message)"
        Write-Log $errorMsg
        Write-Host $errorMsg
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-DirectoryNavigation {
    Clear-ScreenAndLog
    Write-Log "Starting interactive directory navigation"
    
    do {
        $currentDir = Get-Location
        Write-Host "DIRECTORY NAVIGATION"
        Write-Host "Current Directory: $currentDir"
        Write-Host ""
        
        try {
            $items = Get-ChildItem -Path $currentDir | Sort-Object Name
            Write-Host "Directory Contents:"
            
            for ($i = 0; $i -lt $items.Count; $i++) {
                $item = $items[$i]
                $type = if ($item.PSIsContainer) { "[DIR]" } else { "[FILE]" }
                $size = if ($item.PSIsContainer) { "" } else { "($($item.Length) bytes)" }
                Write-Host "$($i + 1). $type $($item.Name) $size"
            }
            
            Write-Log "Displayed $($items.Count) items in directory: $currentDir"
        }
        catch {
            $errorMsg = "Error reading directory: $($_.Exception.Message)"
            Write-Log $errorMsg
            Write-Host $errorMsg
        }
        
        Write-Host ""
        Write-Host "NAVIGATION OPTIONS"
        Write-Host "Enter number to navigate to folder"
        Write-Host ".. - Go up one directory"
        Write-Host "cd <path> - Change to specific directory"
        Write-Host "back - Return to main menu"
        Write-Host ""
        Write-Host "Choice: " -NoNewline
        
        $navChoice = Read-Host
        Write-Log "Navigation choice: $navChoice"
        
        switch -Regex ($navChoice) {
            "^back$" {
                Write-Log "User returned to main menu from directory navigation"
                return
            }
            "^\.\.$" {
                try {
                    Set-Location ".."
                    Write-Log "Navigated up to parent directory: $(Get-Location)"
                    Clear-Host
                }
                catch {
                    Write-Host "Cannot navigate up: $($_.Exception.Message)"
                    Start-Sleep 2
                }
            }
            "^cd\s+(.+)$" {
                $targetPath = $matches[1]
                try {
                    Set-Location $targetPath
                    Write-Log "Changed directory to: $(Get-Location)"
                    Clear-Host
                }
                catch {
                    Write-Host "Cannot change directory: $($_.Exception.Message)"
                    Start-Sleep 2
                }
            }
            "^\d+$" {
                $index = [int]$navChoice - 1
                if ($index -ge 0 -and $index -lt $items.Count) {
                    $selectedItem = $items[$index]
                    if ($selectedItem.PSIsContainer) {
                        try {
                            Set-Location $selectedItem.FullName
                            Write-Log "Navigated to directory: $(Get-Location)"
                            Clear-Host
                        }
                        catch {
                            Write-Host "Cannot navigate to directory: $($_.Exception.Message)"
                            Start-Sleep 2
                        }
                    }
                    else {
                        Write-Host "Selected item is a file, not a directory."
                        Start-Sleep 2
                    }
                }
                else {
                    Write-Host "Invalid selection."
                    Start-Sleep 2
                }
            }
            default {
                Write-Host "Invalid option. Try again."
                Start-Sleep 2
            }
        }
        Clear-Host
    } while ($true)
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "MAIN MENU"
    Write-Host "1. View Event Logs"
    Write-Host "2. View Processes"
    Write-Host "3. Navigate Directory"
    Write-Host "4. Quit"
    Write-Host ""
    Write-Host "Please select an option (1-4): " -NoNewline
}

Write-Log "System Navigator Script initialized"
Write-Host "Welcome to System Navigator!"
Write-Log "User started interactive session"

Show-DirectoryNavigation

do {
    Show-MainMenu
    $choice = Read-Host
    Write-Log "User selected option: $choice"
    
    switch ($choice) {
        "1" {
            Show-EventLogs
        }
        "2" {
            Show-Processes
        }
        "3" {
            Clear-ScreenAndLog
            Show-DirectoryNavigation
        }
        "4" {
            Write-Log "User chose to quit"
            Write-Host "Goodbye!"
            break
        }
        default {
            Write-Log "Invalid selection: $choice"
            Write-Host "Invalid selection. Please choose 1-4."
            Start-Sleep 2
        }
    }
} while ($choice -ne "4")

$endTime = Get-Date
Write-Log "=== System Navigator Script Ended at $endTime ==="
Write-Log "Total runtime: $((New-TimeSpan -Start $startTime -End $endTime).TotalMinutes) minutes"