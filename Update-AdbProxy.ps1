# Update-AdbProxy.ps1 (Version 3 - Final)

Write-Host "Searching for the Docker/WSL virtual network adapter..." -ForegroundColor Cyan

# Find any vEthernet adapter with "WSL" in its name. This is more reliable.
# Ensure the result is always treated as an array to safely check its count.
$wslAdapters = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like 'vEthernet (WSL*)' })

# Check if we found exactly one adapter.
if ($wslAdapters.Count -ne 1) {
    Write-Host "ERROR: Found $($wslAdapters.Count) network adapters matching 'vEthernet (WSL*)'." -ForegroundColor Red
    Write-Host "Please run 'Get-NetIPAddress -AddressFamily IPv4' and manually identify the correct one."
    # If you know the correct one, you can hardcode it here, for example:
    # $wslIp = "172.17.80.1"
    # In your case, it seems the script should work, but this is a safeguard.
    exit
}

$wslIp = $wslAdapters[0].IPAddress
Write-Host "Found Docker Host IP: $wslIp on adapter '$($wslAdapters[0].InterfaceAlias)'" -ForegroundColor Green

# --- The rest of the script is the same ---

$portsToForward = @(5554, 5555)

foreach ($port in $portsToForward) {
    Write-Host "Configuring port proxy for port $port..." -ForegroundColor Cyan
    # Remove any old rule on any old IP to prevent conflicts.
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=* | Out-Null
    # Add the new, correct rule.
    $result = netsh interface portproxy add v4tov4 listenport=$port listenaddress=$wslIp connectport=$port connectaddress=127.0.0.1
    Write-Host "  $result"
}

Write-Host "`nConfiguration complete. You may now start your emulator and the VS Code container." -ForegroundColor Green
Write-Host "Make sure your devcontainer.json uses 'host.docker.internal'." -ForegroundColor Yellow