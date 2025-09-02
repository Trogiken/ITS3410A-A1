# Start
Write-Host "Script Start Date and Time: $(Get-Date)"

# Hostname
Write-Host "System Hostname: $(hostname)"

# IP
Write-Host "System IP Addresses:"
Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -notlike '169.*' } | Select-Object -ExpandProperty IPAddress

# DNS
Write-Host "System DNS Servers:"
Get-DnsClientServerAddress | ForEach-Object { $_.ServerAddresses }

# Gateway
Write-Host "System Default Gateway:"
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object -ExpandProperty NextHop

# Memory
Write-Host "Available Physical Memory (MB):"
(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024

# PATH
Write-Host "PATH Environment Variable:"
$env:PATH

# Drivers
Write-Host "Installed Drivers:"
Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, Manufacturer

# Tasks
Write-Host "Current Running Tasks:"
Get-Process | Select-Object Name, Id, CPU | Format-Table | Out-String | Write-Host

# TCP/IP
Write-Host "TCP/IP Network Connections and Listening Ports:"
Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State | Format-Table | Out-String | Write-Host

# End
Write-Host "Script End Date and Time: $(Get-Date)"