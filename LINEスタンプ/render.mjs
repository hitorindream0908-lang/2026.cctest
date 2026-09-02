// SVG -> PNG (LINEスタンプ規格: 370x320, 透過) を Chromium で書き出す
// 事前に `npm install playwright-core` が必要です。
import pw from 'playwright-core';
const { chromium } = pw;
// Chromium の実行パスは環境変数 CHROME_PATH で上書きできます。
const CHROME = process.env.CHROME_PATH || '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';
import fs from 'fs';
import path from 'path';

const here = path.dirname(decodeURIComponent(new URL(import.meta.url).pathname));
const svgDir = path.join(here, 'svg');
const pngDir = path.join(here, 'png');
fs.mkdirSync(pngDir, { recursive: true });

const browser = await chromium.launch({
  executablePath: CHROME,
  args: ['--no-sandbox', '--force-color-profile=srgb'],
});
// LINE規格ぴったり(370x320, 等倍)で書き出す
const page = await browser.newPage({ deviceScaleFactor: 1 });

async function shot(svg, w, h, out) {
  const html = `<!doctype html><html><head><meta charset="utf-8">
    <style>*{margin:0;padding:0}html,body{background:transparent}
    #s{width:${w}px;height:${h}px}#s svg{width:${w}px;height:${h}px;display:block}</style></head>
    <body><div id="s">${svg.replace(/<\?xml.*?\?>/, '')}</div></body></html>`;
  await page.setViewportSize({ width: w, height: h });
  await page.setContent(html, { waitUntil: 'networkidle' });
  const el = await page.$('#s');
  await el.screenshot({ path: out, omitBackground: true });
}

const files = fs.readdirSync(svgDir).filter(f => f.endsWith('.svg')).sort();
for (const f of files) {
  const svg = fs.readFileSync(path.join(svgDir, f), 'utf8');
  const out = path.join(pngDir, f.replace('.svg', '.png'));
  await shot(svg, 370, 320, out);          // 各スタンプ 370x320
  console.log('rendered', path.basename(out));
}

// メイン画像(240x240) と タブ画像(96x74) を「ありがとう」ベースで生成
const mainSvg = fs.readFileSync(path.join(svgDir, '05_arigatou.svg'), 'utf8');
await shot(mainSvg, 240, 240, path.join(pngDir, 'main.png'));
console.log('rendered main.png (240x240)');
const tabSvg = fs.readFileSync(path.join(svgDir, '16_matane.svg'), 'utf8');
await shot(tabSvg, 96, 74, path.join(pngDir, 'tab.png'));
console.log('rendered tab.png (96x74)');

await browser.close();
console.log('done');
