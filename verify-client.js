// Node.js verification script for WebSocket client methods
const fs = require('fs');
const path = require('path');

console.log('🔍 Verifying WebSocket Client Implementation...\n');

// Read the WebSocket client file
const clientPath = path.join(__dirname, 'frontend', 'js', 'websocket-client.js');
const clientCode = fs.readFileSync(clientPath, 'utf8');

console.log('✅ WebSocket client file loaded successfully');
console.log(`📁 File size: ${clientCode.length} characters\n`);

// Check for class definition
const classMatch = clientCode.match(/class SepticaWebSocketClient\s*{/);
if (classMatch) {
    console.log('✅ SepticaWebSocketClient class found');
} else {
    console.log('❌ SepticaWebSocketClient class NOT found');
    process.exit(1);
}

// Check for essential methods
const requiredMethods = [
    'joinMatchmaking',
    'leaveMatchmaking',
    'playCard',
    'connect',
    'disconnect',
    'sendMessage'
];

console.log('\n🔍 Checking for required methods:');

const missingMethods = [];
const foundMethods = [];

requiredMethods.forEach(method => {
    // Look for method definition patterns
    const methodPatterns = [
        new RegExp(`${method}\\s*\\(`), // methodName(
        new RegExp(`${method}\\s*=`),   // methodName =
    ];

    const found = methodPatterns.some(pattern => pattern.test(clientCode));

    if (found) {
        console.log(`  ✅ ${method}`);
        foundMethods.push(method);
    } else {
        console.log(`  ❌ ${method}`);
        missingMethods.push(method);
    }
});

// Check for window export
const windowExportMatch = clientCode.match(/window\.SepticaWebSocketClient\s*=\s*SepticaWebSocketClient/);
if (windowExportMatch) {
    console.log('\n✅ Window export found: window.SepticaWebSocketClient = SepticaWebSocketClient');
} else {
    console.log('\n❌ Window export NOT found');
}

// Extract and display method signatures
console.log('\n📋 Method signatures found:');

foundMethods.forEach(method => {
    const methodRegex = new RegExp(`${method}\\s*\\([^)]*\\)\\s*{`, 'g');
    const matches = clientCode.match(methodRegex);

    if (matches) {
        matches.forEach(match => {
            console.log(`  ${match.replace('{', '').trim()}`);
        });
    }
});

// Summary
console.log('\n📊 SUMMARY:');
console.log(`✅ Methods found: ${foundMethods.length}/${requiredMethods.length}`);

if (missingMethods.length > 0) {
    console.log(`❌ Missing methods: ${missingMethods.join(', ')}`);
    process.exit(1);
} else {
    console.log('🎉 All required methods are present!');
}

// Additional checks
console.log('\n🔍 Additional checks:');

// Check for MESSAGE_TYPES
const messageTypesMatch = clientCode.match(/MESSAGE_TYPES\s*=\s*{/);
if (messageTypesMatch) {
    console.log('✅ MESSAGE_TYPES object found');
} else {
    console.log('❌ MESSAGE_TYPES object NOT found');
}

// Check for specific matchmaking message types
const matchmakingTypes = ['JOIN_MATCHMAKING', 'LEAVE_MATCHMAKING', 'MATCH_FOUND'];
matchmakingTypes.forEach(type => {
    if (clientCode.includes(type)) {
        console.log(`✅ ${type} message type found`);
    } else {
        console.log(`❌ ${type} message type NOT found`);
    }
});

console.log('\n✅ WebSocket client verification complete!');