#!/bin/bash

# Septica PWA Test Launcher
# This script helps you quickly test the PWA with the Go backend

echo "🎮 Septica Game Tester PWA - Quick Test Launcher"
echo "=================================================="
echo ""

# Check if we're in the frontend directory
if [[ ! -f "index.html" ]]; then
    echo "❌ Error: Run this script from the frontend directory"
    echo "📁 Current directory: $(pwd)"
    echo "💡 Expected files: index.html, manifest.json, etc."
    exit 1
fi

echo "📁 Frontend directory: $(pwd)"
echo "✅ All required files found"
echo ""

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Check backend server
echo "🔍 Checking for Go backend server..."
if check_port 8080; then
    echo "✅ Backend server detected on port 8080"
    BACKEND_STATUS="🟢 Running"
else
    echo "⚠️  Backend server not detected on port 8080"
    echo "💡 Make sure to start your Go backend with: ./server"
    echo "🔗 Expected endpoint: ws://localhost:8080/ws/connect"
    BACKEND_STATUS="🔴 Not Running"
fi
echo ""

# Find available port for frontend
FRONTEND_PORT=8000
while check_port $FRONTEND_PORT; do
    FRONTEND_PORT=$((FRONTEND_PORT + 1))
done

echo "🚀 Starting PWA server on port $FRONTEND_PORT..."
echo ""

# Show the test plan
echo "📋 Testing Checklist:"
echo "  1. ✅ Open browser to http://localhost:$FRONTEND_PORT"
echo "  2. ⚙️  Check connection status (should show disconnected)"
echo "  3. 🔗 Click 'Connect' to connect to WebSocket backend"
echo "  4. 📡 Send ping to test basic connectivity"
echo "  5. 🎮 Join a game using the game mode selector"
echo "  6. 🃏 Test card playing functionality"
echo "  7. 📝 Monitor message log for debugging"
echo "  8. 📱 Test PWA install prompt (after a few seconds)"
echo ""

echo "🎯 Backend Status: $BACKEND_STATUS"
echo "🌐 Frontend URL: http://localhost:$FRONTEND_PORT"
echo "🔧 WebSocket URL: ws://localhost:8080/ws/connect"
echo ""

echo "⌨️  Keyboard shortcuts available in PWA:"
echo "  • Ctrl/Cmd+Enter: Connect/Disconnect"
echo "  • Space: Send ping"
echo "  • J: Join game"
echo "  • L: Leave game"
echo "  • G: Get game state"
echo "  • F1 or Ctrl+H: Show help"
echo ""

# Choose server type
if command -v python3 >/dev/null 2>&1; then
    echo "🐍 Starting Python HTTP server..."
    python3 serve.py 2>/dev/null || python3 -m http.server $FRONTEND_PORT
elif command -v node >/dev/null 2>&1; then
    echo "📗 Starting Node.js HTTP server..."
    PORT=$FRONTEND_PORT node serve.js
else
    echo "❌ Error: Neither Python 3 nor Node.js found"
    echo "💡 Please install Python 3 or Node.js to run the server"
    echo "📦 Alternative: Use any static file server to serve this directory"
    exit 1
fi