#!/usr/bin/env bash
# deploy.sh — Publish a slide deck to Vercel
#
# Usage:
#   bash scripts/deploy.sh <path-to-html>
#
# On first run: creates a personal Vercel project named {username}-uem-edgenta-slides
# All future decks deploy under that same project.
# Dashboard lives at: {username}-uem-edgenta-slides.vercel.app
#
set -euo pipefail

# ─── Colors ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${CYAN}ℹ${NC}  $*"; }
ok()   { echo -e "${GREEN}✓${NC}  $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }
err()  { echo -e "${RED}✗${NC}  $*" >&2; }

# ─── Input ─────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  err "Usage: bash scripts/deploy.sh <path-to-html>"
  exit 1
fi

HTML="$1"
[[ ! -f "$HTML" || "$HTML" != *.html ]] && { err "'$HTML' is not a valid HTML file."; exit 1; }
HTML="$(cd "$(dirname "$HTML")" && pwd)/$(basename "$HTML")"
DECK_NAME=$(basename "$HTML" .html | tr '[:upper:]' '[:lower:]' | tr '_' '-' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       Deploy Slides to Vercel         ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""
info "File: $(basename "$HTML")"
echo ""

# ─── Check Node / Vercel CLI ───────────────────────────────
if ! command -v npx &>/dev/null; then
  err "Node.js is required. Visit https://nodejs.org to install it."
  exit 1
fi

info "Checking Vercel CLI..."
if command -v vercel &>/dev/null; then
  VERCEL_CMD="vercel"
elif npx --yes vercel --version &>/dev/null 2>&1; then
  VERCEL_CMD="npx --yes vercel"
else
  info "Installing Vercel CLI..."
  npm install -g vercel
  VERCEL_CMD="vercel"
fi
ok "Vercel CLI ready"

# ─── Check login ───────────────────────────────────────────
echo ""
info "Checking Vercel login..."

if ! $VERCEL_CMD whoami &>/dev/null 2>&1; then
  warn "Not logged in. Opening vercel.com/login in your browser..."
  open "https://vercel.com/login" 2>/dev/null || xdg-open "https://vercel.com/login" 2>/dev/null || true
  echo ""
  echo "  Complete login in your browser, then press Enter to continue..."
  read -r
  if ! $VERCEL_CMD whoami &>/dev/null 2>&1; then
    err "Still not logged in. Please run 'vercel login' in your terminal and try again."
    exit 1
  fi
fi

# Get username — strip trailing numeric suffix (e.g. roysoetantio-6144 → roysoetantio)
RAW_USER=$($VERCEL_CMD whoami 2>/dev/null)
USERNAME=$(echo "$RAW_USER" | sed 's/-[0-9]*$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
PROJECT_NAME="${USERNAME}-uem-edgenta-slides"

ok "Logged in as: $RAW_USER"
ok "Project: $PROJECT_NAME"

# ─── Persistent project directory ─────────────────────────
PROJECT_DIR="$HOME/.edgenta-slides/$PROJECT_NAME"
mkdir -p "$PROJECT_DIR"

# ─── Link to existing Vercel project if needed ─────────────
# .vercel/project.json may be missing on a fresh machine.
# If so, link by project name so we reuse the existing project
# rather than creating a duplicate.
if [[ ! -f "$PROJECT_DIR/.vercel/project.json" ]]; then
  info "No local project link found — checking Vercel for existing project '$PROJECT_NAME'..."
  # Place a placeholder so vercel link has something to work with
  cp /dev/null "$PROJECT_DIR/index.html" 2>/dev/null || true
  if $VERCEL_CMD link "$PROJECT_DIR" --yes --project "$PROJECT_NAME" &>/dev/null 2>&1; then
    ok "Linked to existing project: $PROJECT_NAME"
  else
    warn "Could not link to existing project — a new project will be created on first deploy."
  fi
fi

# ─── Find dashboard template ───────────────────────────────
# Look relative to this script's location inside the skill package
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_TEMPLATE="$SCRIPT_DIR/../assets/dashboard-template.html"

if [[ ! -f "$DASHBOARD_TEMPLATE" ]]; then
  err "dashboard-template.html not found at: $DASHBOARD_TEMPLATE"
  exit 1
fi

# ─── Deploy deck as preview ────────────────────────────────
# Temporarily set index.html to the deck, deploy as preview
cp "$HTML" "$PROJECT_DIR/index.html"

echo ""
info "Deploying deck: $DECK_NAME..."
echo ""

DEPLOY_OUTPUT=$($VERCEL_CMD deploy "$PROJECT_DIR" --yes 2>&1) || {
  err "Deck deployment failed:"
  echo "$DEPLOY_OUTPUT"
  exit 1
}

DEPLOY_URL=$(echo "$DEPLOY_OUTPUT" | grep -Eo 'https://[a-zA-Z0-9._-]+\.vercel\.app' | head -1)

if [[ -z "$DEPLOY_URL" ]]; then
  err "Could not extract deployment URL. Raw output:"
  echo "$DEPLOY_OUTPUT"
  exit 1
fi

ok "Deck deployed: $DEPLOY_URL"

# ─── Update registry ───────────────────────────────────────
REGISTRY="$PROJECT_DIR/registry.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [[ ! -f "$REGISTRY" ]]; then
  echo '{"project":"'"$PROJECT_NAME"'","decks":[]}' > "$REGISTRY"
fi

python3 - <<EOF
import json
with open("$REGISTRY") as f:
    data = json.load(f)
# Remove any existing entry for this deck name, then append latest
data["decks"] = [d for d in data["decks"] if d["name"] != "$DECK_NAME"]
data["decks"].append({
    "name": "$DECK_NAME",
    "url":  "$DEPLOY_URL",
    "published": "$TIMESTAMP"
})
with open("$REGISTRY", "w") as f:
    json.dump(data, f, indent=2)
EOF

# ─── Deploy dashboard as production ────────────────────────
echo ""
info "Updating dashboard..."

# Deploy dashboard + registry together so /registry.json is served
cp "$DASHBOARD_TEMPLATE" "$PROJECT_DIR/index.html"
# registry.json is already in PROJECT_DIR — it deploys alongside index.html

DASH_OUTPUT=$($VERCEL_CMD deploy "$PROJECT_DIR" --yes --prod 2>&1) || {
  err "Dashboard deployment failed:"
  echo "$DASH_OUTPUT"
  exit 1
}

DASHBOARD_URL="https://${PROJECT_NAME}.vercel.app"

# ─── Write result file for Claude to read ──────────────────
RESULT_FILE="$PROJECT_DIR/last-deploy.json"
IS_FIRST_DEPLOY="false"
[[ $(python3 -c "import json; d=json.load(open('$REGISTRY')); print(len(d['decks']))") -eq 1 ]] && IS_FIRST_DEPLOY="true"

cat > "$RESULT_FILE" <<EOF
{
  "status": "ok",
  "deck_name": "$DECK_NAME",
  "deck_url": "$DEPLOY_URL",
  "dashboard_url": "$DASHBOARD_URL",
  "first_deploy": $IS_FIRST_DEPLOY
}
EOF

# ─── Success ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
ok "Published successfully!"
echo ""
echo -e "  ${BOLD}Deck URL:${NC}   ${DEPLOY_URL}"
echo -e "  ${BOLD}Dashboard:${NC}  ${DASHBOARD_URL}"
echo ""
echo "  Permanent link — works on any device."
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo ""

open "$DEPLOY_URL" 2>/dev/null || xdg-open "$DEPLOY_URL" 2>/dev/null || true
