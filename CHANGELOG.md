# WaterBee Firmware Flasher Changelog

## v1.2.1 - 09.May.2024

### Improvements
- Optimized release scripts to only detect and release the latest versions:
  - Fixed version detection logic to properly identify the newest version
  - Improved filtering to only release files for the latest version
  - Removed unnecessary ZIP packaging from release_app.sh
  - Enhanced validation to ensure proper version detection
  - Added robust sorting and comparison of version numbers

### Bug Fixes
- Fixed issue in release_app.sh where older APK versions were being released alongside newer ones
- Improved version extraction from filenames with better regex pattern matching
- Fixed release_fw.sh to only release the latest firmware builds

## v1.2.0 - 08.May.2024

### Features
- Added dedicated release scripts for firmware and Android app:
  - `release_fw.sh` - For releasing firmware with proper version tags
  - `release_app.sh` - For releasing Android app with proper version tags
- Improved repository structure with better separation of local and remote files
- Enhanced project organization with clean repository history

### Technical Improvements
- Created robust firmware release system with version detection from filenames
- Implemented Android app release system with APK packaging and metadata
- Added support for both GitHub CLI and API methods for releases
- Improved dependency checking and error handling in release scripts
- Enhanced release notes generation with automatic version detection
- ZIP packaging for combined firmware and app releases
- Better local file management for firmware and Android app folders

## v1.1.0 - 07.May.2025

### Features
- Added interactive firmware selection mode allowing users to choose between debug/release builds
- Implemented automatic port detection for macOS and Linux
- Enhanced cross-platform compatibility for better support on different OS
- Created hidden virtual environment (.waterBeeFW) for better project organization

### Technical Improvements
- Refactored flash_waterbee.sh script with improved error handling and user feedback
- Added comprehensive documentation including detailed README and updated CHANGELOG
- Created a more inclusive .gitignore file with better environment exclusions
- Fixed compatibility issues with older bash versions on macOS
- Updated script outputs with color coding for better readability
- Added direct virtual environment activation during setup

## v1.0.3 - 06.May.2025

### Critical Fixes
- Fixed SHA-256 comparison failures during boot by preserving firmware integrity
- Enhanced flash parameters to match ESP-IDF build environment
- Added proper chip and flash size auto-detection

### Technical Improvements
- Used complete esptool.py parameters for firmware flashing
- Added compression and proper reset parameters
- Improved error reporting for flash failures
- Optimized erase operation with higher baud rate
- Maintained firmware binary integrity throughout flash process

## v1.0.2 - 06.May.2025

### Fixes
- Fixed "CMakeLists.txt not found" error when using the monitor command
- Improved serial monitoring with direct PySerial implementation
- Added fallback monitoring with automatic temporary CMakeLists.txt creation

### Technical Improvements
- Used serial.tools.miniterm directly for better terminal experience
- Implemented intelligent fallback mechanism when dependencies are missing
- Added proper cleanup of temporary files

## v1.0.1 - 06.May.2025

### Features
- Added the ability to automatically start monitoring after flashing with `--monitor` or `-m` flag
- Enhanced monitoring support with better error checking and fallback options
- Improved port validation before attempting to monitor

### Technical Improvements
- Added fallback to PySerial miniterm when ESP-IDF is not available for monitoring
- Better error handling for port access issues
- Fixed return values for monitoring to properly indicate success/failure

## v1.0.0 - 06.May.2025

### Features
- Created comprehensive ESP32 firmware flashing utility with CLI and GUI interfaces
- Automatic device detection and port identification
- Firmware management with browsing and auto-organization capabilities
- Clean flash and firmware writing operations
- Integrated serial monitoring with logging capabilities
- Cross-platform support (macOS, Linux, Windows)

### Technical Improvements
- Python-based architecture with proper error handling
- Automatic ESP-IDF detection and integration
- Virtualized Python environment for dependency isolation
- Intelligent port detection for ESP32 devices
- Multi-threaded operations for non-blocking UI
- Proper firmware file management system

## v0.9.0 - 05.May.2025

### Initial Implementation
- Basic ESP32 flashing functionality
- Command line interface for fundamental operations
- Essential firmware management
- Basic error handling
- Initial cross-platform compatibility

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). 