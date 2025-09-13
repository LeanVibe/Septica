#!/bin/bash

# Romanian Septica App Store Screenshots Capture Script
# This script captures screenshots for all required device sizes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="/Users/bogdan/work/Septica"
APP_BUNDLE_ID="dev.leanvibe.game.Septica"
SCHEME_NAME="Septica"

# Romanian flag colors
ROMANIAN_BLUE="#004C9F"
ROMANIAN_YELLOW="#FCD535"
ROMANIAN_RED="#CE1126"

echo "🇷🇴 Starting Romanian Septica App Store Screenshots Capture"
echo "============================================================"

# Function to wait for simulator to boot
wait_for_simulator() {
    local device_id=$1
    echo "⏳ Waiting for simulator to boot..."
    
    while true; do
        local state=$(xcrun simctl list devices | grep "$device_id" | grep -o "([^)]*)" | tail -1 | tr -d "()")
        if [[ "$state" == "Booted" ]]; then
            echo "✅ Simulator is ready"
            break
        fi
        echo "   Simulator state: $state"
        sleep 2
    done
}

# Function to install and launch app
install_and_launch_app() {
    local device_id=$1
    echo "📱 Installing and launching app on device: $device_id"
    
    # Find the built app
    local app_path="/Users/bogdan/Library/Developer/Xcode/DerivedData/Septica-bhxnubcmusynzbbkytwvuelspvfa/Build/Products/Debug-iphonesimulator/Septica.app"
    
    if [[ ! -d "$app_path" ]]; then
        echo "❌ App not found at: $app_path"
        echo "Building app first..."
        cd "$PROJECT_DIR"
        xcodebuild -project Septica.xcodeproj -scheme "$SCHEME_NAME" -destination "platform=iOS Simulator,id=$device_id" build
    fi
    
    # Install the app
    xcrun simctl install "$device_id" "$app_path"
    
    # Launch the app
    xcrun simctl launch "$device_id" "$APP_BUNDLE_ID"
    
    # Wait for app to launch
    sleep 5
}

# Function to take screenshot
take_screenshot() {
    local device_id=$1
    local device_type=$2
    local screenshot_name=$3
    local description=$4
    
    local output_dir="$SCRIPT_DIR/$device_type/Raw"
    local output_file="$output_dir/${screenshot_name}.png"
    
    echo "📸 Taking screenshot: $description"
    echo "   Device: $device_type ($device_id)"
    echo "   Output: $output_file"
    
    # Take screenshot
    xcrun simctl io "$device_id" screenshot "$output_file"
    
    if [[ -f "$output_file" ]]; then
        echo "   ✅ Screenshot saved successfully"
        
        # Get image dimensions for verification
        local dimensions=$(sips -g pixelWidth -g pixelHeight "$output_file" | grep -E "pixelWidth|pixelHeight" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
        echo "   📏 Dimensions: ${dimensions}"
    else
        echo "   ❌ Failed to save screenshot"
    fi
    
    # Small delay between screenshots
    sleep 2
}

# Function to navigate app for specific screenshots
navigate_for_screenshot() {
    local device_id=$1
    local screenshot_type=$2
    
    case $screenshot_type in
        "main_menu")
            echo "🏠 Navigating to main menu"
            # App should already be on main menu
            ;;
        "gameplay")
            echo "🎮 Navigating to gameplay"
            # Tap "New Game" button
            xcrun simctl io "$device_id" tap 200 400
            sleep 3
            # Start game
            xcrun simctl io "$device_id" tap 200 500
            sleep 5
            ;;
        "settings")
            echo "⚙️ Navigating to settings"
            # Tap settings button
            xcrun simctl io "$device_id" tap 200 600
            sleep 3
            ;;
        "rules")
            echo "📖 Navigating to rules"
            # Tap "How to Play" button
            xcrun simctl io "$device_id" tap 200 450
            sleep 3
            ;;
        "statistics")
            echo "📊 Navigating to statistics"
            # Tap "Statistics" button  
            xcrun simctl io "$device_id" tap 200 350
            sleep 3
            ;;
    esac
}

