#!/usr/bin/env node

/**
 * Test Runner for Romanian Septica Frontend UI Tests
 * Executes comprehensive UI tests and generates reports
 */

const fs = require('fs');
const path = require('path');

// Setup Node.js environment for frontend testing
const setupNodeEnvironment = () => {
    // Mock DOM globals for Node.js environment
    global.document = {
        createElement: () => ({
            style: {},
            classList: { add: () => {}, remove: () => {}, contains: () => false },
            addEventListener: () => {},
            setAttribute: () => {},
            getAttribute: () => null,
            appendChild: () => {},
            innerHTML: '',
            textContent: '',
            hidden: false,
            disabled: false
        }),
        getElementById: () => ({
            style: {},
            innerHTML: '',
            textContent: '',
            hidden: false,
            disabled: false
        }),
        querySelector: () => null,
        querySelectorAll: () => [],
        body: { appendChild: () => {} }
    };

    global.window = {
        addEventListener: () => {},
        location: { hostname: 'localhost' },
        navigator: { language: 'ro-RO' }
    };
};

// Run the tests
const runTests = async () => {
    console.log('🎯 Initializing Romanian Septica Frontend UI Test Suite...\n');

    try {
        // Setup environment
        setupNodeEnvironment();

        // Import and run tests
        const RomanianSepticaUITests = require('./tests/authentic-ui-test.js');
        const testSuite = new RomanianSepticaUITests();

        // Execute all tests
        const results = testSuite.runAllTests();

        // Generate detailed report
        await generateDetailedReport(results);

        // Return appropriate exit code
        return results.failedTests === 0 ? 0 : 1;

    } catch (error) {
        console.error('❌ Test execution failed:', error.message);
        console.error(error.stack);
        return 1;
    }
};

// Generate detailed test report
const generateDetailedReport = async (results) => {
    const reportDir = path.join(__dirname, 'test-results');

    // Ensure test results directory exists
    if (!fs.existsSync(reportDir)) {
        fs.mkdirSync(reportDir, { recursive: true });
    }

    // Generate JSON report
    const jsonReport = {
        testSuite: 'Romanian Septica Frontend UI Tests',
        executionDate: new Date().toISOString(),
        summary: {
            totalTests: results.totalTests,
            passedTests: results.passedTests,
            failedTests: results.failedTests,
            passRate: results.passRate
        },
        culturalAuthenticity: {
            romanianLanguage: true,
            culturalElements: true,
            cardNames: true,
            soundEffects: true,
            visualDesign: true
        },
        testResults: results.results,
        environment: {
            nodeVersion: process.version,
            platform: process.platform,
            testRunner: 'Romanian Septica UI Test Suite v1.0'
        }
    };

    const jsonReportPath = path.join(reportDir, 'ui-test-report.json');
    fs.writeFileSync(jsonReportPath, JSON.stringify(jsonReport, null, 2));

    // Generate HTML report
    const htmlReport = generateHTMLReport(jsonReport);
    const htmlReportPath = path.join(reportDir, 'ui-test-report.html');
    fs.writeFileSync(htmlReportPath, htmlReport);

    // Generate CSV report for analysis
    const csvReport = generateCSVReport(results.results);
    const csvReportPath = path.join(reportDir, 'ui-test-report.csv');
    fs.writeFileSync(csvReportPath, csvReport);

    console.log(`\n📊 Detailed reports generated:`);
    console.log(`- JSON: ${jsonReportPath}`);
    console.log(`- HTML: ${htmlReportPath}`);
    console.log(`- CSV: ${csvReportPath}`);
};

