---
name: edgenta-html-slides
description: >
  [v0.52] Build or convert content into UEM Edgenta-branded HTML slide decks.
  Only trigger on explicit /edgenta-html-slides command.
  Outputs a single self-contained HTML file with navigation and animations.
---

# Edgenta HTML Slides

## How to Invoke

Type `/` in Claude Code and select **edgenta-html-slides** from the autocomplete menu. Or just describe what you want naturally — Claude will trigger this skill automatically when the request matches.

---

## Prerequisites

**Every generated deck starts from `assets/base-template.html`.** Read it before generating. Fill in all placeholders and inject content at `<!-- CONTENT_SLIDES -->`, `<!-- DECK_CSS -->`, `<!-- DECK_JS -->`. Do not rewrite the shell — only add what's unique to the deck.

| Placeholder | Where | Notes |
|---|---|---|
| `{{DECK_TITLE}}` | `<title>` + nav bar | Deck name |
| `{{COVER_TITLE}}` | Cover slide | Main title, Playfair Display |
| `{{COVER_SUBTITLE}}` | Cover slide | Subtitle below title |
| `{{BREAKER_NUM}}` | Each breaker | Zero-padded: `01`, `02`, `03`… |
| `{{BREAKER_TITLE}}` | Each breaker | Section name |
| `{{BREAKER_SUBTITLE}}` | Each breaker | Recommended; omit the div if not needed |

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

### Stage 5 — Publish to Vercel (optional)

After the HTML file has been saved, include this one-liner at the end of the generation message — do not ask, do not block:

> Want to share it as a live link? Just say **"publish this"** and I'll take care of it.

---

When the user asks to publish (any phrasing — "publish", "share", "deploy", "send me a link"):

Follow this exact conversational flow. Speak naturally. Never dump raw terminal output at the user.

#### Step 1 — Check Vercel login

Run silently: `npx vercel whoami`

- **If logged in:** "You're logged in as [username] — let's go."
- **If not logged in:** "Before I can publish, you'll need to log in to Vercel. I've opened the login page in your browser — go ahead and sign in, then come back here and let me know when you're done."
  - Run: `open https://vercel.com/login`
  - Wait for the user to confirm they've logged in
  - Re-run `npx vercel whoami` to verify
  - If still not logged in: "Hmm, I'm still not seeing you logged in. Try running `vercel login` in your terminal, then let me know."
  - If now logged in: "Perfect, you're in. Let's continue."

#### Step 2 — Check dashboard

Derive `PROJECT_NAME` as `{username}-uem-edgenta-slides`.
Check if `~/.edgenta-slides/{PROJECT_NAME}/.vercel/project.json` exists.

- **If exists:** "I can see you already have a dashboard set up. I'll add this deck to it."
- **If not exists:** "You don't have a dashboard yet — I'll create one for you as part of this publish. It's where all your HTML slides will live, and you'll get a permanent link to it."

#### Step 3 — Deploy the deck

Run `bash scripts/deploy.sh <path-to-html>` silently.

While it's running, say: "Publishing your deck now — this usually takes about 30 seconds..."

- **If it succeeds:** read `~/.edgenta-slides/{PROJECT_NAME}/last-deploy.json` to get the result. Then go to Step 4.
- **If it fails:** "Something went wrong while publishing. Here's what happened: [plain-English summary of the error]. Want me to try again?"

#### Step 4 — Confirm success

Read `last-deploy.json` — it contains:
```json
{
  "status": "ok",
  "deck_name": "...",
  "deck_url": "https://...",
  "dashboard_url": "https://...",
  "first_deploy": true/false
}
```

Respond warmly and clearly. Always give both links:

> "Done! Here's what I set up for you:
>
> **Your deck:** [deck_url]
> **Your dashboard:** [dashboard_url]
>
> The dashboard is where all your HTML slides live — anyone with the link can access it. The deck link is permanent and works on any device."

If `first_deploy` is `true`, add:
> "This is your first deck — every time you publish a new one, it'll automatically appear on your dashboard."

If `first_deploy` is `false`, add:
> "Your dashboard has been updated with this deck."

---

### Stage 6 — Remove a Deck (optional)

When the user asks to remove, delete, or unpublish a deck from the dashboard:

#### Step 1 — Show what's published

Read `~/.edgenta-slides/{PROJECT_NAME}/registry.json` and list the decks clearly:

> "Here are your published decks:
> 1. [deck-name-one] — published [date]
> 2. [deck-name-two] — published [date]
>
> Which one would you like to remove?"

If registry doesn't exist or is empty:
> "You don't have any published decks yet."

#### Step 2 — Confirm

Always confirm before removing — this is permanent:

> "Just to confirm — you want to completely delete **[deck name]**? This will remove it from your dashboard and delete the live link permanently. It can't be undone."

Wait for the user to confirm.

#### Step 3 — Remove

Run silently: `bash scripts/remove.sh <deck-name>`

While running: "Removing it now and updating your dashboard..."

- **If it succeeds:** read `~/.edgenta-slides/{PROJECT_NAME}/last-remove.json`, then go to Step 4.
- **If it fails:** "Something went wrong. Here's what happened: [plain-English summary]. Want me to try again?"

#### Step 4 — Confirm removal

Read `last-remove.json`:
```json
{
  "status": "ok",
  "deck_name": "...",
  "dashboard_url": "https://...",
  "remaining_decks": 2
}
```

> "Done — **[deck_name]** has been completely deleted. The link no longer works and it's been removed from your dashboard.
>
> **Your dashboard:** [dashboard_url]"

If `remaining_decks` is `0`, add:
> "Your dashboard is now empty. Publish a new deck whenever you're ready."

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

