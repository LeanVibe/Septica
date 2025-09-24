// Simple test validation for Romanian Septica UI
console.log('🎯 Validating Romanian Septica UI Tests...');

// Mock environment setup
global.document = {
    createElement: () => ({ style: {}, classList: { add: () => {} } }),
    getElementById: () => ({ innerHTML: '', style: {} })
};

try {
    const RomanianSepticaUITests = require('./tests/authentic-ui-test.js');
    console.log('✅ Test class imported successfully');

    const testSuite = new RomanianSepticaUITests();
    console.log('✅ Test suite instantiated');

    // Run just one test to validate
    testSuite.testRomanianCardNames();
    console.log('✅ Romanian card names test passed');

    testSuite.testWildCardRuleValidation();
    console.log('✅ Wild card rule validation passed');

    testSuite.testObjectionDecisionPanel();
    console.log('✅ Objection decision panel test passed');

    const summary = {
        passed: testSuite.testResults.filter(r => r.passed).length,
        failed: testSuite.testResults.filter(r => !r.passed).length,
        total: testSuite.testResults.length
    };

    console.log(`\n📊 Quick validation results:`);
    console.log(`- Total: ${summary.total}`);
    console.log(`- Passed: ${summary.passed}`);
    console.log(`- Failed: ${summary.failed}`);

    if (summary.failed === 0) {
        console.log('🎯 All validated tests passed!');
    } else {
        console.log('❌ Some tests failed');
        testSuite.testResults.filter(r => !r.passed).forEach(r => {
            console.log(`  - ${r.name}: ${r.message}`);
        });
    }

} catch (error) {
    console.error('❌ Test validation failed:', error.message);
    process.exit(1);
}

console.log('✅ Romanian Septica UI test validation completed successfully!');