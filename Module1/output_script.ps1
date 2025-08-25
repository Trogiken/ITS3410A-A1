# PowerShell Script: Output user info, date, and file details to log
$logFile = Join-Path $PSScriptRoot "output_log.txt"

# Echo your User Id and date
"User Id: $env:USERNAME" | Out-File -FilePath $logFile
"Date: $(Get-Date)" | Out-File -FilePath $logFile -Append

# List all .scr and .ico files in C:\Windows\System32 with file info
Get-ChildItem -Path "C:\Windows\System32\*" -File -Include *.scr, *.ico |
Select-Object Name, FullName, Length, LastWriteTime |
Format-Table | Out-File -FilePath $logFile -Append

# Echo the current date again
"Date: $(Get-Date)" | Out-File -FilePath $logFile -Append
