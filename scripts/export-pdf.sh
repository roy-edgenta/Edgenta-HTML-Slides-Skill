#!/usr/bin/env bash
# export-pdf.sh — Export an HTML presentation to PDF
#
# Usage:
#   bash scripts/export-pdf.sh <path-to-html> [output.pdf]
#
# Examples:
#   bash scripts/export-pdf.sh ./presentation.html
#   bash scripts/export-pdf.sh ./presentation.html ./slides.pdf
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${CYAN}ℹ${NC} $*"; }
ok()   { echo -e "${GREEN}✓${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*" >&2; }

# ─── Args ─────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    err "Usage: bash scripts/export-pdf.sh <path-to-html> [output.pdf] [--4k] [--compress] [--compress-more]"
    exit 1
fi

# Parse flags
SCALE_FACTOR=2
POSITIONAL=()
for arg in "$@"; do
    case $arg in
        --compress-more) SCALE_FACTOR=1 ;;
        --compress)      SCALE_FACTOR=1.5 ;;
        --4k)            SCALE_FACTOR=3 ;;
        *)               POSITIONAL+=("$arg") ;;
    esac
done
set -- "${POSITIONAL[@]}"

INPUT_HTML=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
if [[ ! -f "$INPUT_HTML" ]]; then err "File not found: $1"; exit 1; fi

if [[ $# -ge 2 ]]; then
    OUTPUT_PDF="$2"
else
    OUTPUT_PDF="$(dirname "$INPUT_HTML")/$(basename "$INPUT_HTML" .html).pdf"
fi
OUTPUT_DIR=$(mkdir -p "$(dirname "$OUTPUT_PDF")" && cd "$(dirname "$OUTPUT_PDF")" && pwd)
OUTPUT_PDF="$OUTPUT_DIR/$(basename "$OUTPUT_PDF")"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       Export Slides to PDF            ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""

# ─── Dependencies ─────────────────────────────────────────

info "Checking dependencies..."
if ! command -v npx &>/dev/null; then
    err "Node.js is required. Install: brew install node"
    exit 1
fi
ok "Node.js found"

# ─── Build export script ───────────────────────────────────

TEMP_DIR=$(mktemp -d)
SERVE_DIR=$(dirname "$INPUT_HTML")
HTML_FILENAME=$(basename "$INPUT_HTML")

cat > "$TEMP_DIR/export.mjs" << 'EOF'
import { chromium } from 'playwright';
import { createServer } from 'http';
import { readFileSync, mkdirSync, unlinkSync, writeFileSync } from 'fs';
import { join, extname } from 'path';
import { execSync } from 'child_process';
import { PDFDocument } from 'pdf-lib';

const [SERVE_DIR, HTML_FILE, OUTPUT_PDF, SCREENSHOT_DIR, SCALE] = process.argv.slice(2);
const deviceScaleFactor = parseFloat(SCALE) || 2;

const MIME = {
  '.html':'text/html', '.css':'text/css', '.js':'application/javascript',
  '.json':'application/json', '.png':'image/png', '.jpg':'image/jpeg',
  '.jpeg':'image/jpeg', '.svg':'image/svg+xml', '.webp':'image/webp',
  '.woff':'font/woff', '.woff2':'font/woff2', '.ttf':'font/ttf',
};

const server = createServer((req, res) => {
  const url = decodeURIComponent(req.url);
  const filePath = join(SERVE_DIR, url === '/' ? HTML_FILE : url);
  try {
    const content = readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': MIME[extname(filePath).toLowerCase()] || 'application/octet-stream' });
    res.end(content);
  } catch { res.writeHead(404); res.end('Not found'); }
});
const port = await new Promise(r => server.listen(0, () => r(server.address().port)));
console.log(`  Local server on port ${port}`);

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor });
await page.goto(`http://localhost:${port}/`, { waitUntil: 'networkidle' });
await page.evaluate(() => document.fonts.ready);

// Hide nav, reset scale, remove dark stage background
await page.evaluate(() => {
  const nav = document.getElementById('nav');
  if (nav) nav.style.display = 'none';
  const container = document.getElementById('slide-container');
  if (container) { container.style.transform = 'none'; container.style.transformOrigin = 'top left'; }
  const stage = document.getElementById('stage');
  if (stage) stage.style.cssText = 'position:fixed;inset:0;margin:0;padding:0;background:transparent;display:block;';
  document.body.style.background = 'transparent';
});

