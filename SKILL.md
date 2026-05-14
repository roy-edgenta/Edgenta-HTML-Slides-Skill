---
name: edgenta-html-slides
description: >
  [v0.3] Build or convert content into UEM Edgenta-branded HTML slide decks. Trigger on /edgenta-html-slides
  or when the user says "presentation", "deck", "slides", "pitch", or wants a file turned into slides.
  Outputs a single self-contained HTML file with navigation and animations.
---

# Edgenta HTML Slides

## How to Invoke

Type `/` in Claude Code and select **edgenta-html-slides** from the autocomplete menu. Or just describe what you want naturally — Claude will trigger this skill automatically when the request matches.

---

## Prerequisites

Read `/mnt/skills/public/frontend-design/SKILL.md` for general design thinking, typography,
motion, spatial composition, and visual detail principles. Brand-specific rules in this file
take precedence over the general skill wherever they conflict.

---

## Workflow

Every generation follows these stages in order. Never skip a stage. Never start generating HTML until the user has approved the outline and confirmed the final prompt.

**Always use the `AskUserQuestion` tool to present choices — never list options as plain markdown text.** This applies to every decision point: structure choice (Condense vs 1:1), theme selection, and any other prompt where the user must pick between options.

---

### Stage 1 — Detect Input Mode

| Mode                       | Signal                                            |
|----------------------------|---------------------------------------------------|
| **From scratch**           | No content provided                               |
| **From text / notes**      | User pastes a brief, outline, or notes            |
| **From file (PDF / PPTX)** | File uploaded                                     |
| **Research**               | User provides a topic and asks Claude to research |

---

### Stage 2 — Mode-Specific Steps

#### From Scratch
- Nothing is provided yet — ask what's needed to understand the topic, audience, and purpose before proceeding. See Information Gathering below.

#### From Text / Notes / Brief
- Infer structure and content from what's provided.
- Do not re-ask anything clearly answered by the content.

#### From File (PDF / PPTX)
- **PDF:** Use the bash tool to extract text (`pdftotext` or python `pdfplumber`). Treat headings as slide titles, body text as content.
- **PPTX:** Use python `python-pptx` to iterate slides — extract title, body, and notes per slide.
- Infer charts or visuals from data tables or bullet lists of numbers.
- After extracting, ask the user how they want to structure the deck:

| Option                            | Description                                                                                               |
|-----------------------------------|-----------------------------------------------------------------------------------------------------------|
| **A — Condense** *(Recommended)* | Combine related slides into fewer, stronger slides. Similar topics are merged, redundant content trimmed.  |
| **B — 1:1**                       | Same number of slides as the original. Content is preserved but fully redesigned.                         |

- Always recommend Condense. Never assume.
- If the source has more than 10 slides, explicitly note this when presenting the options — e.g. *"Your file has 18 slides — I'd recommend Condense to keep the deck focused."*
- **1:1 means same slide count and content — not a copy.** Claude still fully redesigns layout, typography, and visual treatment.

#### Research
- Ask what's needed to understand the angle, audience, and scope before researching. See Information Gathering below.
- Conduct research first, then structure findings into a deck.

---

### Stage 3 — Slide Outline

Present the proposed slide structure as a table, then immediately use `AskUserQuestion` with exactly two options:

| #  | Type    | Title          | Content Summary                                                  |
|----|---------|----------------|------------------------------------------------------------------|
| 1  | Cover   | Deck title     | Subtitle                                                         |
| 2  | Content | Slide title    | What goes on this slide — layout type, key data points, visuals  |
| 3  | Breaker | Section title  | —                                                                |
| …  | …       | …              | …                                                                |
| n  | End     | —              | —                                                                |

- Content summary describes the intended layout and content — not copied text from the source.
- For file inputs, flag any slides where source content was unclear or visuals could not be extracted.

**`AskUserQuestion` after the outline:**
- Option 1: "Looks good, let's go!"
- Option 2: "I want to make changes" — user types what they want to change

