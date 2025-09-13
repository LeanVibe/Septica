#!/bin/bash

# Romanian Septica App Store Screenshot Optimization Script
# Optimizes processed screenshots for App Store submission

echo "📐 Romanian Septica App Store Screenshot Optimization"
echo "===================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# App Store screenshot requirements
declare -A RESOLUTIONS=(
    ["iPhone_6.7"]="1290x2796"
    ["iPhone_6.5"]="1242x2688"
    ["iPhone_5.5"]="1242x2208"
    ["iPad_12.9"]="2048x2732"
    ["iPad_11.0"]="1668x2388"
)

echo "🔍 Checking processed screenshots..."

# Function to optimize screenshots for a device type
optimize_device_screenshots() {
    local device_type=$1
    local expected_resolution=${RESOLUTIONS[$device_type]}
    local processed_dir="$SCRIPT_DIR/$device_type/Processed"
    local optimized_dir="$SCRIPT_DIR/$device_type/Optimized"
    
    if [[ ! -d "$processed_dir" ]]; then
        echo "⚠️  Processed directory not found: $processed_dir"
        return
    fi
    
    echo ""
    echo "📱 Optimizing $device_type (${expected_resolution})..."
    
    # Create optimized directory
    mkdir -p "$optimized_dir"
    
    local screenshot_count=0
    local optimized_count=0
    
    # Process each screenshot
    for screenshot in "$processed_dir"/*.png; do
        if [[ -f "$screenshot" ]]; then
            screenshot_count=$((screenshot_count + 1))
            local filename=$(basename "$screenshot")
            local output_path="$optimized_dir/$filename"
            
            echo "  🖼️  Optimizing: $filename"
            
            # Check if ImageMagick is available
            if command -v convert &> /dev/null; then
                # Use ImageMagick for optimization
                convert "$screenshot" -quality 90 -strip -resize "${expected_resolution}>" "$output_path" && {
                    optimized_count=$((optimized_count + 1))
                    echo "    ✅ Optimized with ImageMagick"
                }
            elif command -v sips &> /dev/null; then
                # Use macOS sips as fallback
                local width=$(echo "$expected_resolution" | cut -d'x' -f1)
                local height=$(echo "$expected_resolution" | cut -d'x' -f2)
                
                sips -z "$height" "$width" "$screenshot" --out "$output_path" >/dev/null 2>&1 && {
                    optimized_count=$((optimized_count + 1))
                    echo "    ✅ Optimized with sips"
                }
            else
                # Simple copy if no optimization tools available
                cp "$screenshot" "$output_path" && {
                    optimized_count=$((optimized_count + 1))
                    echo "    ➡️  Copied (no optimization tools available)"
                }
            fi
            
            # Verify file size and dimensions
            if [[ -f "$output_path" ]]; then
                local file_size=$(ls -lh "$output_path" | awk '{print $5}')
                echo "    📏 Size: $file_size"
                
                if command -v sips &> /dev/null; then
                    local dimensions=$(sips -g pixelWidth -g pixelHeight "$output_path" 2>/dev/null | grep -E "pixelWidth|pixelHeight" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
                    echo "    📐 Dimensions: $dimensions"
                fi
            fi
        fi
    done
    
    echo "  📊 $device_type: $optimized_count/$screenshot_count screenshots optimized"
}

# Check for optimization tools
echo "🛠️  Checking optimization tools..."
if command -v convert &> /dev/null; then
    echo "✅ ImageMagick available (recommended)"
elif command -v sips &> /dev/null; then
    echo "✅ macOS sips available (fallback)"
else
    echo "⚠️  No optimization tools available. Install ImageMagick:"
    echo "   brew install imagemagick"
fi

# Optimize screenshots for all device types
for device_type in "${!RESOLUTIONS[@]}"; do
    optimize_device_screenshots "$device_type"
done

echo ""
echo "🎯 Final App Store Package Structure:"
echo "AppStoreScreenshots/"
for device_type in "${!RESOLUTIONS[@]}"; do
    optimized_dir="$SCRIPT_DIR/$device_type/Optimized"
    if [[ -d "$optimized_dir" ]]; then
        count=$(find "$optimized_dir" -name "*.png" | wc -l | tr -d ' ')
        echo "├── $device_type/Optimized/ ($count screenshots - ${RESOLUTIONS[$device_type]})"
    fi
done

# Generate submission checklist
echo ""
echo "✅ App Store Submission Checklist:"
echo "================================="

total_screenshots=0
for device_type in "${!RESOLUTIONS[@]}"; do
    optimized_dir="$SCRIPT_DIR/$device_type/Optimized"
    if [[ -d "$optimized_dir" ]]; then
        count=$(find "$optimized_dir" -name "*.png" | wc -l | tr -d ' ')
        total_screenshots=$((total_screenshots + count))
        
        if [[ $count -eq 6 ]]; then
            echo "✅ $device_type: $count/6 screenshots ready"
        else
            echo "⚠️  $device_type: $count/6 screenshots (missing screenshots)"
        fi
    else
        echo "❌ $device_type: No optimized screenshots found"
    fi
done

echo ""
echo "📊 Total Screenshots: $total_screenshots/30"
echo ""

if [[ $total_screenshots -eq 30 ]]; then
    echo "🎉 All screenshots ready for App Store submission!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Review all optimized screenshots manually"
    echo "2. Ensure Romanian cultural elements are visible"
    echo "3. Upload to App Store Connect"
    echo "4. Complete app metadata with Romanian heritage focus"
else
    echo "⚠️  Missing screenshots detected. Please:"
    echo "1. Capture missing screenshots manually"
    echo "2. Process with ./add_overlays.sh"
    echo "3. Re-run this optimization script"
fi

echo ""
echo "🇷🇴 Romanian Cultural Elements Checklist:"
echo "==========================================="
echo "□ Romanian flag colors prominent (Blue, Yellow, Red)"
echo "□ 'Jocul Tradițional Românesc' text visible"
echo "□ Traditional Romanian card game rules highlighted"
echo "□ Cultural heritage messaging clear"
echo "□ Romanian phrases used appropriately"
echo "□ Folk art influences visible in design"
echo "□ Accessibility features respectfully presented"
echo "□ Premium gaming quality evident"