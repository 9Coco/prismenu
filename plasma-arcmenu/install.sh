#!/usr/bin/env bash
# Install Arc Menu plasmoid for the current user (no root required).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TARGET="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/org.kde.plasma.arcmenu"

echo "Installing Arc Menu to: $TARGET"
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
echo "  1) Right-click panel → Add Widgets → Arc Menu"
echo "  2) Or right-click Kickoff → Show Alternatives → Arc Menu"
echo "No Plasma restart is required."
