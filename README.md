# Edgenta HTML Slides

A Claude Code skill for creating UEM Edgenta-branded HTML presentations — from scratch or converted from existing content (PDF, PPTX, notes, briefs).

## What It Does

- Generates a single self-contained HTML file per deck
- Keyboard + on-screen navigation, fullscreen mode, dot pagination
- Slide transitions with directional fade and staggered element animations
- Chart.js support for data visualisation
- Export to PDF via included script

---

## Usage

In Claude Code, trigger the skill with:

```
/edgenta-html-slides
```

Or describe what you want naturally — "make me a deck about X", "turn this PDF into slides", "create a presentation for Y".

---

## Slide Types

| Type | Description |
|------|-------------|
| **Cover** | Full-bleed branded background, title + subtitle |
| **Content** | Logo top-right, title, subtitle, flexible layout |
| **Breaker** | Section divider with branded background |
| **End** | Branded closing slide, no text |

**Slide order:** Cover → Content → [Breaker → Content]* → End

---

## Themes

| Theme | Description |
|-------|-------------|
| **Default** | Light mode, full brand colour palette |
| **Duo Tone Blue** | Restricted palette — white, near-black, and primary blue only |
| **Dark Mode** | Deep navy backgrounds, adjusted primary blue |

---

## Brand Colours

| Token | Hex |
|-------|-----|
| Primary | `#2940BE` |
| Primary Light | `#3d55d4` |
| Primary Dark | `#1a2a8a` |
| Sky Blue | `#1490EA` |
| Purple | `#732BCC` |
| Teal | `#19C9A5` |
| Orange | `#E97132` |

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `→` / `Space` | Next slide |
| `←` | Previous slide |
| `H` | First slide |
| `E` | Last slide |
| `F` | Toggle fullscreen |

---

## Export to PDF

Requires Node.js. Playwright and Chromium install automatically on first run.

```bash
bash scripts/export-pdf.sh <path-to-html> [output.pdf] [flag]
```

| Flag | Resolution | Quality |
|------|------------|---------|
| `--4k` | 3840×2160 | 4K |
| *(default)* | 2560×1440 | HD |
| `--compress` | 1920×1080 | Standard |
| `--compress-more` | 1280×720 | Compact |

**Examples:**

```bash
# Default HD export
bash scripts/export-pdf.sh output/my-deck.html

# 4K export
bash scripts/export-pdf.sh output/my-deck.html --4k

# Compressed
bash scripts/export-pdf.sh output/my-deck.html output/my-deck-small.pdf --compress
```

---

## Assets

| File | Description |
|------|-------------|
| `assets/icons.json` | 1,512 Phosphor icons (SVG strings) |
| `references/icon-index.md` | Icon name index for quick lookup |
| `scripts/export-pdf.sh` | HTML → PDF export script |

---

## Version

Current: **v0.3**
