#!/usr/bin/env bash
# --------------------------------------------------------------------
# Universal flasher for any WaterBee build (release or debug)
# --------------------------------------------------------------------
set -euo pipefail

##############################################################################
# USER‑TUNABLE DEFAULTS
##############################################################################
DEFAULT_PORT=${PORT:-/dev/tty.usbmodem2101}     # override:  PORT=/dev/ttyACMx ./flash_waterbee.sh
BAUD=${BAUD:-115200}
TARGET=esp32c6
VENV_PATH="./.venv"  # Path to the hidden virtual environment
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
    # Use a for loop instead of mapfile for better compatibility
    for file in "$base_dir"/*; do
      if [ -d "$file" ]; then
        versions+=("$(basename "$file")")
      fi
    done
    
    # Sort versions (compatible with bash 3.x on macOS)
    local sorted_versions=()
    local IFS=$'\n'
    sorted_versions=($(echo "${versions[*]}" | sort -V))
    unset IFS
    
    echo "${sorted_versions[@]}"
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
  local available_versions
  available_versions=($(find_firmware_versions "$base_dir"))
  
  if [ ${#available_versions[@]} -eq 0 ]; then
    echo -e "${RED}No $firmware_type firmware versions found in $base_dir${NC}"
    exit 1
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
  
  FOLDER="$base_dir/$selected_version"
}

##############################################################################
# Helper function to find latest version in a directory
##############################################################################
find_latest() {
  local base="$1"
  [[ -d "$base" ]] || return 1
  ls -1 "$base" | sort -V | tail -n1
}

##############################################################################
# Main execution
##############################################################################

# Check if interactive mode
if [[ $# -eq 0 ]]; then
  # Interactive mode
  choose_firmware
  detect_ports
elif [[ $1 == "debug" ]]; then
  # Quick debug mode - use latest debug firmware
  FOLDER="firmware/debug/$(find_latest firmware/debug)"
  # Ask for port if not provided
  if [[ $# -lt 2 ]]; then
    detect_ports
  else
    PORT="$2"
  fi
elif [[ $1 == "release" ]]; then
  # Quick release mode - use latest release firmware
  FOLDER="firmware/release/$(find_latest firmware/release)"
  # Ask for port if not provided
  if [[ $# -lt 2 ]]; then
    detect_ports
  else
    PORT="$2"
  fi
else
  # Use provided folder
  FOLDER="$1"
  # Use provided port or detect if not provided
  if [[ $# -lt 2 ]]; then
    detect_ports
  else
    PORT="$2"
  fi
fi

##############################################################################
# Check if folder exists and contains required files
##############################################################################
[[ -d "$FOLDER" ]] || { echo -e "${RED}ERROR: Folder '$FOLDER' not found${NC}" >&2 ; exit 2; }

BIN=$(ls "$FOLDER"/*.bin 2>/dev/null | head -n1)
ARGS_FILE="$FOLDER/flash_args"

[[ -f "$BIN" ]] || { echo -e "${RED}ERROR: merged .bin not found in $FOLDER${NC}" >&2 ; exit 3; }
[[ -f "$ARGS_FILE" ]] || { echo -e "${RED}ERROR: flash_args not found in $FOLDER${NC}" >&2 ; exit 4; }

echo -e "${BLUE}------------------------------------------------------------${NC}"
echo -e "${BLUE} WaterBee flasher${NC}"
echo -e "${BLUE}------------------------------------------------------------${NC}"
echo -e "${GREEN}  Folder : $FOLDER${NC}"
echo -e "${GREEN}  Binary : $(basename "$BIN")${NC}"
echo -e "${GREEN}  Port   : $PORT  (baud $BAUD)${NC}"
echo -e "${GREEN}  Using  : $(python --version)${NC}"
echo -e "${BLUE}------------------------------------------------------------${NC}"

read -rp "Press <Enter> to FLASH, or Ctrl‑C to abort " _

python -m esptool --chip "$TARGET" -b "$BAUD" -p "$PORT" \
      --before default_reset --after hard_reset \
      write_flash "@$ARGS_FILE"

echo -e "\n${GREEN}Flash OK!${NC}  You can now open a serial monitor:"
echo -e "    python -m esptool --chip $TARGET -p $PORT monitor"
