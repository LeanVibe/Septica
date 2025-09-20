#!/usr/bin/env python3
"""
Simple HTTP Server for Septica PWA Testing
Serves the PWA with proper MIME types and CORS headers
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

# Set the port
PORT = 8000

# Change to the directory containing this script
os.chdir(Path(__file__).parent)

class PWAHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler with proper MIME types and headers for PWA"""
    
    def end_headers(self):
        # Add CORS headers for development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        
        # Add PWA-specific headers
        if self.path.endswith('.js'):
            self.send_header('Content-Type', 'application/javascript')
        elif self.path.endswith('.json'):
            self.send_header('Content-Type', 'application/json')
        elif self.path.endswith('.css'):
            self.send_header('Content-Type', 'text/css')
        elif self.path.endswith('.html'):
            self.send_header('Content-Type', 'text/html')
        
        # Service worker should not be cached
        if self.path.endswith('sw.js'):
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Expires', '0')
        
        super().end_headers()
    
    def guess_type(self, path):
        """Override to handle additional file types"""
        mime_type = super().guess_type(path)
        if path.endswith('.js'):
            return 'application/javascript'
        elif path.endswith('.json'):
            return 'application/json'
        elif path.endswith('.webmanifest'):
            return 'application/manifest+json'
        return mime_type

def main():
    try:
        with socketserver.TCPServer(("", PORT), PWAHandler) as httpd:
            print(f"🎮 Septica PWA Server")
            print(f"📡 Serving at http://localhost:{PORT}")
            print(f"📁 Serving directory: {os.getcwd()}")
            print(f"🔗 Open http://localhost:{PORT} in your browser")
            print(f"⚡ Make sure your Go backend is running on ws://localhost:8080/ws/connect")
            print(f"🛑 Press Ctrl+C to stop")
            print()
            
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n👋 Server stopped")
        sys.exit(0)
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Port {PORT} is already in use")
            print(f"💡 Try using a different port or stop the other server")
        else:
            print(f"❌ Error starting server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()