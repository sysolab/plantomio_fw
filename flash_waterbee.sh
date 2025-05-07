#!/usr/bin/env bash
# --------------------------------------------------------------------
# Universal flasher for any WaterBee build (release or debug)
# --------------------------------------------------------------------
# CHANGELOG:
# 2024-05-07: 
# - Fixed firmware extraction to correct folders
# - Updated to handle merged binary files properly
# - Added option to erase flash before flashing
# - Fixed monitoring command to use miniterm instead of esptool
# --------------------------------------------------------------------
set -euo pipefail

##############################################################################
# USER‑TUNABLE DEFAULTS
##############################################################################
DEFAULT_PORT=${PORT:-/dev/tty.usbmodem2101}     # override:  PORT=/dev/ttyACMx ./flash_waterbee.sh
BAUD=${BAUD:-115200}
TARGET=esp32c6
VENV_PATH="./.venv"  # Path to the hidden virtual environment
GITHUB_REPO="sysolab/plantomio_fw"  # GitHub repository
##############################################################################

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
  cat <<EOF
Usage:
  ./flash_waterbee.sh [FOLDER] [PORT]

  FOLDER  Folder that contains the firmware artefacts (merged .bin + flash_args).
          • If omitted  =>  interactive mode will be used
          • If "debug"  =>  latest build inside firmware/debug/ is used
          • If "release" => latest build inside firmware/release/ is used
          • If a full path is supplied, that exact folder is used.

  PORT    Optional serial port. Can also be set via the PORT environment
          variable (defaults to automatic detection).

Examples
  # Interactive mode (recommended)
  ./flash_waterbee.sh

  # flash latest *release*
  ./flash_waterbee.sh release

  # flash latest *debug*
  ./flash_waterbee.sh debug

  # flash an explicit folder on a specific port
  ./flash_waterbee.sh firmware/debug/waterBee_debug_1.0.47 /dev/tty.usbserial‑0001
EOF
  exit 0
}

[[ ${1:-} == "-h" || ${1:-} == "--help" ]] && show_help

##############################################################################
# Check for virtual environment
##############################################################################
if [ ! -d "$VENV_PATH" ]; then
  echo -e "${RED}ERROR: Virtual environment '$VENV_PATH' not found.${NC}"
  echo -e "Please run ./setup.sh first to create the virtual environment."
  exit 1
fi

# Check if virtual environment is activated
if [[ -z "${VIRTUAL_ENV:-}" || "$VIRTUAL_ENV" != *"$VENV_PATH"* ]]; then
  echo -e "${YELLOW}Activating virtual environment '$VENV_PATH'...${NC}"
  source "$VENV_PATH/bin/activate"
fi

##############################################################################
# Function to download the latest firmware from GitHub releases
##############################################################################
download_latest_firmware() {
  echo -e "${BLUE}Checking for latest firmware releases...${NC}"
  
  # Create firmware directories if they don't exist
  mkdir -p firmware/debug firmware/release
  
  # Get list of releases with firmware tag
  echo -e "${YELLOW}Fetching firmware releases from GitHub...${NC}"
  local releases_json
  releases_json=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases")
  
  # Check if GitHub API request failed
  if [ $? -ne 0 ] || [[ "$releases_json" == *"API rate limit exceeded"* ]]; then
    echo -e "${RED}Failed to fetch releases from GitHub API. Rate limit may be exceeded.${NC}"
    echo -e "${YELLOW}Will use existing firmware if available.${NC}"
    return 1
  fi
  
  # Find latest firmware release (tag that starts with firmware-v)
  local latest_firmware_tag
  latest_firmware_tag=$(echo "$releases_json" | grep -o '"tag_name": "firmware-v[^"]*"' | head -1 | sed 's/"tag_name": "//;s/"$//')
  
  if [ -z "$latest_firmware_tag" ]; then
    echo -e "${YELLOW}No firmware releases found on GitHub. Will use existing firmware if available.${NC}"
    return 1
  fi
  
  echo -e "${GREEN}Found latest firmware release: $latest_firmware_tag${NC}"
  
  # Extract version number from tag (e.g., firmware-v1.0.103 -> 1.0.103)
  local firmware_version
  firmware_version=$(echo "$latest_firmware_tag" | sed 's/firmware-v//')
  
  # Define paths for debug and release firmware
  local debug_zip="firmware_v${firmware_version}_debug.zip"
  local release_zip="firmware_v${firmware_version}_release.zip"
  local debug_url="https://github.com/$GITHUB_REPO/releases/download/$latest_firmware_tag/$debug_zip"
  local release_url="https://github.com/$GITHUB_REPO/releases/download/$latest_firmware_tag/$release_zip"
  
  # Define version folders
  local debug_dir="firmware/debug/waterBee_${firmware_version}_debug_merged"
  local release_dir="firmware/release/waterBee_${firmware_version}_release_merged"
  
  # Download debug firmware
  echo -e "${YELLOW}Downloading debug firmware...${NC}"
  if curl -L -s -f -o "/tmp/$debug_zip" "$debug_url"; then
    echo -e "${GREEN}Successfully downloaded debug firmware.${NC}"
    
    # Extract debug firmware
    echo -e "${YELLOW}Extracting debug firmware...${NC}"
    rm -rf "$debug_dir"
    mkdir -p "$debug_dir"
    unzip -q -o "/tmp/$debug_zip" -d "$debug_dir"
    rm "/tmp/$debug_zip"
    
    echo -e "${GREEN}Debug firmware extracted to $debug_dir${NC}"
  else
    echo -e "${RED}Failed to download debug firmware from $debug_url${NC}"
  fi
  
  # Download release firmware
  echo -e "${YELLOW}Downloading release firmware...${NC}"
  if curl -L -s -f -o "/tmp/$release_zip" "$release_url"; then
    echo -e "${GREEN}Successfully downloaded release firmware.${NC}"
    
    # Extract release firmware
    echo -e "${YELLOW}Extracting release firmware...${NC}"
    rm -rf "$release_dir"
    mkdir -p "$release_dir"
    unzip -q -o "/tmp/$release_zip" -d "$release_dir"
    rm "/tmp/$release_zip"
    
    echo -e "${GREEN}Release firmware extracted to $release_dir${NC}"
  else
    echo -e "${RED}Failed to download release firmware from $release_url${NC}"
  fi
  
  return 0
}

