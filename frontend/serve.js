#!/usr/bin/env node
/**
 * Simple Node.js HTTP Server for Septica PWA Testing
 * Alternative to Python server with same functionality
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 8000;
const MIME_TYPES = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.webmanifest': 'application/manifest+json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2'
};

function getMimeType(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    return MIME_TYPES[ext] || 'application/octet-stream';
}

function serveFile(res, filePath) {
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/html' });
            res.end('<h1>404 Not Found</h1>');
            return;
        }
        
        const mimeType = getMimeType(filePath);
        const headers = {
            'Content-Type': mimeType,
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        };
        
        // Service worker should not be cached
        if (path.basename(filePath) === 'sw.js') {
            headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
            headers['Pragma'] = 'no-cache';
            headers['Expires'] = '0';
        }
        
        res.writeHead(200, headers);
        res.end(data);
    });
}

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url);
    let pathname = parsedUrl.pathname;
    
    // Handle root path
    if (pathname === '/') {
        pathname = '/index.html';
    }
    
    // Security: prevent directory traversal
    const safePath = path.normalize(pathname).replace(/^(\.\.[\/\\])+/, '');
    const filePath = path.join(__dirname, safePath);
    
    // Check if file exists
    fs.stat(filePath, (err, stats) => {
        if (err || !stats.isFile()) {
            // Try to serve index.html for PWA routing
            const indexPath = path.join(__dirname, 'index.html');
            fs.stat(indexPath, (indexErr) => {
                if (indexErr) {
                    res.writeHead(404, { 'Content-Type': 'text/html' });
                    res.end('<h1>404 Not Found</h1>');
                } else {
                    serveFile(res, indexPath);
                }
            });
        } else {
            serveFile(res, filePath);
        }
    });
});

server.listen(PORT, () => {
    console.log('🎮 Septica PWA Server');
    console.log(`📡 Serving at http://localhost:${PORT}`);
    console.log(`📁 Serving directory: ${__dirname}`);
    console.log(`🔗 Open http://localhost:${PORT} in your browser`);
    console.log(`⚡ Make sure your Go backend is running on ws://localhost:8080/ws/connect`);
    console.log(`🛑 Press Ctrl+C to stop`);
    console.log();
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.log(`❌ Port ${PORT} is already in use`);
        console.log(`💡 Try using a different port: PORT=8001 node serve.js`);
    } else {
        console.log(`❌ Error starting server: ${err.message}`);
    }
    process.exit(1);
});

process.on('SIGINT', () => {
    console.log('\n👋 Server stopped');
    process.exit(0);
});