## Output Requirements

- Slide canvas: **1280×720px**. Usable area: **1208×648px** (36px inner margin all sides).
- Scale all content proportionally — fonts, spacing, icons, charts, layout. Do not reflow responsively.

**Scale formula:** `scale = min(viewportWidth / 1280, (viewportHeight - 40) / 720)` — handled by the base template.

---

## Core Principles

1. **Show, Don't Tell** — Once approved, generate the full HTML immediately without asking further questions. People discover what they want by seeing it, not by answering more prompts.
2. **Distinctive Design** — No generic "AI slop." Every deck must feel custom-crafted and context-specific.
3. **Visualise Content** — Charts, stat cards, icons, diagrams, and timelines are always preferred over plain bullet lists.

## Design Rules

- **Never copy-paste source content and reformat it.** The source file or text is reference material only — not a design template.
- Every slide must be redesigned from the ground up. Turn bullet lists into stat cards, tables into charts, paragraphs into callouts.
- This applies equally to 1:1 mode, PDF inputs, PPTX inputs, and any other file type.
- No slide should look like it was lifted from the original with brand colors applied.

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
Defined in `assets/base-template.html` — do not regenerate. Fill `{{COVER_TITLE}}` and `{{COVER_SUBTITLE}}` only.

### Breaker
Insert between sections. The breaker HTML lives as a commented template block inside `assets/base-template.html` (you already read this file). For each breaker needed:

1. Copy the commented block from `base-template.html`
2. Fill in the placeholders — do not leave any unfilled
3. Inject it (uncommented) inside `<!-- CONTENT_SLIDES -->`

**Placeholder rules:**
- `{{BREAKER_NUM}}` — zero-padded section counter: `01`, `02`, `03`… increments per breaker across the whole deck
- `{{BREAKER_TITLE}}` — the section name, always required
- `{{BREAKER_SUBTITLE}}` — recommended; if genuinely not needed, remove the `.breaker-subtitle` div entirely

The canvas (`.brk-dots`) and all styling are handled by the base template — no extra CSS or JS needed.

### End
Defined in `assets/base-template.html` — do not regenerate. It is always the last slide.

### Content
- Title top-left, color `#161618`, font-size 32px, class `slide-title`.
- Subtitle directly below, color `#36383C`, font-size 20px, class `slide-subtitle`.
- **Every content slide must have a subtitle — no exceptions.**
- Logo top-right (see Logo section). The logo sits **outside** `.slide-body`.
- All other content — titles, subtitles, grids, charts, cards — goes inside `.slide-body`.
- Never use `padding` on `.slide-content` for spacing — use `.slide-body` instead.

```html
<div class="slide slide-content">
  <img class="logo" src="https://raw.githubusercontent.com/roysoetantio/assets/refs/heads/main/edgenta-slide/asset/uemedgenta.png" alt="UEM Edgenta">
  <div class="slide-body">
    <div class="slide-title">Slide Title</div>
    <div class="slide-subtitle">Slide subtitle</div>
    <!-- content -->
  </div>
</div>
```

`.slide-body` is a fixed 1208×648px container — every layout must fit within it. Cover, Breaker, and End slides do not use `.slide-body`.

---

## Slide Order

```
Cover → [Content slides...] → [Breaker → Content slides...]* → End
```

Every deck starts with a Cover and ends with an End. Insert a Breaker only when content transitions to a new section.

---

## Typography

Both fonts are loaded by the base template. Reference them via CSS variables: `var(--font-sans)` (DM Sans) and `var(--font-serif)` (Playfair Display).

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
| Nav bar bg       | Handled by `assets/base-template.html` — do not override           |

Chart series (light→dark on dark bg): `#7b8ff5`, `#4a63e0`, `#2940BE`, `#1a2a8a`

Rules:
- Use `rgba(41, 64, 190, 0.1–0.2)` for subtle tinted card backgrounds.
- Logo: always use `uemedgenta_white.png` on dark slides.
- Charts: use the full accent palette (Sky Blue, Teal, Orange, Purple + primary blue family) — colorful charts read better on dark surfaces.

---

## Slide Transitions

All transition and entrance animation CSS is defined in `assets/base-template.html` — do not duplicate it. Keep all slides in the DOM at all times — control visibility via `opacity` and `pointer-events`, never `display: none/block`.

### Element Entrance Animations

The base template already handles stagger animations for `.logo`, `.slide-title`, `.slide-subtitle`, `.stat-card`, `.pillar-card`, `.chart-wrap`, and `.insight-item`. When you introduce new repeating components, add stagger selectors inside `<!-- DECK_CSS -->` following the same `nth-child` pattern. Example:

```css
.slide.slide-in .timeline-item:nth-child(1) { animation: fadeSlideUp 0.4s var(--ease) 0.25s both; }
.slide.slide-in .timeline-item:nth-child(2) { animation: fadeSlideUp 0.4s var(--ease) 0.33s both; }
.slide.slide-in .timeline-item:nth-child(3) { animation: fadeSlideUp 0.4s var(--ease) 0.41s both; }
```

---

## Charts

Chart.js is loaded by the base template. The animation defaults are also set there.

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

## Deploying to Vercel

Publishing is handled conversationally — see **Stage 5** above. Do not run `deploy.sh` directly and paste output at the user.

**What the script does under the hood** (for reference):
- Deploys the deck as a Vercel preview → unique permanent URL
- Updates `registry.json` locally with the deck name, URL, and timestamp
- Deploys `dashboard-template.html` + `registry.json` to production → `{username}-uem-edgenta-slides.vercel.app`

**Requirements:** Node.js must be installed. The Vercel CLI is installed automatically if not present.

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
