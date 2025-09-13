#!/bin/bash

# App Store Archive Creation Script for Romanian Septica
# This script creates an archive ready for App Store submission

set -e  # Exit on any error

# Configuration
PROJECT_NAME="Septica"
SCHEME_NAME="Septica"
PROJECT_FILE="Septica.xcodeproj"
CONFIGURATION="Release"
ARCHIVE_NAME="Septica-$(date +%Y%m%d-%H%M%S)"
ARCHIVE_PATH="./Archives/${ARCHIVE_NAME}.xcarchive"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🇷🇴 Romanian Septica - App Store Archive Creator${NC}"
echo "=================================================="

# Check if we're in the right directory
if [[ ! -f "$PROJECT_FILE/project.pbxproj" ]]; then
    echo -e "${RED}❌ Error: Septica.xcodeproj not found in current directory${NC}"
    echo "Please run this script from the Septica project root directory"
    exit 1
fi

echo -e "${YELLOW}📋 Pre-Archive Validation${NC}"
echo "Checking project configuration..."

# Validate deployment target
DEPLOYMENT_TARGET=$(xcodebuild -project $PROJECT_FILE -showBuildSettings -configuration $CONFIGURATION | grep IPHONEOS_DEPLOYMENT_TARGET | head -1 | awk '{print $3}')
echo "iOS Deployment Target: $DEPLOYMENT_TARGET"

if [[ "$DEPLOYMENT_TARGET" != "18.0" ]]; then
    echo -e "${RED}❌ Warning: Deployment target is $DEPLOYMENT_TARGET, expected 18.0${NC}"
fi

# Validate Swift version
SWIFT_VERSION=$(xcodebuild -project $PROJECT_FILE -showBuildSettings -configuration $CONFIGURATION | grep SWIFT_VERSION | head -1 | awk '{print $3}')
echo "Swift Version: $SWIFT_VERSION"

# Check bundle identifier
BUNDLE_ID=$(xcodebuild -project $PROJECT_FILE -showBuildSettings -configuration $CONFIGURATION | grep PRODUCT_BUNDLE_IDENTIFIER | head -1 | awk '{print $3}')
echo "Bundle Identifier: $BUNDLE_ID"

# Check marketing version
MARKETING_VERSION=$(xcodebuild -project $PROJECT_FILE -showBuildSettings -configuration $CONFIGURATION | grep MARKETING_VERSION | head -1 | awk '{print $3}')
echo "Marketing Version: $MARKETING_VERSION"

echo ""
echo -e "${YELLOW}🧹 Cleaning Previous Builds${NC}"
xcodebuild clean -project $PROJECT_FILE -scheme $SCHEME_NAME -configuration $CONFIGURATION

echo ""
echo -e "${YELLOW}🏗️  Building for Release${NC}"
echo "This may take a few minutes..."

# Build for testing first
xcodebuild build -project $PROJECT_FILE -scheme $SCHEME_NAME -configuration $CONFIGURATION -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

BUILD_STATUS=$?
if [[ $BUILD_STATUS -ne 0 ]]; then
    echo -e "${RED}❌ Build failed with status $BUILD_STATUS${NC}"
    echo "Please fix build errors before creating archive"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"

echo ""
echo -e "${YELLOW}📦 Creating App Store Archive${NC}"

# Create archives directory if it doesn't exist
mkdir -p Archives

# Create archive for generic iOS device (required for App Store)
xcodebuild archive \
    -project $PROJECT_FILE \
    -scheme $SCHEME_NAME \
    -configuration $CONFIGURATION \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates

ARCHIVE_STATUS=$?
if [[ $ARCHIVE_STATUS -ne 0 ]]; then
    echo -e "${RED}❌ Archive creation failed with status $ARCHIVE_STATUS${NC}"
    echo "Common issues:"
    echo "1. Code signing issues - check Apple Developer account"
    echo "2. Missing provisioning profile"
    echo "3. Build errors - check Xcode for details"
    exit 1
fi

echo -e "${GREEN}✅ Archive created successfully${NC}"
echo "Archive location: $ARCHIVE_PATH"

echo ""
echo -e "${YELLOW}🔍 Archive Validation${NC}"

# Validate the archive
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist ExportOptions.plist \
    -exportPath "./Export" \
    -validateOnly

VALIDATION_STATUS=$?
if [[ $VALIDATION_STATUS -ne 0 ]]; then
    echo -e "${YELLOW}⚠️  Archive validation had issues (status $VALIDATION_STATUS)${NC}"
    echo "This may indicate signing or configuration problems"
    echo "The archive was created but may have issues for App Store submission"
else
    echo -e "${GREEN}✅ Archive validation passed${NC}"
fi

echo ""
echo -e "${BLUE}📊 Archive Information${NC}"
echo "======================================="
echo "Project: $PROJECT_NAME"
echo "Archive: $ARCHIVE_NAME.xcarchive"
echo "Bundle ID: $BUNDLE_ID"
echo "Version: $MARKETING_VERSION"
echo "Configuration: $CONFIGURATION"
echo "Date: $(date)"

# Show archive contents
if [[ -d "$ARCHIVE_PATH" ]]; then
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    echo "Archive Size: $ARCHIVE_SIZE"
    
    # Check if dSYMs are included
    if [[ -d "$ARCHIVE_PATH/dSYMs" ]]; then
        DSYM_COUNT=$(find "$ARCHIVE_PATH/dSYMs" -name "*.dSYM" | wc -l)
        echo "Debug Symbols: $DSYM_COUNT dSYM files included"
    fi
fi

echo ""
echo -e "${GREEN}🎉 Archive Ready for App Store Submission${NC}"
echo ""
echo "Next Steps:"
echo "1. Open Xcode Organizer (Window > Organizer)"
echo "2. Select the Archives tab"
echo "3. Find your archive: $ARCHIVE_NAME"
echo "4. Click 'Distribute App'"
echo "5. Choose 'App Store Connect'"
echo "6. Follow the upload wizard"
echo ""
echo "Alternative: Upload using Xcode command line:"
echo "xcodebuild -exportArchive \\"
echo "    -archivePath '$ARCHIVE_PATH' \\"
echo "    -exportOptionsPlist ExportOptions.plist \\"
echo "    -exportPath './Export'"
echo ""
echo -e "${BLUE}📝 Don't forget to complete:${NC}"
echo "• App Store screenshots (see AppStoreScreenshots.md)"
echo "• App icons (see AppIconDesignGuide.md)"
echo "• App Store Connect metadata setup"
echo "• Privacy policy hosting (see PrivacyPolicy.md)"
echo ""
echo -e "${YELLOW}🇷🇴 Good luck with your Romanian Septica app submission!${NC}"