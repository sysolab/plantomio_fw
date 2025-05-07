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
  - [Release Scripts](#release-scripts)
  - [Creating New Releases](#creating-new-releases)
- [Troubleshooting](#troubleshooting)
- [Technical Details](#technical-details)
- [License](#license)
- [Version History](#version-history)

## Overview

The WaterBee system consists of two main components:

1. **WaterBee Firmware** - Runs on the WaterBee hardware device, controlling sensors and irrigation systems
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



## LED Status Codes

The system uses an RGB LED to indicate various operational states and events. The following table documents all LED status patterns:

| Status Pattern | Visual Indication | Description | When It Occurs |
|----------------|-------------------|-------------|----------------|
| `led_status_ok` | Single green flash | Operation successful | After successful initialization, operation completion |
| `led_status_working` | Green fade effect | System is working normally | During normal processing tasks |
| `led_status_connecting` | Blue disco (pulsing) | Device is connecting | During WiFi or Bluetooth connection attempts |
| `led_status_connected` | Solid green | Connection established | When WiFi or BLE connection is established |
| `led_status_warning` | Yellow flash | Warning condition | Non-critical issues that require attention |
| `led_status_error` | Red flash | Error detected | When an operation fails or error occurs |
| `led_status_critical` | Fast red flashing | Critical error | Severe system problems that may require reset |
| `led_status_boot` | Blue breath | System booting | During system initialization at startup |
| `led_status_self_test` | White disco | Self-test in progress | During internal diagnostics |
| `led_status_data_sending` | Blue-green pulse | Transmitting data | When sending data to server/cloud |
| `led_status_sensor_error` | Red-yellow alternating | Sensor malfunction | When a sensor reading fails or gives invalid data |
| `led_status_low_battery` | Orange flash | Low battery warning | When battery level is below threshold |
| `led_status_factory_reset` | Rainbow effect | Factory reset in progress | During configuration reset to defaults |
| `led_status_ota_update` | Cyan pulse | Firmware update | During over-the-air firmware updates |
| `led_status_no_wifi` | Orange disco | No WiFi credentials | When no valid WiFi credentials are configured |
| `led_status_ble_advertising` | Blue breath | BLE advertising active | When device is in BLE advertising mode |
| `led_status_measurement` | Orange light | Measurement in progress | During sensor measurement cycles |

### LED Usage in Code

To use these status indicators in your code:

```c
// Initialize LED hardware first (usually done in main.c)
led_initialize();

// Show a status pattern
led_status_connecting();  // Example: Show the connecting status pattern

// Direct LED control is also available
led_red_on();   // Turn on red LED
led_green_on(); // Turn on green LED
led_blue_on();  // Turn on blue LED
led_off();      // Turn off all LEDs
```

### Error Sequence Priority

When multiple conditions occur simultaneously, LED patterns follow this priority order:

1. Critical errors (highest priority)
2. Errors
3. Warnings
4. Connection status
5. Operational status (lowest priority)

### Technical Details

The LED controller uses the RMT (Remote Control) peripheral for precise timing control of the RGB LED. The implementation includes:

- Fade effects using PWM-like brightness control
- Breathing patterns with smooth transitions
- Disco effects with color transitions
- Task-based background patterns that don't block the main application
- Safe resource management to prevent resource leaks

The LED components draw power from the 3.3V rail and use minimal current to preserve battery life.


## For Contributors

### Release Scripts

The repository includes dedicated scripts for releasing firmware and Android applications to GitHub:

#### Firmware Release (`release_fw.sh`)

```bash
# Set GitHub token (if not using GitHub CLI)
export GITHUB_TOKEN=your_personal_access_token

# Run the script
./release_fw.sh
```

This script will:
- Automatically detect firmware versions from directory names in the firmware folder
- Create proper release notes with installation instructions
- Package firmware into zip files for easy distribution
- Create GitHub releases with the tag format: `firmware-v1.0.103`

#### Android App Release (`release_app.sh`)

```bash
# Set GitHub token (if not using GitHub CLI)
export GITHUB_TOKEN=your_personal_access_token

# Run the script
./release_app.sh
```

This script will:
- Automatically detect APK files in the android_app directory
- Extract version number from APK filenames
- Create a combined ZIP file with all APK variants
- Generate detailed release notes with information about each APK variant
- Create GitHub releases with the tag format: `android-v1.6.0`

Both scripts support using either the GitHub CLI (if installed) or the GitHub API with a personal access token.

### Creating New Releases

1. Place new firmware files in:
   - `firmware/debug/waterBee_VERSION_debug_merged/`
   - `firmware/release/waterBee_VERSION_release_merged/`

2. Place new APK files in:
   - `android_app/`

3. Run the appropriate release script:
   ```bash
   # For firmware releases
   ./release_fw.sh
   
   # For Android app releases
   ./release_app.sh
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
- Release scripts support both GitHub CLI and API methods for releases
- Scripts use GitHub API to fetch the latest releases automatically
- Local directories (`firmware/` and `android_app/`) are used for staging files but not tracked in git

## License

See LICENSE file for details.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes. 