##############################################################################
# Function to detect available serial ports
##############################################################################
detect_ports() {
  echo -e "${BLUE}Detecting available serial ports...${NC}"
  
  # Array to store detected ports
  local detected_ports=()
  
  # Check the operating system
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS - Look for both USB and Bluetooth serial ports
    for port in /dev/tty.usbmodem* /dev/tty.usbserial* /dev/tty.SLAB* /dev/cu.usbmodem*; do
      if [ -e "$port" ]; then
        detected_ports+=("$port")
      fi
    done
  elif [[ "$(uname)" == "Linux" ]]; then
    # Linux
    for port in /dev/ttyUSB* /dev/ttyACM* /dev/ttyS*; do
      if [ -e "$port" ]; then
        detected_ports+=("$port")
      fi
    done
  fi
  
  # Check if no ports were found
  if [ ${#detected_ports[@]} -eq 0 ]; then
    echo -e "${YELLOW}No serial ports found. Make sure your device is connected.${NC}"
    echo -e "${YELLOW}Using default port: ${DEFAULT_PORT}${NC}"
    PORT="${DEFAULT_PORT}"
    return 1
  fi
  
  echo -e "${GREEN}Found ${#detected_ports[@]} port(s):${NC}"
  for i in "${!detected_ports[@]}"; do
    echo -e "  $((i+1)). ${detected_ports[$i]}"
  done
  
  # Ask user to select a port
  echo -e "${YELLOW}Please select a port (1-${#detected_ports[@]}) or press Enter for default:${NC}"
  read -r port_selection
  
  # If the user pressed Enter without typing anything, use the first port
  if [ -z "$port_selection" ]; then
    selected_port="${detected_ports[0]}"
    echo -e "${GREEN}Using default port: $selected_port${NC}"
  elif [[ "$port_selection" =~ ^[0-9]+$ ]] && [ "$port_selection" -ge 1 ] && [ "$port_selection" -le "${#detected_ports[@]}" ]; then
    selected_port="${detected_ports[$((port_selection-1))]}"
    echo -e "${GREEN}Selected port: $selected_port${NC}"
  else
    echo -e "${RED}Invalid selection. Using default port: ${detected_ports[0]}${NC}"
    selected_port="${detected_ports[0]}"
  fi
  
  PORT="$selected_port"
  return 0
}

##############################################################################
# Function to find available firmware versions
##############################################################################
find_firmware_versions() {
  local base_dir="$1"
  local versions=()
  
  if [ -d "$base_dir" ]; then
    # First check for subdirectories (original behavior)
    for file in "$base_dir"/*; do
      if [ -d "$file" ]; then
        versions+=("$(basename "$file")")
      fi
    done
    
    # If no subdirectories found, check if we have bin files directly in the directory
    if [ ${#versions[@]} -eq 0 ]; then
      if ls "$base_dir"/*.bin >/dev/null 2>&1; then
        # If bin files found, create a dummy version name based on directory
        local dir_name=$(basename "$base_dir")
        versions+=("$dir_name")
      fi
    fi
    
    # Sort versions (compatible with bash 3.x on macOS)
    # Check if any versions were found first to avoid unbound variable error
    if [ ${#versions[@]} -gt 0 ]; then
      local IFS=$'\n'
      local sorted_versions=($(echo "${versions[*]}" | sort -V))
      unset IFS
      
      echo "${sorted_versions[@]}"
    else
      # Return empty if no versions found
      echo ""
    fi
  else
    # Return empty if directory doesn't exist
    echo ""
  fi
}

##############################################################################
# Function to choose firmware type and version
##############################################################################
choose_firmware() {
  echo -e "${BLUE}WaterBee Firmware Selection${NC}"
  echo -e "${YELLOW}Do you want to flash a debug or release firmware?${NC}"
  echo -e "1. Release (stable version)"
  echo -e "2. Debug (development version)"
  read -r firmware_type_selection
  
  local firmware_type
  local base_dir
  
  if [ "$firmware_type_selection" == "2" ]; then
    firmware_type="debug"
    base_dir="firmware/debug"
  else
    firmware_type="release"
    base_dir="firmware/release"
  fi
  
  echo -e "${GREEN}Selected: $firmware_type firmware${NC}"
  echo -e "${YELLOW}Looking for available $firmware_type firmware versions...${NC}"
  
  # Get available versions
  local available_versions_output
  available_versions_output=$(find_firmware_versions "$base_dir")
  
  # Convert output to array
  local available_versions=()
  if [ -n "$available_versions_output" ]; then
    # Read the space-separated output into an array
    read -r -a available_versions <<< "$available_versions_output"
  fi
  
  if [ ${#available_versions[@]} -eq 0 ]; then
    echo -e "${RED}No $firmware_type firmware versions found in $base_dir${NC}"
    echo -e "${YELLOW}Attempting to download firmware from GitHub...${NC}"
    download_latest_firmware
    
    # Try to get versions again
    available_versions_output=$(find_firmware_versions "$base_dir")
    read -r -a available_versions <<< "$available_versions_output"
    
    if [ ${#available_versions[@]} -eq 0 ]; then
      echo -e "${RED}Unable to find or download any firmware.${NC}"
      exit 1
    fi
  fi
  
  echo -e "${GREEN}Found ${#available_versions[@]} version(s):${NC}"
  for i in "${!available_versions[@]}"; do
    echo -e "  $((i+1)). ${available_versions[$i]}"
  done
  
  # Choose the latest version by default
  local latest_version="${available_versions[${#available_versions[@]}-1]}"
  
  echo -e "${YELLOW}Please select a version (1-${#available_versions[@]}) or press Enter for latest (${latest_version}):${NC}"
  read -r version_selection
  
  local selected_version
  
  if [ -z "$version_selection" ]; then
    selected_version="$latest_version"
    echo -e "${GREEN}Using latest version: $selected_version${NC}"
  elif [[ "$version_selection" =~ ^[0-9]+$ ]] && [ "$version_selection" -ge 1 ] && [ "$version_selection" -le "${#available_versions[@]}" ]; then
    selected_version="${available_versions[$((version_selection-1))]}"
    echo -e "${GREEN}Selected version: $selected_version${NC}"
  else
    echo -e "${RED}Invalid selection. Using latest version: $latest_version${NC}"
    selected_version="$latest_version"
  fi
  
  # Check if the selected version is a directory name or the same as base_dir name
  if [ "$selected_version" = "$(basename "$base_dir")" ]; then
    # Files are directly in the base directory
    FIRMWARE_PATH="$base_dir"
  else
    # Files are in a subdirectory
    FIRMWARE_PATH="$base_dir/$selected_version"
  fi
  
  echo -e "${BLUE}Selected firmware: $FIRMWARE_PATH${NC}"
}

##############################################################################
# Main Script Logic
##############################################################################

# First try to download latest firmware (won't replace existing if download fails)
download_latest_firmware

# Check if a folder is specified
if [ $# -ge 1 ] && [ "$1" != "debug" ] && [ "$1" != "release" ]; then
  # Use the specified folder
  FIRMWARE_PATH="$1"
elif [ $# -ge 1 ]; then
  # Use debug or release mode
  if [ "$1" == "debug" ]; then
    # Find latest debug version
    base_dir="firmware/debug"
    available_versions_output=$(find_firmware_versions "$base_dir")
    
    # Convert output to array
    local available_versions=()
    if [ -n "$available_versions_output" ]; then
      read -r -a available_versions <<< "$available_versions_output"
    fi
    
    if [ ${#available_versions[@]} -eq 0 ]; then
      echo -e "${RED}No debug firmware found. Trying to download...${NC}"
      download_latest_firmware
      
      # Try to get versions again
      available_versions_output=$(find_firmware_versions "$base_dir")
      read -r -a available_versions <<< "$available_versions_output"
      
      if [ ${#available_versions[@]} -eq 0 ]; then
        echo -e "${RED}Unable to find or download any debug firmware.${NC}"
        exit 1
      fi
    fi
    
    latest_version="${available_versions[${#available_versions[@]}-1]}"
    
    # Check if the latest version is a directory name or the same as base_dir name
    if [ "$latest_version" = "$(basename "$base_dir")" ]; then
      # Files are directly in the base directory
      FIRMWARE_PATH="$base_dir"
    else
      # Files are in a subdirectory
      FIRMWARE_PATH="$base_dir/$latest_version"
    fi
  else # release
    # Find latest release version
    base_dir="firmware/release"
    available_versions_output=$(find_firmware_versions "$base_dir")
    
    # Convert output to array
    local available_versions=()
    if [ -n "$available_versions_output" ]; then
      read -r -a available_versions <<< "$available_versions_output"
    fi
    
    if [ ${#available_versions[@]} -eq 0 ]; then
      echo -e "${RED}No release firmware found. Trying to download...${NC}"
      download_latest_firmware
      
      # Try to get versions again
      available_versions_output=$(find_firmware_versions "$base_dir")
      read -r -a available_versions <<< "$available_versions_output"
      
      if [ ${#available_versions[@]} -eq 0 ]; then
        echo -e "${RED}Unable to find or download any release firmware.${NC}"
        exit 1
      fi
    fi
    
    latest_version="${available_versions[${#available_versions[@]}-1]}"
    
    # Check if the latest version is a directory name or the same as base_dir name
    if [ "$latest_version" = "$(basename "$base_dir")" ]; then
      # Files are directly in the base directory
      FIRMWARE_PATH="$base_dir"
    else
      # Files are in a subdirectory
      FIRMWARE_PATH="$base_dir/$latest_version"
    fi
  fi
else
  # Interactive mode
  choose_firmware
fi

echo -e "${BLUE}Selected firmware: $FIRMWARE_PATH${NC}"

# Check if the specified folder exists
if [ ! -d "$FIRMWARE_PATH" ]; then
  echo -e "${RED}Firmware folder not found: $FIRMWARE_PATH${NC}"
  exit 1
fi

# Check if a port was specified as the second argument
if [ $# -ge 2 ]; then
  PORT="$2"
else
  # If no port was specified, try to detect available ports
  detect_ports
fi

echo -e "${BLUE}Using port: $PORT${NC}"

# Check if the bin file exists in the folder
BIN_FILE=$(find "$FIRMWARE_PATH" -name "*.bin" | head -1)
if [ -z "$BIN_FILE" ]; then
  echo -e "${RED}No .bin file found in $FIRMWARE_PATH${NC}"
  exit 1
fi

echo -e "${GREEN}Found merged bin file: $BIN_FILE${NC}"

# Ask if user wants to erase flash before flashing
echo -e "${YELLOW}Do you want to erase the flash completely before flashing? (y/n)${NC}"
read -r erase_flash

# Build the esptool command
echo -e "${BLUE}Building flash command...${NC}"

# Initialize flash command with basic parameters
FLASH_CMD="python -m esptool --chip $TARGET --port $PORT --baud $BAUD --before default_reset --after hard_reset"

# Erase flash if requested
if [[ "$erase_flash" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Erasing flash...${NC}"
  eval "$FLASH_CMD erase_flash"
  echo -e "${GREEN}Flash erased.${NC}"
fi

# Since we have a merged bin file, we can flash it directly to address 0x0
echo -e "${GREEN}Flashing merged bin file to address 0x0${NC}"
FLASH_CMD="$FLASH_CMD write_flash 0x0 \"$BIN_FILE\""

# Show the command that will be executed
echo -e "${YELLOW}About to execute:${NC}"
echo -e "${BLUE}$FLASH_CMD${NC}"
echo -e "${YELLOW}Press Enter to continue or Ctrl+C to abort${NC}"
read -r

# Execute the flash command
echo -e "${GREEN}Flashing...${NC}"
eval "$FLASH_CMD"

echo -e "${GREEN}Firmware flashed successfully!${NC}"
echo -e "${BLUE}Do you want to monitor the device? (y/n)${NC}"
read -r monitor_device

if [[ "$monitor_device" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Starting monitor...${NC}"
  python -m serial.tools.miniterm --raw $PORT $BAUD
else
  echo -e "${BLUE}To monitor the device later, run:${NC}"
  echo -e "${YELLOW}python -m serial.tools.miniterm --raw $PORT $BAUD${NC}"
fi

exit 0 