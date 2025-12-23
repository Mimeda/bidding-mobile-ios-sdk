#!/bin/bash

# Build XCFramework script for MimedaSDK
# This script builds the SDK for both iOS device and simulator, then combines them into an XCFramework

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCHEME="bidding-mobile-ios-sdk"
PROJECT="bidding-mobile-ios-sdk.xcodeproj"
FRAMEWORK_NAME="bidding_mobile_ios_sdk"
OUTPUT_DIR="build"
XCFRAMEWORK_NAME="${FRAMEWORK_NAME}.xcframework"
ZIP_NAME="${FRAMEWORK_NAME}.xcframework.zip"

echo -e "${GREEN}🚀 Building XCFramework for ${SCHEME}${NC}"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "${OUTPUT_DIR}"
rm -rf "${XCFRAMEWORK_NAME}"
rm -rf "${ZIP_NAME}"
mkdir -p "${OUTPUT_DIR}"

# Build for iOS Device
echo -e "${GREEN}📱 Building for iOS Device...${NC}"
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "generic/platform=iOS" \
    -archivePath "${OUTPUT_DIR}/ios.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Build for iOS Simulator
echo -e "${GREEN}📱 Building for iOS Simulator...${NC}"
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${OUTPUT_DIR}/ios-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Find framework paths
IOS_FRAMEWORK=$(find "${OUTPUT_DIR}/ios.xcarchive" -name "${FRAMEWORK_NAME}.framework" -type d | head -1)
SIM_FRAMEWORK=$(find "${OUTPUT_DIR}/ios-simulator.xcarchive" -name "${FRAMEWORK_NAME}.framework" -type d | head -1)

if [ -z "$IOS_FRAMEWORK" ] || [ -z "$SIM_FRAMEWORK" ]; then
    echo -e "${RED}❌ Framework not found in archives${NC}"
    echo "iOS Framework: ${IOS_FRAMEWORK}"
    echo "Simulator Framework: ${SIM_FRAMEWORK}"
    exit 1
fi

# Create XCFramework
echo -e "${GREEN}📦 Creating XCFramework...${NC}"
xcodebuild -create-xcframework \
    -framework "${IOS_FRAMEWORK}" \
    -framework "${SIM_FRAMEWORK}" \
    -output "${XCFRAMEWORK_NAME}"

# Create ZIP
echo -e "${GREEN}📦 Creating ZIP archive...${NC}"
zip -r "${ZIP_NAME}" "${XCFRAMEWORK_NAME}" > /dev/null

# Verify
if [ -d "${XCFRAMEWORK_NAME}" ] && [ -f "${ZIP_NAME}" ]; then
    echo -e "${GREEN}✅ XCFramework created successfully!${NC}"
    echo -e "${GREEN}   Framework: ${XCFRAMEWORK_NAME}${NC}"
    echo -e "${GREEN}   ZIP: ${ZIP_NAME}${NC}"
    
    # Show size
    ZIP_SIZE=$(du -h "${ZIP_NAME}" | cut -f1)
    echo -e "${GREEN}   Size: ${ZIP_SIZE}${NC}"
else
    echo -e "${RED}❌ Failed to create XCFramework${NC}"
    exit 1
fi