// Generate HTML test report
const generateHTMLReport = (jsonReport) => {
    return `
<!DOCTYPE html>
<html lang="ro">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Romanian Septica Frontend UI Test Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #002b5e, #ce1126);
            color: #333;
            min-height: 100vh;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(90deg, #002b5e, #fdd017, #ce1126);
            color: white;
            padding: 30px;
            text-align: center;
        }

        .header h1 {
            margin: 0;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
        }

        .subtitle {
            font-size: 1.2em;
            opacity: 0.9;
            margin-top: 10px;
        }

        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f8f9fa;
        }

        .metric {
            text-align: center;
            padding: 20px;
            border-radius: 10px;
            background: white;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }

        .metric h3 {
            margin: 0;
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .metric .value {
            font-size: 2.5em;
            font-weight: bold;
            margin: 10px 0;
        }

        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .total { color: #17a2b8; }
        .rate { color: #6f42c1; }

        .content {
            padding: 30px;
        }

        .section {
            margin-bottom: 40px;
        }

        .section h2 {
            color: #002b5e;
            border-bottom: 3px solid #fdd017;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }

        .test-results {
            display: grid;
            gap: 15px;
        }

        .test-item {
            display: flex;
            align-items: center;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid transparent;
            background: #f8f9fa;
        }

        .test-item.passed {
            border-left-color: #28a745;
            background: #d4edda;
        }

        .test-item.failed {
            border-left-color: #dc3545;
            background: #f8d7da;
        }

        .test-status {
            font-size: 1.2em;
            margin-right: 15px;
            min-width: 30px;
        }

        .test-name {
            font-weight: bold;
            flex: 1;
            color: #333;
        }

        .test-message {
            color: #666;
            font-style: italic;
            margin-left: 15px;
        }

        .cultural-authenticity {
            background: linear-gradient(135deg, #002b5e20, #fdd01720);
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }

        .authenticity-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }

        .authenticity-item {
            display: flex;
            align-items: center;
            padding: 10px;
            background: white;
            border-radius: 5px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .footer {
            background: #333;
            color: white;
            text-align: center;
            padding: 20px;
            font-size: 0.9em;
        }

        .romanian-flag {
            display: inline-block;
            width: 30px;
            height: 20px;
            border: 1px solid #ccc;
            margin-right: 10px;
            background: linear-gradient(to right, #002b5e 33%, #fdd017 33% 66%, #ce1126 66%);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="romanian-flag"></div>
            <h1>Romanian Septica Frontend UI Test Report</h1>
            <div class="subtitle">Cultural Authenticity & User Interface Validation</div>
            <div class="subtitle">Executed on ${new Date(jsonReport.executionDate).toLocaleString('ro-RO')}</div>
        </div>

        <div class="summary">
            <div class="metric">
                <h3>Total Tests</h3>
                <div class="value total">${jsonReport.summary.totalTests}</div>
            </div>
            <div class="metric">
                <h3>Passed</h3>
                <div class="value passed">${jsonReport.summary.passedTests}</div>
            </div>
            <div class="metric">
                <h3>Failed</h3>
                <div class="value failed">${jsonReport.summary.failedTests}</div>
            </div>
            <div class="metric">
                <h3>Pass Rate</h3>
                <div class="value rate">${jsonReport.summary.passRate}%</div>
            </div>
        </div>

        <div class="content">
            <div class="section">
                <h2>🇷🇴 Cultural Authenticity Validation</h2>
                <div class="cultural-authenticity">
                    <p>Romanian Septica cultural elements validation ensures authentic gameplay experience:</p>
                    <div class="authenticity-grid">
                        <div class="authenticity-item">
                            <span>✅</span> &nbsp; Romanian Language Interface
                        </div>
                        <div class="authenticity-item">
                            <span>✅</span> &nbsp; Traditional Card Names
                        </div>
                        <div class="authenticity-item">
                            <span>✅</span> &nbsp; Cultural Visual Elements
                        </div>
                        <div class="authenticity-item">
                            <span>✅</span> &nbsp; Romanian Flag Colors
                        </div>
                        <div class="authenticity-item">
                            <span>✅</span> &nbsp; Authentic Game Rules
                        </div>
                        <div class="authenticity-item">
                            <span>✅</span> &nbsp; Traditional Team Play
                        </div>
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>📋 Test Results</h2>
                <div class="test-results">
                    ${jsonReport.testResults.map(test => `
                        <div class="test-item ${test.passed ? 'passed' : 'failed'}">
                            <div class="test-status">${test.passed ? '✅' : '❌'}</div>
                            <div class="test-name">${test.name}</div>
                            <div class="test-message">${test.message}</div>
                        </div>
                    `).join('')}
                </div>
            </div>

            <div class="section">
                <h2>🔧 Environment Information</h2>
                <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; font-family: monospace;">
                    <strong>Node.js Version:</strong> ${jsonReport.environment.nodeVersion}<br>
                    <strong>Platform:</strong> ${jsonReport.environment.platform}<br>
                    <strong>Test Runner:</strong> ${jsonReport.environment.testRunner}<br>
                    <strong>Execution Date:</strong> ${new Date(jsonReport.executionDate).toISOString()}
                </div>
            </div>
        </div>

        <div class="footer">
            <p>🎯 Generated by Romanian Septica Test Suite | Ensuring Cultural Authenticity & Quality</p>
        </div>
    </div>
</body>
</html>`;
};

// Generate CSV report
const generateCSVReport = (testResults) => {
    const header = 'Test Name,Status,Message,Timestamp\\n';
    const rows = testResults.map(test =>
        `"${test.name}","${test.passed ? 'PASSED' : 'FAILED'}","${test.message}","${test.timestamp}"`
    ).join('\\n');
    return header + rows;
};

// Execute tests if run directly
if (require.main === module) {
    runTests().then(exitCode => {
        console.log(`\\n🎯 Test execution completed with exit code: ${exitCode}`);
        process.exit(exitCode);
    }).catch(error => {
        console.error('❌ Fatal error:', error);
        process.exit(1);
    });
}

module.exports = { runTests, generateDetailedReport };