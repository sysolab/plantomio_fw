#!/bin/bash

echo "Downloading WaterBee Android APKs from GitHub releases..."
mkdir -p android_app

# Set the GitHub release URL
RELEASE_URL="https://github.com/sysolab/plantomio_fw/releases/download/v1.6.0"

# Download all APK variants
echo "Downloading universal release APK..."
curl -L "${RELEASE_URL}/waterBee_universal-release_v1.6.0.apk" -o android_app/waterBee_universal-release_v1.6.0.apk

echo "Downloading ARM64 release APK..."
curl -L "${RELEASE_URL}/waterBee_arm64-v8a-release_v1.6.0.apk" -o android_app/waterBee_arm64-v8a-release_v1.6.0.apk

echo "Downloading ARMv7 release APK..."
curl -L "${RELEASE_URL}/waterBee_armeabi-v7a-release_v1.6.0.apk" -o android_app/waterBee_armeabi-v7a-release_v1.6.0.apk

echo "Downloading debug APK..."
curl -L "${RELEASE_URL}/waterBee_debug_v1.6.0.apk" -o android_app/waterBee_debug_v1.6.0.apk

echo "Download complete! APKs are available in the android_app directory." 