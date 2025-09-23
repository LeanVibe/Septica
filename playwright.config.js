/**
 * Playwright Configuration for Romanian Septica E2E Testing
 * Comprehensive test configuration for two-tab auto-matchmaking validation
 */

import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Test directory structure
  testDir: './e2e-tests',
  
  // Parallel execution settings
  fullyParallel: true,
  workers: process.env.CI ? 2 : 4,
  
  // Test execution configuration
  timeout: 45000, // 45 seconds per test
  expect: {
    timeout: 10000, // 10 seconds for assertions
  },
  
  // Global test setup/teardown
  globalSetup: './e2e-tests/global-setup.js',
  globalTeardown: './e2e-tests/global-teardown.js',
  
  // Retry configuration
  retries: process.env.CI ? 2 : 1,
  
  // Reporter configuration
  reporter: [
    ['html', { 
      outputFolder: 'test-results/html-report',
      open: 'never'
    }],
    ['json', { 
      outputFile: 'test-results/test-results.json' 
    }],
    ['junit', { 
      outputFile: 'test-results/junit.xml' 
    }],
    ['line']
  ],
  
  // Global test configuration
  use: {
    // Browser settings
    headless: process.env.CI ? true : false,
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
    
    // Performance monitoring
    extraHTTPHeaders: {
      'Accept-Language': 'en-US,en;q=0.9',
    },
  },

  // Browser projects for cross-browser testing
  projects: [
    {
      name: 'chromium-desktop',
      use: { 
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
        permissions: ['microphone', 'camera'],
      },
    },
    
    {
      name: 'firefox-desktop',
      use: { 
        ...devices['Desktop Firefox'],
        viewport: { width: 1280, height: 720 },
      },
    },
    
    {
      name: 'webkit-desktop',
      use: { 
        ...devices['Desktop Safari'],
        viewport: { width: 1280, height: 720 },
      },
    },
    
    // Mobile testing
    {
      name: 'mobile-chrome',
      use: { 
        ...devices['Pixel 5'],
      },
    },
    
    {
      name: 'mobile-safari',
      use: { 
        ...devices['iPhone 12'],
      },
    },

    // Specific browser configurations for multi-tab testing
    {
      name: 'dual-chrome-contexts',
      use: {
        ...devices['Desktop Chrome'],
        contextOptions: {
          permissions: ['microphone', 'camera'],
          viewport: { width: 1280, height: 720 },
        },
      },
    },
  ],

  // Development server configuration (disabled - using existing servers)
  // webServer: [
  //   {
  //     command: 'cd frontend && python3 -m http.server 3000',
  //     port: 3000,
  //     timeout: 30000,
  //     reuseExistingServer: !process.env.CI,
  //   },
  //   {
  //     command: 'DATABASE_URL="postgres://septica:septica@localhost:5433/septica?sslmode=disable" ./backend/server',
  //     port: 8080,
  //     timeout: 30000,
  //     reuseExistingServer: !process.env.CI,
  //   }
  // ],

  // Test result output
  outputDir: 'test-results',
  
  // Test metadata
  metadata: {
    project: 'Romanian Septica',
    environment: process.env.NODE_ENV || 'test',
    version: '1.0.0',
    testType: 'e2e-auto-matchmaking',
  },
});