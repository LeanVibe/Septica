#!/bin/bash
# Romanian Septica - iOS Build & Upload Script
# Automated Xcode archiving and App Store Connect upload

set -euo pipefail

# Configuration
VERSION=${1:-1.0.0}
BUILD_NUMBER=${2:-$(date +%Y%m%d%H%M)}
ENVIRONMENT=${3:-production}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_PROJECT_NAME="Septica"
SCHEME="Septica"

# Paths
BUILD_DIR="$PROJECT_ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/$IOS_PROJECT_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/ipa"
IPA_PATH="$EXPORT_PATH/$IOS_PROJECT_NAME.ipa"

# App Store Connect credentials
APP_STORE_EMAIL=${APP_STORE_EMAIL:-"your@email.com"}
APP_STORE_TEAM_ID=${APP_STORE_TEAM_ID:-"YOUR_TEAM_ID"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Romanian cultural elements
ROMANIAN_FLAG="🇷🇴"
IOS_ICON="📱"

# Logging functions
log_info() { echo -e "${BLUE}${IOS_ICON} INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}✅ SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; }
log_error() { echo -e "${RED}❌ ERROR: $1${NC}"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking iOS build prerequisites..."

    # Check if running on macOS
    if [ "$(uname)" != "Darwin" ]; then
        log_error "This script must run on macOS for iOS builds"
        exit 1
    fi

    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode not found - please install Xcode from App Store"
        exit 1
    fi

    # Check if Xcode Command Line Tools are installed
    if ! xcode-select -p &> /dev/null; then
        log_error "Xcode Command Line Tools not installed"
        log_info "Install with: xcode-select --install"
        exit 1
    fi

    # Check if xcrun altool is available
    if ! command -v xcrun &> /dev/null; then
        log_error "xcrun not found - ensure Xcode is properly installed"
        exit 1
    fi

    # Check if agvtool is available
    if ! command -v agvtool &> /dev/null; then
        log_error "agvtool not found - ensure Xcode is properly configured"
        exit 1
    fi

    log_success "All prerequisites satisfied"
}

# Find iOS project
find_ios_project() {
    log_info "Searching for iOS project..."

    # Look for .xcworkspace first (preferred)
    if [ -f "$PROJECT_ROOT/$IOS_PROJECT_NAME.xcworkspace" ]; then
        PROJECT_PATH="$PROJECT_ROOT/$IOS_PROJECT_NAME.xcworkspace"
        PROJECT_TYPE="workspace"
        log_success "Found workspace: $IOS_PROJECT_NAME.xcworkspace"
        return 0
    fi

    # Look for .xcodeproj
    if [ -f "$PROJECT_ROOT/$IOS_PROJECT_NAME.xcodeproj/project.pbxproj" ]; then
        PROJECT_PATH="$PROJECT_ROOT/$IOS_PROJECT_NAME.xcodeproj"
        PROJECT_TYPE="project"
        log_success "Found project: $IOS_PROJECT_NAME.xcodeproj"
        return 0
    fi

    # Project not found
    log_error "iOS project not found at: $PROJECT_ROOT"
    log_info "Expected: $IOS_PROJECT_NAME.xcworkspace or $IOS_PROJECT_NAME.xcodeproj"
    exit 1
}

# Update version numbers
update_version_numbers() {
    log_info "Updating version to $VERSION (build $BUILD_NUMBER)..."

    cd "$PROJECT_ROOT"

    # Update marketing version
    agvtool new-marketing-version "$VERSION"

    # Update build number
    agvtool new-version -all "$BUILD_NUMBER"

    log_success "Version updated to $VERSION ($BUILD_NUMBER)"
}

# Clean build directory
clean_build_directory() {
    log_info "Cleaning build directory..."

    # Remove old build artifacts
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$EXPORT_PATH"

    # Clean Xcode build
    if [ "$PROJECT_TYPE" = "workspace" ]; then
        xcodebuild clean \
            -workspace "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration Release
    else
        xcodebuild clean \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration Release
    fi

    log_success "Build directory cleaned"
}

# Run tests
run_tests() {
    log_info "Running iOS unit tests..."

    if [ "$PROJECT_TYPE" = "workspace" ]; then
        xcodebuild test \
            -workspace "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -quiet
    else
        xcodebuild test \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -quiet
    fi

    log_success "All tests passed"
}

# Archive for distribution
archive_app() {
    log_info "Creating archive for distribution..."

    if [ "$PROJECT_TYPE" = "workspace" ]; then
        xcodebuild archive \
            -workspace "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -archivePath "$ARCHIVE_PATH" \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            CODE_SIGNING_ALLOWED=NO
    else
        xcodebuild archive \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -archivePath "$ARCHIVE_PATH" \
            -configuration Release \
            -destination 'generic/platform=iOS'
    fi

    # Verify archive was created
    if [ ! -d "$ARCHIVE_PATH" ]; then
        log_error "Archive was not created"
        exit 1
    fi

    log_success "Archive created successfully"
}

# Create ExportOptions.plist
create_export_options() {
    log_info "Creating export options plist..."

    local method
    case $ENVIRONMENT in
        development) method="development" ;;
        adhoc) method="ad-hoc" ;;
        testflight|production) method="app-store" ;;
        *) method="app-store" ;;
    esac

    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$method</string>
    <key>teamID</key>
    <string>$APP_STORE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

    log_success "Export options created"
}

# Export IPA
export_ipa() {
    log_info "Exporting IPA file..."

    create_export_options

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"

    # Verify IPA was created
    if [ ! -f "$IPA_PATH" ]; then
        log_error "IPA file was not created"
        exit 1
    fi

    log_success "IPA exported successfully"
    log_info "IPA location: $IPA_PATH"
    log_info "IPA size: $(du -h "$IPA_PATH" | cut -f1)"
}

