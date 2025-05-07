#!/bin/bash

# WaterBee Android App Downloader
# This script automatically downloads the latest Android APK files from GitHub releases

# Configuration
GITHUB_REPO="sysolab/plantomio_fw"
OUTPUT_DIR="android_app"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}WaterBee Android App Downloader${NC}"
echo -e "----------------------------------------"
echo -e "${YELLOW}This script will download the latest Android APK files for WaterBee.${NC}"

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

# Find latest Android app release (tag that starts with android-v)
latest_android_tag=$(echo "$releases_json" | grep -o '"tag_name": "android-v[^"]*"' | head -1 | sed 's/"tag_name": "//;s/"$//')

if [ -z "$latest_android_tag" ]; then
  echo -e "${RED}No Android app releases found on GitHub.${NC}"
  exit 1
fi

echo -e "${GREEN}Found latest Android app release: $latest_android_tag${NC}"

# Extract version number from tag (e.g., android-v1.6.0 -> v1.6.0)
app_version=$(echo "$latest_android_tag" | sed 's/android-//')

# Get asset URLs from the release
echo -e "${YELLOW}Getting download URLs for APK files...${NC}"
assets_url=$(echo "$releases_json" | grep -m 1 -A 100 "\"tag_name\": \"$latest_android_tag\"" | grep -m 1 -A 100 "\"assets\":" | grep -o "\"browser_download_url\": \"[^\"]*\.apk\"" | sed 's/"browser_download_url": "//' | sed 's/"$//')
zip_url=$(echo "$releases_json" | grep -m 1 -A 100 "\"tag_name\": \"$latest_android_tag\"" | grep -m 1 -A 100 "\"assets\":" | grep -o "\"browser_download_url\": \"[^\"]*\.zip\"" | sed 's/"browser_download_url": "//' | sed 's/"$//')

if [ -z "$assets_url" ]; then
  echo -e "${RED}No APK files found in the release.${NC}"
  exit 1
fi

# Download each APK file
echo -e "${YELLOW}Downloading APK files...${NC}"
for url in $assets_url; do
  filename=$(basename "$url")
  echo -e "${BLUE}Downloading $filename...${NC}"
  
  # Add variant descriptions
  case "$filename" in
    *arm64*)
      desc="For ARM64 devices (most modern Android phones)"
      ;;
    *armeabi*)
      desc="For ARMv7 devices (older Android phones)"
      ;;
    *universal*)
      desc="Universal version (works on all Android devices)"
      ;;
    *debug*)
      desc="Debug version with additional logging (for developers)"
      ;;
    *)
      desc=""
      ;;
  esac
  
  # Download the file
  if curl -L -s -f -o "$OUTPUT_DIR/$filename" "$url"; then
    echo -e "${GREEN}Successfully downloaded $filename${NC}"
    if [ -n "$desc" ]; then
      echo -e "  ${YELLOW}$desc${NC}"
    fi
  else
    echo -e "${RED}Failed to download $filename${NC}"
  fi
done

# Download ZIP bundle if available
if [ -n "$zip_url" ]; then
  zip_filename=$(basename "$zip_url")
  echo -e "${BLUE}Downloading $zip_filename (complete bundle)...${NC}"
  
  if curl -L -s -f -o "$OUTPUT_DIR/$zip_filename" "$zip_url"; then
    echo -e "${GREEN}Successfully downloaded $zip_filename${NC}"
  else
    echo -e "${RED}Failed to download $zip_filename${NC}"
  fi
fi

echo -e "----------------------------------------"
echo -e "${GREEN}Download complete! APK files are available in the $OUTPUT_DIR directory.${NC}"
echo -e ""
echo -e "${YELLOW}To install on your Android device:${NC}"
echo -e "1. Transfer the APK file to your Android device"
echo -e "2. On your device, navigate to the APK file and tap to install"
echo -e "3. You may need to enable 'Install from Unknown Sources' in your Android settings"
echo -e ""
echo -e "${BLUE}Available APK variants:${NC}"
echo -e "• ${YELLOW}arm64-v8a${NC} - For modern Android devices (64-bit ARM)"
echo -e "• ${YELLOW}armeabi-v7a${NC} - For older Android devices (32-bit ARM)"
echo -e "• ${YELLOW}universal${NC} - Works on any Android device (larger file size)"
echo -e "• ${YELLOW}debug${NC} - For development and testing (includes logging)"
echo -e ""
echo -e "${GREEN}Current version: $app_version${NC}" 