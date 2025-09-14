# enhanced system analysis script - project 2
# set up logging and basic variables
$logFile = "system_analysis_log.txt"
$hostName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "dd-MM-yy-HH-mm-ss"

# function to write to log file
function Write-Log {
    param($Message)
    $logTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$logTimestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Output $Message
}

# function to create csv filename with naming convention
function Get-CsvFileName {
    param($Type)
    return "$hostName-$Type-$timestamp.csv"
}

# start logging
Write-Log "=== Enhanced System Analysis Script Started ==="
Write-Log "Host Name: $hostName"
Write-Log "Timestamp: $timestamp"

try {
    # 1. get total memory size
    Write-Log "Getting total memory size..."
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $totalMemoryGB = [Math]::Round($memoryInfo.Sum / 1GB, 2)
    Write-Log "Total Memory: $totalMemoryGB GB"

    # 2. get all installed software
    Write-Log "Getting all installed software..."
    $installedSoftware = Get-CimInstance -ClassName Win32_Product | Select-Object Name, Version, Vendor, InstallDate
    Write-Log "Found $($installedSoftware.Count) installed software packages"

    # 3. network information mapping
    Write-Log "Gathering network information..."
    
    # get ip address information
    $ipAddresses = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -ne "WellKnown" }
    
    # get dns client server address
    $dnsServers = Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 }
    
    # get network routes
    $netRoutes = Get-NetRoute | Where-Object { $_.AddressFamily -eq "IPv4" }
    
    # create merged network information
    $networkInfo = @()
    foreach ($ip in $ipAddresses) {
        $dns = $dnsServers | Where-Object { $_.InterfaceAlias -eq $ip.InterfaceAlias } | Select-Object -First 1
        $route = $netRoutes | Where-Object { $_.InterfaceAlias -eq $ip.InterfaceAlias } | Select-Object -First 1
        
        $networkInfo += [PSCustomObject]@{
            HostName = $hostName
            InterfaceAlias = $ip.InterfaceAlias
            IPAddress = $ip.IPAddress
            PrefixLength = $ip.PrefixLength
            DestinationPrefix = if ($route) { $route.DestinationPrefix } else { "N/A" }
            NextHop = if ($route) { $route.NextHop } else { "N/A" }
            DNSServer = if ($dns -and $dns.ServerAddresses) { $dns.ServerAddresses -join "; " } else { "N/A" }
            InterfaceIndex = $ip.InterfaceIndex
        }
    }
    Write-Log "Network information mapping completed"

    # 4. gather additional system information
    Write-Log "Gathering additional system information..."
    
    # system info
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
    $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    
    # environment paths
    $environmentPaths = @()
    $pathVariable = $env:PATH -split ';'
    foreach ($path in $pathVariable) {
        if ($path.Trim() -ne "") {
            $environmentPaths += [PSCustomObject]@{
                HostName = $hostName
                PathType = "PATH"
                PathValue = $path.Trim()
            }
        }
    }
    
    # add other environment variables
    $envVars = @("USERPROFILE", "PROGRAMFILES", "PROGRAMFILES(X86)", "WINDIR", "TEMP", "TMP")
    foreach ($envVar in $envVars) {
        $value = [Environment]::GetEnvironmentVariable($envVar)
        if ($value) {
            $environmentPaths += [PSCustomObject]@{
                HostName = $hostName
                PathType = $envVar
                PathValue = $value
            }
        }
    }
    
    # network connections
    $networkConnections = Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess
    $networkConnectionsFormatted = @()
    foreach ($conn in $networkConnections) {
        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        $networkConnectionsFormatted += [PSCustomObject]@{
            HostName = $hostName
            LocalAddress = $conn.LocalAddress
            LocalPort = $conn.LocalPort
            RemoteAddress = $conn.RemoteAddress
            RemotePort = $conn.RemotePort
            State = $conn.State
            ProcessId = $conn.OwningProcess
            ProcessName = if ($process) { $process.ProcessName } else { "Unknown" }
        }
    }
    
    # running tasks/processes
    $runningTasks = Get-Process | Select-Object ProcessName, Id, CPU, WorkingSet, VirtualMemorySize, StartTime
    $runningTasksFormatted = @()
    foreach ($task in $runningTasks) {
        $runningTasksFormatted += [PSCustomObject]@{
            HostName = $hostName
            ProcessName = $task.ProcessName
            ProcessId = $task.Id
            CPU = if ($task.CPU) { [Math]::Round($task.CPU, 2) } else { 0 }
            WorkingSetMB = [Math]::Round($task.WorkingSet / 1MB, 2)
            VirtualMemoryMB = [Math]::Round($task.VirtualMemorySize / 1MB, 2)
            StartTime = $task.StartTime
        }
    }

    # create csv files
    Write-Log "Creating CSV files..."
    
    # 1. info csv - system information
    $infoData = [PSCustomObject]@{
        HostName = $hostName
        Manufacturer = $computerSystem.Manufacturer
        Model = $computerSystem.Model
        TotalPhysicalMemoryGB = $totalMemoryGB
        ProcessorName = $processor.Name
        ProcessorCores = $processor.NumberOfCores
        ProcessorLogicalProcessors = $processor.NumberOfLogicalProcessors
        OSName = $operatingSystem.Caption
        OSVersion = $operatingSystem.Version
        OSArchitecture = $operatingSystem.OSArchitecture
        TotalVisibleMemoryGB = [Math]::Round($operatingSystem.TotalVisibleMemorySize / 1MB, 2)
        FreePhysicalMemoryGB = [Math]::Round($operatingSystem.FreePhysicalMemory / 1MB, 2)
        AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $infoFileName = Get-CsvFileName "Info"
    $infoData | Export-Csv -Path $infoFileName -NoTypeInformation
    Write-Log "Created Info CSV: $infoFileName"

    # 2. netinfo csv - network information
    $netInfoFileName = Get-CsvFileName "NetInfo"
    $networkInfo | Export-Csv -Path $netInfoFileName -NoTypeInformation
    Write-Log "Created NetInfo CSV: $netInfoFileName"

    # 3. environpaths csv - environment paths
    $environPathsFileName = Get-CsvFileName "EnvironPaths"
    $environmentPaths | Export-Csv -Path $environPathsFileName -NoTypeInformation
    Write-Log "Created EnvironPaths CSV: $environPathsFileName"

    # 4. networkconnection csv - network connections
    $networkConnectionFileName = Get-CsvFileName "NetworkConnection"
    $networkConnectionsFormatted | Export-Csv -Path $networkConnectionFileName -NoTypeInformation
    Write-Log "Created NetworkConnection CSV: $networkConnectionFileName"

    # 5. running tasks csv
    $runningTasksFileName = Get-CsvFileName "RunningTasks"
    $runningTasksFormatted | Export-Csv -Path $runningTasksFileName -NoTypeInformation
    Write-Log "Created RunningTasks CSV: $runningTasksFileName"

    # 6. software csv
    $softwareFormatted = @()
    foreach ($software in $installedSoftware) {
        $softwareFormatted += [PSCustomObject]@{
            HostName = $hostName
            SoftwareName = $software.Name
            Version = $software.Version
            Vendor = $software.Vendor
            InstallDate = $software.InstallDate
        }
    }
    
    $softwareFileName = Get-CsvFileName "Software"
    $softwareFormatted | Export-Csv -Path $softwareFileName -NoTypeInformation
    Write-Log "Created Software CSV: $softwareFileName"

    # display summary information
    Write-Log ""
    Write-Log "=== SYSTEM ANALYSIS SUMMARY ==="
    Write-Log "Host Name: $hostName"
    Write-Log "Total Memory: $totalMemoryGB GB"
    Write-Log "Processor: $($processor.Name)"
    Write-Log "Operating System: $($operatingSystem.Caption)"
    Write-Log "Network Interfaces: $($networkInfo.Count)"
    Write-Log "Network Connections: $($networkConnectionsFormatted.Count)"
    Write-Log "Running Processes: $($runningTasksFormatted.Count)"
    Write-Log "Installed Software: $($softwareFormatted.Count)"
    Write-Log ""
    Write-Log "=== CREATED CSV FILES ==="
    Write-Log "1. $infoFileName"
    Write-Log "2. $netInfoFileName"
    Write-Log "3. $environPathsFileName"
    Write-Log "4. $networkConnectionFileName"
    Write-Log "5. $runningTasksFileName"
    Write-Log "6. $softwareFileName"
    
    Write-Log "=== Enhanced System Analysis Script Completed Successfully ==="

} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "Script execution failed!"
    exit 1
}