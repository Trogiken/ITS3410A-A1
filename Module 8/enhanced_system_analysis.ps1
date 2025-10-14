$logFile = "system_analysis_log.txt"
$hostName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "dd-MM-yy-HH-mm-ss"

function Write-Log {
    param($Message)
    $logTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$logTimestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Output $Message
}

function Get-CsvFileName {
    param($Type)
    return "$hostName-$Type-$timestamp.csv"
}

# start logging
Write-Log "=== Enhanced System Analysis Script Started ==="
Write-Log "Host Name: $hostName"
Write-Log "Timestamp: $timestamp"

try {
    Write-Log "Getting total memory size..."
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $totalMemoryGB = [Math]::Round($memoryInfo.Sum / 1GB, 2)
    Write-Log "Total Memory: $totalMemoryGB GB"

    Write-Log "Getting all installed software..."
    $installedSoftware = Get-CimInstance -ClassName Win32_Product | Select-Object Name, Version, Vendor, InstallDate
    Write-Log "Found $($installedSoftware.Count) installed software packages"

    Write-Log "Gathering network information..."
    
    $ipAddresses = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -ne "WellKnown" }
    
    $dnsServers = Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 }
    
    $netRoutes = Get-NetRoute | Where-Object { $_.AddressFamily -eq "IPv4" }
    
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

    Write-Log "Gathering additional system information..."
    
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
# SIG # Begin signature block
# MIIFnQYJKoZIhvcNAQcCoIIFjjCCBYoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQmyCT49h/UtXbT/KaU8eIkr/
# Re2gggMzMIIDLzCCAhegAwIBAgIQG0s8nYRyi79Pl/APrYg+JDANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUiDboxUC+
# 6TopV46dT5wnuIpD+HowDQYJKoZIhvcNAQEBBQAEggEAvZOXQgFNmWtYpwOTjFSM
# Eg0dvx02/wpT3N8q2pmOZz0MaIVERq2Z3FRuvyi3RSKVpGVL7bF6kW2tLr7Nq3rt
# ehMKjKFYRhHsjdev3OdSvkUaR2bCT+zp3yps5vxmJ27tZQY+D73NaY4morZiXWeM
# r8h4oIBPFuEugmj4moS0G2NypmBM3X02upOuq2cdX8LpMkYkEABQ/o63q09wwzTf
# B7DHUnAU6z3t1IH+6HTYVA+avC1j2+z8kp1MSjuWdQRi2gZZo8mS66SEKs20Tdzz
# BgQESAz8r6W6DNHlijxxdCvtZ0xAUl42W2woqPN5LCI2QoY0+oRAvXKuizhuQSlk
# PA==
# SIG # End signature block
