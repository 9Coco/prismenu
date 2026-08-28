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
        "Enabled", "MaxItems", "RecentApps", "GroupViewOptions", "HomeGroupId",
        "Order", "Hidden", "CustomNames", "CustomIcons", "ShowEmpty",
        "DirectoryShortcuts", "PlaceSectionOrder", "SystemPlaceOrder", "HiddenSystemPlaces",
        "DolphinPlaceOrder", "HiddenDolphinPlaces", "HiddenCustomPlaces", "ApplicationShortcuts",
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
        "General", "Menu Button", "Menu Layout", "ArcMenu layout adjustment",
        "Frequent Locations", "Application Shortcuts",
        "Menu Visual Appearance", "Menu Theme", "Fine-tuning",
        "Menu Groups", "Search Options", "Power Options",
    ]:
        check(label in config_model, f"settings category: {label}")
    check("Modify ArcMenu Context Menu" not in config_model
          and "pageContext" not in config_model,
          "obsolete context-menu settings entry removed")
    top_config = (PKG / "contents/config/config.qml").read_text(encoding="utf-8")
    check(top_config.index('tr("Menu")') < top_config.index('tr("General")')
          < top_config.index('tr("Menu Button")'),
          "top-level settings put functional menu pages before appearance")
    check(config_model.index('tr("What should show on the menu?")')
          < config_model.index('tr("How should the menu look?")'),
          "menu settings put functional content before appearance")
    menu_config = (PKG / "contents/ui/config/ConfigMenu.qml").read_text(encoding="utf-8")
    check(menu_config.index('title: root.tr("Menu Layout")')
          < menu_config.index('title: root.tr("Frequent Locations")')
          < menu_config.index('title: root.tr("ArcMenu layout adjustment")')
          < menu_config.index('title: root.tr("Power Options")')
          < menu_config.index('title: root.tr("How should the menu look?")'),
          "menu layout leads while ArcMenu adjustment and power stay lower")
    check('title: root.tr("Pinned Applications")' not in config_model,
          "pinned apps page removed from menu hub")
    visual_cfg = (PKG / "contents/ui/config/ConfigVisual.qml").read_text(encoding="utf-8")
    check("Left panel width" not in visual_cfg and "Width offset" not in visual_cfg,
          "visual settings no longer include drag-resized panel widths")
    fine_cfg = (PKG / "contents/ui/config/ConfigFineTune.qml").read_text(encoding="utf-8")
    check("Show category submenus" not in fine_cfg
          and "Scrollview fade effects" not in fine_cfg,
          "unused GNOME leftover toggles removed from fine-tuning")
    setting_row = (PKG / "contents/ui/config/ConfigSettingRow.qml").read_text(encoding="utf-8")
    extra_cfg = (PKG / "contents/ui/config/ConfigExtraCategories.qml").read_text(encoding="utf-8")
    check("Components.ResolvedIcon" in setting_row
          and "iconName: newGroupDialog.groupIcon" in extra_cfg,
          "custom group preset icons resolve in dialogs and settings rows")
    check("groupCreationPending" in extra_cfg
          and "submitLocked" in extra_cfg
          and "duplicate custom group ignored" in extra_cfg
          and "writeConfig()" not in extra_cfg
          and "scheduleGroupModelsRebuild" in extra_cfg,
          "custom group creation is single-shot, deduplicated, and coalesced")
    check("function toQmlColor" in (PKG / "contents/code/Theme.js").read_text(encoding="utf-8"),
          "theme colors convert rgb() for QML swatches")
    dirs_page = (PKG / "contents/ui/config/ConfigDirectoryShortcuts.qml").read_text(encoding="utf-8")
    check("Frequent Locations" in dirs_page, "places page uses Frequent Locations title")
    check("Ui.PlasmaNative" in dirs_page
          and "System Locations" in dirs_page
          and "File Manager Locations" in dirs_page
          and "User Custom Locations" in dirs_page
          and "Managed in Dolphin Places" in dirs_page
          and "Add default user directory" not in dirs_page,
          "places settings mirrors KDE system and user location groups")
    check("PlaceSectionOrder" in dirs_page and "HiddenSystemPlaces" in dirs_page
          and "HiddenDolphinPlaces" in dirs_page and "HiddenCustomPlaces" in dirs_page
          and "removeDolphinPlace" in dirs_page and "Add custom application" in dirs_page,
          "three place blocks support order visibility removal and app additions")
    check("Add custom file" in dirs_page and "FileDialog" in dirs_page,
          "places page can add custom files")

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
    pin_backend = apps_backend.split("function pinToTaskManager", 1)[1].split("function addDesktopShortcut", 1)[0]
    check('triggerSystemAction(app, "addToTaskManager", undefined)' in pin_backend
          and "sourceModel.trigger(path[path.length - 1]" in apps_backend,
          "taskbar pin uses Kicker native action")
    check("evaluateScript" not in pin_backend and "writeConfig('launchers'" not in pin_backend,
          "taskbar pin does not edit Plasma panel configuration")
    check("appletInterface: root.appletInterface" in apps_backend
          and "appletInterface: root" in (PKG / "contents/ui/main.qml").read_text(encoding="utf-8"),
          "Kicker receives the ArcMenu PlasmoidItem like Kickoff")
    check("favoritesModel.initForClient" in apps_backend,
          "Kicker global favorites model is initialized")
    check("model.actionList" in apps_backend and "triggerSystemAction" in apps_backend,
          "context menu uses Kicker native action list")
    layout_search = (PKG / "contents/ui/components/LayoutSearchField.qml").read_text(encoding="utf-8")
    check("Components.LayoutAppList" in layout_base, "shared all-layout app preloader")
    check("function openArcMenuSettings" in layout_base, "shared ArcMenu Settings opener")
    check("sidebarShortcuts" in layout_base, "shared settings-driven sidebar shortcuts")
    check('indexOf("qgrp-")' in layout_base, "custom groups resolve in content pane")
    check("function usesGridView" in layout_base, "per-group grid vs list display")
    extra_cfg = (PKG / "contents/ui/config/ConfigExtraCategories.qml").read_text(encoding="utf-8")
    check('icon.name: "settings-configure"' in extra_cfg, "menu group rows have column settings button")
    check("Column settings" in extra_cfg, "column settings dialog")
    check("Icon grid" in extra_cfg and "List" in extra_cfg, "column view mode options")
    check("setGroupIconSize" in extra_cfg and "Icon size" in extra_cfg,
          "grid columns can change icon size")
    check("Applications in this column" in extra_cfg, "type groups list current apps")
    check("columnAppsList" in extra_cfg and "QQC2.ScrollBar.AlwaysOn" in extra_cfg,
          "column apps list has a visible scrollbar")
    check("visible: columnDialog.isType" in extra_cfg, "preference groups do not add apps")
    check("root.localApps" in extra_cfg, "column app picker uses AppsBackend catalog")
    check('id: manageDialog' in extra_cfg
          and "contentItem: Rectangle" in extra_cfg
          and "Kirigami.Theme.backgroundColor" in extra_cfg,
          "add-app dialog fills with an opaque pane")
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
    check("root.typeCategories" in layout_sources["LayoutKickoff.qml"],
          "Kickoff uses shared type groups")
    check("root.preferenceGroups" in layout_sources["LayoutKickoff.qml"],
          "Kickoff uses shared preference groups")
    check("placeShortcuts" in layout_base, "shared frequent-locations list")
    registry_src = (PKG / "contents/code/LayoutRegistry.js").read_text(encoding="utf-8")
    check("SHARED_DEFAULT_WIDTH = 620" in registry_src
          and "function sizeForLayout" in registry_src,
          "layouts share one default size and remember per-layout resizes")
    config_layout = (PKG / "contents/ui/config/ConfigLayout.qml").read_text(encoding="utf-8")
    check("meta.defaultWidth" not in config_layout
          and "sizeForLayout" in config_layout,
          "switching layouts does not apply per-layout default sizes")
    main_qml = (PKG / "contents/ui/main.qml").read_text(encoding="utf-8")
    check("layoutFillsAvailableHeight: false" in main_qml,
          "layouts do not open at full desktop height")
    check('name="LayoutSizes"' in (PKG / "contents/config/main.xml").read_text(encoding="utf-8"),
          "per-layout size map is persisted")
    check("applicationShortcuts" in layout_base, "shared application-shortcut list")
    for fname, needle, msg in [
        ("LayoutRedmond.qml", "root.placeShortcuts", "Redmond uses frequent locations"),
        ("LayoutWindows.qml", "root.placeShortcuts", "Windows uses frequent locations"),
        ("LayoutTognee.qml", "root.placeShortcuts", "Tognee uses frequent locations"),
        ("LayoutUnity.qml", "root.placeShortcuts", "Unity uses frequent locations"),
        ("LayoutDeepin.qml", "root.usesGridView", "Deepin honors column view mode"),
        ("LayoutEnterprise.qml", "LayoutGroupPane", "Enterprise honors column view mode"),
        ("LayoutLibrary.qml", "LayoutGroupPane", "Library honors column view mode"),
        ("LayoutPlasmaDash.qml", "root.preferenceGroups", "Plasma Dash uses preference groups"),
        ("LayoutApplicationMenu.qml", "root.preferenceGroups", "Application Menu uses preference groups"),
        ("LayoutSleek.qml", "usesGridView", "Sleek honors pinned/all-apps view mode"),
    ]:
        check(needle in layout_sources[fname], msg)
    deepin_layout = layout_sources["LayoutDeepin.qml"]
    check("Layout.maximumWidth: root.categorySidebarWidth" in deepin_layout
          and "Layout.minimumWidth: 0" in deepin_layout
          and "Components.ColumnSplitHandle" in deepin_layout
          and "onWidthDragged: (w) => root.setSidebarFromDrag(w)" in deepin_layout,
          "Cinnamenu grid keeps its app pane inside the popup and resizes its sidebar")

    arc_layout = layout_sources["LayoutArcMenu.qml"]
    arc_apps_page = (PKG / "contents/ui/pages/ArcAppsPage.qml").read_text(encoding="utf-8")
    check('showSystemShortcuts: false' in arc_layout,
          "ArcMenu layout omits redundant software/settings/tweaks block")
    check('root.usesGridView(root.homeGroupId)' in arc_layout
          and "host.groupViewMode(root.activeGroupId)" in arc_apps_page
          and "Components.AppGrid {" in arc_apps_page,
          "ArcMenu home and category pages honor per-group grid mode")
    check("customById[eid]" in arc_apps_page
          and "Never expose an internal qgrp-* id" in arc_apps_page,
          "custom preference groups resolve their configured name and icon")
    app_grid = (PKG / "contents/ui/components/AppGrid.qml").read_text(encoding="utf-8")
    check("currentIndex: -1" in app_grid and "minCellWidth:" in arc_layout,
          "ArcMenu pinned grid uses adaptive spacing without a stale first-item highlight")
    plasma_native = (PKG / "contents/ui/PlasmaNative.qml").read_text(encoding="utf-8")
    menu_data = (PKG / "contents/ui/MenuData.qml").read_text(encoding="utf-8")
    config_menu = (PKG / "contents/ui/config/ConfigMenu.qml").read_text(encoding="utf-8")
    backup_js = (PKG / "contents/code/ConfigBackup.js").read_text(encoding="utf-8")
    check('property string cfg_HomeGroupId: "pinned"' in extra_cfg
          and 'writeLive("HomeGroupId"' in extra_cfg
          and '"HomeGroupId"' in config_menu
          and '"HomeGroupId"' in backup_js,
          "home group setting is editable, live, and included in backup")
    check("readonly property var homeApps" in menu_data
          and 'id === "pinned"' in menu_data
          and 'id === "all-apps"' in menu_data
          and 'root.customGroupApps(id)' in menu_data
          and 'AppsModel.appsInCategory(root.allApps, id)' in menu_data,
          "home group resolves special, custom, and system categories")
    home_area_layouts = [
        (PKG / "contents/ui/layouts" / name).read_text(encoding="utf-8") for name in [
            "LayoutChromebook.qml", "LayoutElementary.qml", "LayoutInsider.qml",
            "LayoutPop.qml", "LayoutRunner.qml", "LayoutSimple.qml",
        ]
    ]
    check("root.homeItems" in arc_layout
          and all("root.homeItems" in source for source in home_area_layouts),
          "dedicated home application areas use the selected group")
    check(all("function resetForOpen" in layout_sources[name]
              and "root.homeGroupId" in layout_sources[name] for name in [
                  "LayoutBrisk.qml", "LayoutBudgie.qml", "LayoutDeepin.qml",
                  "LayoutEnterprise.qml", "LayoutKickoff.qml", "LayoutKickoffCompact.qml",
                  "LayoutMint.qml", "LayoutPlasmaDash.qml", "LayoutTognee.qml",
                  "LayoutWhisker.qml", "LayoutZest.qml",
              ]), "group-navigation layouts open on the selected home group")
    places_sidebar = (PKG / "contents/ui/components/PlacesSidebar.qml").read_text(encoding="utf-8")
    check("Kicker.ComputerModel {" in plasma_native
          and 'provider: "kicker-computer"' in plasma_native,
          "places use the same Kicker ComputerModel as Kickoff")
    check("isSystemItem" in plasma_native
          and "isSystemPlace:" in plasma_native
          and "xmllint --xpath" in plasma_native,
          "KDE built-in places are separated from Dolphin user bookmarks")
    check("readonly property var systemPlaces" in menu_data
          and "readonly property var customPlaces" in menu_data
          and 'id: "place-bookmarks"' not in menu_data,
          "system and custom places are separate without a synthetic bookmarks tab")
    check("Exactly two permanent boundaries" in places_sidebar
          and "model: root.placeSections" in places_sidebar
          and "placeSections.length - 1" in places_sidebar,
          "places sidebar always separates all three configurable blocks")

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
    menu_data = (PKG / "contents/ui/MenuData.qml").read_text(encoding="utf-8")
    main_qml = (PKG / "contents/ui/main.qml").read_text(encoding="utf-8")
    arc_cfg = (PKG / "contents/ui/config/ConfigArcLayout.qml").read_text(encoding="utf-8")
    check("PresetIcons.isPreset" in ctx and "icon.source: root.groupIconSource" in ctx,
          "custom group context rows resolve bundled preset icons")
    check("function customGroupAppId" in menu_data
          and "function customGroupAppByStoredId" in menu_data
          and "root.catalog.customGroupAppId(app)" in main_qml,
          "custom group writes and reads canonical catalog app ids")
    check("plasmoid.configuration.CustomGroupApps" in arc_apps_page
          and "host.extrasSignature" in arc_apps_page
          and "root.refreshTick++" in arc_apps_page,
          "custom group pages refresh after live membership writes")
    for source, label in [(extra_cfg, "menu groups"), (arc_cfg, "ArcMenu layout")]:
        check(all(key in source for key in [
            'writeLive("CustomGroupApps"', 'writeLive("ExtraCategoriesOrder"',
            'writeLive("ExtraCategoriesEnabled"', 'writeLive("SidebarOrder"',
            'writeLive("SidebarHidden"', 'writeLive("QuickLinksOrder"',
            'writeLive("QuickLinksEnabled"', 'writeLive("GroupViewOptions"',
        ]), f"deleted custom groups clean every reference: {label}")
    check("activeCustomGroupExists" in arc_apps_page,
          "deleting an open custom group returns to categories")
    check('indexOf("qgrp-") === 0' in arc_apps_page
          and "root.openSpecialList(String(id))" in arc_apps_page
          and "root.dataHost.customGroupAppIds(id)" in arc_apps_page,
          "custom group category clicks resolve explicit member ids")
    check("function dismissAndClear" in ctx
          and "onClosed: root.clearSelection()" in ctx
          and "contextMenu.dismissAndClear()" in main_qml,
          "context menu closes and clears selection with the launcher")
    layout_host = (PKG / "contents/ui/LayoutHost.qml").read_text(encoding="utf-8")
    check("menuData.resetView();" in main_qml.split("onExpandedChanged", 1)[1]
          and "host.resetForOpen();" in main_qml,
          "every popup-open path resets to the default page")
    check("function resetForOpen" in layout_host
          and "_resetForOpenPending" in layout_host
          and "function resetForOpen" in arc_layout
          and "root.showingApps = false" in arc_layout
          and "resetToCategories()" in arc_layout,
          "ArcMenu resets layout-local app/category navigation without reload")

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