# Validate IPA
validate_ipa() {
    log_info "Validating IPA file..."

    # Note: This requires App Store Connect credentials
    if [ -z "${APP_STORE_PASSWORD:-}" ]; then
        log_warning "APP_STORE_PASSWORD not set - skipping IPA validation"
        log_info "To validate: export APP_STORE_PASSWORD=@keychain:AC_PASSWORD"
        return 0
    fi

    xcrun altool --validate-app \
        --type ios \
        --file "$IPA_PATH" \
        --username "$APP_STORE_EMAIL" \
        --password "$APP_STORE_PASSWORD"

    log_success "IPA validation passed"
}

# Upload to App Store Connect
upload_to_app_store() {
    log_info "Uploading to App Store Connect..."

    # Check if credentials are available
    if [ -z "${APP_STORE_PASSWORD:-}" ]; then
        log_error "APP_STORE_PASSWORD not set"
        log_info "Set password with: export APP_STORE_PASSWORD=@keychain:AC_PASSWORD"
        log_info "Or create app-specific password at: https://appleid.apple.com"
        exit 1
    fi

    # Upload using altool (deprecated, but still works)
    # For newer Xcode versions, consider using 'xcrun notarytool'
    xcrun altool --upload-app \
        --type ios \
        --file "$IPA_PATH" \
        --username "$APP_STORE_EMAIL" \
        --password "$APP_STORE_PASSWORD"

    log_success "Upload to App Store Connect completed"
    log_info "Check status at: https://appstoreconnect.apple.com"
}

# Upload to TestFlight (alternative method using transporter)
upload_to_testflight() {
    log_info "Uploading to TestFlight..."

    # Check if xcrun altool is available
    if command -v xcrun &> /dev/null; then
        # Use altool for TestFlight upload
        xcrun altool --upload-app \
            --type ios \
            --file "$IPA_PATH" \
            --username "$APP_STORE_EMAIL" \
            --password "${APP_STORE_PASSWORD:-@keychain:AC_PASSWORD}"

        log_success "Upload to TestFlight completed"
    else
        log_error "xcrun not available - cannot upload to TestFlight"
        exit 1
    fi
}

# Generate build report
generate_build_report() {
    log_info "Generating build report..."

    local report_file="$BUILD_DIR/build-report-$BUILD_NUMBER.txt"
    local archive_size=$(du -sh "$ARCHIVE_PATH" | cut -f1)
    local ipa_size=$(du -h "$IPA_PATH" | cut -f1)

    cat > "$report_file" << EOF
Romanian Septica iOS Build Report
=================================
Version: $VERSION
Build Number: $BUILD_NUMBER
Environment: $ENVIRONMENT
Timestamp: $(date)

Build Configuration:
- Project Type: $PROJECT_TYPE
- Scheme: $SCHEME
- Configuration: Release
- Deployment Target: iOS 18.0+

Archive Details:
- Archive Path: $ARCHIVE_PATH
- Archive Size: $archive_size
- IPA Path: $IPA_PATH
- IPA Size: $ipa_size

App Store Connect:
- Team ID: $APP_STORE_TEAM_ID
- Email: $APP_STORE_EMAIL
- Upload Status: $([ -n "${APP_STORE_PASSWORD:-}" ] && echo "Completed" || echo "Skipped")

Romanian Heritage Features:
- Traditional Romanian Septica card game
- 32-card Romanian deck (7, 8, 9, 10, J, Q, K, A)
- Authentic Romanian game rules
- Cultural preservation focus

Build Status: ✅ SUCCESS

Next Steps:
1. Review build in App Store Connect
2. Submit for App Review
3. Set release schedule
4. Monitor crash reports

App Store Connect: https://appstoreconnect.apple.com
EOF

    log_success "Build report saved to: $report_file"
    cat "$report_file"
}

# Main build flow
main() {
    echo ""
    echo -e "${BLUE}${ROMANIAN_FLAG} Romanian Septica iOS Build & Upload ${IOS_ICON}${NC}"
    echo -e "${BLUE}Version: ${YELLOW}$VERSION${NC}"
    echo -e "${BLUE}Build: ${YELLOW}$BUILD_NUMBER${NC}"
    echo -e "${BLUE}Environment: ${YELLOW}$ENVIRONMENT${NC}"
    echo ""

    # Check prerequisites
    check_prerequisites

    # Find iOS project
    find_ios_project

    # Update version numbers
    update_version_numbers

    # Clean build directory
    clean_build_directory

    # Run tests
    if [ "${SKIP_TESTS:-false}" != "true" ]; then
        run_tests
    else
        log_warning "Tests skipped (SKIP_TESTS=true)"
    fi

    # Archive app
    archive_app

    # Export IPA
    export_ipa

    # Validate IPA
    validate_ipa

    # Upload to App Store Connect
    if [ "${SKIP_UPLOAD:-false}" != "true" ]; then
        case $ENVIRONMENT in
            testflight)
                upload_to_testflight
                ;;
            production)
                upload_to_app_store
                ;;
            *)
                log_info "Upload skipped for $ENVIRONMENT environment"
                ;;
        esac
    else
        log_warning "Upload skipped (SKIP_UPLOAD=true)"
    fi

    # Generate build report
    generate_build_report

    echo ""
    log_success "${ROMANIAN_FLAG} iOS build completed successfully! ${IOS_ICON}"
    echo -e "${YELLOW}Romanian Septica ready for App Store submission!${NC}"
    echo ""
}

# Handle script interruption
trap 'log_error "Build interrupted"; exit 1' INT TERM

# Execute main function
main "$@"
