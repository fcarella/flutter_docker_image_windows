#!/bin/bash

# This script creates the directory structure and configuration files for a
# Flutter development environment using Docker and VS Code on a Windows 11 host.

# --- Create .devcontainer Directory ---
echo "Creating .devcontainer directory..."
mkdir -p .devcontainer

# --- Create .devcontainer/devcontainer.json ---
echo "Creating .devcontainer/devcontainer.json..."
cat > .devcontainer/devcontainer.json <<'EOF'
{
	"name": "Flutter Windows Dev",

	// Point to the new, platform-agnostic docker-compose file.
	"dockerComposeFile": "../docker-compose.yml",

	// The service within the compose file VS Code should use.
	"service": "flutter-dev",

	// The folder where your project will be mounted and opened.
	"workspaceFolder": "/home/flutteruser/app",

	// IMPORTANT: Connect as the non-root user created in the Dockerfile.
	"remoteUser": "flutteruser",

	// VS Code specific settings and extensions for the container.
	"customizations": {
		"vscode": {
			"extensions": [
				"Dart-Code.flutter",
				"Dart-Code.dart-code"
			]
		}
	}
}
EOF

# --- Create Dockerfile ---
echo "Creating Dockerfile..."
cat > Dockerfile <<'EOF'
# Use the official Fedora 42 base image
FROM fedora:42

# --- Root-level Setup ---
# Install sudo and all other system-wide dependencies as root.
RUN dnf install -y \
    bash \
    bzip2 \
    ca-certificates \
    clang \
    cmake \
    curl \
    file \
    git \
    gtk3-devel \
    java-21-openjdk-devel \
    mesa-libGLU \
    ninja-build \
    pkg-config \
    sudo \
    unzip \
    which \
    xz \
    zip \
    && dnf clean all

# --- Non-Root User Setup (Best Practice) ---
# Create a dedicated user and give it passwordless sudo privileges.
# This allows the user to install tools (like Chrome) without halting the build.
RUN useradd -ms /bin/bash flutteruser && \
    echo "flutteruser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the non-root user for all subsequent operations.
USER flutteruser
WORKDIR /home/flutteruser

# --- Flutter SDK ---
# Clone the Flutter SDK as the non-root user.
RUN git clone https://github.com/flutter/flutter.git -b stable /home/flutteruser/flutter
ENV PATH="/home/flutteruser/flutter/bin:${PATH}"

# --- Android SDK ---
# Download and install Android command-line tools.
RUN mkdir -p /home/flutteruser/android/cmdline-tools && \
    curl -o android_sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip -q android_sdk.zip -d /home/flutteruser/android/cmdline-tools && \
    mv /home/flutteruser/android/cmdline-tools/cmdline-tools /home/flutteruser/android/cmdline-tools/latest && \
    rm android_sdk.zip

# Set Android environment variables.
ENV ANDROID_SDK_ROOT="/home/flutteruser/android"
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# Accept licenses and install required SDK components.
# Redirecting output to /dev/null keeps the build logs cleaner.
RUN yes | sdkmanager --licenses > /dev/null && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null

# --- Google Chrome ---
# As 'flutteruser', use sudo to download and install Google Chrome.
RUN curl -fSLo google-chrome.rpm "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" && \
    sudo dnf install -y ./google-chrome.rpm && \
    rm google-chrome.rpm && \
    sudo dnf clean all

# --- Final Verification ---
# Pre-download Flutter artifacts and run flutter doctor to verify the setup.
RUN flutter precache && \
    flutter doctor -v

# Set the final working directory for projects.
WORKDIR /home/flutteruser/app

# The default command to keep the container alive for VS Code to attach.
CMD ["/bin/bash"]
EOF

# --- Create docker-compose.yml ---
echo "Creating docker-compose.yml..."
cat > docker-compose.yml <<'EOF'
services:
  flutter-dev:
    # Build the image from the Dockerfile in the project's root.
    build:
      context: .
    
    # Mount the project folder into the app directory in the container.
    volumes:
      - .:/home/flutteruser/app:cached

    # Forward specific ports from the container to the Windows host.
    # This replaces the Linux-only 'network_mode: host'.
    ports:
      # Forward a common port for Flutter web development.
      # You can access your web app at http://localhost:8080 on Windows.
      - "8080:8080"
    
    # Keep the container running in the background.
    command: sleep infinity
EOF

echo ""
echo "✅ All files and folders have been created successfully!"
echo ""
echo "Next steps:"
echo "1. Place this project structure in your Flutter application's root directory."
echo "2. Open the folder in VS Code."
echo "3. Click 'Reopen in Container' when prompted."

