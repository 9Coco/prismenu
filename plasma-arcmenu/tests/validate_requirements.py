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
    meta = json.loads((PKG / "metadata.json").read_text(encoding="utf-8"))
    check(meta["KPlugin"]["Id"] == "org.kde.plasma.arcmenu", "metadata id")
    check("org.kde.plasma.launchermenu" in meta.get("X-Plasma-Provides", []), "launcher provides")
    check(meta.get("X-Plasma-API-Minimum-Version", "").startswith("6"), "Plasma 6 API")

    registry = (PKG / "contents/code/LayoutRegistry.js").read_text(encoding="utf-8")
    # LayoutRegistry is the single source of truth. Adding a layout must not
    # require a second ID/file list in this validator.
    layout_blocks = re.findall(
        r"\{\s*id:\s*\"([^\"]+)\"(?P<body>.*?source:\s*\"layouts/([^\"]+)\".*?)\n\s*\}",
        registry,
        re.DOTALL,
    )
    layout_files = {layout_id: filename for layout_id, _body, filename in layout_blocks}
    category_section = registry.split("var CATEGORIES = [", 1)[1].split("];", 1)[0]
    category_ids = set(re.findall(r'id:\s*"([^"]+)"', category_section))
    desktop_section = registry.split("var DESKTOPS = [", 1)[1].split("];", 1)[0]
    desktop_ids = set(re.findall(r'id:\s*"([^"]+)"', desktop_section))
    desktop_categories = set(re.findall(r'category:\s*"([^"]+)"', desktop_section))
    check(bool(layout_files), "layouts discovered from registry")
    check(len(layout_files) == len(layout_blocks), "unique layout ids")
    check("gnome" not in layout_files, "duplicate GNOME layout removed")
    check(category_ids == {"linux", "windows", "chromeos", "android", "apple", "other"},
          "source-platform layout categories")
    check("plasma" in desktop_ids and "win7" in desktop_ids and "gnome" in desktop_ids,
          "desktop subgroups include KDE / GNOME / Windows 7")
    check(desktop_categories <= category_ids, "desktop groups belong to known platforms")
    check("CATEGORIES.filter" in registry, "unused source categories stay hidden")
    check("DESKTOPS.filter" in registry, "unused desktop groups stay hidden")
    expected_desktops = {
        "kickoff": "plasma",
        "kicker": "plasma",
        "plasma-dash": "plasma",
        "arcmenu": "arcmenu",
        "whisker": "xfce",
        "mint": "mint",
        "redmond": "win7",
        "windows": "win10",
        "eleven": "win11",
        "az": "win11",
        "chromebook": "chromeos",
    }
    for layout_id, desktop_id in expected_desktops.items():
        block = next((body for lid, body, _fname in layout_blocks if lid == layout_id), "")
        check(f'desktop: "{desktop_id}"' in block,
              f"desktop subgroup {desktop_id}: {layout_id}")
    expected_windows_names = {
        "redmond": "Windows 7 (Two-column)",
        "insider": "Windows 10 (Early)",
        "windows": "Windows 10 (Classic)",
        "eleven": "Windows 11 (Standard)",
        "az": "Windows 11 (Pinned + A-Z)",
    }
    for layout_id, display_name in expected_windows_names.items():
        block = next((body for lid, body, _fname in layout_blocks if lid == layout_id), "")
        check(f'name: "{display_name}"' in block,
              f"versioned Windows layout name: {layout_id}")
    for lid, body, fname in layout_blocks:
        category_match = re.search(r'\bcategory:\s*"([^"]+)"', body)
        desktop_match = re.search(r'\bdesktop:\s*"([^"]+)"', body)
        check(bool(category_match) and category_match.group(1) in category_ids,
              f"known source category: {lid}")
        check(bool(desktop_match) and desktop_match.group(1) in desktop_ids,
              f"known desktop group: {lid}")
        check(bool(re.search(r"\bpreviewKind\s*:", body)), f"layout preview metadata: {lid}")
        check(bool(re.search(r"\bdefaultWidth\s*:", body)), f"layout width metadata: {lid}")
        check(bool(re.search(r"\bdefaultHeight\s*:", body)), f"layout height metadata: {lid}")
        check((PKG / "contents/ui/layouts" / fname).exists(), f"layout file: {fname}")

    # Shared layout architecture: every selectable layout inherits the same
    # catalog projections and preloader instead of maintaining cold-start
    # workarounds or full-catalog sorting locally.
    layout_sources = {
        name: (PKG / "contents/ui/layouts" / name).read_text(encoding="utf-8")
        for name in layout_files.values()
    }
    for fname, source in layout_sources.items():
        check("LayoutBase {" in source, f"shared layout base: {fname}")
        check(
            "AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps))" not in source,
            f"no duplicate full-catalog sort: {fname}",
        )
        check(
            "AppsModel.appsAzSections(menuData.allApps)" not in source,
            f"no duplicate A-Z grouping: {fname}",
        )
        check(
            not any(pattern in source for pattern in [
                "model: root.allAppsItems.length",
                "model: root.gridItems.length",
                "model: section.apps.length",
            ]),
            f"no eager full-app repeater: {fname}",
        )
        pinned_grid_blocks = re.findall(
            r"Components\.PinnedAppsGrid\s*\{.*?^\s*\}", source, re.MULTILINE | re.DOTALL
        )
        check(
            all(not re.search(r"^\s*fg\s*:", block, re.MULTILINE) for block in pinned_grid_blocks),
            f"PinnedAppsGrid uses supported properties: {fname}",
        )
        check("Components.SearchField {" not in source, f"shared search adapter: {fname}")
        check("Components.AppGrid {" not in source, f"shared grid adapter: {fname}")
        check("Components.VirtualizedAppList {" not in source, f"shared list adapter: {fname}")
        # Face photos must go through UserFace (or a chrome helper that uses it).
        # ShortcutRow / icon.name treats the path as a symbolic mask → solid disc.
        if "userIcon" in source:
            uses_face = (
                "Components.UserFace {" in source
                or "PlacesSidebar" in source
                or "SystemActionsBar" in source
            )
            uses_row = bool(re.search(
                r"ShortcutRow\s*\{[^}]*userIcon", source, re.DOTALL
            ))
            uses_icon_name = bool(re.search(
                r"icon\.name:\s*[^\n]*userIcon", source
            ))
            check(uses_face and not uses_row and not uses_icon_name,
                  f"user avatar via UserFace: {fname}")

    for lid, body, fname in layout_blocks:
        if not re.search(r"hasUser:\s*true", body):
            continue
        src = layout_sources.get(fname, "")
        check(
            "Components.UserFace {" in src
            or "PlacesSidebar" in src
            or "SystemActionsBar" in src,
            f"hasUser layout shows UserFace: {lid}",
        )

    redmond = layout_sources.get("LayoutRedmond.qml", "")
    check("Components.UserFace {" in redmond, "Redmond uses shared user avatar")

    kickoff = layout_sources.get("LayoutKickoff.qml", "")
    kickoff_meta = next((body for lid, body, _fname in layout_blocks if lid == "kickoff"), "")
    check('defaultSidebarWidth: 185' in kickoff_meta, "Kickoff sidebar width metadata")
    check('property string section: "applications"' in kickoff, "Kickoff applications/places sections")
    check('property string applicationsPage: "special:favorites"' in kickoff, "Kickoff applications pages")
    check('property string placesPage: "computer"' in kickoff, "Kickoff places pages")
    check("Components.LayoutGroupPane {" in kickoff, "Kickoff shared favorites grid")
    check("useGrid: root.showingGrid" in kickoff, "Kickoff shared applications list")
    check("Components.ResolvedIcon {" in kickoff, "Kickoff shared category icon resolver")
    check("signal keepOpenRequested(bool pinned)" in kickoff, "Kickoff keep-open contract")
    check(kickoff.count("Layout.maximumHeight: Layout.preferredHeight") >= 2,
          "Kickoff fixed header and footer heights")
    check("Layout.minimumWidth: Layout.preferredWidth" in kickoff,
          "Kickoff reserved header action width")

    check((PKG / "contents/ui/layouts/budgie/README.md").exists(), "budgie folder")
    check((PKG / "contents/ui/layouts/LayoutBudgie.qml").exists(), "budgie layout entry")
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
    check((PKG / "contents/ui/layouts/redmond/README.md").exists(), "redmond folder")
    check((PKG / "contents/ui/layouts/LayoutRedmond.qml").exists(), "redmond layout entry")
    check((PKG / "contents/ui/layouts/sleek/README.md").exists(), "sleek folder")
    check((PKG / "contents/ui/layouts/LayoutSleek.qml").exists(), "sleek layout entry")
    check((PKG / "contents/ui/layouts/tognee/README.md").exists(), "tognee folder")
    check((PKG / "contents/ui/layouts/LayoutTognee.qml").exists(), "tognee layout entry")
    check((PKG / "contents/ui/layouts/unity/README.md").exists(), "unity folder")
    check((PKG / "contents/ui/layouts/LayoutUnity.qml").exists(), "unity layout entry")
    check((PKG / "contents/ui/layouts/windows/README.md").exists(), "windows folder")
    check((PKG / "contents/ui/layouts/LayoutWindows.qml").exists(), "windows layout entry")
    check((PKG / "contents/ui/layouts/zest/README.md").exists(), "zest folder")
    check((PKG / "contents/ui/layouts/LayoutZest.qml").exists(), "zest layout entry")
    check((PKG / "contents/ui/layouts/chromebook/README.md").exists(), "chromebook folder")
    check((PKG / "contents/ui/layouts/LayoutChromebook.qml").exists(), "chromebook layout entry")
    check((PKG / "contents/ui/layouts/elementary/README.md").exists(), "elementary folder")
    check((PKG / "contents/ui/layouts/LayoutElementary.qml").exists(), "elementary layout entry")
    check((PKG / "contents/ui/layouts/raven/README.md").exists(), "raven folder")
    check((PKG / "contents/ui/layouts/LayoutRaven.qml").exists(), "raven layout entry")

    cfg = (PKG / "contents/config/main.xml").read_text(encoding="utf-8")
    required_keys = [
        "ButtonIcon", "ButtonLabelVisible", "ButtonLabelText", "MenuHotkey", "PopupAnimation",
        "UiLanguage",
        "PanelButtonIconSize", "PanelButtonPadding",
        "LeftClickAction", "RightClickAction", "MiddleClickAction",
        "ButtonStyleFgEnabled", "ButtonStyleBgEnabled", "ButtonStyleHoverBgEnabled",
        "ButtonStyleHoverFgEnabled", "ButtonStyleActiveBgEnabled", "ButtonStyleActiveFgEnabled",
        "ButtonStyleRadiusEnabled", "ButtonStyleBorderWidthEnabled", "ButtonStyleBorderColorEnabled",
        "MenuLayoutId", "FlipHorizontal", "SearchbarLocation",
        "AllAppsButtonAction", "ShowUserAvatar", "AvatarShape", "ShowVerticalSeparator",
        "ShowExternalDevices", "ShowBookmarks", "QuickLinksOrder", "QuickLinksEnabled", "QuickLinkPosition",
        "MenuWidth", "MenuHeight", "SidebarWidth", "CategoryColumnWidth",
        "LeftPanelWidth", "RightPanelWidth", "WidthOffset", "OverrideMenuPosition", "OverrideMenuRise", "MenuRiseDistance",
        "IconSizeGrid", "IconSizeApps", "IconSizeShortcuts", "IconSizeCategories", "IconSizeButtons", "IconSizeOther",
        "ShowCategorySubmenus", "ShowAppDescriptions", "ShowGenericNames", "ShowHiddenRecentFiles",
        "MultiLineLabels", "ShowTooltips", "GroupAppsAlphabeticallyList", "GroupAppsAlphabeticallyGrid",
        "ActivateExistingWindow", "KeepOpenOnCtrlClick", "ScrollviewFadeEffects", "ShowScrollbars",
        "OverlayScrollbars", "CategoryIconType", "ShortcutIconType",
        "ThemeMode", "OverrideMenuTheme", "MenuThemeName", "CustomThemes",
        "BgColor", "FgColor", "BorderColor", "BorderWidth", "CornerRadius",
        "Font", "FontSize", "SeparatorColor", "HoverBg", "HoverFg", "ActiveBg", "ActiveFg",
        "SelectedBg", "SelectedFg", "CategoryIconSize", "AppIconSize",
        "FollowColorScheme",
        "PinnedApps", "PinnedCols", "SyncWithPlasma",
        "Enabled", "MaxItems", "RecentApps", "GroupViewOptions",
        "Order", "Hidden", "CustomNames", "CustomIcons", "ShowEmpty",
        "DirectoryShortcuts", "ApplicationShortcuts",
        "ExtraCategoriesOrder", "ExtraCategoriesEnabled", "SidebarOrder", "SidebarHidden", "ContextMenuItems",
        "Providers", "Placeholder", "ShowDescription", "MaxResults",
        "HideSearchBar", "HighlightSearchTerms", "SearchBoxRadiusEnabled",
        "SearchBoxRadius", "SearchWindows", "SearchRecentFiles",
        "Options", "PowerOptionsOrder", "Confirm", "SoftwareCenterCmd", "PowerDisplayStyle",
    ]
    for key in required_keys:
        check(f'name="{key}"' in cfg, f"config key: {key}")

    config_pages = [
        "ConfigGeneral.qml", "ConfigMenuButton.qml", "ConfigLayout.qml", "ConfigArcLayout.qml", "ConfigPinned.qml",
        "ConfigDirectoryShortcuts.qml", "ConfigAppShortcuts.qml", "ConfigExtraCategories.qml",
        "ConfigContextMenu.qml",
        "LayoutPreview.qml", "ConfigTheme.qml", "ConfigVisual.qml", "ConfigFineTune.qml",
        "ConfigContent.qml", "ConfigSearch.qml", "ConfigPower.qml",
    ]
    for page in config_pages:
        check((PKG / "contents/ui/config" / page).exists(), f"settings page: {page}")

    # Static Plasma categories plus the nested menu-page model introduced by
    # ConfigMenu.  Titles in the latter are wrapped in root.tr(...), but the
    # source message ids remain stable and are what this contract validates.
    config_model = "\n".join([
        (PKG / "contents/config/config.qml").read_text(encoding="utf-8"),
        (PKG / "contents/ui/config/ConfigMenu.qml").read_text(encoding="utf-8"),
    ])
    # "About" comes from Plasma metadata, not a custom ConfigCategory
    for label in [
        "General", "Menu Button", "Menu Layout", "ArcMenu layout adjustment", "Pinned Applications",
        "Directory Shortcuts", "Application Shortcuts",
        "Menu Visual Appearance", "Menu Theme", "Fine-tuning",
        "Menu Groups", "Search Options", "Power Options",
        "Modify ArcMenu Context Menu",
    ]:
        check(label in config_model, f"settings category: {label}")

    components = [
        "SearchField.qml", "AppListItem.qml", "CategoryList.qml", "PinnedAppsGrid.qml",
        "AppGrid.qml", "SystemActionsBar.qml", "AppContextMenu.qml", "ConfirmDialog.qml",
        "AppDetailsDialog.qml",
        "ShortcutRow.qml", "PlacesSidebar.qml", "SessionButtons.qml", "AllAppsButton.qml",
        "PinnedAppsList.qml", "VirtualizedAppList.qml",
        "LayoutSearchField.qml", "LayoutAppGrid.qml", "LayoutAppList.qml",
        "LayoutGroupPane.qml", "ArcMenuSettingsButton.qml",
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
    check((PKG / "contents/code/Locale.js").exists(), "Locale.js")
    check((PKG / "contents/code/CategoryMeta.js").exists(), "CategoryMeta.js")
    check((PKG / "contents/code/SidebarModel.js").exists(), "SidebarModel.js")

    for core in ["main.qml", "MenuData.qml", "LayoutHost.qml", "AppsBackend.qml"]:
        check((PKG / "contents/ui" / core).exists(), f"core ui: {core}")

    layout_base = (PKG / "contents/ui/layouts/LayoutBase.qml").read_text(encoding="utf-8")
    check(
        'categorySubset([])' in layout_base
        and "Office\", \"Development\", \"Accessories\"" not in layout_base,
        "layouts use full system categories",
    )
    apps_page = (PKG / "contents/ui/pages/ArcAppsPage.qml").read_text(encoding="utf-8")
    apps_backend = (PKG / "contents/ui/AppsBackend.qml").read_text(encoding="utf-8")
    layout_search = (PKG / "contents/ui/components/LayoutSearchField.qml").read_text(encoding="utf-8")
    check("Components.LayoutAppList" in layout_base, "shared all-layout app preloader")
    check("function openArcMenuSettings" in layout_base, "shared ArcMenu Settings opener")
    check("sidebarShortcuts" in layout_base, "shared settings-driven sidebar shortcuts")
    check('indexOf("qgrp-")' in layout_base, "custom groups resolve in content pane")
    check("function usesGridView" in layout_base, "per-group grid vs list display")
    extra_cfg = (PKG / "contents/ui/config/ConfigExtraCategories.qml").read_text(encoding="utf-8")
    check('icon.name: "settings-configure"' in extra_cfg, "menu group rows have column settings button")
    check("Column settings" in extra_cfg, "column settings dialog")
    check("Square icons" in extra_cfg and "Show in rows" in extra_cfg, "column view mode options")
    check("Applications in this column" in extra_cfg, "type groups list current apps")
    check("visible: columnDialog.isType" in extra_cfg, "preference groups do not add apps")
    check("root.localApps" in extra_cfg, "column app picker uses AppsBackend catalog")
    check("title: root.tr(\"Recent applications\")" not in extra_cfg,
          "recent apps settings live in the frequent column dialog")
    check('id: "frequent", name: tr("Recent Apps")' in (PKG / "contents/code/ShortcutsConfig.js").read_text(encoding="utf-8"),
          "recent apps is a preference group")
    check("Components.LayoutGroupPane" in layout_sources["LayoutKickoff.qml"],
          "Kickoff honors per-group view mode")
    check("ArcMenuSettingsButton" in layout_search, "search field ArcMenu Settings")
    check((PKG / "contents/icons/arcmenu-settings.svg").exists(), "dedicated ArcMenu Settings icon")
    settings_btn = (PKG / "contents/ui/components/ArcMenuSettingsButton.qml").read_text(encoding="utf-8")
    check("arcmenu-settings.svg" in settings_btn, "settings button uses dedicated icon")
    check("Layout.fillHeight: false" in layout_search, "search field does not stretch layouts")
    app_menu = layout_sources.get("LayoutApplicationMenu.qml", "")
    check("ArcMenuSettingsButton" in app_menu, "traditional menus keep settings button")
    id_list = (PKG / "contents/code/IdList.js").read_text(encoding="utf-8")
    check("arcmenu-settings" not in id_list.split("function defaultPinnedIds")[1].split("function")[0],
          "default pins omit in-menu ArcMenu Settings")
    for fname, source in layout_sources.items():
        has_search = "Components.LayoutSearchField" in source
        has_direct = ("ArcMenuSettingsButton" in source
                      or "requestConfigure" in source
                      or "openArcMenuSettings" in source)
        check(has_search or has_direct, f"layout exposes ArcMenu Settings: {fname}")
    check("Components.VirtualizedAppList" in apps_page, "apps page uses shared virtualized list")
    check("CategoryMeta.iconForCategory(" in apps_backend, "shared semantic category icons")
    check("SidebarModel.orderedItems(" in layout_sources["LayoutKickoff.qml"],
          "Kickoff shared configurable sidebar")

    layout_preview = (PKG / "contents/ui/config/LayoutPreview.qml").read_text(encoding="utf-8")
    config_layout = (PKG / "contents/ui/config/ConfigLayout.qml").read_text(encoding="utf-8")
    main_qml = (PKG / "contents/ui/main.qml").read_text(encoding="utf-8")
    check("switch (layoutId)" not in layout_preview, "preview kind comes from registry")
    check("Math.min(width, height)" not in layout_preview, "preview margins avoid size binding loops")
    check("deskBlock.expanded ? deskBlock.deskLayouts.length : 0" in config_layout,
          "collapsed desktop groups stay lazy")
    check("catBlock.expanded ? catBlock.desktops.length : 0" in config_layout,
          "collapsed layout categories stay lazy")
    check("desktopsInCategory" in config_layout, "layout picker nests desktop groups")
    check("switch (cat.id)" not in config_layout,
          "category titles come from registry metadata")
    check("switch (desk.id)" not in config_layout,
          "desktop titles come from registry metadata")
    check('id !== "raven"' not in config_layout, "no layout-id sizing special case in config")
    check("isRavenLayout" not in main_qml, "no layout-id sizing special case at runtime")
    check('MenuLayoutId === "gnome"' in main_qml
          and 'MenuLayoutId = "budgie"' in main_qml,
          "legacy GNOME layout migrates to Budgie")

    for needle in ["Keys.onPressed", "Plasmoid.onActivated", "contextualActions", "ConfirmDialog", "AppContextMenu"]:
        check(needle in main_qml, f"main.qml contains {needle}")

    ctx = (PKG / "contents/ui/components/AppContextMenu.qml").read_text(encoding="utf-8")
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
