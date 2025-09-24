/**
 * Global Setup for Romanian Septica E2E Tests
 * Validates infrastructure readiness before running test suites
 */

import { chromium } from '@playwright/test';
import fetch from 'node-fetch';

async function globalSetup() {
  console.log('🔧 Starting Romanian Septica E2E Test Global Setup...');
  
  const setupStartTime = Date.now();
  const healthChecks = [];
  
  try {
    // 1. Backend Health Check
    console.log('🔍 Checking backend health...');
    try {
      const backendResponse = await fetch('http://localhost:8082/health', {
        timeout: 5000
      });
      
      if (backendResponse.ok) {
        console.log('✅ Backend server is healthy');
        healthChecks.push({ service: 'backend', status: 'healthy', port: 8082 });
      } else {
        console.log('❌ Backend server returned non-200 status:', backendResponse.status);
        healthChecks.push({ service: 'backend', status: 'unhealthy', port: 8082, error: `HTTP ${backendResponse.status}` });
      }
    } catch (error) {
      console.log('❌ Backend server is not responding:', error.message);
      healthChecks.push({ service: 'backend', status: 'unavailable', port: 8082, error: error.message });
    }
    
    // 2. Frontend Availability Check
    console.log('🔍 Checking frontend availability...');
    try {
      const frontendResponse = await fetch('http://localhost:3000', { 
        timeout: 5000 
      });
      
      if (frontendResponse.ok) {
        console.log('✅ Frontend server is available');
        healthChecks.push({ service: 'frontend', status: 'healthy', port: 3000 });
      } else {
        console.log('❌ Frontend server returned non-200 status:', frontendResponse.status);
        healthChecks.push({ service: 'frontend', status: 'unhealthy', port: 3000, error: `HTTP ${frontendResponse.status}` });
      }
    } catch (error) {
      console.log('❌ Frontend server is not responding:', error.message);
      healthChecks.push({ service: 'frontend', status: 'unavailable', port: 3000, error: error.message });
    }
    
    // 3. WebSocket Endpoint Check
    console.log('🔍 Checking WebSocket endpoint...');
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext();
    const page = await context.newPage();
    
    let wsConnectable = false;
    try {
      await page.goto('http://localhost:3000');
      
      // Test WebSocket connection
      const wsResult = await page.evaluate(async () => {
        return new Promise((resolve) => {
          const ws = new WebSocket('ws://localhost:8080/ws/connect?user_id=test-setup');
          const timeout = setTimeout(() => {
            ws.close();
            resolve({ success: false, error: 'Connection timeout' });
          }, 5000);
          
          ws.onopen = () => {
            clearTimeout(timeout);
            ws.close();
            resolve({ success: true });
          };
          
          ws.onerror = (error) => {
            clearTimeout(timeout);
            resolve({ success: false, error: 'Connection failed' });
          };
        });
      });
      
      if (wsResult.success) {
        console.log('✅ WebSocket endpoint is connectable');
        wsConnectable = true;
        healthChecks.push({ service: 'websocket', status: 'healthy', endpoint: 'ws://localhost:8080/ws/connect' });
      } else {
        console.log('❌ WebSocket endpoint failed:', wsResult.error);
        healthChecks.push({ service: 'websocket', status: 'unhealthy', endpoint: 'ws://localhost:8080/ws/connect', error: wsResult.error });
      }
      
    } catch (error) {
      console.log('❌ WebSocket endpoint test failed:', error.message);
      healthChecks.push({ service: 'websocket', status: 'unavailable', endpoint: 'ws://localhost:8080/ws/connect', error: error.message });
    } finally {
      await browser.close();
    }
    
    // 4. Database Connectivity Check (via backend API)
    console.log('🔍 Checking database connectivity...');
    try {
      const dbResponse = await fetch('http://localhost:8080/api/health/db', { 
        timeout: 5000 
      });
      
      if (dbResponse.ok) {
        console.log('✅ Database is accessible via backend');
        healthChecks.push({ service: 'database', status: 'healthy' });
      } else {
        console.log('⚠️ Database health check endpoint not available (may be normal)');
        healthChecks.push({ service: 'database', status: 'unknown', note: 'No health endpoint' });
      }
    } catch (error) {
      console.log('⚠️ Database health check failed (may be normal):', error.message);
      healthChecks.push({ service: 'database', status: 'unknown', error: error.message });
    }
    
    // 5. Performance Baseline Check
    console.log('🔍 Establishing performance baselines...');
    const performanceBaselines = {
      setupTime: Date.now() - setupStartTime,
      backendLatency: 0,
      frontendLoadTime: 0,
      wsConnectionTime: 0
    };
    
    // Measure backend latency
    const backendLatencyStart = Date.now();
    try {
      await fetch('http://localhost:8080/health');
      performanceBaselines.backendLatency = Date.now() - backendLatencyStart;
    } catch (error) {
      performanceBaselines.backendLatency = -1; // Failed
    }
    
    // Measure frontend load time
    const browser2 = await chromium.launch({ headless: true });
    const context2 = await browser2.newContext();
    const page2 = await context2.newPage();
    
    const frontendLoadStart = Date.now();
    try {
      await page2.goto('http://localhost:3000', { waitUntil: 'domcontentloaded' });
      performanceBaselines.frontendLoadTime = Date.now() - frontendLoadStart;
    } catch (error) {
      performanceBaselines.frontendLoadTime = -1; // Failed
    } finally {
      await browser2.close();
    }
    
    // Generate setup report
    const setupReport = {
      timestamp: new Date().toISOString(),
      duration: Date.now() - setupStartTime,
      healthChecks,
      performanceBaselines,
      readiness: {
        backend: healthChecks.find(h => h.service === 'backend')?.status === 'healthy',
        frontend: healthChecks.find(h => h.service === 'frontend')?.status === 'healthy',
        websocket: wsConnectable,
        overall: healthChecks.filter(h => h.status === 'healthy').length >= 3
      }
    };
    
    // Save setup report
    const fs = await import('fs');
    await fs.promises.mkdir('test-results', { recursive: true });
    await fs.promises.writeFile(
      'test-results/setup-report.json', 
      JSON.stringify(setupReport, null, 2)
    );
    
    // Summary
    console.log('\n📊 Setup Summary:');
    console.log(`⏱️  Setup duration: ${setupReport.duration}ms`);
    console.log(`🖥️  Backend: ${setupReport.readiness.backend ? '✅' : '❌'}`);
    console.log(`🌐 Frontend: ${setupReport.readiness.frontend ? '✅' : '❌'}`);
    console.log(`📡 WebSocket: ${setupReport.readiness.websocket ? '✅' : '❌'}`);
    console.log(`🎯 Overall readiness: ${setupReport.readiness.overall ? '✅ READY' : '❌ NOT READY'}`);
    
    if (!setupReport.readiness.overall) {
      console.log('\n❌ CRITICAL: System not ready for testing!');
      console.log('Please ensure all services are running:');
      console.log('  • Backend: DATABASE_URL="postgres://septica:septica@localhost:5433/septica?sslmode=disable" ./backend/server');
      console.log('  • Frontend: cd frontend && python3 -m http.server 3000');
      console.log('  • Database: PostgreSQL on port 5433');
      
      // Still continue with tests but mark as degraded
      process.env.SEPTICA_TEST_MODE = 'degraded';
    } else {
      console.log('\n✅ System ready for comprehensive E2E testing!');
      process.env.SEPTICA_TEST_MODE = 'optimal';
    }
    
    // Store results globally for tests to access
    global.setupReport = setupReport;
    
  } catch (error) {
    console.error('💥 Global setup failed:', error);
    throw error;
  }
  
  console.log('🎬 Global setup completed. Starting test execution...\n');
}

export default globalSetup;