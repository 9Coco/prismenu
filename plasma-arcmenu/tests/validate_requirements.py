#!/usr/bin/env python3
"""Structural compliance checks against the Arc Menu KDE requirements spec."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PKG = ROOT / "package"
errors: list[str] = []
ok: list[str] = []


def check(cond: bool, msg: str) -> None:
    if cond:
        ok.append(msg)
    else:
        errors.append(msg)


def main() -> int:
    meta = json.loads((PKG / "metadata.json").read_text())
    check(meta["KPlugin"]["Id"] == "org.kde.plasma.arcmenu", "metadata id")
    check("org.kde.plasma.launchermenu" in meta.get("X-Plasma-Provides", []), "launcher provides")
    check(meta.get("X-Plasma-API-Minimum-Version", "").startswith("6"), "Plasma 6 API")

    layouts_expected = [
        "arcmenu", "brisk", "mint", "whisker", "elementary", "gnome",
        "plasma-dash", "plasma", "pop", "unity-dash", "redmond", "eleven", "az", "enterprise", "insider", "budgie",
        "kickoff", "kicker", "simple",
    ]
    registry = (PKG / "contents/code/LayoutRegistry.js").read_text()
    layout_files = {
        "arcmenu": "LayoutArcMenu.qml",
        "brisk": "LayoutBrisk.qml",
        "mint": "LayoutMint.qml",
        "whisker": "LayoutWhisker.qml",
        "elementary": "LayoutElementary.qml",
        "gnome": "LayoutGnome.qml",
        "plasma-dash": "LayoutPlasmaDash.qml",
        "plasma": "LayoutPlasma.qml",
        "pop": "LayoutPop.qml",
        "unity-dash": "LayoutUnityDash.qml",
        "redmond": "LayoutRedmond.qml",
        "eleven": "LayoutEleven.qml",
        "az": "LayoutAz.qml",
        "enterprise": "LayoutEnterprise.qml",
        "insider": "LayoutInsider.qml",
        "budgie": "LayoutBudgie.qml",
        "kickoff": "LayoutKickoff.qml",
        "kicker": "LayoutKicker.qml",
        "simple": "LayoutSimple.qml",
    }
    for lid in layouts_expected:
        check(f'id: "{lid}"' in registry, f"layout registered: {lid}")
        fname = layout_files[lid]
        check((PKG / "contents/ui/layouts" / fname).exists(), f"layout file: {fname}")

    check((PKG / "contents/ui/layouts/arcmenu/LayoutArcMenu.qml").exists(), "arcmenu folder snapshot")
    check((PKG / "contents/ui/layouts/brisk/BriskSidebar.qml").exists(), "brisk sidebar")
    check((PKG / "contents/ui/layouts/brisk/BriskContent.qml").exists(), "brisk content")
    check((PKG / "contents/ui/layouts/brisk/BriskNavRow.qml").exists(), "brisk nav row")
    check((PKG / "contents/ui/layouts/budgie/README.md").exists(), "budgie folder")
    check((PKG / "contents/ui/layouts/LayoutBudgie.qml").exists(), "budgie layout entry")
    check((PKG / "contents/ui/layouts/gnome/README.md").exists(), "gnome folder")
    check((PKG / "contents/ui/layouts/LayoutGnome.qml").exists(), "gnome layout entry")
    check((PKG / "contents/ui/layouts/mint/README.md").exists(), "mint folder")
    check((PKG / "contents/ui/layouts/LayoutMint.qml").exists(), "mint layout entry")
    check((PKG / "contents/ui/layouts/whisker/README.md").exists(), "whisker folder")
    check((PKG / "contents/ui/layouts/LayoutWhisker.qml").exists(), "whisker layout entry")
    check((PKG / "contents/ui/layouts/eleven/README.md").exists(), "eleven folder")
    check((PKG / "contents/ui/layouts/LayoutEleven.qml").exists(), "eleven layout entry")
    check((PKG / "contents/ui/layouts/az/README.md").exists(), "az folder")
    check((PKG / "contents/ui/layouts/LayoutAz.qml").exists(), "az layout entry")
    check((PKG / "contents/ui/layouts/enterprise/README.md").exists(), "enterprise folder")
    check((PKG / "contents/ui/layouts/LayoutEnterprise.qml").exists(), "enterprise layout entry")
    check((PKG / "contents/ui/layouts/insider/README.md").exists(), "insider folder")
    check((PKG / "contents/ui/layouts/LayoutInsider.qml").exists(), "insider layout entry")
    check((PKG / "contents/ui/layouts/plasma/README.md").exists(), "plasma folder")
    check((PKG / "contents/ui/layouts/LayoutPlasma.qml").exists(), "plasma layout entry")
    check((PKG / "contents/ui/layouts/pop/README.md").exists(), "pop folder")
    check((PKG / "contents/ui/layouts/LayoutPop.qml").exists(), "pop layout entry")

    cfg = (PKG / "contents/config/main.xml").read_text()
    required_keys = [
        "ButtonIcon", "ButtonLabelVisible", "ButtonLabelText", "MenuHotkey", "PopupAnimation",
        "MenuLayoutId", "FlipHorizontal", "SearchbarLocation", "MenuWidth", "MenuHeight",
        "ThemeMode", "BgColor", "FgColor", "BorderColor", "BorderWidth", "CornerRadius",
        "Font", "FontSize", "SelectedBg", "SelectedFg", "CategoryIconSize", "AppIconSize",
        "FollowColorScheme",
        "PinnedApps", "PinnedCols", "SyncWithPlasma",
        "Enabled", "MaxItems", "RecentApps",
        "Order", "Hidden", "CustomNames", "CustomIcons", "ShowEmpty",
        "Providers", "Placeholder", "ShowDescription", "MaxResults",
        "Options", "Confirm", "SoftwareCenterCmd",
    ]
    for key in required_keys:
        check(f'name="{key}"' in cfg, f"config key: {key}")

    config_pages = [
        "ConfigGeneral.qml", "ConfigLayout.qml", "ConfigTheme.qml",
        "ConfigContent.qml", "ConfigSearch.qml", "ConfigPower.qml", "ConfigAbout.qml",
    ]
    for page in config_pages:
        check((PKG / "contents/ui/config" / page).exists(), f"settings page: {page}")

    config_model = (PKG / "contents/config/config.qml").read_text()
    for label in ["General", "Menu Layout", "Theme & Appearance", "Menu Content", "Search", "System Actions", "About"]:
        check(label in config_model, f"settings category: {label}")

    components = [
        "SearchField.qml", "AppListItem.qml", "CategoryList.qml", "PinnedAppsGrid.qml",
        "AppGrid.qml", "SystemActionsBar.qml", "AppContextMenu.qml", "ConfirmDialog.qml",
        "AppDetailsDialog.qml",
        "ShortcutRow.qml", "PlacesSidebar.qml", "SessionButtons.qml", "AllAppsButton.qml",
        "PinnedAppsList.qml",
    ]
    for c in components:
        check((PKG / "contents/ui/components" / c).exists(), f"component: {c}")

    pages = [
        "PageHost.qml", "ArcHomePage.qml", "ArcAppsPage.qml", "ArcSearchPage.qml",
    ]
    for p in pages:
        check((PKG / "contents/ui/pages" / p).exists(), f"page: {p}")

    check((PKG / "contents/code/PageRegistry.js").exists(), "PageRegistry.js")
    check((PKG / "contents/code/IdList.js").exists(), "IdList.js")

    for core in ["main.qml", "MenuData.qml", "LayoutHost.qml", "AppsBackend.qml"]:
        check((PKG / "contents/ui" / core).exists(), f"core ui: {core}")

    main_qml = (PKG / "contents/ui/main.qml").read_text()
    for needle in ["Keys.onPressed", "Plasmoid.onActivated", "contextualActions", "ConfirmDialog", "AppContextMenu"]:
        check(needle in main_qml, f"main.qml contains {needle}")

    ctx = (PKG / "contents/ui/components/AppContextMenu.qml").read_text()
    for item in ["Launch", "Favorites", "Desktop", "Panel", "Edit", "Details", "Uninstall", "Terminal"]:
        check(item.lower() in ctx.lower() or item in ctx, f"context menu: {item}")

    langs = [
        "zh_CN", "zh_TW", "fr", "de", "es", "pt_BR", "ru", "ja", "ko", "it", "tr",
        "pl", "cs", "nl", "fi", "hu", "he", "sk", "sv", "nb", "uk", "ca",
    ]
    check((ROOT / "po/plasma_applet_org.kde.plasma.arcmenu.pot").exists(), "pot template")
    for lang in langs:
        check((ROOT / "po" / lang / "plasma_applet_org.kde.plasma.arcmenu.po").exists(), f"translation: {lang}")

    check((ROOT / "COPYING").exists(), "COPYING license")
    check((ROOT / "README.md").exists() or (ROOT.parent / "README.md").exists(), "README")
    check((ROOT / "CMakeLists.txt").exists(), "CMakeLists.txt")
    check((ROOT / "install.sh").exists(), "install.sh")
    check((ROOT / "kcm/kcm_arcmenu.json").exists(), "KCM registration json")

    # Layout capability flags
    check("supportsFlip" in registry, "flip capability")
    check("supportsSearchbarLocation" in registry, "searchbar location capability")

    print(f"OK: {len(ok)}")
    for m in ok:
        print(f"  ✓ {m}")
    if errors:
        print(f"FAIL: {len(errors)}")
        for m in errors:
            print(f"  ✗ {m}")
        return 1
    print("All requirement structure checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