If the user selects option 2, apply the changes and re-present the outline. Repeat until approved.

**Do not ask about theme in this message. Do not generate any code. Stop and wait.**

---

### Stage 4 — Theme

After outline approval, use `AskUserQuestion` to ask which theme:

- Option 1: **Default** — light mode, full brand colour palette
- Option 2: **Duo Tone Blue** — restricted palette, primary blue family only
- Option 3: **Dark Mode** — deep navy backgrounds, primary blue adjusted for dark surfaces

**Do not generate any code in this message. Stop and wait for the user's selection, then generate.**

---

### Design Rules — All Input Modes

- **Never copy-paste source content and reformat it.** The source file or text is reference material only — not a design template.
- Every slide must be redesigned from the ground up. Turn bullet lists into stat cards, tables into charts, paragraphs into callouts.
- This applies equally to 1:1 mode, PDF inputs, PPTX inputs, and any other file type.
- No slide should look like it was lifted from the original with brand colors applied.

---

### Information Gathering

Before building the outline, Claude needs to understand the following. **Do not ask as a numbered list.** Read what the user has provided, infer what you can, and ask only about what's genuinely missing — in natural language, grouped into a single conversational message.

| What's needed      | When to ask                                                              |
|--------------------|--------------------------------------------------------------------------|
| Title and subtitle | Ask if not clear from the content                                        |
| Purpose / goal     | Ask if the intent is ambiguous                                           |
| Audience           | Ask if it affects tone, depth, or content decisions                      |
| Slide count        | Ask only if no clear scope exists — otherwise infer from content volume  |
| Content / topics   | Ask only if there's not enough to work with                              |

**Examples of good vs. rigid:**

❌ Rigid — don't do this:
> Q1. What is the title?
> Q2. What is the purpose?
> Q3. Who is the audience?

✅ Natural — do this:
> *Quick question before I map this out — who's the audience for this, and is there a specific message or outcome you want the deck to land?*

If the user has provided enough context to infer all of the above, skip this step entirely and go straight to the outline.

---

## Versioning

Add the following comment as the last line before `</html>` in every generated deck:

```html
<!-- Edgenta HTML Slides v0.3 -->
</html>
```

Do not change the version string. It tracks which version of the skill generated the file.

---

## Output Requirements

- Single self-contained HTML file — no external dependencies except Google Fonts, Chart.js CDN, and the Edgenta asset URLs (all load from the internet; no local file references).
- Slide canvas: **1280×720px**. Usable area: **1208×648px** (36px inner margin all sides).
- Canvas must stay fully fitted to the browser viewport at all times.
- Apply `transform: scale()` to the slide container with `transform-origin: center center`.
- Set `flex-shrink: 0` on the slide container — without it, flexbox compresses the canvas and breaks scale centering.
- Recalculate scale on page load and every browser resize.
- Scale all content proportionally — fonts, spacing, icons, charts, layout. Do not reflow responsively.

### Slide Body Container

Every content slide **must** use a `.slide-body` wrapper for all content. This gives every layout — including charts — a fixed, predictable container to measure against, preventing overflow and Chart.js sizing errors.

```html
<div class="slide slide-content">
  <img class="logo" src="..." alt="UEM Edgenta" />
  <div class="slide-body">
    <!-- all slide content goes here -->
  </div>
</div>
```

```css
.slide-body {
  position: absolute;
  top: 36px;
  left: 36px;
  width: 1208px;
  height: 648px;
  overflow: hidden;
}
```

- The logo sits outside `.slide-body` — it is positioned absolutely at `top: 36px; right: 36px` relative to the slide canvas.
- All other content — titles, subtitles, grids, charts, cards — goes inside `.slide-body`.
- Never use `padding` on `.slide slide-content` for spacing — use `.slide-body` instead.
- Cover, Breaker, and End slides do not use `.slide-body`.

**Scale formula:** `scale = min(viewportWidth / 1280, (viewportHeight - navHeight) / 720)`

Where `navHeight = 40` — the fixed nav bar height, matching `NAV_H = 40` in the navbar JavaScript template.