# Function to capture screenshots for a device
capture_device_screenshots() {
    local device_name=$1
    local device_id=$2
    local device_type=$3
    
    echo ""
    echo "🎯 Capturing screenshots for: $device_name"
    echo "   Device ID: $device_id"
    echo "   Type: $device_type"
    
    # Boot simulator
    xcrun simctl boot "$device_id" || true
    wait_for_simulator "$device_id"
    
    # Install and launch app
    install_and_launch_app "$device_id"
    
    # Screenshot 1: Main Menu
    navigate_for_screenshot "$device_id" "main_menu"
    take_screenshot "$device_id" "$device_type" "01_main_menu" "Main Menu with Romanian Cultural Design"
    
    # Screenshot 2: Gameplay
    navigate_for_screenshot "$device_id" "gameplay"
    take_screenshot "$device_id" "$device_type" "02_gameplay" "Active Gameplay with Traditional Rules"
    
    # Screenshot 3: Settings (for accessibility features)
    # Return to main menu first
    xcrun simctl io "$device_id" tap 50 50  # Back button
    sleep 2
    navigate_for_screenshot "$device_id" "settings"
    take_screenshot "$device_id" "$device_type" "03_settings_accessibility" "Accessibility and Settings"
    
    # Screenshot 4: Rules
    # Return to main menu
    xcrun simctl io "$device_id" tap 50 50  # Back button
    sleep 2
    navigate_for_screenshot "$device_id" "rules"
    take_screenshot "$device_id" "$device_type" "04_rules" "Traditional Romanian Rules"
    
    # Screenshot 5: Statistics
    # Return to main menu
    xcrun simctl io "$device_id" tap 50 50  # Back button
    sleep 2
    navigate_for_screenshot "$device_id" "statistics"
    take_screenshot "$device_id" "$device_type" "05_statistics" "Game Statistics and Progress"
    
    # Screenshot 6: Main menu again (for cultural elements focus)
    # Return to main menu
    xcrun simctl io "$device_id" tap 50 50  # Back button
    sleep 2
    take_screenshot "$device_id" "$device_type" "06_cultural_heritage" "Romanian Cultural Heritage Design"
    
    echo "✅ Completed screenshots for $device_name"
}

# Device configurations
# Note: Using available simulators from the build output

# iPhone 16 Pro Max (6.7" equivalent)
IPHONE_67_NAME="iPhone 16 Pro Max"
IPHONE_67_ID="669B46B7-5D6F-4E21-A567-A7ADCBEC42B4"  # From build output

# iPhone 16 Plus (6.5" equivalent) 
IPHONE_65_NAME="iPhone 16 Plus"
IPHONE_65_ID="6B19E99C-10C0-459D-9752-8331841FC0F1"  # From build output

# iPhone 16 (5.5" equivalent)
IPHONE_55_NAME="iPhone 16"
IPHONE_55_ID="CD18F2A2-68CE-4A6E-80DB-73573350C64C"  # From build output

# iPad Pro 13-inch (12.9" equivalent)
IPAD_129_NAME="iPad Pro 13-inch (M4)"
IPAD_129_ID="E42D067C-1B66-482D-B118-8E2274131C07"  # From build output

# iPad Pro 11-inch
IPAD_11_NAME="iPad Pro 11-inch (M4)"
IPAD_11_ID="D4DA257C-92EA-427D-9F01-E40D245C6FFF"  # From build output

# Capture screenshots for all devices
echo "🚀 Starting screenshot capture for all devices..."

# iPhone devices
capture_device_screenshots "$IPHONE_67_NAME" "$IPHONE_67_ID" "iPhone_6.7"
capture_device_screenshots "$IPHONE_65_NAME" "$IPHONE_65_ID" "iPhone_6.5" 
capture_device_screenshots "$IPHONE_55_NAME" "$IPHONE_55_ID" "iPhone_5.5"

# iPad devices  
capture_device_screenshots "$IPAD_129_NAME" "$IPAD_129_ID" "iPad_12.9"
capture_device_screenshots "$IPAD_11_NAME" "$IPAD_11_ID" "iPad_11.0"

echo ""
echo "🎉 All screenshots captured successfully!"
echo "📁 Screenshots saved in: $SCRIPT_DIR"
echo ""
echo "📋 Next steps:"
echo "   1. Review raw screenshots"
echo "   2. Add Romanian cultural text overlays"
echo "   3. Optimize for App Store submission"
echo "   4. Organize final package"

# Generate summary report
echo ""
echo "📊 Screenshot Summary Report"
echo "=========================="
for device_dir in "$SCRIPT_DIR"/*/Raw; do
    device_type=$(basename "$(dirname "$device_dir")")
    screenshot_count=$(ls -1 "$device_dir"/*.png 2>/dev/null | wc -l)
    echo "   $device_type: $screenshot_count screenshots"
done