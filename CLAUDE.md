# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Claude Code skill (`/edgenta-html-slides`) that generates UEM Edgenta-branded HTML slide decks and exports them to PDF. The entire skill is defined in `SKILL.md` — read it before making any changes.

## Key Files

| File | Purpose |
|------|---------|
| `SKILL.md` | The skill definition — all generation rules, brand guidelines, templates, and CSS/JS to use verbatim |
| `scripts/export-pdf.sh` | Bash + Playwright script to export HTML decks to PDF |
| `assets/icons.json` | 1,512 Phosphor icons — always read SVGs from here, never reconstruct from memory |
| `references/icon-index.md` | Index of icon names — read this first to find the right icon key before loading `icons.json` |

## Skill Workflow

When `/edgenta-html-slides` is triggered, always follow the staged workflow in `SKILL.md`:
1. Detect input mode (scratch / text / file / research)
2. Gather missing info
3. Present slide outline → wait for approval
4. Ask theme → wait for selection
5. Generate full HTML
6. After saving, drop a one-liner deploy hint — do not ask, do not block

Never skip stages or generate HTML before outline approval.

## HTML Output Rules

- Single self-contained HTML file, no local asset references
- Slide canvas: **1280×720px**, scaled to viewport via `transform: scale()`
- All slides use `opacity` + `pointer-events` for visibility — never `display: none`
- Nav bar, slide transitions, and element animations must use the exact CSS/JS templates in `SKILL.md`
- Icons must be read verbatim from `assets/icons.json` — never written from memory
- End every generated file with `<!-- Edgenta HTML Slides v0.4 -->`

## PDF Export

```bash
bash scripts/export-pdf.sh <path-to-html> [output.pdf] [--4k|--compress|--compress-more]
```

Resolutions: `--4k` = 3840×2160, default = 2560×1440, `--compress` = 1920×1080, `--compress-more` = 1280×720.

Requires Node.js. Playwright + Chromium install automatically on first run.

## Deploy to Vercel

```bash
bash scripts/deploy.sh <path-to-html>
```

Publishes the deck to a live public URL on Vercel. Handles Vercel CLI install and login automatically on first run. Always deploy the HTML file, not the PDF.

## Packaging

When the user asks to package the skill:
1. Ask for version number
2. Prepend `[vX.X]` to the description in `SKILL.md` frontmatter
3. Update the version stamp comment in `SKILL.md` (`<!-- Edgenta HTML Slides vX.X -->`)
4. Delete any existing `.skill` file for that version, then zip fresh:
   ```bash
   zip -r "_package/edgenta-html-slides-vX.X.skill" SKILL.md assets/ references/ scripts/
   ```
   Only these four — no `CLAUDE.md`, `README.md`, `.claude/`, or repo files.
