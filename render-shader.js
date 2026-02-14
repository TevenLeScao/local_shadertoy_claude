#!/usr/bin/env node
/**
 * Headless Shader Renderer
 *
 * Renders a shader at multiple time points and saves screenshots.
 *
 * Usage:
 *   node render-shader.js
 */

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const HTML_FILE = path.join(__dirname, 'capture-standalone.html');

async function main() {
    console.log('Starting headless capture...');

    // Ensure screenshots directory exists
    if (!fs.existsSync(SCREENSHOT_DIR)) {
        fs.mkdirSync(SCREENSHOT_DIR);
    }

    const browser = await puppeteer.launch({
        headless: false,  // Use headed mode for WebGL support
        args: [
            '--enable-webgl',
            '--enable-webgl2',
            '--use-gl=angle',
            '--use-angle=metal',  // macOS Metal backend
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-web-security',
            '--allow-file-access-from-files'
        ]
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1400, height: 1000 });

    // Load the standalone capture page
    const fileUrl = `file://${HTML_FILE}`;
    console.log(`Loading ${fileUrl}`);

    await page.goto(fileUrl, { waitUntil: 'networkidle0', timeout: 30000 });

    // Wait for page to load and check for errors
    console.log('Waiting for page...');
    await new Promise(r => setTimeout(r, 3000));

    // Get page status
    const pageStatus = await page.evaluate(() => {
        return {
            status: document.getElementById('status')?.textContent || 'unknown',
            hasCanvas: !!document.getElementById('c'),
            hasWebGL: !!document.getElementById('c')?.getContext('webgl2'),
            capturedFrames: window.capturedFrames?.length || 0,
            errors: window.errors || []
        };
    });
    console.log('Page status:', pageStatus);

    // Take debug screenshot
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'debug.png'), fullPage: true });
    console.log('Debug screenshot saved');

    // Wait for captures to complete (with shorter timeout for debugging)
    console.log('Waiting for captures...');
    try {
        await page.waitForFunction(() => window.capturedFrames && window.capturedFrames.length >= 5, {
            timeout: 10000
        });
    } catch (e) {
        console.log('Capture wait timed out, checking what we have...');
    }

    // Get captured frame data
    const frames = await page.evaluate(() => window.capturedFrames || []);
    console.log(`Captured ${frames.length} frames`);

    if (frames.length === 0) {
        console.log('No frames captured. Check debug.png for details.');
        await browser.close();
        return;
    }

    // Save each frame
    for (const frame of frames) {
        const filename = `gare_de_lest_t${frame.time}.png`;
        const filepath = path.join(SCREENSHOT_DIR, filename);

        // Convert data URL to buffer
        const base64Data = frame.data.replace(/^data:image\/png;base64,/, '');
        const buffer = Buffer.from(base64Data, 'base64');

        fs.writeFileSync(filepath, buffer);
        console.log(`Saved: ${filepath}`);
    }

    // Also take a screenshot of the full page
    const pageScreenshot = path.join(SCREENSHOT_DIR, 'capture_page.png');
    await page.screenshot({ path: pageScreenshot, fullPage: true });
    console.log(`Page screenshot: ${pageScreenshot}`);

    await browser.close();
    console.log('Done!');
}

main().catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
