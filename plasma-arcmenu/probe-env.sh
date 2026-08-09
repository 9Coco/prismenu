#!/usr/bin/env bash
# One-shot environment probe: dump host facts + plasma shell QML sources
# so the resize problem can be diagnosed without guesswork.
#
# Usage:  ./probe-env.sh     (then read logs/probe-env.log from Windows)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/logs/probe-env.log"
mkdir -p "$ROOT/logs"

{
    echo "======== probe-env $(date -Is) ========"

    echo "---- session ----"
    echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}  WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}  DISPLAY=${DISPLAY:-}"
    xrandr 2>/dev/null | head -12 || true
    echo

    echo "---- arcmenu appletsrc sections (where is the applet? popupWidth?) ----"
    awk '/^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$/{keep=0} /plugin=org.kde.plasma.arcmenu/{keep=1} keep' \
        "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | head -40
    echo "-- raw arcmenu block (sed) --"
    sed -n '/\[Containments\]\[1\]\[Applets\]\[41\]/,/^\[/p' \
        "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | head -30
    echo "-- containment lines --"
    grep -nE "^\[Containments\]\[[0-9]+\]$|^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$|plugin=org.kde.plasma.(panel|desktop|arcmenu)" \
        "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | head -40
    echo

    echo "---- shell applet qml dirs ----"
    for d in /usr/share/plasma/shells/*/contents/applet; do
        echo ">> $d"
        ls -la "$d" 2>/dev/null || echo "(missing)"
    done
    echo

    echo "---- shell applet qml dumps ----"
    for f in /usr/share/plasma/shells/*/contents/applet/*.qml; do
        [ -f "$f" ] || continue
        echo "==== $f ===="
        cat "$f"
        echo
    done

    echo "---- locate desktop containment QML + applet sizing code ----"
    find /usr/share/plasma -type d -name "org.kde.desktop*" 2>/dev/null
    find /usr/share/plasma/plasmoids -name "*.qml" -path "*desktop*" 2>/dev/null | head -40
    echo "-- grep applet sizing candidates --"
    grep -rn "implicitWidth" /usr/share/plasma/plasmoids/org.kde.desktop*/contents/ui/ 2>/dev/null | head -30
    grep -rln "AppletQuickItem\|appletInterface\|containmentInterfaces" /usr/share/plasma/plasmoids/org.kde.desktop*/contents/ 2>/dev/null | head -20
    echo

    echo "---- dump desktop containment applet-related qml ----"
    for f in /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/main.qml \
             /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/FolderViewLayer.qml \
             /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/FolderView.qml; do
        [ -f "$f" ] || continue
        echo "==== $f ===="
        cat "$f"
        echo
    done

    echo "---- containmentlayoutmanager qml module ----"
    LM_DIR="$(find /usr/lib /usr/lib64 /usr/local/lib /opt -type d -name "containmentlayoutmanager" 2>/dev/null | head -1)"
    echo "dir: $LM_DIR"
    for f in "$LM_DIR"/*.qml "$LM_DIR"/qmldir; do
        [ -f "$f" ] || continue
        echo "==== $f ===="
        cat "$f"
        echo
    done

    echo "---- containment[1] full section of appletsrc ----"
    sed -n '/^\[Containments\]\[1\]$/,/^\[Containments\]\[2\]/p' \
        "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | head -60

    echo "---- arcmenu metadata (provides?) ----"
    cat "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.arcmenu/metadata.json" 2>/dev/null | head -40
    echo "======== done ========"
} >"$OUT" 2>&1

echo "wrote $OUT"
