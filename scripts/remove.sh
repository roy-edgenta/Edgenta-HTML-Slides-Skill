#!/usr/bin/env bash
# remove.sh — Remove a deck from the dashboard
#
# Usage:
#   bash scripts/remove.sh <deck-name>
#
# Removes the deck entry from registry.json and redeploys the dashboard.
# The Vercel preview URL for the deck remains live but is no longer listed.
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
  err "Usage: bash scripts/remove.sh <deck-name>"
  exit 1
fi

DECK_NAME="$1"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       Remove Deck from Dashboard      ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""
info "Deck to remove: $DECK_NAME"
echo ""

# ─── Check Node / Vercel CLI ───────────────────────────────
if ! command -v npx &>/dev/null; then
  err "Node.js is required. Visit https://nodejs.org to install it."
  exit 1
fi

if command -v vercel &>/dev/null; then
  VERCEL_CMD="vercel"
else
  VERCEL_CMD="npx --yes vercel"
fi

# ─── Check login ───────────────────────────────────────────
if ! $VERCEL_CMD whoami &>/dev/null 2>&1; then
  err "Not logged in to Vercel. Run 'vercel login' and try again."
  exit 1
fi

RAW_USER=$($VERCEL_CMD whoami 2>/dev/null)
USERNAME=$(echo "$RAW_USER" | sed 's/-[0-9]*$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
PROJECT_NAME="${USERNAME}-uem-edgenta-slides"
PROJECT_DIR="$HOME/.edgenta-slides/$PROJECT_NAME"
REGISTRY="$PROJECT_DIR/registry.json"

# ─── Check registry ────────────────────────────────────────
if [[ ! -f "$REGISTRY" ]]; then
  err "No registry found at $REGISTRY — nothing to remove."
  exit 1
fi

# Check deck exists in registry
FOUND=$(python3 -c "
import json, sys
data = json.load(open('$REGISTRY'))
found = any(d['name'] == '$DECK_NAME' for d in data['decks'])
print('yes' if found else 'no')
")

if [[ "$FOUND" == "no" ]]; then
  err "Deck '$DECK_NAME' not found in registry."
  echo ""
  info "Published decks:"
  python3 -c "
import json
data = json.load(open('$REGISTRY'))
for d in data['decks']:
    print(f\"  - {d['name']}\")
"
  exit 1
fi

# ─── Get deck URL before removing ─────────────────────────
DECK_URL=$(python3 -c "
import json
data = json.load(open('$REGISTRY'))
match = next((d for d in data['decks'] if d['name'] == '$DECK_NAME'), None)
print(match['url'] if match else '')
")

# ─── Delete Vercel deployment ──────────────────────────────
if [[ -n "$DECK_URL" ]]; then
  info "Deleting Vercel deployment: $DECK_URL"
  if $VERCEL_CMD rm "$DECK_URL" --yes &>/dev/null 2>&1; then
    ok "Deployment deleted"
  else
    warn "Could not delete the Vercel deployment — it may have already been removed."
  fi
fi

# ─── Remove from registry ──────────────────────────────────
info "Removing '$DECK_NAME' from registry..."

python3 - <<EOF
import json
with open("$REGISTRY") as f:
    data = json.load(f)
data["decks"] = [d for d in data["decks"] if d["name"] != "$DECK_NAME"]
with open("$REGISTRY", "w") as f:
    json.dump(data, f, indent=2)
EOF

ok "Removed from registry"

# ─── Find dashboard template ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_TEMPLATE="$SCRIPT_DIR/../assets/dashboard-template.html"

if [[ ! -f "$DASHBOARD_TEMPLATE" ]]; then
  err "dashboard-template.html not found at: $DASHBOARD_TEMPLATE"
  exit 1
fi

# ─── Redeploy dashboard ────────────────────────────────────
echo ""
info "Updating dashboard..."

cp "$DASHBOARD_TEMPLATE" "$PROJECT_DIR/index.html"

DASH_OUTPUT=$($VERCEL_CMD deploy "$PROJECT_DIR" --yes --prod 2>&1) || {
  err "Dashboard redeployment failed:"
  echo "$DASH_OUTPUT"
  exit 1
}

DASHBOARD_URL="https://${PROJECT_NAME}.vercel.app"

# ─── Write result file for Claude to read ──────────────────
RESULT_FILE="$PROJECT_DIR/last-remove.json"
REMAINING=$(python3 -c "import json; d=json.load(open('$REGISTRY')); print(len(d['decks']))")

cat > "$RESULT_FILE" <<EOF
{
  "status": "ok",
  "deck_name": "$DECK_NAME",
  "dashboard_url": "$DASHBOARD_URL",
  "remaining_decks": $REMAINING
}
EOF

# ─── Success ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
ok "Removed successfully!"
echo ""
echo -e "  ${BOLD}Deck removed:${NC}  $DECK_NAME"
echo -e "  ${BOLD}Dashboard:${NC}     ${DASHBOARD_URL}"
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo ""
