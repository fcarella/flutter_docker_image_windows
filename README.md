Of course. Here is a complete `README.md` file tailored for the Windows 11-hosted Flutter development environment.

It includes detailed instructions on prerequisites, usage, and Windows-specific troubleshooting for common issues like Android device detection and web server access.

---

# Flutter Development Environment with Docker on Windows 11

This project provides a fully containerized, reproducible development environment for building Flutter applications. It uses a **Fedora 42** Linux container to ensure a consistent toolchain and is integrated with **Visual Studio Code's Dev Containers** feature for a seamless "open and code" experience on a **Windows 11 host**.

The environment is built on best practices, including running as a **non-root user** for enhanced security and installing the complete toolchain for Android, Linux desktop, and web development, all from the comfort of your Windows machine.

## Features

-   **Consistent Environment:** Builds inside a Fedora 42 container, eliminating "works on my machine" issues.
-   **Flutter SDK:** Latest stable version, cloned directly from the official repository.
-   **Android Toolchain:** Java 21 OpenJDK and the latest Android SDK tools are pre-installed in the container.
-   **Web Development:** Google Chrome is included, and ports are forwarded for easy debugging from your Windows browser.
-   **Linux Desktop:** All dependencies are included to build the Linux version of your app from Windows.
-   **Secure by Default:** All tools and processes run under a dedicated, non-root `flutteruser`.
-   **VS Code Integration:** Fully configured for use with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

## Prerequisites

Before you begin, ensure you have the following installed on your **Windows 11 host machine**:

1.  [**Docker Desktop for Windows**](https://docs.docker.com/desktop/install/windows-install/): Make sure it is configured to use the **WSL 2 backend**, which is the default setting.
2.  [**Visual Studio Code**](https://code.visualstudio.com/).
3.  The **[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)** extension for VS Code.
4.  **(For Android Physical Devices)** The appropriate [OEM USB drivers](https://developer.android.com/studio/run/oem-usb) for your Android device installed on Windows.

## Project Structure

To use this setup, place the configuration files in the root of your Flutter project.

```
/your_flutter_project
|
|-- .devcontainer/
|   |-- devcontainer.json   # Configures VS Code Dev Containers
|
|-- docker-compose.yml      # Defines and orchestrates the Docker service
|
|-- Dockerfile              # The blueprint for building the Fedora image
|
|-- lib/
|-- pubspec.yaml
... (rest of your Flutter app files)
```

## How to Use

1.  **Open the Project in VS Code:**
    Open the root folder of your project in Visual Studio Code.

2.  **Reopen in Container:**
    VS Code will detect the `.devcontainer` folder and show a notification in the bottom-right corner: *"Folder contains a Dev Container configuration file. Reopen folder to develop in a container."*
    ![Reopen in Container Prompt](https://code.visualstudio.com/assets/docs/remote/containers/reopen-in-container.png)
    Click the **"Reopen in Container"** button.

3.  **First-Time Build:**
    The first time you open the container, Docker will build the image from the `Dockerfile`. This will take several minutes as it needs to download the Fedora base image, all system dependencies, Google Chrome, and the Flutter and Android SDKs. Subsequent launches will be much faster as the Docker image will be cached.

4.  **Start Developing:**
    Once the build is complete, VS Code will reload and connect to the container. Your workspace is now running entirely inside the isolated Fedora environment, but you can edit files and use the VS Code interface as you normally would on Windows.

## Running Your Application

1.  **Open the Integrated Terminal:**
    Use the shortcut (`Ctrl`+`\``) or the "Terminal" menu in VS Code to open a new terminal. The prompt should show you are the `flutteruser` inside the container (`flutteruser@...`).

2.  **Check for Available Devices:**
    Run `flutter devices` to see a list of available targets. You should see options for **Linux**, **Chrome**, and any connected **Android devices** or running emulators from your Windows host.

    ```bash
    $ flutter devices
    Found 3 connected devices:
    Linux (desktop) • linux  • linux-x64  • Fedora Linux 42 (Workstation Edition)
    Chrome (web)    • chrome • web-javascript • Google Chrome 123.0.6312.86
    sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 14 (API 34) (emulator)
    ```

3.  **Run the App:**
    You can now run the app on any of the available targets from the container's terminal.

    *   **To run on the web:**
        This command starts a web server on port 8080 inside the container, which is forwarded to your Windows host.
        ```bash
        flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
        ```
        After it builds, open a browser **on Windows** and navigate to **http://localhost:8080**.

    *   **To run on an Android device/emulator:**
        (Replace `emulator-5554` with your device ID from the `flutter devices` command).
        ```bash
        flutter run -d emulator-5554
        ```

    *   **To run as a Linux desktop app:**
        ```bash
        flutter run -d linux
        ```
        **Note:** Running a Linux GUI application requires an X11 server (like VcXsrv or GWSL) to be installed and configured on Windows. This is an advanced use case not covered here.

## Configuration Files Explained

#### `Dockerfile`

This is the master blueprint for the development environment. It starts from a Fedora 42 image and installs the Flutter SDK, Android SDK, Java, and all other necessary build tools inside a Linux environment. This file does not need to be changed for Windows, as its purpose is to create a consistent Linux build environment.

#### `docker-compose.yml`

This file is used by Docker Compose to manage the container's lifecycle.
-   It builds the image from the `Dockerfile`.
-   It mounts the current project directory into `/home/flutteruser/app` inside the container.
-   It uses `ports` mapping (e.g., `"8080:8080"`) to forward network traffic from the container to your Windows host, allowing you to access the web server.

#### `.devcontainer/devcontainer.json`

This is the configuration file for the VS Code Dev Containers extension. It tells VS Code how to connect to the container, which user to run as (`flutteruser`), and which extensions (`Dart`, `Flutter`) to install inside the container for a seamless coding experience.

## Troubleshooting on Windows

#### Android Device Not Detected

**Symptom:** Your connected Android phone or running emulator does not appear when you run `flutter devices` inside the container.

**Solutions:**

1.  **Check on Windows First:** Ensure the device is detectable on your host. Open a **PowerShell or Command Prompt window** (not in VS Code) and run `adb devices`.
    *   If it shows `unauthorized`, you must accept the "Allow USB debugging?" prompt on your device's screen.
    *   If it's not listed at all, check your USB cable, ensure USB Debugging is enabled in Developer Options, and verify that the correct Windows USB drivers are installed.

2.  **Restart ADB Server:** The connection between the host's ADB server and the container's can sometimes fail. Restarting it often fixes the issue.
    *   First, run `adb kill-server` in a terminal on your **Windows host**.
    *   Then, run `adb kill-server` in the **VS Code container terminal**.
    *   Finally, run `flutter devices` again in the container. This should re-establish the connection.

#### Container Build Fails or VS Code Cannot Connect

**Symptom:** The "Reopen in Container" process fails with a network or Docker error.

**Solutions:**

1.  **Check Docker Desktop:** Make sure Docker Desktop is running on Windows and that its status is "running".
2.  **Network Issues:** The build process downloads a lot of software. A failure in `dnf install` or `git clone` usually points to a network problem. Check your internet connection and proxy settings if you are on a corporate network.
3.  **Rebuild Container:** Docker may be using a corrupted cache. In VS Code, open the Command Palette (`Ctrl`+`Shift`+`P`) and run **"Remote-Containers: Rebuild and Reopen Container"**. This will force a fresh build from scratch.