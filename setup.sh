#!/usr/bin/env bash

# Colors for terminal output
if [ -t 1 ]; then  # Check if stdout is a terminal
  if command -v tput &> /dev/null; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    NC=$(tput sgr0)  # No Color
  else
    # Fallback to ANSI color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
  fi
else
  # No colors if not a terminal
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

echo -e "${BLUE}ESP32 Firmware Flasher Setup${NC}"
echo -e "================================\n"

# Detect script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Detect OS
OS_TYPE="unknown"
if [[ "$(uname)" == "Darwin" ]]; then
  OS_TYPE="macos"
elif [[ "$(uname)" == "Linux" ]]; then
  OS_TYPE="linux"
elif [[ "$(uname)" =~ "MINGW"|"MSYS" ]]; then
  OS_TYPE="windows"
fi
echo -e "${YELLOW}Detected OS: $OS_TYPE${NC}"

# Check Python installation
echo -e "${YELLOW}Checking Python installation...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed.${NC}"
    echo -e "Please install Python 3 and try again."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        echo -e "\nOn macOS, you can install Python using Homebrew:"
        echo -e "  brew install python3"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        echo -e "\nOn Ubuntu/Debian, you can install Python using apt:"
        echo -e "  sudo apt update && sudo apt install python3 python3-pip python3-venv"
    elif [[ "$OS_TYPE" == "windows" ]]; then
        echo -e "\nOn Windows, you can download Python from:"
        echo -e "  https://www.python.org/downloads/"
    fi
    
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo -e "${GREEN}Python $PYTHON_VERSION detected.${NC}"

# Create a virtual environment with specific name (hidden folder)
echo -e "\n${YELLOW}Creating a virtual environment...${NC}"
python3 -m venv .venv
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create virtual environment.${NC}"
    echo -e "You may need to install the Python venv package."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        echo -e "\nOn macOS:"
        echo -e "  brew install python3"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        echo -e "\nOn Ubuntu/Debian:"
        echo -e "  sudo apt install python3-venv"
    fi
    
    exit 1
fi

# Activate virtual environment
echo -e "${GREEN}Virtual environment created successfully.${NC}"
source .venv/bin/activate

# Install dependencies
echo -e "\n${YELLOW}Installing dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install dependencies.${NC}"
    exit 1
fi

echo -e "${GREEN}Dependencies installed successfully.${NC}"

# Check/detect ESP-IDF
echo -e "\n${YELLOW}Checking for ESP-IDF...${NC}"

if [ -z "$IDF_PATH" ]; then
    # Try to find ESP-IDF in common locations
    ESP_IDF_LOCATIONS=(
        "$HOME/esp/v5.4/esp-idf"
        "$HOME/esp/esp-idf"
        "/opt/esp-idf"
        "$HOME/esp-idf"
    )
    
    for location in "${ESP_IDF_LOCATIONS[@]}"; do
        if [ -d "$location" ] && [ -f "$location/export.sh" ]; then
            echo -e "${GREEN}ESP-IDF found at: $location${NC}"
            echo -e "${YELLOW}You can source ESP-IDF by running:${NC}"
            echo -e "  source $location/export.sh"
            break
        fi
    done
    
    if [ -z "$ESP_IDF_FOUND" ]; then
        echo -e "${YELLOW}ESP-IDF not found in common locations.${NC}"
        echo -e "This tool works best with ESP-IDF installed."
        echo -e "You can install ESP-IDF by following the instructions at:"
        echo -e "  https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/"
    fi
else
    echo -e "${GREEN}ESP-IDF found at: $IDF_PATH${NC}"
fi

# Make scripts executable
echo -e "\n${YELLOW}Making scripts executable...${NC}"
chmod +x flash_waterbee.sh
chmod +x get_android_app.sh

# Activate the virtual environment for the current session
echo -e "\n${YELLOW}Activating virtual environment for current session...${NC}"
# This will affect the parent shell when script is run with source ./setup.sh
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    echo -e "${GREEN}Virtual environment activated for current session.${NC}"
else
    # Script is being executed, not sourced
    echo -e "${YELLOW}Note: To activate the virtual environment in your current shell, run:${NC}"
    echo -e "  source .venv/bin/activate"
fi

# Done
echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo -e "\n${BLUE}waterBee Firmware Flasher${NC}"
echo -e "================================\n"
echo -e "${YELLOW}How to use the firmware flasher:${NC}"
echo -e "\n${GREEN}# FLASH THE LATEST RELEASE BUILD${NC}"
echo -e "./flash_waterbee.sh                       # uses the newest release"
echo -e "\n${GREEN}# FLASH A SPECIFIC RELEASE${NC}"
echo -e "./flash_waterbee.sh release/waterBee_release_1.0.60"
echo -e "\n${GREEN}# FLASH THE DEBUG BUILD${NC}"
echo -e "./flash_waterbee.sh debug/waterBee_debug_1.0.60"
echo -e "\n${GREEN}# SPECIFY PORT MANUALLY${NC}"
echo -e "PORT=/dev/ttyUSB0 ./flash_waterbee.sh     # Linux example"
echo -e "PORT=/dev/tty.usbmodem* ./flash_waterbee.sh # macOS example"
echo -e "\nFor more information, see firmware/README_FLASH.txt" 