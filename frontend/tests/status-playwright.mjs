import { chromium, webkit } from 'playwright';
import { spawn } from 'node:child_process';

const SERVER_PORT = 3300;

async function startServer() {
  const server = spawn('python3', ['-m', 'http.server', String(SERVER_PORT), '--directory', 'frontend'], {
    stdio: 'ignore'
  });
  await new Promise((resolve) => setTimeout(resolve, 1500));
  return server;
}

async function runInBrowser(browserType) {
  const browser = await browserType.launch({ headless: true, args: ['--no-sandbox'] }).catch(() => null);
  if (!browser) return false;
  try {
    const page = await browser.newPage();
    await page.goto(`http://localhost:${SERVER_PORT}/index.html`, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('game-table');
    await page.waitForFunction(() => {
      const table = document.querySelector('game-table');
      if (!table) return false;
      const statusEl = table.shadowRoot?.querySelector('.status');
      return statusEl?.textContent?.includes('Waiting for opponent');
    }, { timeout: 5000 });
    const canvas = page.locator('game-table canvas');
    await canvas.click({ position: { x: 320, y: 420 } });
    await page.waitForFunction(() => {
      const table = document.querySelector('game-table');
      if (!table) return false;
      const statusEl = table.shadowRoot?.querySelector('.status');
      return statusEl?.textContent?.startsWith('Played');
    }, { timeout: 4000 });
    await page.waitForFunction(() => {
      const table = document.querySelector('game-table');
      if (!table) return false;
      const statusEl = table.shadowRoot?.querySelector('.status');
      return statusEl?.textContent?.includes('Your turn');
    }, { timeout: 4000 });
    await browser.close();
    return true;
  } catch (err) {
    await browser.close();
    console.warn(`Playwright check failed in ${browserType.name()}:`, err.message);
    return false;
  }
}

async function run() {
  const server = await startServer();
  let passed = false;
  try {
    passed = (await runInBrowser(chromium)) || (await runInBrowser(webkit));
    if (passed) {
      console.log('Playwright status test passed');
    } else {
      console.error('Playwright status test could not run in available browsers.');
      process.exitCode = 1;
    }
  } finally {
    server.kill('SIGINT');
  }
}

run().catch((error) => {
  console.error('Playwright status test failed:', error);
  process.exit(1);
});
