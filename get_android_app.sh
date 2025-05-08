#!/bin/bash

# WaterBee Android App Downloader
# This script automatically downloads the latest Android APK files from GitHub releases
# Compatible with both macOS and Linux

# Configuration
GITHUB_REPO="sysolab/plantomio_fw"
OUTPUT_DIR="android_app"
DOWNLOAD_ALL=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --all)
      DOWNLOAD_ALL=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--all]"
      echo "  --all    Download all versions, not just the latest"
      echo "  -h, --help    Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--all]"
      echo "  --all    Download all versions, not just the latest"
      exit 1
      ;;
  esac
done

# Detect OS type
OS_TYPE="unknown"
if [[ "$(uname)" == "Darwin" ]]; then
  OS_TYPE="macos"
elif [[ "$(uname)" == "linux-gnu"* || "$(uname)" == "Linux" ]]; then
  OS_TYPE="linux"
fi
echo "Detected OS: $OS_TYPE"

# Check for required commands
for cmd in curl grep sed; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is required but not installed. Please install it and try again."
    exit 1
  fi
done

# Colors for output (using tput for better compatibility)
if [ -t 1 ]; then  # Check if stdout is a terminal
  if command -v tput &> /dev/null; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    BLUE=$(tput setaf 4)
    NC=$(tput sgr0)  # No Color
  else
    # Fallback to ANSI color codes
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m'
  fi
else
  # No colors if not a terminal
  GREEN=''
  YELLOW=''
  RED=''
  BLUE=''
  NC=''
fi

echo -e "${BLUE}WaterBee Android App Downloader${NC}"
echo -e "----------------------------------------"
if [ $DOWNLOAD_ALL -eq 1 ]; then
  echo -e "${YELLOW}This script will download ALL Android APK files for WaterBee.${NC}"
else
  echo -e "${YELLOW}This script will download the LATEST Android APK files for WaterBee.${NC}"
  echo -e "${YELLOW}Use --all flag to download all versions.${NC}"
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}Created directory: $OUTPUT_DIR${NC}"

# Fetch releases from GitHub API
echo -e "${YELLOW}Fetching latest releases from GitHub...${NC}"
releases_json=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases")

# Check if GitHub API request failed
if [ $? -ne 0 ] || [[ "$releases_json" == *"API rate limit exceeded"* ]]; then
  echo -e "${RED}Failed to fetch releases from GitHub API. Rate limit may be exceeded.${NC}"
  exit 1
fi

# Find the latest android-v* release tag
latest_android_tag=$(echo "$releases_json" | grep -o '"tag_name": "android-v[^"]*"' | head -1 | sed 's/"tag_name": "//;s/"$//')
if [ -z "$latest_android_tag" ]; then
  echo -e "${RED}No Android app releases found on GitHub.${NC}"
  exit 1
fi

echo -e "${GREEN}Found latest Android app release: $latest_android_tag${NC}"

# Find the release block for this tag
release_block=$(echo "$releases_json" | awk -v tag="$latest_android_tag" 'BEGIN{RS="},"} $0 ~ tag {print $0 "},"}')

# Try to use jq if available for robust asset extraction
if command -v jq &> /dev/null; then
  asset_urls=$(echo "$releases_json" | jq -r ".[] | select(.tag_name == \"$latest_android_tag\") | .assets[] | select(.name | endswith(\".apk\")) | select((.name | contains(\"universal\") | not) and (.name | contains(\"debug\") | not)) | .browser_download_url")
else
  # Fallback: grep/sed extraction
  asset_urls=$(echo "$release_block" | grep 'browser_download_url' | grep '.apk' | grep -v 'universal' | grep -v 'debug' | sed 's/.*"browser_download_url": "//;s/".*$//')
fi

if [ -z "$asset_urls" ]; then
  echo -e "${YELLOW}No APK assets found for the latest release.${NC}"
  exit 0
fi

# Extract version info for filtering
# Store filenames and versions in temporary files for processing
tmpdir=$(mktemp -d)
files_list="$tmpdir/files_list.txt"
versions_list="$tmpdir/versions.txt"

# Save list of files with their URLs
echo "$asset_urls" > "$files_list"

# Extract all unique version numbers
all_versions=""
for url in $asset_urls; do
  filename=$(basename "$url")
  # Extract version using regex
  if [[ "$filename" =~ [_v]([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    version="${BASH_REMATCH[1]}"
    all_versions="$all_versions $version"
  fi
done

# Get unique versions and sort them
all_versions=$(echo "$all_versions" | tr ' ' '\n' | sort -V | uniq)
latest_version=$(echo "$all_versions" | tail -1)

if [ -n "$latest_version" ]; then
  echo -e "${GREEN}Latest APK version: $latest_version${NC}"
fi

download_count=0
download_failed=0
for url in $asset_urls; do
  filename=$(basename "$url")
  
  # If not downloading all, skip files that don't match the latest version
  if [ $DOWNLOAD_ALL -eq 0 ] && [ -n "$latest_version" ]; then
    # Check if file contains the latest version
    if [[ "$filename" =~ [_v]([0-9]+\.[0-9]+\.[0-9]+) ]]; then
      version="${BASH_REMATCH[1]}"
      if [ "$version" != "$latest_version" ]; then
        echo -e "${YELLOW}Skipping older version: $filename (v$version)${NC}"
        continue
      fi
    fi
  fi
  
  if [ -f "$OUTPUT_DIR/$filename" ]; then
    echo -e "${GREEN}$filename already exists. Skipping download.${NC}"
    continue
  fi
  echo -e "${BLUE}Downloading $filename...${NC}"
  if curl -L -s -f -o "$OUTPUT_DIR/$filename" "$url"; then
    echo -e "${GREEN}Successfully downloaded $filename${NC}"
    download_count=$((download_count + 1))
  else
    echo -e "${RED}Failed to download $filename (HTTP error)${NC}"
    download_failed=$((download_failed + 1))
    rm -f "$OUTPUT_DIR/$filename"
  fi
done

# Clean up temporary directory
rm -rf "$tmpdir"

echo -e "----------------------------------------"
if [ $download_count -eq 0 ] && [ $download_failed -eq 0 ]; then
  echo -e "${GREEN}No new APK files to download. You already have the latest versions.${NC}"
elif [ $download_count -eq 0 ] && [ $download_failed -gt 0 ]; then
  echo -e "${RED}Download failed. All $download_failed attempted downloads had errors.${NC}"
  echo -e "${YELLOW}Try again later or check your internet connection.${NC}"
elif [ $download_failed -gt 0 ]; then
  echo -e "${YELLOW}Download partially complete. Downloaded $download_count new APK files, but $download_failed files failed.${NC}"
else
  echo -e "${GREEN}Download complete! Downloaded $download_count new APK files to the $OUTPUT_DIR directory.${NC}"
fi

echo -e ""
echo -e "${YELLOW}To install on your Android device:${NC}"
echo -e "1. Transfer the APK file to your Android device"
echo -e "2. On your device, navigate to the APK file and tap to install"
echo -e "3. You may need to enable 'Install from Unknown Sources' in your Android settings"
echo -e ""
echo -e "${BLUE}Available APK variants:${NC}"
echo -e "• ${YELLOW}arm64-v8a${NC} - For modern Android devices (64-bit ARM)"
echo -e "• ${YELLOW}armeabi-v7a${NC} - For older Android devices (32-bit ARM)"
echo -e ""
if [ -n "$latest_version" ]; then
  echo -e "${GREEN}Current version: v$latest_version${NC}"
else
  echo -e "${GREEN}Current version: $latest_android_tag${NC}" 