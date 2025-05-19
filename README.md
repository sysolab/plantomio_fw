# WaterBee Firmware and Application

This repository provides tools to flash firmware to WaterBee devices, download Android applications, and manage releases.

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
  - [Cloning the Repository](#cloning-the-repository)
  - [Setting Up](#setting-up)
- [Firmware Installation](#firmware-installation)
  - [Flashing the WaterBee Device](#flashing-the-waterbee-device)
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

The setup script:
- Creates a Python virtual environment (`.venv`)
- Installs all required dependencies from `requirements.txt`
- Makes the utility scripts executable
- Tries to detect ESP-IDF installation (optional)
- Works on both macOS and Linux systems

## Firmware Installation

### Flashing the WaterBee Device

The `flash_waterbee.sh` script provides an interactive and user-friendly way to flash your WaterBee device. It automatically downloads the latest firmware (or all versions if requested), detects available serial ports, and guides you through the flashing process step by step.

#### Recommended: Interactive Flashing

Simply run:

```bash
./flash_waterbee.sh
```

This will:
1. Check for the latest firmware releases on GitHub and download them if needed
2. Prompt you to choose between flashing a **release** (stable) or **debug** (development) firmware
3. Show all available firmware versions and let you select which one to flash (default is the latest)
4. Detect available serial ports and let you select the correct one (or use the default)
5. Ask if you want to erase the flash before flashing
6. Flash the selected firmware to your device
7. Offer to start the serial monitor after flashing

#### Command Line Options and Advanced Usage

You can also use command-line arguments for non-interactive or advanced workflows:

```bash
# Flash the latest *release* firmware (auto-downloads if needed)
./flash_waterbee.sh release

# Flash the latest *debug* firmware
./flash_waterbee.sh debug

# Download all available firmware versions (not just the latest)
./flash_waterbee.sh --all

# Download all versions and flash the latest release
./flash_waterbee.sh --all release

# Erase flash before flashing (no prompt)
./flash_waterbee.sh --erase release

# Specify a serial port explicitly
PORT=/dev/ttyUSB0 ./flash_waterbee.sh release    # Linux example
PORT=/dev/tty.usbmodem* ./flash_waterbee.sh      # macOS example

# Flash a specific firmware folder
./flash_waterbee.sh firmware/release/waterBee_1.1.9_release_merged

# Flash a specific folder to a specific port
./flash_waterbee.sh firmware/debug/waterBee_1.0.47 /dev/tty.usbserial‑0001
```

#### Monitoring

After flashing, you can monitor the device's serial output:

- Directly from the script (it will offer to start monitoring)
- Or manually:

```bash
python -m serial.tools.miniterm --raw <PORT> 115200
```

Replace `<PORT>` with your device's port (the same one used for flashing).

#### Notes
- The script will automatically activate the Python virtual environment if needed.
- If the required firmware is not found locally, it will be downloaded from GitHub.
- The script works on both macOS and Linux, and will auto-detect serial ports for you.
- You can always see all available options by running:

```bash
./flash_waterbee.sh --help
```

## Android Application

### Downloading the APK

Download the latest Android APK files using the provided script:

```bash
# Download only the latest version of the APKs
./get_android_app.sh

# Download all versions (not just the latest)
./get_android_app.sh --all

# Show help
./get_android_app.sh --help
```

This script will:
1. Automatically fetch the latest Android app release from GitHub
2. By default, download only the most recent version APKs (both arm64 and armeabi)
3. Create an `android_app` directory with the APK files
4. Show which architecture each APK supports

The script is compatible with both macOS and Linux, and:
- Supports downloading both ARM and ARM64 variants
- Only downloads the latest version by default
- Can download all versions with the `--all` flag
- Skips universal and debug variants
- Shows clear version information

### Installation

1. Transfer the APK file to your Android device
2. On your Android device, navigate to the APK file and tap to install
3. You may need to enable "Install from Unknown Sources" in your Android settings

Choose the appropriate APK variant for your device:
- **arm64-v8a** - For modern Android devices (64-bit ARM)
- **armeabi-v7a** - For older Android devices (32-bit ARM)

## How to Use the App with Device

1. **Go to the Device Tab**
   - Open the app and navigate to the Device tab.
   - The app will automatically scan for nearby BLE devices that advertise the correct manufacturer data (e.g., PLT-A7B3C9D1).
   - Tap on your device in the list to connect. If you have previously saved a device, it will appear in 'My Devices' and auto-reconnect when in range.

2. **Configure Device Settings**
   - Once connected, tap the Settings tab (or the gear/settings icon) to access device configuration options.
   - **WiFi Setup:** Enter your WiFi SSID and password to connect the device to your local network.
   - **MQTT Setup:** Enter your MQTT broker configuration as a JSON string to enable cloud connectivity.
   - **Calibration:** Calibrate sensors (pH, EC, TDS, ORP, Fill Level) as needed for accurate readings. Save calibration values to persist them.
   - **Thresholds:** Set threshold values for each sensor (pH, EC, TDS, ORP, Fill Level, Temperature) to enable alerts and visual indicators.
   - **Notifications:** You can set notification frequency or turn notifications off entirely in the Alerts/Notifications section. If set to 'Off', you will not receive push notifications for threshold events.

3. **Managing Devices**
   - **Disconnect:** Disconnect from a device to stop receiving live data, but keep it in 'My Devices'.
   - **Forget:** Forget a device to remove it from 'My Devices'. It will appear in 'Available Devices' and can be reconnected at any time.
   - The app will auto-reconnect to saved devices when they are in range or after unexpected disconnects.

4. **Best Practices**
   - Always calibrate sensors after installation or when readings seem inaccurate.
   - Set appropriate thresholds for your use case to receive timely alerts.
   - Use the notification settings to control alert frequency or disable them if not needed.

For more details, see the in-app help or contact support.


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
- Create GitHub releases with the tag format: `firmware-v1.1.9`

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
- Create GitHub releases with the tag format: `android-v1.6.2`

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

### Serial Port is Busy

If you see an error like "Could not open port: Resource temporarily unavailable":
- Close any other applications that might be using the port (like Arduino IDE, serial monitor, screen)
- Try unplugging and re-plugging the device
- Restart your terminal

### Virtual Environment Issues

- If you encounter issues with the virtual environment, try:
  ```bash
  rm -rf .venv
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
- Default baud rate: 115200 bps
- Merged bin file at address 0x0
- Cross-platform scripts work on both macOS and Linux
- Color terminal output for better readability
- The APK downloader has special handling for different ARM architectures
- Fallback methods for JSON parsing if jq is not available
- Unified error handling and user feedback

## License

See LICENSE file for details.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes. 