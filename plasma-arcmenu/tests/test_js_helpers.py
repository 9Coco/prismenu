#!/usr/bin/env python3
"""Port of critical JS helper behaviors for offline verification."""

from __future__ import annotations

import json
import sys


def match_app(app: dict, query: str) -> int:
    if not query:
        return 0
    q = query.lower()
    name = (app.get("name") or "").lower()
    generic = (app.get("genericName") or "").lower()
    app_id = (app.get("id") or "").lower()
    keywords = app.get("keywords") or []
    if name.startswith(q):
        return 100
    if q in name:
        return 80
    if q in generic:
        return 60
    for kw in keywords:
        if q in str(kw).lower():
            return 40
    if q in app_id:
        return 20
    return 0


def push_recent(recent: list[str], app_id: str, max_items: int) -> list[str]:
    copy = [x for x in recent if x != app_id]
    copy.insert(0, app_id)
    max_n = max(1, min(20, max_items or 5))
    return copy[:max_n]


def toggle_favorite(pinned: list[str], app_id: str) -> list[str]:
    copy = list(pinned)
    if app_id in copy:
        copy.remove(app_id)
    else:
        copy.append(app_id)
    return copy


def contrast_ratio(fg: str, bg: str) -> float:
    def lum(hex_color: str) -> float:
        r = int(hex_color[1:3], 16) / 255
        g = int(hex_color[3:5], 16) / 255
        b = int(hex_color[5:7], 16) / 255

        def lin(c: float) -> float:
            return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)

    l1, l2 = lum(fg), lum(bg)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def main() -> int:
    app = {
        "id": "org.kde.kate.desktop",
        "name": "Kate",
        "genericName": "Advanced Text Editor",
        "keywords": ["editor", "text"],
    }
    assert match_app(app, "ka") == 100
    assert match_app(app, "ate") == 80
    assert match_app(app, "text") == 60  # genericName
    assert match_app({"id": "x", "name": "Foo", "genericName": "", "keywords": ["editor"]}, "editor") == 40
    assert match_app(app, "org.kde.kate") == 20
    assert match_app(app, "zzz") == 0

    recent = push_recent(["a", "b"], "c", 5)
    assert recent == ["c", "a", "b"]
    recent = push_recent(recent, "a", 5)
    assert recent[0] == "a"
    recent = push_recent(["1", "2", "3", "4", "5"], "6", 5)
    assert recent == ["6", "1", "2", "3", "4"]

    pinned = toggle_favorite([], "x")
    assert pinned == ["x"]
    pinned = toggle_favorite(pinned, "x")
    assert pinned == []

    assert contrast_ratio("#000000", "#ffffff") > 4.5
    assert contrast_ratio("#777777", "#888888") < 4.5

    print("JS helper behavior tests passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
