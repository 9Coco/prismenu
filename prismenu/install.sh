#!/usr/bin/env bash
# Install Prismenu plasmoid for the current user (no root required).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TARGET="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/com.github.9coco.prismenu"

echo "Installing Prismenu to: $TARGET"
rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -a "$ROOT/package/." "$TARGET/"
# Refresh plasmashell cache if available
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 >/dev/null 2>&1 || true
fi

echo "Done."
echo "Enable it with:"
echo "  1) Right-click panel → Add Widgets → Prismenu"
echo "  2) Or right-click Kickoff → Show Alternatives → Prismenu"
echo "No Plasma restart is required."
echo ""
echo "App catalog uses Plasma Kicker (same as Kickoff)."
echo "Install + restart plasmashell (console + logs/latest-reload.log):"
echo "  ./reload.sh"