// Disable Chart.js animations
await page.evaluate(() => {
  if (window.Chart) {
    Chart.defaults.animation = false;
    Chart.defaults.animations = false;
    Chart.defaults.transitions = {};
    Object.values(Chart.instances).forEach(c => { c.options.animation = false; c.update('none'); });
  }
});
await page.waitForTimeout(800);

const slideCount = await page.evaluate(() => document.querySelectorAll('.slide').length);
console.log(`  Found ${slideCount} slides`);
if (slideCount === 0) { console.error('  ERROR: No .slide elements found.'); await browser.close(); server.close(); process.exit(1); }

mkdirSync(SCREENSHOT_DIR, { recursive: true });
const screenshotPaths = [];

for (let i = 0; i < slideCount; i++) {
  await page.evaluate((idx) => {
    document.querySelectorAll('.slide').forEach((s, j) => {
      s.style.transition = 'none';
      s.style.opacity = j === idx ? '1' : '0';
      s.style.transform = 'translate(0,0)';
      s.style.pointerEvents = j === idx ? 'all' : 'none';
      if (j === idx) s.classList.add('active'); else s.classList.remove('active');
    });
  }, i);

  await page.evaluate((idx) => {
    const slide = document.querySelectorAll('.slide')[idx];
    slide?.querySelectorAll('canvas').forEach(c => { const ch = Chart.getChart(c); if (ch) { ch.options.animation = false; ch.update('none'); } });
  }, i);

  await page.waitForTimeout(300);

  const screenshotPath = join(SCREENSHOT_DIR, `slide-${String(i + 1).padStart(3, '0')}.jpg`);
  await page.locator('.slide.active').first().screenshot({ path: screenshotPath, type: 'jpeg', quality: 97 });
  try { execSync(`sips --deleteProperty profile "${screenshotPath}" 2>/dev/null`); } catch {}
  screenshotPaths.push(screenshotPath);
  console.log(`  Captured slide ${i + 1}/${slideCount}`);
}

await browser.close();
server.close();

console.log('  Assembling PDF...');
const pdfDoc = await PDFDocument.create();
for (const p of screenshotPaths) {
  const img = await pdfDoc.embedJpg(readFileSync(p));
  const pg = pdfDoc.addPage([img.width, img.height]);
  pg.drawImage(img, { x: 0, y: 0, width: img.width, height: img.height });
}
writeFileSync(OUTPUT_PDF, await pdfDoc.save());
screenshotPaths.forEach(p => unlinkSync(p));
console.log(`  ✓ PDF saved to: ${OUTPUT_PDF}`);
EOF

# ─── Install deps ──────────────────────────────────────────

info "Setting up Playwright..."
info "This may take a moment on first run..."
echo ""

cd "$TEMP_DIR"
echo '{"name":"slide-export","private":true,"type":"module"}' > package.json
npm install playwright pdf-lib &>/dev/null || { err "npm install failed."; rm -rf "$TEMP_DIR"; exit 1; }
npx playwright install chromium 2>/dev/null || { err "Chromium install failed."; rm -rf "$TEMP_DIR"; exit 1; }
ok "Playwright ready"
echo ""

# ─── Run ───────────────────────────────────────────────────

SCREENSHOT_DIR="$TEMP_DIR/screenshots"
info "Exporting slides to PDF..."
echo ""

node "$TEMP_DIR/export.mjs" "$SERVE_DIR" "$HTML_FILENAME" "$OUTPUT_PDF" "$SCREENSHOT_DIR" "$SCALE_FACTOR" || {
    err "PDF export failed."
    rm -rf "$TEMP_DIR"
    exit 1
}

rm -rf "$TEMP_DIR"

echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
ok "PDF exported successfully!"
echo ""
echo -e "  ${BOLD}File:${NC}  $OUTPUT_PDF"
echo -e "  Size:  $(du -h "$OUTPUT_PDF" | cut -f1 | xargs)"
echo ""
echo "  Note: Animations are not preserved (static export)."
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo ""

command -v open &>/dev/null && open "$OUTPUT_PDF"
