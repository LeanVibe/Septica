#!/bin/bash

# Romanian Septica Screenshot Overlay Wrapper Script

echo "🇷🇴 Romanian Septica Screenshot Overlay Generation"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/add_overlays.py"

# Check if Python script exists
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    echo "❌ Python overlay script not found: $PYTHON_SCRIPT"
    exit 1
fi

# Check for Python 3 and PIL/Pillow
echo "🔍 Checking dependencies..."

# Check Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "   Install with: brew install python3"
    exit 1
fi

# Check PIL/Pillow
if ! python3 -c "import PIL" 2>/dev/null; then
    echo "📦 Installing PIL/Pillow for image processing..."
    pip3 install Pillow || {
        echo "❌ Failed to install Pillow. Try:"
        echo "   pip3 install --user Pillow"
        echo "   or"
        echo "   brew install pillow"
        exit 1
    }
fi

echo "✅ Dependencies checked successfully"
echo ""

# Run the Python overlay script
echo "🎨 Starting overlay generation..."
python3 "$PYTHON_SCRIPT" "$SCRIPT_DIR"

echo ""
echo "🎯 Next Steps:"
echo "1. Review processed screenshots in */Processed/ directories"
echo "2. Adjust any overlays if needed"
echo "3. Run ./optimize_for_appstore.sh for final optimization"
echo "4. Package screenshots for App Store submission"

echo ""
echo "📁 Directory Structure:"
echo "AppStoreScreenshots/"
echo "├── iPhone_6.7/Processed/ ← Check these!"
echo "├── iPhone_6.5/Processed/ ← Check these!"  
echo "├── iPhone_5.5/Processed/ ← Check these!"
echo "├── iPad_12.9/Processed/ ← Check these!"
echo "└── iPad_11.0/Processed/ ← Check these!"