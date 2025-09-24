/**
 * Simple Playwright Configuration for Romanian Septica E2E Testing
 * Without global setup/teardown for immediate testing
 */

import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Test directory structure
  testDir: './e2e-tests',

  // Parallel execution settings
  fullyParallel: false, // Disable parallel to avoid conflicts
  workers: 1,

  // Test execution configuration
  timeout: 60000, // 60 seconds per test
  expect: {
    timeout: 15000, // 15 seconds for assertions
  },

  // Retry configuration
  retries: 1,

  // Reporter configuration
  reporter: [
    ['html', {
      outputFolder: 'test-results/html-report',
      open: 'never'
    }],
    ['json', {
      outputFile: 'test-results/test-results.json'
    }],
    ['line']
  ],

  // Global test configuration
  use: {
    // Browser settings
    headless: false, // Run in headed mode for debugging
    viewport: { width: 1280, height: 720 },

    // Network and timing
    actionTimeout: 15000,
    navigationTimeout: 30000,

    // Screenshots and videos
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',

    // Base URL for tests
    baseURL: 'http://localhost:3000',

    // Ignore HTTPS errors (for local testing)
    ignoreHTTPSErrors: true,
  },

  // Browser projects for testing
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },
  ],

  // Test result output
  outputDir: 'test-results',

  // Test metadata
  metadata: {
    project: 'Romanian Septica',
    environment: 'test',
    version: '1.0.0',
    testType: 'e2e-simplified',
  },
});