## How to Use This Template

There are two ways to use this project depending on your goals:

### Option A: Starting a New App (Recommended)
If you want to use this environment to build your own Flutter application:
1. Click the **"Use this template"** button at the top of this GitHub page to create a fresh repository.
2. Clone **your new** repository to your Windows machine.
3. Follow the [One-Time Network Setup](#one-time-network-setup) below.
4. Open the folder in VS Code and click **"Reopen in Container"**.
5. In the container terminal, run `flutter create .` inside the `/app` folder.

### Option B: Contributing to this Setup
If you want to suggest improvements to the Docker image or scripts:
1. **Fork** this repository.
2. Clone your fork and make your changes.
3. Submit a **Pull Request**.

# Flutter Dev Container Template for Windows 11

This repository is a starter template for bootstrapping a new Flutter project from scratch. It uses a **Fedora 42** Linux container and is integrated with **Visual Studio Code's Dev Containers** for a seamless "clone and code" experience on a **Windows 11 host**.

The environment handles all the complex networking required for emulator access and hot reload, allowing you to go from `git clone` to a running Flutter app in minutes.

## Features

-   **Consistent Environment:** Builds inside a Fedora 42 container, eliminating "works on my machine" issues.
-   **Flutter SDK:** Latest stable version, ready to create and run projects.
-   **Android Toolchain:** Java 21 OpenJDK and the latest Android SDK tools are pre-installed.
-   **Automated Emulator Networking:** Includes a PowerShell script to handle dynamic WSL IP addresses after reboots.
-   **Working Hot Reload:** Configured to use VS Code's debugger for a reliable hot reload experience.
-   **Git-Ready Workflow:** Includes instructions for detaching from this template and starting your own project history.

## Prerequisites

Before you begin, ensure you have the following installed and configured on your **Windows 11 host machine**:

1.  [**Docker Desktop for Windows**](https://docs.docker.com/desktop/install/windows-install/): Must be configured to use the **WSL 2 backend**.
2.  [**Visual Studio Code**](https://code.visualstudio.com/).
3.  The **[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)** extension for VS Code.
4.  An Android Emulator installed via **Android Studio**.
5.  The **Android SDK Platform-Tools** added to your Windows `Path` environment variable, so you can run `adb` from any terminal.
6.  **Administrator access** to PowerShell.

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

1.  Once the container is running, open the integrated terminal (`Ctrl`+`\``). The terminal prompt will be in the `/home/flutteruser/app` directory, which corresponds to the `app` folder on your Windows machine.
2.  Run the following command to create the new Flutter project inside this directory (the `.` means "this current folder"):
    ```bash
    flutter create .
    ```
3.  Your `app` folder on Windows will now be populated with the new Flutter project files.

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
    ```powershell
    # For Windows Command Prompt / PowerShell
    rd /s /q .git
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

**Symptom:** The container fails to start with an error like "No route to host" or "Connection refused" in the `postStartCommand` log.
**Cause:** Network isolation between Docker and Windows, combined with dynamic IP addresses for the WSL network.
**Solution:** This template includes a PowerShell script to automatically find the correct host IP and configure Windows network port forwarding.

**Step 1: Create the `Update-AdbProxy.ps1` Script**
Create a file named `Update-AdbProxy.ps1` in your root project folder with the following content:
```powershell
# Update-AdbProxy.ps1 (Version 3 - Robust)

Write-Host "Searching for the Docker/WSL virtual network adapter..." -ForegroundColor Cyan

# Find any vEthernet adapter with "WSL" in its name.
# Ensure the result is always treated as an array to safely check its count.
$wslAdapters = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like 'vEthernet (WSL*)' })

if ($wslAdapters.Count -ne 1) {
    Write-Host "ERROR: Found $($wslAdapters.Count) network adapters matching 'vEthernet (WSL*)'." -ForegroundColor Red
    Write-Host "Please run 'Get-NetIPAddress -AddressFamily IPv4' and manually identify the correct one."
    exit
}

$wslIp = $wslAdapters.IPAddress
Write-Host "Found Docker Host IP: $wslIp on adapter '$($wslAdapters.InterfaceAlias)'" -ForegroundColor Green

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
Ensure your `.devcontainer/devcontainer.json` uses `host.docker.internal` for both the ADB server host and the connection command. This allows it to work automatically with the IP found by the script.
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

### Hot Reload Does Not Work in Terminal

**Symptom:** You run `flutter run` in the terminal and saving a file does not trigger hot reload.
**Cause:** File-saving events on Windows are not properly communicated to the Linux container.
**Solution:** Always launch your app using the VS Code debugger (**F5**). The VS Code Dart extension correctly sends the reload command.

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


***

## iOS Development for macOS Users

While this Fedora-based Docker environment provides a complete and reproducible setup for **Android, Web, and Linux Desktop**, it is important to note the limitations regarding **iOS development**.

### The Limitation
Apple’s build toolchain (**Xcode**) is proprietary and only runs on macOS. Because Docker containers share the host's Linux kernel, it is currently impossible to compile, sign, or simulate a native iOS application from *inside* this (or any) Linux-based Docker container.

### Recommended Workflow for Mac Users
If you are developing on a Mac, you should adopt a **hybrid approach**:

1.  **Logic & Cross-Platform Development:** Use the **Dev Container** as usual for writing Dart code, managing business logic, and testing on the Web or Android. This ensures your development environment remains consistent with the rest of the team.
2.  **Native iOS Builds:** When you need to run the app on an iOS Simulator or a physical iPhone:
    *   Ensure you have **Xcode**, **CocoaPods**, and the **Flutter SDK** installed natively on your host macOS machine.
    *   Open a terminal on your **host Mac** (not inside the VS Code Dev Container).
    *   Navigate to the project folder and run:
        ```bash
        flutter precache --ios
        cd app/ios && pod install
        cd .. && flutter run -d <ios_device_id>
        ```
    *   Alternatively, you can open the `app/ios/Runner.xcworkspace` file in **Xcode** on your Mac to manage certificates, signing, and App Store releases.

### For Windows and Linux Users
If you do not have access to a Mac, you can still develop the Flutter application using this container. However, to generate an iOS build (IPA), you will need to:
*   Use a **CI/CD Service** (such as GitHub Actions, Codemagic, or Bitrise) which provides Mac-based build agents.
*   The code you write inside this container is fully compatible; it simply requires a Mac-based environment to perform the final compilation and signing step.