# Flutter Dev Container Template for Windows 11

This repository is a starter template for bootstrapping a new Flutter project with a fully containerized, reproducible development environment. It uses a **Fedora 42** Linux container and is integrated with **Visual Studio Code's Dev Containers** for a seamless "clone and code" experience on a **Windows 11 host**.

The environment handles all the complex networking required for emulator access and hot reload, allowing you to go from `git clone` to a running Flutter app in minutes.

## Features

-   **Consistent Environment:** Builds inside a Fedora 42 container, eliminating "works on my machine" issues.
-   **Flutter SDK:** Latest stable version, ready to create and run projects.
-   **Android Toolchain:** Java 21 OpenJDK and the latest Android SDK tools are pre-installed.
-   **Automated Emulator Networking:** Includes a script to handle dynamic IP addresses after reboots.
-   **Working Hot Reload:** Configured to use VS Code's debugger for a reliable hot reload experience.
-   **Git-Ready Workflow:** Includes instructions for detaching from this template and starting your own project history.

## Prerequisites

Before you begin, ensure you have the following installed on your **Windows 11 host machine**:

1.  [**Docker Desktop for Windows**](https://docs.docker.com/desktop/install/windows-install/): Must be configured to use the **WSL 2 backend**.
2.  [**Visual Studio Code**](https://code.visualstudio.com/).
3.  The **[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)** extension for VS Code.
4.  An Android Emulator installed via **Android Studio** and the latest **Android SDK Platform-Tools**.
5.  **Administrator access** to PowerShell for the one-time network setup.

## How to Use This Template

This guide walks you through cloning this template, creating your own app, and preparing it for your own Git repository.

#### Step 1: Clone This Template

Clone this repository to your local machine. You will rename this folder to match your project's name later.
```bash
git clone <URL_of_this_repository>
```

#### Step 2: Perform the One-Time Network Setup

Your computer's WSL IP address can change after a reboot. The included script automatically configures Windows networking to handle this. You must run it once before your first use and once after every reboot.

Follow the detailed guide in the **Troubleshooting** section below: **"Emulator Not Detected (Dynamic IP Address Fix)"**. This is a mandatory step.

#### Step 3: Open in VS Code and Build the Container

1.  Open the cloned folder in Visual Studio Code.
2.  VS Code will show a notification: *"Folder contains a Dev Container configuration file. Reopen folder to develop in a container."* Click the **"Reopen in Container"** button.
3.  The first time you do this, Docker will build the Fedora image. This will take several minutes.

#### Step 4: Create Your Flutter Application

1.  Once the container is running, open the integrated terminal (`Ctrl`+`\`). You will be in the `/home/flutteruser/app` directory.
2.  Run the following command to create a new Flutter project inside the `app` folder:
    ```bash
    flutter create .
    ```
3.  The `app` folder on your Windows machine will now be populated with the new Flutter project files.

#### Step 5: Run and Develop Your App

1.  Start your Android Emulator on Windows.
2.  In VS Code, open the **"Run and Debug"** panel (Ctrl+Shift+D).
3.  Press the **green play button (F5)** to launch your app.
4.  After the initial build, you can edit your Dart code. **Saving a file will automatically trigger hot reload.**

#### Step 6: Prepare Your Project for a New Git Repository

Once you are ready to treat this as your own project, detach it from this template's Git history.

1.  **Close VS Code.**
2.  **Rename the root project folder** to your own project's name (e.g., `my-awesome-app`).
3.  Open a terminal (like PowerShell or Git Bash) and navigate into your newly renamed folder.
4.  **Delete the template's Git history** and initialize your own:
    ```bash
    # For Windows Command Prompt / PowerShell
    rd /s /q .git

    # For Git Bash on Windows
    # rm -rf .git
    ```
5.  **Create your new repository:**
    ```bash
    git init
    git add .
    git commit -m "Initial commit"
    ```
6.  You can now add a remote and push it to your own GitHub or other service.

---

## Daily Workflow After a Reboot

Because the WSL IP address is dynamic, you must run the network setup script **once** after every time you restart your computer.

1.  **Run the Automation Script:** Right-click the `Update-AdbProxy.ps1` script in your project folder and select **"Run with PowerShell"**. This will re-configure the network proxy rules.
2.  **Start ADB Server:** Open a regular PowerShell terminal and run `adb start-server`.
3.  You can now start your emulator and open the dev container as usual.

## Troubleshooting

### Emulator Not Detected (Dynamic IP Address Fix)

**Symptom:** The `postStartCommand` fails with "No route to host" or "Connection refused".
**Cause:** The WSL virtual network IP address changes on reboot, breaking the port forwarding rules.
**Solution:** This template includes a PowerShell script to automatically find the correct IP and configure the network. You must run it once before first use and once after every reboot.

**Step 1: Create the `Update-AdbProxy.ps1` Script**
Create a file named `Update-AdbProxy.ps1` in your root project folder with the following content:
```powershell
# Update-AdbProxy.ps1

Write-Host "Finding the IP address for the Docker WSL network adapter..." -ForegroundColor Cyan
$wslIp = (Get-NetIPAddress -InterfaceAlias 'vEthernet (Default Switch)' -AddressFamily IPv4).IPAddress

if (-not $wslIp) {
    Write-Host "ERROR: Could not find IP for 'vEthernet (Default Switch)'. Please check adapter names with 'Get-NetIPAddress'." -ForegroundColor Red
    exit
}

Write-Host "Found Docker Host IP: $wslIp" -ForegroundColor Green
$portsToForward = @(5554, 5555)

foreach ($port in $portsToForward) {
    Write-Host "Configuring port proxy for port $port..." -ForegroundColor Cyan
    # Remove any old rule for this port on any old IP to prevent conflicts. This is a robust way to clean up.
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=* | Out-Null
    # Add the new, correct rule.
    $result = netsh interface portproxy add v4tov4 listenport=$port listenaddress=$wslIp connectport=$port connectaddress=127.0.0.1
    Write-Host "  $result"
}

Write-Host "`nConfiguration complete." -ForegroundColor Green
```

**Step 2: Run the Script for the First Time**
1.  Open **PowerShell as an Administrator**.
2.  Temporarily bypass the execution policy for this single session by running:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    ```
3.  Navigate to your project folder and run the script:
    ```powershell
    cd path\to\your\project
    .\Update-AdbProxy.ps1
    ```
4.  The script will find the correct IP and set up the necessary port forwarding. You can now close the admin PowerShell window.

**Step 3: Verify `devcontainer.json` is Dynamic**
Ensure your `.devcontainer/devcontainer.json` uses `host.docker.internal`. This allows it to work automatically with the IP found by the script.

```json
{
	// ...
	"containerEnv": {
		"ADB_SERVER_HOST": "host.docker.internal"
	},
	"postStartCommand": "adb connect host.docker.internal:5555",
	// ...
}
```

### Build Fails with Dart Errors (e.g., 'Vector3' not found)

**Symptom:** `flutter run` fails with errors from within the Flutter SDK's own files.
**Cause:** The Flutter SDK or the project build cache inside the container is corrupted.
**Solution:** Run a full clean-and-reset sequence **inside the container's terminal**:
```bash
flutter channel stable
flutter upgrade
flutter precache --force
flutter clean
flutter pub get
```