---

## Core Principles

1. **Show, Don't Tell** — Once approved, generate the full HTML immediately without asking further questions. People discover what they want by seeing it, not by answering more prompts.
2. **Distinctive Design** — No generic "AI slop." Every deck must feel custom-crafted and context-specific.
3. **Visualise Content** — Charts, stat cards, icons, diagrams, and timelines are always preferred over plain bullet lists.

---

## Design Aesthetics

You tend to converge toward generic, "on distribution" outputs — predictable layouts, safe color use, repeated component patterns. Avoid this. Make creative, distinctive slides that surprise and delight.

Focus on:
- **Color & Theme:** Commit to a cohesive aesthetic within the brand palette. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion:** Use animations for high-impact moments. One well-orchestrated slide entry with staggered reveals (`animation-delay`) creates more delight than scattered micro-interactions.
- **Layout:** Bold splits, color panels, asymmetric grids, overlap. Never use the same layout twice in a row.

**Brand guardrail:** Creative freedom applies to layout, composition, and palette use — not to overriding brand colors, fonts, or logo rules.

---

## Brand Colors

Default slide background: `#f2f2f2`. Layouts are encouraged to be creative — split backgrounds, bold color panels, and primary blue accent zones are all welcome.

### Primary Palette

| Token          | Hex       | Usage                         |
|----------------|-----------|-------------------------------|
| Primary        | `#2940BE` | Main brand anchor             |
| Primary Light  | `#3d55d4` | Highlights and lighter fills  |
| Primary Dark   | `#1a2a8a` | Depth and contrast            |
| Primary Darker | `#0d1a6e` | Strong contrast and emphasis  |

### Accent Colors — use only when semantically appropriate

| Token     | Hex       | Usage                                  |
|-----------|-----------|----------------------------------------|
| Sky Blue  | `#1490EA` | Secondary fills and accents            |
| Purple    | `#732BCC` | Contrast and emphasis                  |
| Teal      | `#19C9A5` | Positive, complete, successful states  |
| Orange    | `#E97132` | Warning, delay, on-hold states         |
| Dark Text | `#313231` | Default body text                      |
| White     | `#FFFFFF` | Text or icons on dark backgrounds      |

---

## Logo

Appears on **content slides only** — not on Cover, Breaker, or End.

| Property  | Value                                       |
|-----------|---------------------------------------------|
| Width     | 98px                                        |
| Height    | 53px                                        |
| Placement | Top-right corner: `top: 36px; right: 36px`  |

- Light backgrounds: `https://raw.githubusercontent.com/roysoetantio/assets/refs/heads/main/edgenta-slide/asset/uemedgenta.png`
- Dark or primary blue backgrounds: `https://raw.githubusercontent.com/roysoetantio/assets/refs/heads/main/edgenta-slide/asset/uemedgenta_white.png`

---

## Slide Types

### Cover
- Background: full-bleed `https://raw.githubusercontent.com/roysoetantio/assets/refs/heads/main/edgenta-slide/asset/slide_cover.jpg`
- No logo.
- Title and subtitle **right-aligned**, left edge ~700px, right margin 36px, vertically centered at ~42% from top.
- Title color: `#1C6BA3`, bold. Subtitle color: `#36383C`, directly below title.

### Breaker
- Background: full-bleed `https://raw.githubusercontent.com/roysoetantio/assets/refs/heads/main/edgenta-slide/asset/slide_breaker.jpg`
- No logo. Same title/subtitle placement and colors as Cover.
- Use when content transitions to a new section.

### End
- Background: full-bleed `https://raw.githubusercontent.com/roysoetantio/assets/refs/heads/main/edgenta-slide/asset/slide_end.jpg`
- No logo. No text. Use as-is. Always the last slide.

### Content
- Title top-left, color `#161618`, font-size 32px.
- Subtitle directly below title, color `#36383C`, font-size 20px.
- **Every content slide must have a subtitle — no exceptions.**
- Logo top-right (see Logo section).

