#!/usr/bin/env bash
# --------------------------------------------------------------------
# WaterBee Android App Releaser
# This script releases Android app to GitHub with correct version tags
# --------------------------------------------------------------------
set -euo pipefail

# Configuration
GITHUB_REPO="sysolab/plantomio_fw"
ANDROID_APP_DIR="android_app"
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
TEMP_DIR="/tmp/waterbee_app_release"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check dependencies
check_dependencies() {
  echo -e "${BLUE}Checking dependencies...${NC}"
  
  # Check for GitHub CLI
  if command -v gh &> /dev/null; then
    echo -e "${GREEN}GitHub CLI found.${NC}"
    USE_GH_CLI=1
  else
    echo -e "${YELLOW}GitHub CLI not found. Falling back to API method.${NC}"
    USE_GH_CLI=0
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
      echo -e "${RED}Error: curl is required but not installed.${NC}"
      exit 1
    fi
    
    # Check for GitHub token when using API
    if [ -z "$GITHUB_TOKEN" ]; then
      echo -e "${RED}Error: GITHUB_TOKEN environment variable is not set.${NC}"
      echo -e "${YELLOW}Please set it using: export GITHUB_TOKEN=your_token${NC}"
      exit 1
    fi
  fi
  
  # Check for jq if using API method
  if [ "$USE_GH_CLI" -eq 0 ] && ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo -e "${YELLOW}Please install jq:${NC}"
    echo -e "  - macOS: brew install jq"
    echo -e "  - Ubuntu/Debian: sudo apt install jq"
    exit 1
  fi
}

