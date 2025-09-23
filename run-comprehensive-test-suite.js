#!/usr/bin/env node

/**
 * Comprehensive Romanian Septica Test Suite Runner
 * Executes all automated tests and generates detailed reports
 */

const { spawn, exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

const TEST_CONFIG = {
  frontendUrl: 'http://localhost:3000',
  backendUrl: 'http://localhost:8080',
  outputDir: './test-results',
  reportFile: './test-results/comprehensive-report.json',
  summaryFile: './test-results/test-summary.md'
};

class ComprehensiveTestRunner {
  constructor() {
    this.results = {
      startTime: new Date().toISOString(),
      testSuites: [],
      overallResults: {
        totalTests: 0,
        passedTests: 0,
        failedTests: 0,
        skippedTests: 0,
        duration: 0
      },
      environment: {
        nodeVersion: process.version,
        platform: process.platform,
        frontendUrl: TEST_CONFIG.frontendUrl,
        backendUrl: TEST_CONFIG.backendUrl
      }
    };
  }

  async runComprehensiveTestSuite() {
    console.log('🎯 ROMANIAN SEPTICA COMPREHENSIVE TEST SUITE');
    console.log('='.repeat(60));
    console.log(`Started at: ${this.results.startTime}`);
    console.log(`Frontend: ${TEST_CONFIG.frontendUrl}`);
    console.log(`Backend: ${TEST_CONFIG.backendUrl}`);
    console.log('');

    try {
      // Ensure output directory exists
      await this.ensureOutputDirectory();

      // Pre-flight checks
      await this.runPreflightChecks();

      // Execute test suites in order
      await this.runTestSuite('Infrastructure Connectivity', 'e2e-tests/infrastructure/connectivity.spec.js');
      await this.runTestSuite('Romanian Septica Rules Validation', 'e2e-tests/rules/romanian-septica-validation.spec.js');
      await this.runTestSuite('Two-Tab Auto-Matchmaking', 'e2e-tests/matchmaking/two-tab-auto-matchmaking.spec.js');
      await this.runTestSuite('Performance Benchmarks', 'e2e-tests/performance/benchmarks.spec.js');
      await this.runTestSuite('Stress Testing', 'e2e-tests/performance/stress-testing.spec.js');
      await this.runTestSuite('Regression Prevention', 'e2e-tests/regression/prevention-suite.spec.js');
      await this.runTestSuite('Comprehensive Integration', 'e2e-tests/comprehensive-romanian-septica.spec.js');

      // Generate final reports
      await this.generateComprehensiveReport();

      // Display summary
      this.displayFinalSummary();

    } catch (error) {
      console.error('❌ Test suite execution failed:', error.message);
      process.exit(1);
    }
  }

  async ensureOutputDirectory() {
    try {
      await fs.access(TEST_CONFIG.outputDir);
    } catch {
      await fs.mkdir(TEST_CONFIG.outputDir, { recursive: true });
    }
  }

  async runPreflightChecks() {
    console.log('🔍 Running pre-flight checks...');

    const checks = [
      { name: 'Frontend Server', check: () => this.checkUrl(TEST_CONFIG.frontendUrl) },
      { name: 'Backend Server', check: () => this.checkUrl(TEST_CONFIG.backendUrl) },
      { name: 'Playwright Installation', check: () => this.checkPlaywrightInstallation() }
    ];

    for (const check of checks) {
      try {
        await check.check();
        console.log(`  ✅ ${check.name}: OK`);
      } catch (error) {
        console.log(`  ❌ ${check.name}: FAILED`);
        throw new Error(`Pre-flight check failed: ${check.name} - ${error.message}`);
      }
    }

    console.log('✅ All pre-flight checks passed\n');
  }

  async checkUrl(url) {
    const { default: fetch } = await import('node-fetch');
    const response = await fetch(url, { timeout: 5000 });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
  }

  async checkPlaywrightInstallation() {
    return new Promise((resolve, reject) => {
      exec('npx playwright --version', (error, stdout) => {
        if (error) {
          reject(new Error('Playwright not installed'));
        } else {
          resolve(stdout.trim());
        }
      });
    });
  }

  async runTestSuite(suiteName, testFile) {
    console.log(`🧪 Running: ${suiteName}`);
    console.log('-'.repeat(40));

    const startTime = Date.now();
    const suiteResult = {
      name: suiteName,
      file: testFile,
      startTime: new Date().toISOString(),
      duration: 0,
      status: 'running',
      tests: [],
      summary: {
        total: 0,
        passed: 0,
        failed: 0,
        skipped: 0
      }
    };

    try {
      const testOutput = await this.executePlaywrightTest(testFile);

      // Parse test results
      suiteResult.tests = this.parseTestOutput(testOutput);
      suiteResult.summary = this.calculateSuiteSummary(suiteResult.tests);
      suiteResult.status = suiteResult.summary.failed > 0 ? 'failed' : 'passed';

      console.log(`  Tests: ${suiteResult.summary.passed}/${suiteResult.summary.total} passed`);

      if (suiteResult.summary.failed > 0) {
        console.log(`  ❌ ${suiteResult.summary.failed} tests failed`);
      } else {
        console.log(`  ✅ All tests passed`);
      }

    } catch (error) {
      suiteResult.status = 'error';
      suiteResult.error = error.message;
      console.log(`  ❌ Suite execution failed: ${error.message}`);
    }

    suiteResult.duration = Date.now() - startTime;
    suiteResult.endTime = new Date().toISOString();

    this.results.testSuites.push(suiteResult);
    console.log(`  Duration: ${(suiteResult.duration / 1000).toFixed(2)}s\n`);

    return suiteResult;
  }

  async executePlaywrightTest(testFile) {
    return new Promise((resolve, reject) => {
      const playwright = spawn('npx', ['playwright', 'test', testFile, '--reporter=json'], {
        stdio: ['pipe', 'pipe', 'pipe']
      });

      let stdout = '';
      let stderr = '';

      playwright.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      playwright.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      playwright.on('close', (code) => {
        if (code === 0 || stdout.length > 0) {
          resolve({ stdout, stderr, exitCode: code });
        } else {
          reject(new Error(`Playwright test failed with exit code ${code}: ${stderr}`));
        }
      });

      playwright.on('error', (error) => {
        reject(error);
      });
    });
  }

  parseTestOutput(testOutput) {
    const tests = [];

    try {
      // Try to parse JSON output
      const jsonOutput = JSON.parse(testOutput.stdout);

      if (jsonOutput.suites) {
        jsonOutput.suites.forEach(suite => {
          suite.specs.forEach(spec => {
            spec.tests.forEach(test => {
              tests.push({
                title: test.title,
                status: test.results[0]?.status || 'unknown',
                duration: test.results[0]?.duration || 0,
                error: test.results[0]?.error?.message || null
              });
            });
          });
        });
      }
    } catch (error) {
      // Fallback to parsing text output
      console.log('  ⚠️ Could not parse JSON output, using text parsing');
      tests.push({
        title: 'Test suite execution',
        status: testOutput.exitCode === 0 ? 'passed' : 'failed',
        duration: 0,
        error: testOutput.exitCode !== 0 ? testOutput.stderr : null
      });
    }

    return tests;
  }

  calculateSuiteSummary(tests) {
    return {
      total: tests.length,
      passed: tests.filter(t => t.status === 'passed').length,
      failed: tests.filter(t => t.status === 'failed').length,
      skipped: tests.filter(t => t.status === 'skipped').length
    };
  }

  async generateComprehensiveReport() {
    console.log('📊 Generating comprehensive test report...');

    // Calculate overall results
    this.results.overallResults = this.calculateOverallResults();
    this.results.endTime = new Date().toISOString();
    this.results.duration = new Date(this.results.endTime) - new Date(this.results.startTime);

    // Save detailed JSON report
    await fs.writeFile(
      TEST_CONFIG.reportFile,
      JSON.stringify(this.results, null, 2),
      'utf8'
    );

    // Generate markdown summary
    const markdownSummary = this.generateMarkdownSummary();
    await fs.writeFile(TEST_CONFIG.summaryFile, markdownSummary, 'utf8');

    console.log(`  ✅ Detailed report: ${TEST_CONFIG.reportFile}`);
    console.log(`  ✅ Summary report: ${TEST_CONFIG.summaryFile}`);
  }

  calculateOverallResults() {
    let totalTests = 0;
    let passedTests = 0;
    let failedTests = 0;
    let skippedTests = 0;

    this.results.testSuites.forEach(suite => {
      totalTests += suite.summary.total;
      passedTests += suite.summary.passed;
      failedTests += suite.summary.failed;
      skippedTests += suite.summary.skipped;
    });

    return {
      totalTests,
      passedTests,
      failedTests,
      skippedTests,
      duration: this.results.duration
    };
  }

  generateMarkdownSummary() {
    const overall = this.results.overallResults;
    const passRate = overall.totalTests > 0 ? (overall.passedTests / overall.totalTests * 100).toFixed(1) : 0;

    let markdown = `# Romanian Septica Test Suite Report\n\n`;
    markdown += `**Generated**: ${this.results.endTime}\n`;
    markdown += `**Duration**: ${(this.results.duration / 1000).toFixed(2)} seconds\n`;
    markdown += `**Environment**: ${this.results.environment.platform} | Node ${this.results.environment.nodeVersion}\n\n`;

    // Overall summary
    markdown += `## Overall Results\n\n`;
    markdown += `| Metric | Count | Percentage |\n`;
    markdown += `|--------|-------|------------|\n`;
    markdown += `| **Total Tests** | ${overall.totalTests} | 100% |\n`;
    markdown += `| **Passed** | ${overall.passedTests} | ${passRate}% |\n`;
    markdown += `| **Failed** | ${overall.failedTests} | ${(overall.failedTests / overall.totalTests * 100).toFixed(1)}% |\n`;
    markdown += `| **Skipped** | ${overall.skippedTests} | ${(overall.skippedTests / overall.totalTests * 100).toFixed(1)}% |\n\n`;

    // Quality assessment
    markdown += `## Quality Assessment\n\n`;
    if (passRate >= 95) {
      markdown += `🟢 **EXCELLENT** - Production ready (${passRate}% pass rate)\n\n`;
    } else if (passRate >= 85) {
      markdown += `🟡 **GOOD** - Minor issues to address (${passRate}% pass rate)\n\n`;
    } else {
      markdown += `🔴 **NEEDS WORK** - Critical issues detected (${passRate}% pass rate)\n\n`;
    }

    // Test suite breakdown
    markdown += `## Test Suite Results\n\n`;
    markdown += `| Test Suite | Status | Tests | Pass Rate | Duration |\n`;
    markdown += `|------------|--------|-------|-----------|----------|\n`;

    this.results.testSuites.forEach(suite => {
      const suitePassRate = suite.summary.total > 0 ?
        (suite.summary.passed / suite.summary.total * 100).toFixed(1) : 0;
      const statusIcon = suite.status === 'passed' ? '✅' :
                        suite.status === 'failed' ? '❌' : '⚠️';

      markdown += `| ${suite.name} | ${statusIcon} ${suite.status} | ${suite.summary.passed}/${suite.summary.total} | ${suitePassRate}% | ${(suite.duration / 1000).toFixed(2)}s |\n`;
    });

    markdown += `\n`;

    // Failed tests details
    const failedSuites = this.results.testSuites.filter(suite => suite.summary.failed > 0);
    if (failedSuites.length > 0) {
      markdown += `## Failed Tests\n\n`;

      failedSuites.forEach(suite => {
        markdown += `### ${suite.name}\n\n`;
        const failedTests = suite.tests.filter(test => test.status === 'failed');

        failedTests.forEach(test => {
          markdown += `- **${test.title}**\n`;
          if (test.error) {
            markdown += `  \`\`\`\n  ${test.error}\n  \`\`\`\n`;
          }
        });
        markdown += `\n`;
      });
    }

    // Romanian Septica specific validation
    markdown += `## Romanian Septica Compliance\n\n`;
    markdown += `| Aspect | Status |\n`;
    markdown += `|--------|--------|\n`;
    markdown += `| 32-card deck composition | ${this.checkFeatureCompliance('deck') ? '✅' : '❌'} |\n`;
    markdown += `| Authentic beating rules | ${this.checkFeatureCompliance('rules') ? '✅' : '❌'} |\n`;
    markdown += `| Traditional point system | ${this.checkFeatureCompliance('points') ? '✅' : '❌'} |\n`;
    markdown += `| Two-player matchmaking | ${this.checkFeatureCompliance('matchmaking') ? '✅' : '❌'} |\n`;
    markdown += `| Cultural authenticity | ${this.checkFeatureCompliance('culture') ? '✅' : '❌'} |\n\n`;

    // Performance summary
    markdown += `## Performance Summary\n\n`;
    const perfSuite = this.results.testSuites.find(suite => suite.name.includes('Performance') || suite.name.includes('Stress'));
    if (perfSuite) {
      markdown += `- **Performance tests**: ${perfSuite.summary.passed}/${perfSuite.summary.total} passed\n`;
      markdown += `- **Load testing**: ${perfSuite.status === 'passed' ? 'Passed' : 'Failed'}\n`;
    }
    markdown += `- **Overall test duration**: ${(this.results.duration / 1000).toFixed(2)} seconds\n\n`;

    // Recommendations
    markdown += `## Recommendations\n\n`;
    if (passRate >= 95) {
      markdown += `- ✅ System is ready for production deployment\n`;
      markdown += `- ✅ All critical Romanian Septica features working correctly\n`;
      markdown += `- ✅ Performance and reliability targets met\n`;
    } else if (passRate >= 85) {
      markdown += `- ⚠️ Address failing tests before production deployment\n`;
      markdown += `- ⚠️ Review failed Romanian Septica rule implementations\n`;
      markdown += `- ✅ Core functionality appears stable\n`;
    } else {
      markdown += `- 🔴 **DO NOT DEPLOY** - Critical issues must be resolved\n`;
      markdown += `- 🔴 Review and fix failing test suites\n`;
      markdown += `- 🔴 Validate Romanian Septica rule compliance\n`;
    }

    return markdown;
  }

  checkFeatureCompliance(feature) {
    // Simple heuristic - if related test suites passed, assume compliance
    const relevantSuites = this.results.testSuites.filter(suite => {
      const suiteName = suite.name.toLowerCase();
      switch (feature) {
        case 'deck':
        case 'rules':
        case 'points':
          return suiteName.includes('romanian') || suiteName.includes('rules');
        case 'matchmaking':
          return suiteName.includes('matchmaking');
        case 'culture':
          return suiteName.includes('romanian') || suiteName.includes('comprehensive');
        default:
          return false;
      }
    });

    return relevantSuites.length > 0 && relevantSuites.every(suite => suite.status === 'passed');
  }

  displayFinalSummary() {
    const overall = this.results.overallResults;
    const passRate = overall.totalTests > 0 ? (overall.passedTests / overall.totalTests * 100).toFixed(1) : 0;

    console.log('\n' + '='.repeat(60));
    console.log('🏆 COMPREHENSIVE TEST SUITE COMPLETED');
    console.log('='.repeat(60));
    console.log(`Total Tests: ${overall.totalTests}`);
    console.log(`Passed: ${overall.passedTests} (${passRate}%)`);
    console.log(`Failed: ${overall.failedTests}`);
    console.log(`Skipped: ${overall.skippedTests}`);
    console.log(`Duration: ${(this.results.duration / 1000).toFixed(2)} seconds`);

    console.log('\n📊 QUALITY ASSESSMENT:');
    if (passRate >= 95) {
      console.log('🟢 EXCELLENT - Romanian Septica system is production ready!');
    } else if (passRate >= 85) {
      console.log('🟡 GOOD - Minor issues detected, review before deployment');
    } else {
      console.log('🔴 NEEDS WORK - Critical issues must be resolved');
    }

    console.log('\n📁 REPORTS GENERATED:');
    console.log(`  Detailed Report: ${TEST_CONFIG.reportFile}`);
    console.log(`  Summary Report: ${TEST_CONFIG.summaryFile}`);

    if (overall.failedTests > 0) {
      console.log('\n❌ FAILED TEST SUITES:');
      this.results.testSuites
        .filter(suite => suite.summary.failed > 0)
        .forEach(suite => {
          console.log(`  ${suite.name}: ${suite.summary.failed} failed tests`);
        });
    }

    console.log('\n✅ Test execution completed successfully!');
  }
}

// CLI execution
if (require.main === module) {
  const testRunner = new ComprehensiveTestRunner();
  testRunner.runComprehensiveTestSuite().catch(error => {
    console.error('Test runner failed:', error);
    process.exit(1);
  });
}

module.exports = { ComprehensiveTestRunner };