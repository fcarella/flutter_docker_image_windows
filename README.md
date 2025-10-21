# Flutter Dev Container Template for Windows 11

This repository is a starter template for bootstrapping a new Flutter project with a fully containerized, reproducible development environment. It uses a **Fedora 42** Linux container and is integrated with **Visual Studio Code's Dev Containers** feature for a seamless "clone and code" experience on a **Windows 11 host**.

The environment handles all the complex networking required for emulator access and hot reload, allowing you to go from `git clone` to a running Flutter app in minutes.

## Features

-   **Consistent Environment:** Builds inside a Fedora 42 container, eliminating "works on my machine" issues.
-   **Flutter SDK:** Latest stable version, ready to create and run projects.
-   **Android Toolchain:** Java 21 OpenJDK and the latest Android SDK tools are pre-installed.
-   **Seamless Emulator Integration:** Pre-configured to connect to Android Emulators running on the Windows host.
-   **Working Hot Reload:** Configured to use VS Code's debugger for a reliable hot reload experience.
-   **Git-Ready Workflow:** Includes instructions for detaching from this template and starting your own project history.

## Prerequisites

Before you begin, ensure you have the following installed on your **Windows 11 host machine**:

1.  [**Docker Desktop for Windows**](https://docs.docker.com/desktop/install/windows-install/): Must be configured to use the **WSL 2 backend**.
2.  [**Visual Studio Code**](https://code.visualstudio.com/).
3.  The **[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)** extension for VS Code.
4.  An Android Emulator installed via **Android Studio** and the latest **Android SDK Platform-Tools**.
5.  **Administrator access** to PowerShell for a one-time network setup.

## How to Use This Template

This guide walks you through cloning this template, creating your own app, and preparing it for your own Git repository.

#### Step 1: Clone This Template

Clone this repository to your local machine. You will rename this folder to match your project's name later.```bash
git clone <URL_of_this_repository>
```

#### Step 2: Perform the One-Time Network Setup

Before your first launch, you must configure Windows networking to allow the container to communicate with your Android emulator. Follow the detailed guide in the **Troubleshooting** section below: **"Emulator or Physical Device Not Detected in Container"**. This is a mandatory, one-time setup on your machine.

#### Step 3: Open in VS Code and Build the Container

1.  Open the cloned folder in Visual Studio Code.
2.  VS Code will show a notification: *"Folder contains a Dev Container configuration file. Reopen folder to develop in a container."* Click the **"Reopen in Container"** button.
3.  The first time you do this, Docker will build the Fedora image. This will take several minutes.

#### Step 4: Create Your Flutter Application

1.  Once the container is running, open the integrated terminal (`Ctrl`+`\``). You will be in the `/home/flutteruser/app` directory.
2.  Run the following command to create a new Flutter project inside the `app` folder:
    ```bash
    flutter create .
    ```
3.  Your `app` folder is now populated with your new Flutter project.

#### Step 5: Run and Develop Your App

1.  Start your Android Emulator on Windows.
2.  In VS Code, open the **"Run and Debug"** panel (Ctrl+Shift+D).
3.  Press the **green play button (F5)** to launch your app.
4.  After the initial build, you can edit your Dart code. **Saving a file will automatically trigger hot reload.**

#### Step 6: Prepare Your Project for a New Git Repository

Once you are ready to treat this as your own project, you need to detach it from this template's Git history.

1.  **Close VS Code.**
2.  **Rename the root project folder** from `flutter-dev-template` (or similar) to your own project's name (e.g., `my-awesome-app`).
3.  Open a terminal (like PowerShell or Git Bash) and navigate into your newly renamed folder.
4.  **Delete the template's Git history** and initialize your own:
    ```bash
    # For Git Bash, macOS, or Linux
    rm -rf .git

    # For Windows Command Prompt / PowerShell
    rd /s /q .git
    ```
5.  **Create your new repository:**
    ```bash
    git init
    git add .
    git commit -m "Initial commit"
    ```
6.  You can now add a new remote and push it to your own GitHub, GitLab, or other service:
    ```bash
    git remote add origin <URL_of_your_new_empty_repo>
    git push -u origin main
    ```

---

## Troubleshooting

#### Emulator or Physical Device Not Detected in Container

**Symptom:** `flutter devices` shows "Connection refused", "No route to host", or the emulator is not in the list.
**Cause:** Network isolation between Docker and Windows.
**Solution:**

**1. Find Your Host's WSL IP Address:**
   - Open **PowerShell** on your Windows host.
   - Run `Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress`.
   - Find the interface named `vEthernet (Default Switch)` and note its IP address (e.g., `172.30.208.1`).

**2. Create Windows Port Forwarding Rules:**
   - Open **PowerShell as an Administrator**.
   - Run these two commands, replacing `YOUR_HOST_IP` with the IP you found above.
     ```powershell
     netsh interface portproxy add v4tov4 listenport=5555 listenaddress=YOUR_HOST_IP connectport=5555 connectaddress=127.0.0.1
     netsh interface portproxy add v4tov4 listenport=5554 listenaddress=YOUR_HOST_IP connectport=5554 connectaddress=127.0.0.1
     ```

**3. Update `devcontainer.json`:**
   - Edit `.devcontainer/devcontainer.json` to include the `containerEnv` and `postStartCommand` sections, pasting your host IP where indicated.
     ```json
     {
     	"name": "Flutter Windows Dev",
     	"dockerComposeFile": "../docker-compose.yml",
        // ... (rest of the file) ...
     	"containerEnv": {
     		"ADB_SERVER_HOST": "YOUR_HOST_IP"
     	},
     	"postStartCommand": "adb connect YOUR_HOST_IP:5555"
        // ... (rest of the file) ...
     }
     ```

**4. Rebuild the Container:**
   - In VS Code, open the Command Palette (`Ctrl`+`Shift`+`P`) and run **"Remote-Containers: Rebuild and Reopen Container"**.

#### Hot Reload Does Not Work in Terminal

**Symptom:** You run `flutter run` in the terminal and saving a file does not trigger hot reload.
**Cause:** File-saving events on Windows are not properly communicated to the Linux container.
**Solution:** Always launch your app using the VS Code debugger (**F5**). The VS Code Dart extension correctly sends the reload command, bypassing the faulty file-watching mechanism.

#### Build Fails with Dart Errors (e.g., 'Vector3' not found)

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