---

## Slide Order

```
Cover → [Content slides...] → [Breaker → Content slides...]* → End
```

Every deck starts with a Cover and ends with an End. Insert a Breaker only when content transitions to a new section.

---

## Typography

Load both fonts in `<head>`:

```html
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;900&family=DM+Sans:wght@400;500;700&display=swap" rel="stylesheet">
```

| Font             | Usage                                       |
|------------------|---------------------------------------------|
| Playfair Display | Hero numbers, big statements, key callouts  |
| DM Sans          | All other content — body, labels, captions  |

| Element                        | Size                             |
|--------------------------------|----------------------------------|
| Slide title                    | 32px                             |
| Slide subtitle                 | 20px                             |
| Section headers / key callouts | 36–48px (Playfair Display, bold) |
| Normal paragraph               | 16px                             |
| Minimum font size              | **16px — never smaller**         |

---

## Themes

### Default
Standard light mode. Full brand color palette as defined above.

### Duo Tone Blue
Restricted palette — white, near-black, and primary blue family only. Applies to content slides; Cover, Breaker, and End are unaffected.

| Usage            | Color     |
|------------------|-----------|
| Slide background | `#f2f2f2` |
| Primary elements | `#2940BE` |
| Text             | `#161618` |
| Text on dark bg  | `#FFFFFF`  |

Chart series (light→dark): `#3d55d4`, `#2940BE`, `#1a2a8a`, `#0d1a6e`

Rules: No sky blue, purple, teal, or orange for decorative use. Status colors (teal/orange) allowed only when semantically necessary.

### Dark Mode
Deep navy backgrounds with primary blue adjusted for dark surfaces. Applies to content slides; Cover, Breaker, and End are unaffected.

| Usage            | Color                                                              |
|------------------|--------------------------------------------------------------------|
| Slide background | `linear-gradient(135deg, #0f1117 0%, #111829 50%, #0d1224 100%)`  |
| Card / surface   | `#1a1d2e`                                                          |
| Card elevated    | `#232740`                                                          |
| Primary elements | `#4a63e0`                                                          |
| Text             | `#f2f2f2`                                                          |
| Muted text       | `#9aa0b8`                                                          |
| Card border      | `#2a2f50`                                                          |
| Nav bar bg       | Handled by the fixed navbar template — do not override             |

Chart series (light→dark on dark bg): `#7b8ff5`, `#4a63e0`, `#2940BE`, `#1a2a8a`

Rules:
- Use `rgba(41, 64, 190, 0.1–0.2)` for subtle tinted card backgrounds.
- Logo: always use `uemedgenta_white.png` on dark slides.
- Charts: use the full accent palette (Sky Blue, Teal, Orange, Purple + primary blue family) — colorful charts read better on dark surfaces.

---

## Slide Transitions

Slides transition with a directional fade-nudge: next slides enter from the right, previous slides enter from the left. Keep all slides in the DOM at all times — control visibility via `opacity` and `pointer-events`, never `display: none/block`.

```css
.slide {
  position: absolute;
  inset: 0;
  opacity: 0;
  pointer-events: none;
  transform: translateX(0);
}

.slide.active {
  opacity: 1;
  pointer-events: all;
  transform: translateX(0);
  transition: transform 0.35s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.35s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide.slide-enter-left  { opacity: 0; transform: translateX(40px);  transition: none; }
.slide.slide-enter-right { opacity: 0; transform: translateX(-40px); transition: none; }

.slide.slide-exit-left  { opacity: 0; transform: translateX(-40px); transition: transform 0.35s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.35s cubic-bezier(0.4, 0, 0.2, 1); }
.slide.slide-exit-right { opacity: 0; transform: translateX(40px);  transition: transform 0.35s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.35s cubic-bezier(0.4, 0, 0.2, 1); }
```

### Element Entrance Animations

Each element within a slide staggers in from below when the slide becomes active. Add `slide-in` via JS (see `goTo`) — removing and re-adding it forces a reflow so animations replay on every visit.

