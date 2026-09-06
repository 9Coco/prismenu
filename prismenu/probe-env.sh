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

    echo "---- plasma versions ----"
    plasmashell --version 2>/dev/null || true
    dpkg -l 2>/dev/null | grep -E "plasma-workspace|libplasma|plasma-desktop|kwin " | head -10 || true
    rpm -qa 2>/dev/null | grep -E "plasma-workspace|libplasma|plasma-desktop" | head -10 || true
    echo

    echo "---- prismenu appletsrc sections (where is the applet? popupWidth?) ----"
    awk '/^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$/{keep=0} /plugin=com.github.9coco.prismenu/{keep=1} keep' \
        "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | head -40
    echo "-- raw prismenu block (sed) --"
    sed -n '/\[Containments\]\[1\]\[Applets\]\[41\]/,/^\[/p' \
        "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | head -30
    echo "-- containment lines --"
    grep -nE "^\[Containments\]\[[0-9]+\]$|^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$|plugin=(org.kde.plasma.(panel|desktop)|com.github.9coco.prismenu)" \
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
             /usr/share/plasma/plasmoids/org.kde.plasma.folder/contents/ui/main.qml \
             /usr/share/plasma/plasmoids/org.kde.plasma.folder/contents/ui/FolderViewLayer.qml \
             /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/FolderViewLayer.qml; do
        [ -f "$f" ] || continue
        echo "==== $f ===="
        cat "$f"
        echo
    done
    echo "-- folder containment dir listing --"
    ls -la /usr/share/plasma/plasmoids/org.kde.plasma.folder/contents/ui/ 2>/dev/null
    echo

    echo "---- containmentlayoutmanager qml module ----"
    LM_DIR="$(find /usr/lib /usr/lib64 /usr/local/lib /opt -type d -name "containmentlayoutmanager" 2>/dev/null | head -1)"
    echo "dir: $LM_DIR"
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        echo "==== $f ===="
        cat "$f"
        echo
    done < <(find "$LM_DIR" -maxdepth 3 \( -name "*.qml" -o -name "qmldir" \) 2>/dev/null)

    echo "---- grep Behavior/Animation in desktop containment + layout manager ----"
    grep -rn "Behavior on\|NumberAnimation\|SmoothedAnimation\|PropertyAnimation" \
        /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ \
        /usr/share/plasma/plasmoids/org.kde.plasma.folder/contents/ "$LM_DIR" 2>/dev/null | head -80
    echo

    echo "---- containment[1] full section of appletsrc ----"
    sed -n '/^\[Containments\]\[1\]$/,/^\[Containments\]\[2\]/p' \
        "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | head -60

    echo "---- prismenu metadata (provides?) ----"
    cat "$HOME/.local/share/plasma/plasmoids/com.github.9coco.prismenu/metadata.json" 2>/dev/null | head -40
    echo "======== done ========"
} >"$OUT" 2>&1

echo "wrote $OUT"
