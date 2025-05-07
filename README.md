# WaterBee Firmware Flasher

A comprehensive tool for flashing and managing ESP32-based WaterBee firmware. This utility provides a streamlined process for flashing different versions of WaterBee firmware to ESP32C6 devices, with support for both debug and release builds.

## Overview

This project provides tools to:
- Set up a Python virtual environment with all required dependencies
- Flash WaterBee firmware to ESP32C6 devices
- Interactively select firmware versions and serial ports
- Automatically detect connected devices
- Monitor device serial output after flashing

## Prerequisites

- **Python 3.8+** – already on macOS / most Linux.  
  Windows: install from https://python.org and *tick* "Add to PATH".
- A USB-C / USB-TTL cable connected to your WaterBee device
- (Optional) ESP-IDF installed for additional functionality

## Getting Started

### 1. Setup

Run the setup script to create a virtual environment and install all dependencies:

```bash
# This will create a hidden virtual environment (.waterBeeFW)
# and install all required packages
source ./setup.sh
```

> **Note**: Using `source` is important as it activates the environment in your current shell.

### 2. Flashing Firmware

The interactive mode is the recommended approach for most users:

```bash
./flash_waterbee.sh
```

This will:
1. Ask if you want to flash a debug or release firmware
2. Show available firmware versions
3. Detect available serial ports
4. Flash the selected firmware to the selected port

#### Alternative Flashing Methods

```bash
# Flash latest release firmware
./flash_waterbee.sh release

# Flash latest debug firmware
./flash_waterbee.sh debug

# Flash a specific firmware and specify the port
./flash_waterbee.sh firmware/release/waterBee_release_1.0.60 /dev/ttyUSB0
```

### 3. Monitoring

After flashing, you can monitor the device's serial output:

```bash
python -m esptool --chip esp32c6 -p <PORT> monitor
```

Replace `<PORT>` with your device's port (same as used for flashing).

## Project Structure

```
plantomio_fw/
├── firmware/                  # Firmware files
│   ├── debug/                 # Debug builds
│   │   └── waterBee_debug_*/  # Debug firmware versions
│   ├── release/               # Release builds
│   │   └── waterBee_release_*/# Release firmware versions
│   └── README_FLASH.txt       # Original flashing instructions
├── .waterBeeFW/               # Python virtual environment (hidden)
├── requirements.txt           # Python dependencies
├── setup.sh                   # Setup script
└── flash_waterbee.sh          # Firmware flashing script
```

## Firmware Structure

Each firmware folder contains:
- `*.bin` - The merged firmware binary file
- `flash_args` - Flash arguments file used by esptool

## Cross-Platform Compatibility

This utility works on:
- macOS
- Linux (Ubuntu and other distributions)
- Windows (with appropriate serial port specifications)

## Troubleshooting

### No Serial Ports Detected

- Ensure your device is connected properly
- Check USB cable is functional
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

## Technical Details

- Uses esptool.py for ESP32 firmware flashing
- Target chip: ESP32C6
- Default baud rate: 460800
- Flashing process includes both partition table and application binary

## License

See LICENSE file for details.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## Android App

The Android APK files are available as GitHub releases. To download and install them, you can:

1. Visit the [releases page](https://github.com/sysolab/plantomio_fw/releases) and download the appropriate APK file
2. Or use the provided script to download them automatically:

```bash
# Make the script executable
chmod +x android_app_install.sh

# Run the script
./android_app_install.sh
```

Available APK variants:
- waterBee_universal-release_v1.6.0.apk - Works on all Android devices
- waterBee_arm64-v8a-release_v1.6.0.apk - For ARM64 devices
- waterBee_armeabi-v7a-release_v1.6.0.apk - For ARMv7 devices
- waterBee_debug_v1.6.0.apk - Debug version with additional logging 