#!/usr/bin/env bash
# Install Arc Menu, restart plasmashell, tee console output to logs/
# so the Cursor agent can read it from the shared repo path.
#
# Usage:
#   ./reload.sh           # install + plasmashell --replace + capture logs
#   ./reload.sh journal   # only append latest ArcMenu journal lines
#
# Logs (readable from Windows/Cursor via hgfs):
#   logs/latest-reload.log
#   logs/plasmashell-*.log
set -uo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$ROOT/logs"
STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_LATEST="$LOG_DIR/latest-reload.log"
LOG_STAMPED="$LOG_DIR/reload-$STAMP.log"
SHELL_LOG="$LOG_DIR/plasmashell-$STAMP.log"

mkdir -p "$LOG_DIR"

dump_journal() {
    # Prefer lines from the last 3 minutes so old plasmashell noise isn't mistaken for new errors
    echo "---- journalctl ArcMenu (last 3 min) ----"
    local out=""
    out="$(journalctl --user -b --since '3 minutes ago' --no-pager 2>/dev/null | grep -iE 'ArcMenu|org.kde.plasma.arcmenu' | tail -80 || true)"
    if [[ -z "$out" ]]; then
        out="$(journalctl -b --since '3 minutes ago' --no-pager 2>/dev/null | grep -iE 'ArcMenu|org.kde.plasma.arcmenu' | tail -80 || true)"
    fi
    if [[ -n "$out" ]]; then
        printf '%s\n' "$out"
    else
        echo "(no recent ArcMenu journal lines — open the menu once, then: ./reload.sh journal)"
    fi
    echo ""
    echo "---- plasmashell log errors (latest file, if any) ----"
    local newest
    newest="$(ls -1t "$LOG_DIR"/plasmashell-*.log 2>/dev/null | head -n1 || true)"
    if [[ -n "$newest" && -f "$newest" ]]; then
        echo "file: $newest"
        grep -iE 'error|warn|failed|unavailable|TypeError|Cannot |is not a type|not installed' "$newest" \
            | grep -iE 'ArcMenu|arcmenu|SearchField|PlasmaNative|UserFace|SessionManagement|RunnerModel|kcm' \
            | tail -40 \
            || echo "(no ArcMenu error/warn lines in $newest)"
    else
        echo "(no plasmashell-*.log yet)"
    fi
    echo ""
    echo "---- KCrash / coredumps (latest crash, if any) ----"
    journalctl --user -b --no-pager 2>/dev/null | grep -iE 'kcrash|drkonqi|core-dump|segfault' | tail -30 || true
    if command -v coredumpctl >/dev/null 2>&1; then
        coredumpctl list --no-pager 2>/dev/null | tail -6 || true
        echo "---- coredumpctl info (crashed thread stack) ----"
        coredumpctl info --no-pager 2>/dev/null \
            | awk '/Stack trace of thread/{p=1} p' | head -70 || true
    else
        echo "(coredumpctl not available)"
    fi
    local newest_ini
    newest_ini="$(ls -1t "$HOME/.cache/kcrash-metadata/"*.ini 2>/dev/null | head -n1 || true)"
    if [[ -n "$newest_ini" ]]; then
        echo "---- KCrash metadata backtrace: $newest_ini ----"
        tail -80 "$newest_ini"
    fi
}

if [[ "${1:-}" == "journal" ]]; then
    {
        echo "======== ArcMenu journal $STAMP ========"
        dump_journal
        echo "======== done → $LOG_LATEST ========"
    } 2>&1 | tee -a "$LOG_LATEST"
    exit 0
fi

{
    echo "======== ArcMenu reload $STAMP ========"
    echo "cwd: $ROOT"
    echo "log: $LOG_LATEST"
    echo "plasmashell log: $SHELL_LOG"
    echo "host: $(hostname 2>/dev/null || echo unknown)  user: $(id -un)  date: $(date -Is 2>/dev/null || date)"
    echo ""

    echo "---- install.sh ----"
    if ! "$ROOT/install.sh"; then
        echo "ERROR: install.sh failed"
        exit 1
    fi

    echo ""
    echo "---- plasmashell --replace (background) ----"
    if ! command -v plasmashell >/dev/null 2>&1; then
        echo "ERROR: plasmashell not found on PATH"
        exit 1
    fi

    : > "$SHELL_LOG"
    plasmashell --replace >>"$SHELL_LOG" 2>&1 &
    echo "plasmashell pid: $!"
    echo "plasmashell stdout/stderr → $SHELL_LOG"

    echo ""
    echo "---- wait for QML / Kicker ----"
    sleep 4

    echo ""
    echo "---- plasmashell log (first 120 lines) ----"
    if [[ -f "$SHELL_LOG" ]]; then
        head -n 120 "$SHELL_LOG" || true
    else
        echo "(no plasmashell log yet)"
    fi

    echo ""
    dump_journal

    echo ""
    echo "======== done ========"
    echo "Readable from Windows/Cursor:"
    echo "  plasma-arcmenu/logs/latest-reload.log"
    echo "  plasma-arcmenu/logs/$(basename "$SHELL_LOG")"
    echo "After clicking the menu, refresh journal with:"
    echo "  ./reload.sh journal"
} 2>&1 | tee "$LOG_LATEST" | tee "$LOG_STAMPED"