```css
@keyframes fadeSlideUp {
  from { opacity: 0; transform: translateY(18px); }
  to   { opacity: 1; transform: translateY(0); }
}

.slide.slide-in .logo           { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.05s both; }
.slide.slide-in .cover-title,
.slide.slide-in .slide-title    { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.1s  both; }
.slide.slide-in .cover-subtitle,
.slide.slide-in .slide-subtitle { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.18s both; }

.slide.slide-in .stat-card:nth-child(1),
.slide.slide-in .pillar-card:nth-child(1) { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.25s both; }
.slide.slide-in .stat-card:nth-child(2),
.slide.slide-in .pillar-card:nth-child(2) { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.33s both; }
.slide.slide-in .stat-card:nth-child(3),
.slide.slide-in .pillar-card:nth-child(3) { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.41s both; }
.slide.slide-in .pillar-card:nth-child(4) { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.49s both; }

.slide.slide-in .chart-wrap            { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.25s both; }
.slide.slide-in .insight-item:nth-child(1) { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.3s  both; }
.slide.slide-in .insight-item:nth-child(2) { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.38s both; }
.slide.slide-in .insight-item:nth-child(3) { animation: fadeSlideUp 0.4s cubic-bezier(0.4,0,0.2,1) 0.46s both; }
```

Extend the stagger selectors for any new repeating components (e.g. `.timeline-item`, `.table-row`) following the same `nth-child` pattern.

---

## Charts

Load Chart.js via CDN in `<head>`:

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
```

**Available types:** Bar, Line, Pie, Doughnut, Radar, Polar Area, Bubble, Scatter.

**Animation config — always set individually, never replace the object:**
```js
// ✅ Correct
Chart.defaults.animation.duration = 900;
Chart.defaults.animation.easing   = 'easeOutQuart';

// ❌ Wrong — breaks hover and tooltips
Chart.defaults.animation = { duration: 900, easing: 'easeOutQuart' };
```

**Sizing — always use explicit px height:**
```css
.chart-wrap {
  position: relative; /* required — Chart.js resolves height against this */
  width: 100%;
  height: 212px;      /* explicit px — adjust to fit your layout */
}
```
Never use `flex: 1`, `min-height: 0`, `auto`, or `%` for height. Chart.js reads container dimensions synchronously before flex/grid resolves — without an explicit `px` height, layout breaks.

---

## Icons

- Use icons **only** from `assets/icons.json` (1,512 Phosphor icons).
- To find the right icon: consult `references/icon-index.md` for key names, then read the matching SVG from `assets/icons.json`.
- **Read the full SVG string verbatim from `assets/icons.json` — do not reconstruct or write icon SVGs from memory or training data.** If the value appears truncated in the tool output, re-read with a higher character limit until you have the complete string.
- Copy the entire SVG string as-is into the HTML. Replace `currentColor` with the required hex before inserting.
- Do not use any external icon CDN or library.

---

## Navigation Bar

Use the exact template below — copy it verbatim into every generated deck. Only change the deck title text in `<span class="nav-deck-name">`. Do not alter class names, IDs, or structure.

- **Height:** 40px, fixed at the top
- **Left:** deck title — muted, uppercase, small
- **Center:** dot pagination, always truly centered on screen; active slide shows number in a circle
- **Right:** "Slide Show" button (monitor icon + label) in normal mode; minimize icon only (with border) in fullscreen; `?` help button with shortcut tooltip
- **Fullscreen:** nav overlays the slide (stage takes full viewport); background switches to white at 10% opacity; deck name and button align with slide's 36px left/right margins; nav auto-hides after 3s of inactivity

**Keyboard shortcuts:**

| Key     | Action          |
|---------|-----------------|
| `→`     | Next slide      |
| `←`     | Previous slide  |
| `Space` | Next slide      |
| `H`     | First slide     |
| `E`     | Last slide      |

### CSS — paste inside `<style>`

```css
/* ─── Navbar ─────────────────────────────────────── */
#nav {
  position: fixed;
  top: 0; left: 0; right: 0;
  height: 40px;
  background: rgba(20, 20, 24, 0.82);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(255,255,255,0.06);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  z-index: 100;
  transition: opacity 0.3s ease;
}

