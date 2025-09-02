# Get all running processes
$processes = Get-Process

# Log file path
$logFile = "${PSScriptRoot}\output_log.txt"

# Clear log file if exists
if (Test-Path $logFile) {
    Clear-Content $logFile
}

# Target process names
$targetNames = @('svchost', 'runtimebroker')

foreach ($proc in $processes) {
    foreach ($name in $targetNames) {
        if ($proc.Name -ieq $name) {
            $output = "Id: $($proc.Id), CPU: $($proc.CPU), Name: $($proc.Name)"
            Write-Output $output
            Add-Content -Path $logFile -Value $output
            Start-Sleep -Seconds 1
        }
    }
}
