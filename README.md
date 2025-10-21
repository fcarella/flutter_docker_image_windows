# Flutter Development Environment with Docker on Windows 11

This project provides a complete, containerized setup for starting a new Flutter project from scratch. It uses a **Fedora 42** Linux container to ensure a consistent toolchain and is integrated with **Visual Studio Code's Dev Containers** for a seamless "open and code" experience on a **Windows 11 host**.

The environment handles all the complex networking required for emulator access and hot reload, allowing you to focus on building your app.

## Features

-   **Consistent Environment:** Builds inside a Fedora 42 container, eliminating "works on my machine" issues.
-   **Flutter SDK:** Latest stable version, ready to create and run projects.
-   **Android Toolchain:** Java 21 OpenJDK and the latest Android SDK tools are pre-installed.
-   **Seamless Emulator Integration:** Pre-configured to connect to Android Emulators running on the Windows host.
-   **Working Hot Reload:** Configured to use VS Code's debugger for a reliable hot reload experience.
-   **Secure by Default:** All tools and processes run under a dedicated, non-root `flutteruser`.
-   **VS Code Integration:** Fully configured for use with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

## Prerequisites

Before you begin, ensure you have the following installed on your **Windows 11 host machine**:

1.  [**Docker Desktop for Windows**](https://docs.docker.com/desktop/install/windows-install/): Must be configured to use the **WSL 2 backend**.
2.  [**Visual Studio Code**](https://code.visualstudio.com/).
3.  The **[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)** extension for VS Code.
4.  An Android Emulator installed via **Android Studio** and the latest **Android SDK Platform-Tools**.
5.  **Administrator access** to PowerShell for a one-time network setup.

## Getting Started: Creating a New Project

This guide will walk you through setting up the folder structure and creating a new Flutter application named `app`.

#### 1. Create the Project Structure

First, create the following folder and file structure. The `Dockerfile`, `docker-compose.yml`, and `.devcontainer` folder will live alongside your Flutter project folder (`app`).

```
/your_project_workspace
|
|-- .devcontainer/
|   |-- devcontainer.json   # Configures VS Code
|
|-- app/                    # Create this folder, but leave it EMPTY.
|
|-- docker-compose.yml      # Defines the Docker service
|
|-- Dockerfile              # The blueprint for the Fedora image
|
|-- README.md               # This file
```

#### 2. Perform the One-Time Network Setup

Before the first launch, you must configure Windows networking to allow the container to communicate with your Android emulator. Follow the detailed guide in the **Troubleshooting** section below: **"Emulator or Physical Device Not Detected in Container"**. This is a mandatory step.

#### 3. Open the Workspace and Build the Container

1.  Open the root folder (`your_project_workspace`) in Visual Studio Code.
2.  VS Code will show a notification: *"Folder contains a Dev Container configuration file. Reopen folder to develop in a container."* Click the **"Reopen in Container"** button.
3.  The first time you do this, Docker will build the image. This will take several minutes.

#### 4. Create the Flutter Application

1.  Once the container is running, VS Code will reload. Open the integrated terminal (`Ctrl`+`\``).
2.  The terminal prompt will be in the `/home/flutteruser/app` directory, which is currently empty.
3.  Run the following command to create a new Flutter project in the current directory:
    ```bash
    flutter create .
    ```
4.  The `app` folder on your Windows machine will now be populated with the new Flutter project files.

#### 5. Run Your Application

For the best experience with **Hot Reload**, always launch your application using the VS Code debugger.

1.  Start your Android Emulator on Windows.
2.  In VS Code, open the **"Run and Debug"** panel (Ctrl+Shift+D).
3.  Press the **green play button (F5)** to start your app.
4.  VS Code will build the app and install it on your emulator. You can now edit your Dart code, and saving a file will automatically trigger hot reload.

---

## Troubleshooting

Here are solutions to the most common issues encountered during setup.

### Emulator or Physical Device Not Detected in Container

This is the most complex issue, caused by network isolation between Docker and Windows. Follow these steps exactly to fix it permanently.

**Symptom:** `flutter devices` shows "Connection refused", "No route to host", or the emulator is simply not in the list.

**Cause:** The container cannot see the ADB server or the emulator ports on your host's `localhost`. We must manually forward the network traffic.

**Solution:**

**Step 1: Find Your Host's WSL IP Address**
1.  Open **PowerShell** on your Windows host.
2.  Run `Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress`.
3.  Look for the interface named `vEthernet (Default Switch)` or similar. Note its IP address (e.g., `172.30.208.1`). This is your Host IP.

**Step 2: Create Windows Port Forwarding Rules**
1.  Open **PowerShell as an Administrator**.
2.  Run the following two commands, replacing `YOUR_HOST_IP` with the IP address you found in Step 1.
    ```powershell
    # Forward the ADB service port (5555)
    netsh interface portproxy add v4tov4 listenport=5555 listenaddress=YOUR_HOST_IP connectport=5555 connectaddress=127.0.0.1

    # Forward the emulator device port (5554)
    netsh interface portproxy add v4tov4 listenport=5554 listenaddress=YOUR_HOST_IP connectport=5554 connectaddress=127.0.0.1
    ```
    These rules are permanent and survive reboots.

**Step 3: Update `devcontainer.json`**
Edit your `.devcontainer/devcontainer.json` file to tell the container how to find and connect to the emulator.
```json
{
	"name": "Flutter Windows Dev",
	"dockerComposeFile": "../docker-compose.yml",
	"service": "flutter-dev",
	"workspaceFolder": "/home/flutteruser/app",
	"remoteUser": "flutteruser",

	// Use the specific IP of your WSL adapter
	"containerEnv": {
		"ADB_SERVER_HOST": "YOUR_HOST_IP" // <-- PASTE THE IP ADDRESS HERE
	},

	// Automate the direct connection to the emulator
	"postStartCommand": "adb connect YOUR_HOST_IP:5555",

	"customizations": {
		"vscode": {
			"extensions": [
				"Dart-Code.flutter",
				"Dart-Code.dart-code"
			]
		}
	}
}
```

**Step 4: Perform a Full Rebuild**
In VS Code, open the Command Palette (`Ctrl`+`Shift`+`P`) and run **"Remote-Containers: Rebuild and Reopen Container"** to apply all changes.

### Hot Reload Does Not Work Automatically on File Save

**Symptom:** You save a Dart file, but the app running in the emulator does not update.
**Cause:** The file-saving event on your Windows disk is not properly communicated to the Flutter process inside the Linux container.
**Solution:** Always launch your app using the VS Code debugger (**F5** or the "Run and Debug" panel). The Dart extension for VS Code bypasses the faulty file-watching mechanism and sends the hot reload command directly, which works reliably.

### Build Fails with Dart Errors (e.g., 'Vector3' or 'Matrix4' not found)

**Symptom:** `flutter run` fails with errors like `Method not found: 'Vector3'` coming from within the Flutter SDK's own files.
**Cause:** The Flutter SDK clone inside the container is likely corrupted, or your project's build cache is in a bad state.
**Solution:** Run a full clean-and-reset sequence **inside the container's terminal**:

```bash
# 1. Force a refresh of the Flutter SDK
flutter channel stable
flutter upgrade
flutter precache --force

# 2. Clean your project's build artifacts and dependencies
flutter clean
flutter pub get

# 3. Try building again
flutter run
```

---

## Configuration Files Explained

#### `Dockerfile`
This is the master blueprint for the development environment. It starts from a Fedora image and installs the Flutter SDK, Android SDK, Java, and all other necessary build tools inside a Linux environment.

#### `docker-compose.yml`
This file manages the container's lifecycle. It builds the image and, most importantly, **mounts your local `./app` folder into the `/home/flutteruser/app` directory inside the container**. It also forwards ports for web development and emulator communication.

```yml
services:
  flutter-dev:
    build:
      context: .
    # Mount the 'app' sub-directory into the container's workspace
    volumes:
      - ./app:/home/flutteruser/app:cached
    ports:
      - "8080:8080"
    command: sleep infinity
```

#### `.devcontainer/devcontainer.json`
This is the configuration file for the VS Code Dev Containers extension. It tells VS Code how to connect to the container, which user to run as (`flutteruser`), and which extensions (`Dart`, `Flutter`) to automatically install inside the container for a seamless coding experience.