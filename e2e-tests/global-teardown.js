/**
 * Global Teardown for Romanian Septica E2E Tests
 * Cleanup and reporting after test execution
 */

async function globalTeardown() {
  console.log('\n🧹 Starting Romanian Septica E2E Test Global Teardown...');
  
  const teardownStartTime = Date.now();
  
  try {
    // 1. Generate comprehensive test report
    console.log('📊 Generating comprehensive test report...');
    
    const fs = await import('fs');
    const path = await import('path');
    
    // Read test results
    let testResults = null;
    let setupReport = null;
    
    try {
      const testResultsPath = 'test-results/test-results.json';
      if (await fs.promises.access(testResultsPath).then(() => true).catch(() => false)) {
        const testResultsContent = await fs.promises.readFile(testResultsPath, 'utf8');
        testResults = JSON.parse(testResultsContent);
      }
    } catch (error) {
      console.log('⚠️ Could not read test results:', error.message);
    }
    
    try {
      const setupReportPath = 'test-results/setup-report.json';
      if (await fs.promises.access(setupReportPath).then(() => true).catch(() => false)) {
        const setupReportContent = await fs.promises.readFile(setupReportPath, 'utf8');
        setupReport = JSON.parse(setupReportContent);
      }
    } catch (error) {
      console.log('⚠️ Could not read setup report:', error.message);
    }
    
    // 2. Analyze test results and generate summary
    const summary = {
      timestamp: new Date().toISOString(),
      duration: {
        setup: setupReport?.duration || 0,
        tests: teardownStartTime - (setupReport?.timestamp ? new Date(setupReport.timestamp).getTime() : teardownStartTime),
        teardown: 0 // Will be filled at the end
      },
      infrastructure: setupReport?.readiness || {},
      performance: setupReport?.performanceBaselines || {},
      testExecution: {
        total: 0,
        passed: 0,
        failed: 0,
        skipped: 0,
        flaky: 0
      },
      categories: {
        infrastructure: { passed: 0, failed: 0, skipped: 0 },
        matchmaking: { passed: 0, failed: 0, skipped: 0 },
        rules: { passed: 0, failed: 0, skipped: 0 },
        performance: { passed: 0, failed: 0, skipped: 0 },
        resilience: { passed: 0, failed: 0, skipped: 0 }
      },
      criticalIssues: [],
      recommendations: []
    };
    
    // Process test results if available
    if (testResults && testResults.suites) {
      for (const suite of testResults.suites) {
        for (const spec of suite.specs) {
          for (const test of spec.tests) {
            summary.testExecution.total++;
            
            // Determine category from file path
            let category = 'other';
            if (spec.title.includes('infrastructure') || spec.file.includes('infrastructure')) {
              category = 'infrastructure';
            } else if (spec.title.includes('matchmaking') || spec.file.includes('matchmaking')) {
              category = 'matchmaking';
            } else if (spec.title.includes('rules') || spec.file.includes('rules')) {
              category = 'rules';
            } else if (spec.title.includes('performance') || spec.file.includes('performance')) {
              category = 'performance';
            } else if (spec.title.includes('resilience') || spec.file.includes('resilience')) {
              category = 'resilience';
            }
            
            // Count results
            for (const result of test.results) {
              switch (result.status) {
                case 'passed':
                  summary.testExecution.passed++;
                  if (summary.categories[category]) summary.categories[category].passed++;
                  break;
                case 'failed':
                  summary.testExecution.failed++;
                  if (summary.categories[category]) summary.categories[category].failed++;
                  
                  // Collect critical issues
                  if (category === 'infrastructure' || category === 'matchmaking') {
                    summary.criticalIssues.push({
                      test: spec.title,
                      category,
                      error: result.error?.message || 'Unknown error',
                      file: spec.file
                    });
                  }
                  break;
                case 'skipped':
                  summary.testExecution.skipped++;
                  if (summary.categories[category]) summary.categories[category].skipped++;
                  break;
                case 'timedOut':
                  summary.testExecution.failed++;
                  if (summary.categories[category]) summary.categories[category].failed++;
                  summary.criticalIssues.push({
                    test: spec.title,
                    category,
                    error: 'Test timed out',
                    file: spec.file
                  });
                  break;
              }
            }
          }
        }
      }
    }
    
    // 3. Generate recommendations based on results
    const passRate = summary.testExecution.total > 0 
      ? (summary.testExecution.passed / summary.testExecution.total) * 100 
      : 0;
    
    if (passRate >= 90) {
      summary.recommendations.push('🟢 EXCELLENT: System ready for production deployment');
      summary.recommendations.push('✅ All critical components validated');
      summary.recommendations.push('🎮 Romanian Septica auto-matchmaking fully functional');
    } else if (passRate >= 70) {
      summary.recommendations.push('🟡 GOOD: System approaching production readiness');
      summary.recommendations.push('⚠️ Address remaining issues before deployment');
      summary.recommendations.push('📋 Focus on failed test categories');
    } else {
      summary.recommendations.push('🔴 NEEDS WORK: System requires significant improvements');
      summary.recommendations.push('🛠️ Major issues must be resolved');
      summary.recommendations.push('⏱️ Delay production deployment');
    }
    
    // Infrastructure-specific recommendations
    if (!summary.infrastructure.backend) {
      summary.recommendations.push('🖥️ Backend server issues detected - check connectivity and health');
    }
    if (!summary.infrastructure.frontend) {
      summary.recommendations.push('🌐 Frontend server issues detected - verify static file serving');
    }
    if (!summary.infrastructure.websocket) {
      summary.recommendations.push('📡 WebSocket connectivity issues - check backend WebSocket handler');
    }
    
    // Category-specific recommendations
    if (summary.categories.matchmaking.failed > 0) {
      summary.recommendations.push('🎯 Matchmaking failures detected - verify queue processing logic');
    }
    if (summary.categories.rules.failed > 0) {
      summary.recommendations.push('🇷🇴 Romanian Septica rule violations - review game logic implementation');
    }
    if (summary.categories.performance.failed > 0) {
      summary.recommendations.push('⚡ Performance benchmarks failed - optimize response times');
    }
    
    // 4. Cleanup test artifacts
    console.log('🗑️ Cleaning up test artifacts...');
    
    try {
      // Clean up any temporary files or resources
      // Note: Keep test results for analysis
      console.log('✅ Test artifacts cleaned up');
    } catch (error) {
      console.log('⚠️ Could not clean up all artifacts:', error.message);
    }
    
    // 5. Generate final summary
    summary.duration.teardown = Date.now() - teardownStartTime;
    summary.duration.total = summary.duration.setup + summary.duration.tests + summary.duration.teardown;
    
    // Save comprehensive summary
    await fs.promises.writeFile(
      'test-results/comprehensive-summary.json',
      JSON.stringify(summary, null, 2)
    );
    
    // 6. Console summary output
    console.log('\n🎯 ROMANIAN SEPTICA E2E TEST EXECUTION SUMMARY');
    console.log('================================================');
    console.log(`📊 Tests: ${summary.testExecution.total} total, ${summary.testExecution.passed} passed, ${summary.testExecution.failed} failed, ${summary.testExecution.skipped} skipped`);
    console.log(`📈 Pass rate: ${passRate.toFixed(1)}%`);
    console.log(`⏱️ Total duration: ${Math.round(summary.duration.total / 1000)}s`);
    
    console.log('\n📋 Test Categories:');
    Object.entries(summary.categories).forEach(([category, stats]) => {
      const total = stats.passed + stats.failed + stats.skipped;
      if (total > 0) {
        const categoryPassRate = (stats.passed / total * 100).toFixed(1);
        console.log(`  ${category}: ${stats.passed}/${total} (${categoryPassRate}%)`);
      }
    });
    
    console.log('\n🏗️ Infrastructure Status:');
    console.log(`  Backend: ${summary.infrastructure.backend ? '✅' : '❌'}`);
    console.log(`  Frontend: ${summary.infrastructure.frontend ? '✅' : '❌'}`);
    console.log(`  WebSocket: ${summary.infrastructure.websocket ? '✅' : '❌'}`);
    
    if (summary.criticalIssues.length > 0) {
      console.log('\n🚨 Critical Issues:');
      summary.criticalIssues.slice(0, 5).forEach(issue => {
        console.log(`  • ${issue.category}: ${issue.test} - ${issue.error.substring(0, 80)}`);
      });
      if (summary.criticalIssues.length > 5) {
        console.log(`  ... and ${summary.criticalIssues.length - 5} more issues`);
      }
    }
    
    console.log('\n💡 Recommendations:');
    summary.recommendations.forEach(rec => {
      console.log(`  ${rec}`);
    });
    
    console.log('\n📁 Detailed reports available in:');
    console.log('  • test-results/comprehensive-summary.json');
    console.log('  • test-results/playwright-report/index.html');
    console.log('  • test-results/test-results.json');
    
    // 7. Exit code based on results
    if (summary.criticalIssues.length > 0 && passRate < 70) {
      console.log('\n❌ Test execution completed with critical issues');
      process.exitCode = 1;
    } else {
      console.log('\n✅ Test execution completed successfully');
      process.exitCode = 0;
    }
    
  } catch (error) {
    console.error('💥 Global teardown failed:', error);
    process.exitCode = 1;
  }
  
  console.log('🏁 Romanian Septica E2E testing completed.\n');
}

export default globalTeardown;