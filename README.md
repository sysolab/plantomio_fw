# WaterBee Firmware and Application

A comprehensive toolset for the WaterBee ESP32C6-based irrigation and plant monitoring system. This repository provides tools to flash firmware to WaterBee devices, download Android applications, and manage releases.

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
  - [Cloning the Repository](#cloning-the-repository)
  - [Setting Up](#setting-up)
- [Firmware Installation](#firmware-installation)
  - [Downloading Firmware](#downloading-firmware)
  - [Flashing Instructions](#flashing-instructions)
  - [Monitoring](#monitoring)
- [Android Application](#android-application)
  - [Downloading the APK](#downloading-the-apk)
  - [Installation](#installation)
- [For Contributors](#for-contributors)
  - [Auto-Release Script](#auto-release-script)
  - [Creating New Releases](#creating-new-releases)
- [Troubleshooting](#troubleshooting)
- [Technical Details](#technical-details)
- [License](#license)
- [Version History](#version-history)

## Overview

The WaterBee system consists of two main components:

1. **ESP32C6 Firmware** - Runs on the WaterBee hardware device, controlling sensors and irrigation systems
2. **Android Application** - Allows users to control and monitor their WaterBee devices

This repository provides the tools to install and manage both components.

## Getting Started

### Cloning the Repository

Clone this repository to your local machine:

```bash
git clone https://github.com/sysolab/plantomio_fw.git
cd plantomio_fw
```

### Setting Up

Run the setup script to create a virtual environment and install all dependencies:

```bash
source ./setup.sh
```

> **Note**: Using `source` is important as it activates the environment in your current shell.

## Firmware Installation

### Downloading Firmware

The firmware flash script will automatically download and extract the latest firmware from GitHub releases when needed. You don't need to download firmware files manually.

### Flashing Instructions

The flashing script provides an interactive way to flash your WaterBee device:

```bash
./flash_waterbee.sh
```

This will:
1. Automatically download the latest firmware release from GitHub if needed
2. Ask if you want to flash a debug or release firmware
3. Show available firmware versions
4. Detect available serial ports
5. Flash the selected firmware to the selected port

#### Alternative Flashing Methods

```bash
# Flash latest *release* firmware
./flash_waterbee.sh release

# Flash latest *debug* firmware
./flash_waterbee.sh debug

# Flash a specific firmware and specify the port
./flash_waterbee.sh firmware/release/waterBee_1.0.103_release_merged /dev/ttyUSB0
```

### Monitoring

After flashing, you can monitor the device's serial output:

```bash
python -m esptool --chip esp32c6 -p <PORT> monitor
```

Replace `<PORT>` with your device's port (the same one used for flashing).

## Android Application

### Downloading the APK

Android APK files are available as GitHub releases. The easiest way to download them is using the provided script:

```bash
# Make the script executable
chmod +x get_android_app.sh

# Run the script
./get_android_app.sh
```

This script will:
1. Automatically fetch the latest Android app release from GitHub
2. Download all available APK variants
3. Create an `android_app` directory with the APK files
4. Provide information about each APK variant and installation instructions

Alternatively, you can manually download APK files from the [GitHub releases page](https://github.com/sysolab/plantomio_fw/releases).

### Installation

1. Transfer the APK file to your Android device
2. On your Android device, navigate to the APK file and tap to install
3. You may need to enable "Install from Unknown Sources" in your Android settings

Choose the appropriate APK variant for your device:
- **arm64-v8a** - For modern Android devices (64-bit ARM)
- **armeabi-v7a** - For older Android devices (32-bit ARM)
- **universal** - Works on any Android device (larger file size)
- **debug** - For development and testing (includes logging)

## For Contributors

### Auto-Release Script

The `auto_release.sh` script automates the process of creating and publishing releases:

```bash
# Install dependencies (one-time setup)
brew install jq
brew install gh  # Optional but recommended

# If using GitHub CLI
gh auth login

# If using API method instead
export GITHUB_TOKEN=your_personal_access_token

# Run the script
./auto_release.sh
```

The script will:
- Detect version numbers from firmware and APK files
- Create appropriate tags
- Generate release notes
- Upload files to GitHub releases

### Creating New Releases

1. Place new firmware files in:
   - `firmware/debug/waterBee_VERSION_debug_merged/`
   - `firmware/release/waterBee_VERSION_release_merged/`

2. Place new APK files in:
   - `android_app/`

3. Run the auto-release script:
   ```bash
   ./auto_release.sh
   ```

## Troubleshooting

### No Serial Ports Detected

- Ensure your device is connected properly
- Check that the USB cable is functional
- Try a different USB port
- Install appropriate USB-serial drivers if needed

### Flashing Errors

- Make sure you have proper permissions to access the serial port
  - On Linux: `sudo usermod -a -G dialout $USER` (then log out and back in)
  - On macOS: Check for Security & Privacy permissions for Terminal
- Try a lower baud rate by editing the `BAUD` value in the script
- Make sure the device is in bootloader mode (hold BOOT button while resetting)

### Virtual Environment Issues

- If you encounter issues with the virtual environment, try:
  ```bash
  rm -rf .waterBeeFW
  ./setup.sh
  ```

### Download Issues

- If you're having trouble downloading firmware or APK files:
  1. Check your internet connection
  2. Verify that the GitHub releases exist
  3. If GitHub API rate limits are exceeded, wait and try again later
  4. You can manually download files from the [releases page](https://github.com/sysolab/plantomio_fw/releases)

## Technical Details

- Uses esptool.py for ESP32 firmware flashing
- Target chip: ESP32C6
- Default baud rate: 460800
- Flashing process includes both partition table and application binary
- Both scripts use GitHub API to fetch the latest releases automatically

## License

See LICENSE file for details.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes. 