/* Pagination is always truly centered on screen */
#nav .nav-pagination {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
}

/* In fullscreen, nav overlays the slide */
body.is-fullscreen #nav {
  background: rgba(255, 255, 255, 0.1);
  border-bottom-color: transparent;
}
body.is-fullscreen #nav .nav-deck-name { color: rgba(0,0,0,0.4); }
body.is-fullscreen #nav .nav-pagination .dot { background: rgba(0,0,0,0.2); }
body.is-fullscreen #nav .nav-pagination .dot.active {
  background: rgba(0,0,0,0.06);
  border-color: transparent;
  color: rgba(0,0,0,0.5);
}
body.is-fullscreen #nav .nav-fullscreen {
  color: rgba(0,0,0,0.4);
  border: 1px solid rgba(0,0,0,0.2);
  border-radius: 6px;
  padding: 4px 8px;
}
body.is-fullscreen #nav .nav-fullscreen:hover {
  color: rgba(0,0,0,0.7);
  background: rgba(0,0,0,0.06);
  border-color: rgba(0,0,0,0.35);
}

/* Auto-hide nav in fullscreen after idle */
body.is-fullscreen.nav-hidden #nav {
  opacity: 0;
  pointer-events: none;
}

#nav .nav-deck-name {
  font-family: 'DM Sans', sans-serif;
  font-size: 11px;
  font-weight: 500;
  color: rgba(255,255,255,0.35);
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

#nav .nav-pagination {
  display: flex;
  align-items: center;
  gap: 8px;
  pointer-events: auto;
}

#nav .nav-pagination .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: rgba(255,255,255,0.25);
  transition: background 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0;
  cursor: pointer;
  flex-shrink: 0;
}

#nav .nav-pagination .dot.active {
  width: 22px;
  height: 22px;
  background: rgba(255,255,255,0.15);
  border-radius: 50%;
  font-size: 10px;
  font-weight: 600;
  color: rgba(255,255,255,0.6);
}

#nav .nav-fullscreen {
  background: none;
  border: none;
  color: rgba(255,255,255,0.35);
  font-family: 'DM Sans', sans-serif;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  padding: 4px 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 5px;
  border-radius: 4px;
  transition: color 0.2s, background 0.2s, border-color 0.2s;
}
#nav .nav-fullscreen:hover {
  color: rgba(255,255,255,0.7);
  background: rgba(255,255,255,0.08);
}
#nav .nav-fullscreen svg {
  width: 12px;
  height: 12px;
  flex-shrink: 0;
}

/* ─── Shortcut help ──────────────────────────────── */
.nav-help {
  position: relative;
  background: none;
  border: 1px solid rgba(255,255,255,0.2);
  color: rgba(255,255,255,0.3);
  font-family: 'DM Sans', sans-serif;
  font-size: 11px;
  font-weight: 600;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: 8px;
  transition: color 0.2s, border-color 0.2s;
  flex-shrink: 0;
}
.nav-help:hover { color: rgba(255,255,255,0.7); border-color: rgba(255,255,255,0.4); }
.nav-help .tooltip {
  display: none;
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  background: rgba(20, 20, 24, 0.96);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 8px;
  padding: 12px 16px;
  white-space: nowrap;
  z-index: 200;
  backdrop-filter: blur(10px);
}
.nav-help:hover .tooltip { display: block; }
.tooltip-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 4px 0;
}
.tooltip-row:not(:last-child) { border-bottom: 1px solid rgba(255,255,255,0.06); }
.tooltip-key {
  font-family: 'DM Sans', sans-serif;
  font-size: 11px;
  font-weight: 600;
  color: rgba(255,255,255,0.9);
  background: rgba(255,255,255,0.1);
  border-radius: 4px;
  padding: 2px 7px;
  min-width: 28px;
  text-align: center;
}
.tooltip-desc { font-family: 'DM Sans', sans-serif; font-size: 12px; color: rgba(255,255,255,0.45); }

