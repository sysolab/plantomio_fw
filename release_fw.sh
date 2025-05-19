#!/usr/bin/env bash
# --------------------------------------------------------------------
# WaterBee Firmware Releaser
# This script releases firmware to GitHub with correct version tags
# --------------------------------------------------------------------
set -euo pipefail

# Configuration
GITHUB_REPO="sysolab/plantomio_fw"
DEBUG_FIRMWARE_DIR="firmware/debug"
RELEASE_FIRMWARE_DIR="firmware/release"
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
TEMP_DIR="/tmp/waterbee_release"

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
  
  # Check for zip
  if ! command -v zip &> /dev/null; then
    echo -e "${RED}Error: zip is required but not installed.${NC}"
    exit 1
  fi
}

# Function to find the latest firmware version
find_latest_firmware_version() {
  echo -e "${BLUE}Finding firmware versions...${NC}"
  
  # Arrays to store all found versions
  local all_debug_versions=()
  local all_release_versions=()
  
  # Find debug firmware versions
  if [ -d "$DEBUG_FIRMWARE_DIR" ]; then
    echo -e "${BLUE}Checking debug firmware directory...${NC}"
    for dir in "$DEBUG_FIRMWARE_DIR"/*; do
      if [ -d "$dir" ]; then
        base_name=$(basename "$dir")
        # Extract version from the directory name (format: waterBee_X.Y.Z_debug_merged)
        if [[ $base_name =~ waterBee_([0-9]+\.[0-9]+\.[0-9]+)_debug_merged ]]; then
          version="${BASH_REMATCH[1]}"
          all_debug_versions+=("$version")
          echo -e "${GREEN}Found debug firmware: $base_name (v$version)${NC}"
        fi
      fi
    done
    
    # Check if any debug firmware was found
    if [ ${#all_debug_versions[@]} -eq 0 ]; then
      echo -e "${YELLOW}No debug firmware found.${NC}"
    fi
  else
    echo -e "${YELLOW}Debug firmware directory not found.${NC}"
  fi
  
  # Find release firmware versions
  if [ -d "$RELEASE_FIRMWARE_DIR" ]; then
    echo -e "${BLUE}Checking release firmware directory...${NC}"
    for dir in "$RELEASE_FIRMWARE_DIR"/*; do
      if [ -d "$dir" ]; then
        base_name=$(basename "$dir")
        # Extract version from the directory name (format: waterBee_X.Y.Z_release_merged)
        if [[ $base_name =~ waterBee_([0-9]+\.[0-9]+\.[0-9]+)_release_merged ]]; then
          version="${BASH_REMATCH[1]}"
          all_release_versions+=("$version")
          echo -e "${GREEN}Found release firmware: $base_name (v$version)${NC}"
        fi
      fi
    done
    
    # Check if any release firmware was found
    if [ ${#all_release_versions[@]} -eq 0 ]; then
      echo -e "${YELLOW}No release firmware found.${NC}"
    fi
  else
    echo -e "${YELLOW}Release firmware directory not found.${NC}"
  fi
  
  # Check if any firmware was found
  if [ ${#all_debug_versions[@]} -eq 0 ] && [ ${#all_release_versions[@]} -eq 0 ]; then
    echo -e "${RED}No firmware found in either debug or release directories.${NC}"
    exit 1
  fi
  
  # Get latest debug version
  local debug_latest=""
  if [ ${#all_debug_versions[@]} -gt 0 ]; then
    # Sort versions and get the latest
    IFS=$'\n' debug_sorted=($(sort -V <<<"${all_debug_versions[*]}"))
    unset IFS
    debug_latest="${debug_sorted[${#debug_sorted[@]}-1]}"
    echo -e "${GREEN}Latest debug firmware version: $debug_latest${NC}"
  fi
  
  # Get latest release version
  local release_latest=""
  if [ ${#all_release_versions[@]} -gt 0 ]; then
    # Sort versions and get the latest
    IFS=$'\n' release_sorted=($(sort -V <<<"${all_release_versions[*]}"))
    unset IFS
    release_latest="${release_sorted[${#release_sorted[@]}-1]}"
    echo -e "${GREEN}Latest release firmware version: $release_latest${NC}"
  fi
  
  # Determine the actual version to use (use the latest of the two)
  if [ -n "$debug_latest" ] && [ -n "$release_latest" ]; then
    # Compare versions
    if [ "$(printf '%s\n' "$debug_latest" "$release_latest" | sort -V | tail -n1)" = "$debug_latest" ]; then
      FIRMWARE_VERSION="$debug_latest"
    else
      FIRMWARE_VERSION="$release_latest"
    fi
  elif [ -n "$debug_latest" ]; then
    FIRMWARE_VERSION="$debug_latest"
  elif [ -n "$release_latest" ]; then
    FIRMWARE_VERSION="$release_latest"
  else
    echo -e "${RED}No firmware versions found.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Using latest firmware version: $FIRMWARE_VERSION${NC}"
  
  # Set paths for the latest version only
  DEBUG_DIR="$DEBUG_FIRMWARE_DIR/waterBee_${FIRMWARE_VERSION}_debug_merged"
  RELEASE_DIR="$RELEASE_FIRMWARE_DIR/waterBee_${FIRMWARE_VERSION}_release_merged"
  
  # Verify that at least one of the directories exists
  if [ ! -d "$DEBUG_DIR" ] && [ ! -d "$RELEASE_DIR" ]; then
    echo -e "${RED}Error: Could not find firmware directories for version $FIRMWARE_VERSION${NC}"
    exit 1
  fi
  
  # Check which variants are available for the latest version
  HAS_DEBUG_VARIANT=false
  HAS_RELEASE_VARIANT=false
  
  if [ -d "$DEBUG_DIR" ]; then
    HAS_DEBUG_VARIANT=true
    echo -e "${GREEN}Debug variant for version $FIRMWARE_VERSION is available${NC}"
  else
    echo -e "${YELLOW}Debug variant for version $FIRMWARE_VERSION is not available${NC}"
  fi
  
  if [ -d "$RELEASE_DIR" ]; then
    HAS_RELEASE_VARIANT=true
    echo -e "${GREEN}Release variant for version $FIRMWARE_VERSION is available${NC}"
  else
    echo -e "${YELLOW}Release variant for version $FIRMWARE_VERSION is not available${NC}"
  fi
  
  # Make sure at least one variant is available
  if [ "$HAS_DEBUG_VARIANT" = false ] && [ "$HAS_RELEASE_VARIANT" = false ]; then
    echo -e "${RED}Error: No firmware variants found for version $FIRMWARE_VERSION${NC}"
    exit 1
  fi
}

# Function to prepare release files
prepare_release_files() {
  echo -e "${BLUE}Preparing release files for version $FIRMWARE_VERSION...${NC}"
  
  # Create and clean temp directory
  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"
  
  # Create release tag
  RELEASE_TAG="firmware-v${FIRMWARE_VERSION}"
  
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
  
  # Create release notes file
  RELEASE_NOTES="$TEMP_DIR/RELEASE_NOTES.md"
  
  echo "# WaterBee Firmware v${FIRMWARE_VERSION}" > "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  echo "## Release Date" >> "$RELEASE_NOTES"
  echo "$(date +'%B %d, %Y')" >> "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  echo "## Included Firmware Variants" >> "$RELEASE_NOTES"
  
  # Debug firmware
  if [ "$HAS_DEBUG_VARIANT" = true ]; then
    echo "- Debug firmware (v${FIRMWARE_VERSION})" >> "$RELEASE_NOTES"
    
    # Create debug firmware zip file
    DEBUG_ZIP="$TEMP_DIR/firmware_v${FIRMWARE_VERSION}_debug.zip"
    echo -e "${BLUE}Creating debug firmware archive...${NC}"
    
    # Create zip file
    (cd "$DEBUG_DIR" && zip -r "$DEBUG_ZIP" ./)
    
    echo -e "${GREEN}Debug firmware archive created: $(basename "$DEBUG_ZIP")${NC}"
  fi
  
  # Release firmware
  if [ "$HAS_RELEASE_VARIANT" = true ]; then
    echo "- Release firmware (v${FIRMWARE_VERSION})" >> "$RELEASE_NOTES"
    
    # Create release firmware zip file
    RELEASE_ZIP="$TEMP_DIR/firmware_v${FIRMWARE_VERSION}_release.zip"
    echo -e "${BLUE}Creating release firmware archive...${NC}"
    
    # Create zip file
    (cd "$RELEASE_DIR" && zip -r "$RELEASE_ZIP" ./)
    
    echo -e "${GREEN}Release firmware archive created: $(basename "$RELEASE_ZIP")${NC}"
  fi
  
  # Complete release notes
  echo "" >> "$RELEASE_NOTES"
  echo "## Installation Instructions" >> "$RELEASE_NOTES"
  echo "1. Download the appropriate firmware zip file for your needs" >> "$RELEASE_NOTES"
  echo "2. Extract the zip file" >> "$RELEASE_NOTES"
  echo '3. Flash using the `flash_waterbee.sh` script:' >> "$RELEASE_NOTES"
  echo '   - Debug build: `./flash_waterbee.sh debug`' >> "$RELEASE_NOTES"
  echo '   - Release build: `./flash_waterbee.sh release`' >> "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  echo "## Known Issues" >> "$RELEASE_NOTES"
  echo "- None" >> "$RELEASE_NOTES"
  echo "" >> "$RELEASE_NOTES"
  
  echo -e "${BLUE}Release files prepared successfully.${NC}"
}

# Function to create GitHub release
create_github_release() {
  echo -e "${BLUE}Creating GitHub release for version $FIRMWARE_VERSION...${NC}"
  
  if [ "$USE_GH_CLI" -eq 1 ]; then
    # Create release using GitHub CLI
    echo -e "${BLUE}Creating release $RELEASE_TAG using GitHub CLI...${NC}"
    
    gh release create "$RELEASE_TAG" \
      --repo "$GITHUB_REPO" \
      --title "WaterBee Firmware v${FIRMWARE_VERSION}" \
      --notes-file "$RELEASE_NOTES"
    
    # Upload debug firmware if available
    if [ "$HAS_DEBUG_VARIANT" = true ] && [ -f "$DEBUG_ZIP" ]; then
      echo -e "${BLUE}Uploading debug firmware...${NC}"
      gh release upload "$RELEASE_TAG" "$DEBUG_ZIP" --repo "$GITHUB_REPO"
    fi
    
    # Upload release firmware if available
    if [ "$HAS_RELEASE_VARIANT" = true ] && [ -f "$RELEASE_ZIP" ]; then
      echo -e "${BLUE}Uploading release firmware...${NC}"
      gh release upload "$RELEASE_TAG" "$RELEASE_ZIP" --repo "$GITHUB_REPO"
    fi
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
        \"name\": \"WaterBee Firmware v${FIRMWARE_VERSION}\",
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
    
    # Upload debug firmware if available
    if [ "$HAS_DEBUG_VARIANT" = true ] && [ -f "$DEBUG_ZIP" ]; then
      echo -e "${BLUE}Uploading debug firmware...${NC}"
      curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/zip" \
        --data-binary @"$DEBUG_ZIP" \
        "${upload_url}?name=$(basename "$DEBUG_ZIP")"
    fi
    
    # Upload release firmware if available
    if [ "$HAS_RELEASE_VARIANT" = true ] && [ -f "$RELEASE_ZIP" ]; then
      echo -e "${BLUE}Uploading release firmware...${NC}"
      curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/zip" \
        --data-binary @"$RELEASE_ZIP" \
        "${upload_url}?name=$(basename "$RELEASE_ZIP")"
    fi
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
  echo -e "${BLUE}WaterBee Firmware Release Tool${NC}"
  echo -e "====================================="
  
  check_dependencies
  find_latest_firmware_version
  
  echo -e "${YELLOW}Ready to release firmware v${FIRMWARE_VERSION} to GitHub.${NC}"
  echo -e "${YELLOW}Continue? (y/n)${NC}"
  read -r response
  
  if [[ "$response" =~ ^[Yy]$ ]]; then
    prepare_release_files
    create_github_release
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}Firmware release completed successfully!${NC}"
  else
    echo -e "${YELLOW}Release cancelled.${NC}"
  fi
}

# Run the main function
main 