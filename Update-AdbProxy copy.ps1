# Update-AdbProxy.ps1

Write-Host "Finding the IP address for the Docker WSL network adapter..." -ForegroundColor Cyan

# Find the active IP address for the virtual switch Docker uses.
$wslIp = (Get-NetIPAddress -InterfaceAlias 'vEthernet (Default Switch)' -AddressFamily IPv4).IPAddress

if (-not $wslIp) {
    Write-Host "ERROR: Could not find IP for 'vEthernet (Default Switch)'. Please check your Hyper-V network adapter names." -ForegroundColor Red
    exit
}

Write-Host "Found Docker Host IP: $wslIp" -ForegroundColor Green

# Define the ports the emulator uses
$portsToForward = @(5554, 5555)

foreach ($port in $portsToForward) {
    Write-Host "Configuring port proxy for port $port..." -ForegroundColor Cyan

    # First, try to remove any existing rule for this port to prevent errors.
    # We ignore errors here because the rule might not exist.
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$wslIp | Out-Null

    # Now, add the new, correct rule.
    $result = netsh interface portproxy add v4tov4 listenport=$port listenaddress=$wslIp connectport=$port connectaddress=127.0.0.1
    Write-Host "  $result"
}

Write-Host "`nConfiguration complete. You may now start your emulator and the VS Code container." -ForegroundColor Green
Write-Host "Make sure your devcontainer.json uses 'host.docker.internal'." -ForegroundColor Yellow