body.is-fullscreen .nav-help { color: rgba(0,0,0,0.3); border-color: rgba(0,0,0,0.2); }
body.is-fullscreen .nav-help:hover { color: rgba(0,0,0,0.6); border-color: rgba(0,0,0,0.4); }
body.is-fullscreen .nav-help .tooltip { background: rgba(255,255,255,0.96); border-color: rgba(0,0,0,0.08); }
body.is-fullscreen .tooltip-key { color: rgba(0,0,0,0.8); background: rgba(0,0,0,0.08); }
body.is-fullscreen .tooltip-desc { color: rgba(0,0,0,0.4); }

/* ─── Slide stage ────────────────────────────────── */
#stage {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 40px;
  background: #111;
}
body.is-fullscreen #stage { margin-top: 0; }
```

### HTML — paste after `<body>`

```html
<div id="nav">
  <span class="nav-deck-name">DECK TITLE HERE</span>
  <div class="nav-pagination" id="pagination"></div>
  <div style="display:flex;align-items:center;gap:0">
    <button class="nav-fullscreen" id="btn-fullscreen" onclick="toggleFullscreen()">
      <svg id="fs-icon-expand" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="2" y="3" width="20" height="14" rx="2"/>
        <line x1="12" y1="17" x2="12" y2="21"/>
        <line x1="8" y1="21" x2="16" y2="21"/>
      </svg>
      <span id="fs-label">Slide Show</span>
      <svg id="fs-icon-exit" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:none">
        <polyline points="4 14 10 14 10 20"/><polyline points="20 10 14 10 14 4"/>
        <line x1="10" y1="14" x2="3" y2="21"/><line x1="21" y1="3" x2="14" y2="10"/>
      </svg>
    </button>
    <button class="nav-help">?
      <div class="tooltip">
        <div class="tooltip-row"><span class="tooltip-key">→</span><span class="tooltip-desc">Next slide</span></div>
        <div class="tooltip-row"><span class="tooltip-key">←</span><span class="tooltip-desc">Previous slide</span></div>
        <div class="tooltip-row"><span class="tooltip-key">Space</span><span class="tooltip-desc">Next slide</span></div>
        <div class="tooltip-row"><span class="tooltip-key">H</span><span class="tooltip-desc">First slide</span></div>
        <div class="tooltip-row"><span class="tooltip-key">E</span><span class="tooltip-desc">Last slide</span></div>
      </div>
    </button>
  </div>
</div>
```

### JavaScript — paste inside `<script>`

```js
// ─── Navbar: pagination, scale, fullscreen ────────────
const slides = document.querySelectorAll('.slide');
const totalSlides = slides.length;
let current = 0;

const pagination = document.getElementById('pagination');
const container  = document.getElementById('slide-container');
const deckName   = document.querySelector('.nav-deck-name');
const fsBtn      = document.getElementById('btn-fullscreen');
const NAV_H      = 40;

slides[0].classList.add('slide-in');

function buildPagination() {
  pagination.innerHTML = '';
  for (let i = 0; i < totalSlides; i++) {
    const dot = document.createElement('div');
    dot.className = 'dot' + (i === current ? ' active' : '');
    dot.textContent = i === current ? String(i + 1) : '';
    dot.addEventListener('click', () => goTo(i));
    pagination.appendChild(dot);
  }
}

function goTo(index) {
  const next = Math.max(0, Math.min(index, totalSlides - 1));
  if (next === current) return;
  const goingForward = next > current;

  const outgoing = slides[current];
  const incoming = slides[next];

  incoming.classList.add(goingForward ? 'slide-enter-left' : 'slide-enter-right');

  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      outgoing.classList.remove('active');
      outgoing.classList.add(goingForward ? 'slide-exit-left' : 'slide-exit-right');

      incoming.classList.remove('slide-enter-left', 'slide-enter-right', 'slide-in');
      void incoming.offsetWidth; // force reflow to restart animations
      incoming.classList.add('active', 'slide-in');

      outgoing.addEventListener('transitionend', () => {
        outgoing.classList.remove('slide-exit-left', 'slide-exit-right');
      }, { once: true });
    });
  });

  current = next;
  buildPagination();
}

