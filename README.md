# Edgenta HTML Slides

A Claude Code skill for creating UEM Edgenta-branded HTML presentations — from scratch or converted from existing content (PDF, PPTX, notes, briefs).

## What It Does

- Generates a single self-contained HTML file per deck
- Keyboard + on-screen navigation, fullscreen mode, dot pagination
- Slide transitions with directional fade and staggered element animations
- Chart.js support for data visualisation
- Export to PDF via included script

---

## Getting Started

### 1. Download

Go to the [Releases](https://github.com/roy-edgenta/Edgenta-HTML-Slides-Skill/releases) page and download the latest `edgenta-html-slides-vX.X.skill` file.

### 2. Install in Claude Code

Open your terminal and run:

```bash
claude skill install edgenta-html-slides-vX.X.skill
```

Or via the Claude Code UI: open the Skills panel, click **Install from file**, and select the `.skill` file.

### 3. Use It

In any Claude Code session, trigger the skill with:

```
/edgenta-html-slides
```

Or just describe what you want naturally — "make me a deck about X", "turn this PDF into slides", "create a presentation for the board". Claude will detect the intent and launch the skill automatically.

### 4. What Happens Next

The skill walks you through a short guided flow:

1. **Input** — paste notes, upload a PDF/PPTX, or start from scratch
2. **Outline** — review and approve the proposed slide structure
3. **Theme** — pick Default, Duo Tone Blue, or Dark Mode
4. **Generate** — the full HTML deck is created and saved
5. **Share** — deploy to a live URL when you're ready (see [Deploy to Vercel](#deploy-to-vercel))

---

## Usage

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

## Deploy to Vercel

Just say **"publish this"** after generating a deck — Claude handles the rest conversationally:

1. Checks you're logged in to Vercel (opens browser if not)
2. Checks if you have a dashboard — creates one if not
3. Publishes the deck to a permanent live URL
4. Gives you both the deck link and your dashboard link

Your dashboard lives at `{username}-uem-edgenta-slides.vercel.app` and lists all your published decks.

```bash
# Or run manually:
bash scripts/deploy.sh _output/my-deck.html
```

---

## Remove a Deck

Say **"remove [deck name]"** — Claude will confirm, then permanently delete the deployment and remove it from your dashboard.

```bash
# Or run manually:
bash scripts/remove.sh <deck-name>
```

---

## Assets

| File | Description |
|------|-------------|
| `assets/base-template.html` | Base HTML template all decks are built from |
| `assets/dashboard-template.html` | Vercel dashboard index page |
| `assets/icons.json` | 1,512 Phosphor icons (SVG strings) |
| `references/icon-index.md` | Icon name index for quick lookup |
| `scripts/deploy.sh` | Publish deck to Vercel |
| `scripts/remove.sh` | Remove a deck from Vercel and dashboard |
| `scripts/export-pdf.sh` | HTML → PDF export script |

---

## Version

Current: **v0.52**