# Function to find APK files and extract the latest version
find_latest_apk_version() {
  echo -e "${BLUE}Looking for APK files in $ANDROID_APP_DIR...${NC}"
  
  if [ ! -d "$ANDROID_APP_DIR" ]; then
    echo -e "${RED}Error: Android app directory not found. Please check if $ANDROID_APP_DIR exists.${NC}"
    exit 1
  fi
  
  # Find all APK files
  APK_FILES=()
  while IFS= read -r -d '' file; do
    APK_FILES+=("$file")
  done < <(find "$ANDROID_APP_DIR" -name "*.apk" -print0)
  
  # Check if any APK files were found
  if [ ${#APK_FILES[@]} -eq 0 ]; then
    echo -e "${RED}Error: No APK files found in $ANDROID_APP_DIR${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Found ${#APK_FILES[@]} APK files${NC}"
  
  # Extract all versions from APK filenames and store in an array
  ALL_VERSIONS=()
  
  for apk in "${APK_FILES[@]}"; do
    filename=$(basename "$apk")
    
    # Try various version patterns
    if [[ $filename =~ v([0-9]+\.[0-9]+\.[0-9]+) ]]; then
      version="${BASH_REMATCH[1]}"
      ALL_VERSIONS+=("$version")
    elif [[ $filename =~ _([0-9]+\.[0-9]+\.[0-9]+)_ ]]; then
      version="${BASH_REMATCH[1]}"
      ALL_VERSIONS+=("$version")
    elif [[ $filename =~ -([0-9]+\.[0-9]+\.[0-9]+)- ]]; then
      version="${BASH_REMATCH[1]}"
      ALL_VERSIONS+=("$version")
    fi
  done
  
  # If no versions were found, ask for manual input
  if [ ${#ALL_VERSIONS[@]} -eq 0 ]; then
    echo -e "${YELLOW}Could not automatically determine app version from filenames.${NC}"
    echo -e "${YELLOW}Please enter the app version manually (e.g., 1.0.0):${NC}"
    read -r APP_VERSION
    
    if [ -z "$APP_VERSION" ]; then
      echo -e "${RED}Error: App version cannot be empty${NC}"
      exit 1
    fi
  else
    # Sort versions and get the latest
    IFS=$'\n' SORTED_VERSIONS=($(sort -V <<<"${ALL_VERSIONS[*]}"))
    unset IFS
    
    # Get the latest version
    APP_VERSION="${SORTED_VERSIONS[${#SORTED_VERSIONS[@]}-1]}"
    
    echo -e "${GREEN}Detected latest version: $APP_VERSION${NC}"
    
    # Ask for confirmation
    echo -e "${YELLOW}Is this the correct version? (y/n)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Please enter the correct app version:${NC}"
      read -r APP_VERSION
      if [ -z "$APP_VERSION" ]; then
        echo -e "${RED}Error: App version cannot be empty${NC}"
        exit 1
      fi
    fi
  fi
  
  # Set release tag
  RELEASE_TAG="android-v${APP_VERSION}"
  echo -e "${GREEN}Using release tag: $RELEASE_TAG${NC}"
  
  # Only select APK files with the latest version
  LATEST_APK_FILES=()
  
  for apk in "${APK_FILES[@]}"; do
    filename=$(basename "$apk")
    
    if [[ $filename =~ v$APP_VERSION || $filename =~ _$APP_VERSION_ || $filename =~ -$APP_VERSION- ]]; then
      LATEST_APK_FILES+=("$apk")
    fi
  done
  
  echo -e "${GREEN}Found ${#LATEST_APK_FILES[@]} APK files for version $APP_VERSION${NC}"
  
  # Check if APK files for the latest version were found
  if [ ${#LATEST_APK_FILES[@]} -eq 0 ]; then
    echo -e "${RED}Error: No APK files found for version $APP_VERSION${NC}"
    exit 1
  fi
}

# Function to prepare release artifacts
prepare_release_artifacts() {
  echo -e "${BLUE}Preparing release artifacts...${NC}"
  
  # Create temp directory
  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"
  
  # Check if release already exists
  if [ "$USE_GH_CLI" -eq 1 ]; then
    if gh release view "$RELEASE_TAG" --repo "$GITHUB_REPO" &> /dev/null; then
      echo -e "${YELLOW}Release $RELEASE_TAG already exists!${NC}"
      echo -e "${YELLOW}Would you like to delete it and recreate? (y/n)${NC}"
      read -r response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deleting existing release...${NC}"
        gh release delete "$RELEASE_TAG" --repo "$GITHUB_REPO" --yes
      else
        echo -e "${YELLOW}Release operation cancelled.${NC}"
        exit 0
      fi
    fi
  else
    # Check using the GitHub API
    if curl -s -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_REPO/releases/tags/$RELEASE_TAG" | \
      grep -q "\"tag_name\": \"$RELEASE_TAG\""; then
      echo -e "${YELLOW}Release $RELEASE_TAG already exists!${NC}"
      echo -e "${YELLOW}Would you like to delete it and recreate? (y/n)${NC}"
      read -r response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deleting existing release...${NC}"
        # Get release ID
        release_id=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
          "https://api.github.com/repos/$GITHUB_REPO/releases/tags/$RELEASE_TAG" | \
          jq -r '.id')
        
        # Delete the release
        curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
          "https://api.github.com/repos/$GITHUB_REPO/releases/$release_id"
        
        # Delete the tag
        curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
          "https://api.github.com/repos/$GITHUB_REPO/git/refs/tags/$RELEASE_TAG"
      else
        echo -e "${YELLOW}Release operation cancelled.${NC}"
        exit 0
      fi
    fi
  fi
  
  # Create release notes
  RELEASE_NOTES="$TEMP_DIR/RELEASE_NOTES.md"
  
  echo "# WaterBee Android App v${APP_VERSION}" > "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  echo "## Release Date" >> "$RELEASE_NOTES"
  echo "$(date +'%B %d, %Y')" >> "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  echo "## APK Files" >> "$RELEASE_NOTES"
  
  # Copy individual APK files to temp dir and add them to release notes
  echo -e "${BLUE}Preparing APK files for version $APP_VERSION...${NC}"
  for apk in "${LATEST_APK_FILES[@]}"; do
    filename=$(basename "$apk")
    cp "$apk" "$TEMP_DIR/$filename"
    
    # Add description based on filename patterns
    if [[ $filename == *"arm64"* ]]; then
      echo "- **ARM64 Variant**: $filename - For modern ARM64 devices (most Android phones)" >> "$RELEASE_NOTES"
    elif [[ $filename == *"armeabi"* ]]; then
      echo "- **ARM32 Variant**: $filename - For older ARM32 devices" >> "$RELEASE_NOTES"
    elif [[ $filename == *"universal"* || $filename == *"all"* ]]; then
      echo "- **Universal Variant**: $filename - Compatible with all Android devices (larger size)" >> "$RELEASE_NOTES"
    elif [[ $filename == *"debug"* ]]; then
      echo "- **Debug Variant**: $filename - For development and testing (includes logging)" >> "$RELEASE_NOTES"
    else
      echo "- $filename" >> "$RELEASE_NOTES"
    fi
  done
  
  # Complete release notes
  echo "" >> "$RELEASE_NOTES"
  echo "## Installation Instructions" >> "$RELEASE_NOTES"
  echo "1. Download the appropriate APK file for your device" >> "$RELEASE_NOTES"
  echo "2. Transfer the APK file to your Android device" >> "$RELEASE_NOTES"
  echo "3. On your device, tap the APK file to install it" >> "$RELEASE_NOTES"
  echo "4. If prompted, enable 'Install from Unknown Sources' in your security settings" >> "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  echo "## APK Variants" >> "$RELEASE_NOTES"
  echo "- **ARM64**: For modern Android devices (64-bit ARM)" >> "$RELEASE_NOTES"
  echo "- **ARM32/armeabi**: For older Android devices (32-bit ARM)" >> "$RELEASE_NOTES"
  echo "- **Universal**: Works on any Android device (larger file size)" >> "$RELEASE_NOTES"
  echo "- **Debug**: For development and testing (includes logging)" >> "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  echo "## System Requirements" >> "$RELEASE_NOTES"
  echo "- Android 8.0 (Oreo) or higher" >> "$RELEASE_NOTES"
  echo "- Bluetooth Low Energy (BLE) support" >> "$RELEASE_NOTES"
  echo "- Location permissions for BLE scanning" >> "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  
  echo -e "${BLUE}Release artifacts prepared successfully.${NC}"
}

# Function to create GitHub release
create_github_release() {
  echo -e "${BLUE}Creating GitHub release...${NC}"
  
  if [ "$USE_GH_CLI" -eq 1 ]; then
    # Create release using GitHub CLI
    echo -e "${BLUE}Creating release $RELEASE_TAG using GitHub CLI...${NC}"
    
    gh release create "$RELEASE_TAG" \
      --repo "$GITHUB_REPO" \
      --title "WaterBee Android App v${APP_VERSION}" \
      --notes-file "$RELEASE_NOTES"
    
    # Upload all APK files for the latest version
    for apk in "$TEMP_DIR"/*.apk; do
      if [ -f "$apk" ]; then
        filename=$(basename "$apk")
        echo -e "${BLUE}Uploading $filename...${NC}"
        gh release upload "$RELEASE_TAG" "$apk" --repo "$GITHUB_REPO"
      fi
    done
  else
    # Create release using GitHub API
    echo -e "${BLUE}Creating release $RELEASE_TAG using GitHub API...${NC}"
    
    # Read release notes content
    NOTES_CONTENT=$(cat "$RELEASE_NOTES")
    
    # Create the release
    release_response=$(curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"tag_name\": \"$RELEASE_TAG\",
        \"name\": \"WaterBee Android App v${APP_VERSION}\",
        \"body\": $(echo "$NOTES_CONTENT" | jq -s -R .),
        \"draft\": false,
        \"prerelease\": false
      }" \
      "https://api.github.com/repos/$GITHUB_REPO/releases")
    
    # Extract the upload URL
    upload_url=$(echo "$release_response" | jq -r '.upload_url' | sed 's/{.*}//')
    
    if [ -z "$upload_url" ] || [ "$upload_url" == "null" ]; then
      echo -e "${RED}Failed to create release. Response: $release_response${NC}"
      exit 1
    fi
    
    # Upload APK files for the latest version
    for apk in "$TEMP_DIR"/*.apk; do
      if [ -f "$apk" ]; then
        filename=$(basename "$apk")
        echo -e "${BLUE}Uploading $filename...${NC}"
        curl -s -X POST \
          -H "Authorization: token $GITHUB_TOKEN" \
          -H "Content-Type: application/vnd.android.package-archive" \
          --data-binary @"$apk" \
          "${upload_url}?name=$filename"
      fi
    done
  fi
  
  echo -e "${GREEN}GitHub release created successfully!${NC}"
  
  # Print release URL
  if [ "$USE_GH_CLI" -eq 1 ]; then
    release_url=$(gh release view "$RELEASE_TAG" --repo "$GITHUB_REPO" --json url -q .url)
  else
    release_url="https://github.com/$GITHUB_REPO/releases/tag/$RELEASE_TAG"
  fi
  
  echo -e "${GREEN}Release URL: $release_url${NC}"
}

# Main function
main() {
  echo -e "${BLUE}WaterBee Android App Release Tool${NC}"
  echo -e "====================================="
  
  check_dependencies
  find_latest_apk_version
  
  echo -e "${YELLOW}Ready to release Android app v${APP_VERSION} to GitHub.${NC}"
  echo -e "${YELLOW}Continue? (y/n)${NC}"
  read -r response
  
  if [[ "$response" =~ ^[Yy]$ ]]; then
    prepare_release_artifacts
    create_github_release
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}Android app release completed successfully!${NC}"
  else
    echo -e "${YELLOW}Release cancelled.${NC}"
  fi
}

# Run the main function
main 