document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowRight' || e.key === 'ArrowDown' || e.key === ' ') { e.preventDefault(); goTo(current + 1); }
  if (e.key === 'ArrowLeft'  || e.key === 'ArrowUp')                      goTo(current - 1);
  if (e.key === 'h' || e.key === 'H')                                     goTo(0);
  if (e.key === 'e' || e.key === 'E')                                     goTo(totalSlides - 1);
});

function rescale() {
  const isFs = !!document.fullscreenElement;
  const vw = window.innerWidth;
  const vh = isFs ? window.innerHeight : window.innerHeight - NAV_H;
  const scale = Math.min(vw / 1280, vh / 720);
  container.style.transform = `scale(${scale})`;
  if (isFs) {
    const slideLeft = (vw - 1280 * scale) / 2;
    deckName.style.marginLeft = `${Math.max(0, slideLeft + 36 * scale - 20)}px`;
    const slideRight = (vw + 1280 * scale) / 2;
    fsBtn.style.marginRight = `${Math.max(0, vw - slideRight + 36 * scale - 20)}px`;
  } else {
    deckName.style.marginLeft = '';
    fsBtn.style.marginRight  = '';
  }
}
window.addEventListener('resize', rescale);
rescale();

function toggleFullscreen() {
  if (!document.fullscreenElement) document.documentElement.requestFullscreen();
  else document.exitFullscreen();
}

let hideTimer = null;
function resetHideTimer() {
  document.body.classList.remove('nav-hidden');
  clearTimeout(hideTimer);
  if (document.fullscreenElement)
    hideTimer = setTimeout(() => document.body.classList.add('nav-hidden'), 3000);
}
document.addEventListener('mousemove', resetHideTimer);
document.addEventListener('keydown',   resetHideTimer);

document.addEventListener('fullscreenchange', () => {
  const isFs = !!document.fullscreenElement;
  document.body.classList.toggle('is-fullscreen', isFs);
  document.getElementById('fs-icon-expand').style.display = isFs ? 'none' : '';
  document.getElementById('fs-icon-exit').style.display   = isFs ? ''     : 'none';
  document.getElementById('fs-label').style.display       = isFs ? 'none' : '';
  if (!isFs) { clearTimeout(hideTimer); document.body.classList.remove('nav-hidden'); }
  else resetHideTimer();
  rescale();
});

buildPagination();
```

---

## Layout & Overlap Rules

- Minimum 24px gap between adjacent elements on all sides.
- No content may exceed the usable area of 1208×648px. Any element that would overflow must be resized or restructured to fit.
- Every slide needs strong visual hierarchy — the most important message must be the most dominant element.

---

## Reference Files

| File                       | When to read                                                 |
|----------------------------|--------------------------------------------------------------|
| `references/icon-index.md` | When choosing icons — scan key names to find the best match  |
| `assets/icons.json`        | When you have a key name — read the SVG string for that key  |

Read `references/icon-index.md` before `assets/icons.json` to avoid loading the full 1,512-icon file unnecessarily.

---

## Exporting to PDF

A script is available at `scripts/export-pdf.sh` to export any generated deck to PDF.

```bash
bash scripts/export-pdf.sh <path-to-html> [output.pdf] [--4k] [--compress] [--compress-more]
```

- `--4k`: **3840×2160** (3× — 4K, largest file)
- Default: **2560×1440** (2× — HD quality)
- `--compress`: **1920×1080** (1.5× — smaller file size)
- `--compress-more`: **1280×720** (1× — smallest file size)
- Requires Node.js. Playwright and Chromium are installed automatically on first run.
- The PDF is a static snapshot — animations are not preserved.
