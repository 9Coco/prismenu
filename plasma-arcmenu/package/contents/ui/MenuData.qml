import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "../code/AppsModel.js" as AppsModel
import "../code/Favorites.js" as Favorites
import "../code/Distro.js" as Distro
import "../code/LayoutRegistry.js" as LayoutRegistry
import "../code/Theme.js" as ThemeHelper
import "../code/IdList.js" as IdList
import "../code/Locale.js" as Locale
import "../code/CategoryIcons.js" as CategoryIcons
import "../code/IconSizes.js" as IconSizes
import "../code/ShortcutsConfig.js" as ShortcutsConfig
import "../code/SearchExtras.js" as SearchExtras

QtObject {
    id: root

    // ---- Config bindings (set from main.qml) ----
    property var plasmoidConfig: null
    /** Width ceiling, bound from main.qml to a screen-fit value (MenuData is
     *  a QtObject without a window, so it cannot read Screen itself). */
    property int maxMenuWidth: 900
    // Bound directly from main.qml → plasmoid.configuration.MenuLayoutId
    property string currentLayoutId: "arcmenu"
    /**
     * Bound from main.qml as real QML bindings (not via var/cfg()), so toggles
     * in the config dialog refresh the open menu immediately.
     */
    property var extraCategoriesEnabledRaw
    property var extraCategoriesOrderRaw
    property bool extraCategoriesUserSetRaw: false
    property var quickLinksEnabledRaw
    property var quickLinksOrderRaw
    property var quickLinkPositionRaw
    property var customQuickLinksRaw
    property var customGroupAppsRaw

    // ---- Runtime state ----
    property string searchQuery: ""
    property string currentCategoryId: "all"
    property int kickoffTab: 0 // 0 favorites, 1 recent, 2 apps, 3 places, 4 leave
    property bool categoriesCollapsed: false
    property bool showAllApps: false // legacy toggle; prefer currentPage
    property string currentPage: "home" // home | apps | search
    property var focusedApp: null
    /** Secondary search providers (filled by AppsBackend) */
    property var recentFileResults: []
    property var openWindowResults: []
    property var bookmarkResults: []
    /** Removable devices scanned from /media (fallback when KFilePlacesModel
     *  QML is unavailable) — filled by AppsBackend.refreshDevices() */
    property var deviceResults: []
    /** Bumped when recent-file list is refreshed — forces UI list bindings */
    property int recentFilesEpoch: 0
    property int bookmarksEpoch: 0
    property int devicesEpoch: 0
    /** Increment to ask AppsBackend to re-read recently-used.xbel */
    property int recentFilesRequest: 0
    property int bookmarksRequest: 0
    property int devicesRequest: 0

    function requestRecentFilesRefresh() {
        recentFilesRequest++;
    }
    function requestBookmarksRefresh() {
        bookmarksRequest++;
    }
    function requestDevicesRefresh() {
        devicesRequest++;
    }

    /** Device list for the "External devices" drill-down: prefer live
     *  KFilePlacesModel device entries, fall back to the /media scan. */
    readonly property var deviceEntries: {
        var _e = root.devicesEpoch; // refresh tick
        if (plasmaPlaces && plasmaPlaces.length) {
            var out = [];
            for (var i = 0; i < plasmaPlaces.length; ++i) {
                if (plasmaPlaces[i].isDevice)
                    out.push(plasmaPlaces[i]);
            }
            if (out.length)
                return out;
        }
        return deviceResults || [];
    }

    /**
     * Safe config read: plasmoid.configuration keys can be undefined when
     * accessed via a var alias — never return undefined into typed properties.
     */
    function cfg(key, fallback) {
        try {
            if (!plasmoidConfig)
                return fallback;
            var v = plasmoidConfig[key];
            if (v === undefined || v === null)
                return fallback;
            return v;
        } catch (e) {
            return fallback;
        }
    }

    function cfgBool(key, fallback) {
        var v = cfg(key, fallback);
        return v === true || v === 1 || v === "true";
    }

    function cfgInt(key, fallback) {
        var v = cfg(key, fallback);
        var n = parseInt(v, 10);
        return isNaN(n) ? fallback : n;
    }

    function cfgStr(key, fallback) {
        var v = cfg(key, fallback);
        return (v === undefined || v === null) ? fallback : String(v);
    }

    // ---- UI language (General → Menu language) ----
    readonly property string uiLanguagePref: cfgStr("UiLanguage", "zh_CN")
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function trf(msgid, arg1) {
        return Locale.trf(msgid, uiLang, arg1);
    }

    // ---- Derived config accessors ----
    readonly property var layoutInfo: LayoutRegistry.getLayout(currentLayoutId)
    readonly property bool flipHorizontal: cfgBool("FlipHorizontal", false)
    readonly property string searchbarLocation: cfgStr("SearchbarLocation", "bottom")
    readonly property bool searchbarLocationUserSet: cfgBool("SearchbarLocationUserSet", false)
    readonly property string allAppsButtonAction: cfgStr("AllAppsButtonAction", "category-list")
    readonly property bool showUserAvatar: cfgBool("ShowUserAvatar", true)
    readonly property string avatarShape: cfgStr("AvatarShape", "circle")
    readonly property bool showVerticalSeparator: cfgBool("ShowVerticalSeparator", false)
    readonly property bool showExternalDevices: cfgBool("ShowExternalDevices", false)
    readonly property bool showBookmarks: cfgBool("ShowBookmarks", true)
    readonly property var quickLinksOrder: {
        var o = (quickLinksOrderRaw !== undefined && quickLinksOrderRaw !== null)
            ? quickLinksOrderRaw
            : cfg("QuickLinksOrder", ["favorites", "frequent", "all-apps", "pinned", "recent-files"]);
        if (typeof o === "string")
            return o.length ? o.split(",") : [];
        return o || [];
    }
    readonly property var quickLinksEnabled: {
        var o = (quickLinksEnabledRaw !== undefined && quickLinksEnabledRaw !== null)
            ? quickLinksEnabledRaw
            : cfg("QuickLinksEnabled", []);
        if (typeof o === "string")
            return o.length ? o.split(",") : [];
        return o || [];
    }
    readonly property string quickLinkPosition: {
        if (quickLinkPositionRaw !== undefined && quickLinkPositionRaw !== null && String(quickLinkPositionRaw).length)
            return String(quickLinkPositionRaw);
        return cfgStr("QuickLinkPosition", "bottom");
    }

    function isQuickLinkEnabled(id) {
        return (quickLinksEnabled || []).indexOf(id) >= 0;
    }
    
    // ---- Custom quick link groups (user-defined app collections) ----
    readonly property var customQuickLinkDefs: {
        var raw = (customQuickLinksRaw !== undefined && customQuickLinksRaw !== null)
            ? customQuickLinksRaw : cfg("CustomQuickLinks", []);
        if (typeof raw === "string")
            raw = raw.length ? raw.split(",") : [];
        var out = [];
        for (var i = 0; i < (raw || []).length; ++i) {
            var parts = String(raw[i] || "").split("|");
            var gid = parts[0] || "";
            if (!gid)
                continue;
            out.push({ id: gid, name: parts[1] || gid, icon: parts[2] || "folder-favorites" });
        }
        return out;
    }
    
    readonly property var customGroupMap: {
        var raw = (customGroupAppsRaw !== undefined && customGroupAppsRaw !== null)
            ? customGroupAppsRaw : cfg("CustomGroupApps", "{}");
        try {
            var obj = JSON.parse(String(raw || "{}"));
            return (obj && typeof obj === "object") ? obj : {};
        } catch (e) {
            return {};
        }
    }
    
    function customGroupAppIds(groupId) {
        var list = root.customGroupMap[groupId];
        return Array.isArray(list) ? list : [];
    }
    
    function isAppInCustomGroup(groupId, appId) {
        return root.customGroupAppIds(groupId).indexOf(appId) >= 0;
    }
    
    function setCustomGroupApps(groupId, ids) {
        if (!groupId || !plasmoidConfig)
            return;
        var map = JSON.parse(JSON.stringify(root.customGroupMap));
        map[groupId] = ids || [];
        plasmoidConfig.CustomGroupApps = JSON.stringify(map);
        console.log("ArcMenu setCustomGroupApps", groupId, "->", JSON.stringify(ids || []));
    }
    
    function addToCustomGroup(groupId, appId) {
        if (!appId)
            return;
        var ids = root.customGroupAppIds(groupId).slice();
        if (ids.indexOf(appId) >= 0)
            return;
        ids.push(appId);
        root.setCustomGroupApps(groupId, ids);
    }
    
    function removeFromCustomGroup(groupId, appId) {
        var ids = root.customGroupAppIds(groupId).slice();
        var idx = ids.indexOf(appId);
        if (idx < 0)
            return;
        ids.splice(idx, 1);
        root.setCustomGroupApps(groupId, ids);
    }
    
    /** Resolve a group's app ids to real app objects (unknown ids skipped). */
    function customGroupApps(groupId) {
        var ids = root.customGroupAppIds(groupId);
        var out = [];
        for (var i = 0; i < ids.length; ++i) {
            var app = AppsModel.findAppById(root.allApps, ids[i]);
            if (app)
                out.push(app);
        }
        return out;
    }
    
    readonly property var enabledQuickLinks: {
        var order = quickLinksOrder.length
            ? quickLinksOrder
            : ["favorites", "frequent", "all-apps", "pinned", "recent-files"];
        var out = [];
        for (var i = 0; i < order.length; ++i) {
            var id = order[i];
            // Retired: the sidebar AllAppsButton already navigates to the all-apps view,
            // so a duplicate quick link only confused the menu (removed 2026-08).
            if (id === "all-apps")
                continue;
            // Custom groups are appended by the defs loop below — skip them here,
            // otherwise a raw "qgrp-…" ghost row appears next to the real entry.
            if (String(id).indexOf("qgrp-") === 0)
                continue;
            if (!root.isQuickLinkEnabled(id))
                continue;
            var name = id;
            var icon = "application-x-executable";
            if (id === "favorites") { name = root.tr("Favorites"); icon = "emblem-favorite"; }
            else if (id === "frequent") { name = root.tr("Frequent Apps"); icon = "view-calendar"; }
            else if (id === "all-apps") { name = root.tr("All Applications"); icon = "view-app-grid-symbolic"; }
            else if (id === "pinned") { name = root.tr("Pinned Applications"); icon = "pin"; }
            else if (id === "recent-files") { name = root.tr("Recent Files"); icon = "document-open-recent"; }
            out.push({ id: "quick-" + id, quickId: id, name: name, icon: icon, action: "quicklink:" + id });
        }
        // Custom user-defined groups (created in Layout Adjustment settings)
        var defs = root.customQuickLinkDefs;
        for (var c = 0; c < defs.length; ++c) {
            if (!root.isQuickLinkEnabled(defs[c].id))
                continue;
            out.push({ id: "quick-" + defs[c].id, quickId: defs[c].id, name: defs[c].name,
                icon: defs[c].icon, action: "quicklink:" + defs[c].id });
        }
        return out;
    }
    // Direct plasmoidConfig.* reads so QML tracks live drag-resize writes
    readonly property int leftPanelWidth: LayoutRegistry.clampSize(
        (plasmoidConfig && plasmoidConfig.LeftPanelWidth !== undefined && plasmoidConfig.LeftPanelWidth !== null)
            ? plasmoidConfig.LeftPanelWidth : 380,
        180, 1600, 380)
    readonly property int rightPanelWidth: LayoutRegistry.clampSize(
        (plasmoidConfig && plasmoidConfig.RightPanelWidth !== undefined && plasmoidConfig.RightPanelWidth !== null)
            ? plasmoidConfig.RightPanelWidth : 220,
        160, 360, 220)
    readonly property int widthOffset: LayoutRegistry.clampSize(
        (plasmoidConfig && plasmoidConfig.WidthOffset !== undefined && plasmoidConfig.WidthOffset !== null)
            ? plasmoidConfig.WidthOffset : 0,
        -200, 400, 0)
    /** Traditional panels (+ chrome) + optional width offset for non-traditional layouts */
    readonly property int menuWidth: LayoutRegistry.clampSize(
        leftPanelWidth + rightPanelWidth + 24 + widthOffset, 400, root.maxMenuWidth, 620)
    // Shared MenuHeight max is 800; Raven uses runtime fill height in main.qml instead
    readonly property int menuHeight: LayoutRegistry.clampSize(
        (plasmoidConfig && plasmoidConfig.MenuHeight !== undefined && plasmoidConfig.MenuHeight !== null)
            ? plasmoidConfig.MenuHeight : 540,
        400, 800, 540)
    /** Places / categories side column — synced with right panel for ArcMenu-style shells */
    readonly property int sidebarWidth: LayoutRegistry.clampSize(
        cfgInt("SidebarWidth", cfgInt("RightPanelWidth", 220)), 160, 360, 220)
    /** Zest middle categories column */
    readonly property int categoryColumnWidth: LayoutRegistry.clampSize(cfgInt("CategoryColumnWidth", 220), 160, 360, 220)
    readonly property string overrideMenuPosition: cfgStr("OverrideMenuPosition", "off")
    readonly property bool overrideMenuRise: cfgBool("OverrideMenuRise", false)
    readonly property int menuRiseDistance: LayoutRegistry.clampSize(cfgInt("MenuRiseDistance", 6), 0, 64, 6)
    readonly property int defaultMenuWidth: {
        var meta = layoutInfo;
        return meta && meta.defaultWidth ? meta.defaultWidth : 620;
    }
    readonly property int defaultMenuHeight: {
        var meta = layoutInfo;
        var h = meta && meta.defaultHeight ? meta.defaultHeight : 540;
        return h > 800 ? 800 : h;
    }
    readonly property int defaultSidebarWidth: 220
    readonly property int defaultCategoryColumnWidth: 220

    function setMenuWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 400, root.maxMenuWidth, 620);
        plasmoidConfig.MenuWidth = c;
        // Keep right panel; adjust left so panels stay consistent with drag-resize
        var left = LayoutRegistry.clampSize(c - rightPanelWidth - 24 - widthOffset, 180, 1600, 380);
        plasmoidConfig.LeftPanelWidth = left;
        // The left-panel clamp (180–1600) can leave the derived menuWidth short
        // of / beyond the requested width — absorb the remainder in widthOffset
        // so the persisted menuWidth lands exactly on the dragged size.
        var residual = c - (left + rightPanelWidth + 24 + widthOffset);
        if (residual !== 0)
            plasmoidConfig.WidthOffset = LayoutRegistry.clampSize(widthOffset + residual, -200, 400, 0);
    }

    function setMenuHeight(h) {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.MenuHeight = LayoutRegistry.clampSize(h, 400, 800, 540);
    }

    function setSidebarWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 160, 360, 220);
        plasmoidConfig.SidebarWidth = c;
        plasmoidConfig.RightPanelWidth = c;
    }

    function setCategoryColumnWidth(w) {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.CategoryColumnWidth = LayoutRegistry.clampSize(w, 160, 360, 220);
    }

    function setLeftPanelWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 180, 600, 290);
        plasmoidConfig.LeftPanelWidth = c;
        plasmoidConfig.MenuWidth = LayoutRegistry.clampSize(
            c + rightPanelWidth + 24, 400, root.maxMenuWidth, 620);
    }

    function setRightPanelWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 160, 360, 205);
        plasmoidConfig.RightPanelWidth = c;
        plasmoidConfig.SidebarWidth = c;
        plasmoidConfig.MenuWidth = LayoutRegistry.clampSize(
            leftPanelWidth + c + 24, 400, root.maxMenuWidth, 620);
    }

    function resetLayoutSizesToDefaults() {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.MenuWidth = defaultMenuWidth;
        plasmoidConfig.MenuHeight = defaultMenuHeight;
        plasmoidConfig.SidebarWidth = defaultSidebarWidth;
        plasmoidConfig.CategoryColumnWidth = defaultCategoryColumnWidth;
        plasmoidConfig.LeftPanelWidth = 380;
        plasmoidConfig.RightPanelWidth = 220;
        plasmoidConfig.WidthOffset = 0;
    }

    readonly property int baseAppIconSize: Math.max(16, cfgInt("AppIconSize", 24))
    readonly property int baseCategoryIconSize: Math.max(16, cfgInt("CategoryIconSize", 24))
    readonly property bool gridIconOverride: cfgInt("IconSizeGrid", -1) >= 0
    readonly property bool appsIconOverride: cfgInt("IconSizeApps", -1) >= 0
    readonly property bool shortcutsIconOverride: cfgInt("IconSizeShortcuts", -1) >= 0
    readonly property bool categoriesIconOverride: cfgInt("IconSizeCategories", -1) >= 0
    readonly property bool buttonsIconOverride: cfgInt("IconSizeButtons", -1) >= 0
    readonly property bool otherIconOverride: cfgInt("IconSizeOther", -1) >= 0
    readonly property int appIconSize: IconSizes.resolve(cfgInt("IconSizeApps", -1), baseAppIconSize)
    readonly property int categoryIconSize: IconSizes.resolve(cfgInt("IconSizeCategories", -1), baseCategoryIconSize)
    readonly property int gridIconSize: IconSizes.resolve(cfgInt("IconSizeGrid", -1), Math.max(baseAppIconSize + 12, 36))
    readonly property int shortcutIconSize: IconSizes.resolve(cfgInt("IconSizeShortcuts", -1), categoryIconSize)
    readonly property int buttonIconSize: IconSizes.resolve(cfgInt("IconSizeButtons", -1), 22)
    readonly property int otherIconSize: IconSizes.resolve(cfgInt("IconSizeOther", -1), 22)
    readonly property int pinnedCols: Math.max(1, cfgInt("PinnedCols", 6))
    readonly property bool recentEnabled: cfgBool("Enabled", true)
    readonly property int recentMax: Math.max(0, cfgInt("MaxItems", 5))
    // Bound from main.qml for live Apply from Search Options
    property var showDescriptionRaw
    property var hideSearchBarRaw
    property var highlightSearchTermsRaw
    property var searchBoxRadiusEnabledRaw
    property var searchBoxRadiusRaw
    property var searchWindowsRaw
    property var searchRecentFilesRaw
    property var maxResultsRaw
    property int searchConfigEpoch: 0

    function bumpSearchConfig() { searchConfigEpoch++; }

    readonly property bool showSearchDescription: {
        var _ = searchConfigEpoch;
        if (showDescriptionRaw !== undefined && showDescriptionRaw !== null)
            return showDescriptionRaw === true || showDescriptionRaw === 1;
        return cfgBool("ShowDescription", true);
    }
    readonly property bool hideSearchBar: {
        var _ = searchConfigEpoch;
        if (hideSearchBarRaw !== undefined && hideSearchBarRaw !== null)
            return hideSearchBarRaw === true || hideSearchBarRaw === 1;
        return cfgBool("HideSearchBar", false);
    }
    readonly property bool highlightSearchTerms: {
        var _ = searchConfigEpoch;
        if (highlightSearchTermsRaw !== undefined && highlightSearchTermsRaw !== null)
            return highlightSearchTermsRaw === true || highlightSearchTermsRaw === 1;
        return cfgBool("HighlightSearchTerms", true);
    }
    readonly property bool searchBoxRadiusEnabled: {
        var _ = searchConfigEpoch;
        if (searchBoxRadiusEnabledRaw !== undefined && searchBoxRadiusEnabledRaw !== null)
            return searchBoxRadiusEnabledRaw === true || searchBoxRadiusEnabledRaw === 1;
        return cfgBool("SearchBoxRadiusEnabled", true);
    }
    readonly property int searchBoxRadius: {
        var _ = searchConfigEpoch;
        var n = (searchBoxRadiusRaw !== undefined && searchBoxRadiusRaw !== null)
            ? parseInt(searchBoxRadiusRaw, 10) : cfgInt("SearchBoxRadius", 25);
        return Math.max(0, isNaN(n) ? 25 : n);
    }
    readonly property bool searchWindows: {
        var _ = searchConfigEpoch;
        if (searchWindowsRaw !== undefined && searchWindowsRaw !== null)
            return searchWindowsRaw === true || searchWindowsRaw === 1;
        return cfgBool("SearchWindows", false);
    }
    readonly property bool searchRecentFiles: {
        var _ = searchConfigEpoch;
        if (searchRecentFilesRaw !== undefined && searchRecentFilesRaw !== null)
            return searchRecentFilesRaw === true || searchRecentFilesRaw === 1;
        return cfgBool("SearchRecentFiles", false);
    }

    // ---- Fine-tuning ----
    readonly property bool showCategorySubmenus: cfgBool("ShowCategorySubmenus", false)
    readonly property bool showAppDescriptions: cfgBool("ShowAppDescriptions", false)
    readonly property bool showGenericNames: cfgBool("ShowGenericNames", false)
    readonly property bool showHiddenRecentFiles: cfgBool("ShowHiddenRecentFiles", false)
    readonly property bool multiLineLabels: cfgBool("MultiLineLabels", true)
    readonly property bool showTooltips: cfgBool("ShowTooltips", true)
    readonly property bool groupAppsAlphabeticallyList: cfgBool("GroupAppsAlphabeticallyList", true)
    readonly property bool groupAppsAlphabeticallyGrid: cfgBool("GroupAppsAlphabeticallyGrid", false)
    readonly property bool activateExistingWindow: cfgBool("ActivateExistingWindow", false)
    readonly property bool keepOpenOnCtrlClick: cfgBool("KeepOpenOnCtrlClick", true)
    readonly property bool scrollviewFadeEffects: cfgBool("ScrollviewFadeEffects", true)
    readonly property bool showScrollbars: cfgBool("ShowScrollbars", true)
    readonly property bool overlayScrollbars: cfgBool("OverlayScrollbars", true)
    readonly property string categoryIconType: cfgStr("CategoryIconType", "symbolic")
    readonly property string shortcutIconType: cfgStr("ShortcutIconType", "symbolic")
    readonly property bool categoryIconsSymbolic: categoryIconType !== "fullcolor"
    readonly property bool shortcutIconsSymbolic: shortcutIconType !== "fullcolor"
    readonly property int maxSearchResults: {
        var _ = searchConfigEpoch;
        var n = (maxResultsRaw !== undefined && maxResultsRaw !== null)
            ? parseInt(maxResultsRaw, 10) : cfgInt("MaxResults", 5);
        if (isNaN(n) || n < 1)
            n = 5;
        return n;
    }
    readonly property var searchProviders: {
        var p = cfg("Providers", ["applications"]);
        if (typeof p === "string")
            return p.length ? p.split(",") : ["applications"];
        if (!p || p.length === undefined)
            return ["applications"];
        var list = [];
        for (var i = 0; i < p.length; ++i)
            list.push(p[i]);
        if (root.searchWindows && list.indexOf("windows") < 0)
            list.push("windows");
        if (root.searchRecentFiles && list.indexOf("files") < 0)
            list.push("files");
        return list;
    }
    readonly property string searchPlaceholder: {
        var p = cfgStr("Placeholder", "Search…");
        if (!p || p === "Search…")
            return root.tr("Search…");
        return root.tr(p);
    }
    readonly property var powerOptionsOrder: {
        var fallback = ["logout", "lock", "restart", "shutdown", "suspend", "hybridsleep", "hibernate", "switchuser"];
        var opts = cfg("PowerOptionsOrder", fallback);
        if (typeof opts === "string")
            return opts.length ? opts.split(",") : fallback;
        if (!opts || !opts.length)
            return fallback;
        return opts;
    }
    readonly property var powerOptions: {
        var fallback = ["logout", "lock", "restart", "shutdown"];
        var opts = cfg("Options", fallback);
        if (opts === undefined || opts === null)
            return fallback;
        if (typeof opts === "string")
            return opts.length ? opts.split(",") : fallback;
        if (opts.length === 0)
            return fallback;
        // Stable order from powerOptionsOrder
        var order = root.powerOptionsOrder;
        var sorted = [];
        for (var i = 0; i < order.length; ++i) {
            if (opts.indexOf(order[i]) >= 0)
                sorted.push(order[i]);
        }
        for (var j = 0; j < opts.length; ++j) {
            if (sorted.indexOf(opts[j]) < 0)
                sorted.push(opts[j]);
        }
        return sorted;
    }
    readonly property bool powerConfirm: cfgBool("Confirm", true)
    readonly property string softwareCenterCmd: cfgStr("SoftwareCenterCmd", "auto-detect")
    readonly property string powerDisplayStyle: cfgStr("PowerDisplayStyle", "off")
    readonly property bool syncFavorites: cfgBool("SyncWithPlasma", true)
    readonly property bool showEmptyCategories: cfgBool("ShowEmpty", true)

    // ---- Application catalog (populated by AppsBackend / Kicker RootModel) ----
    property var allApps: []
    /** Bumped when allApps is replaced — forces UI bindings to refresh */
    property int catalogEpoch: 0
    /** Bumped when menu-structure config changes (extra categories, etc.) */
    property int structureEpoch: 0
    property var rawCategories: []
    property string userName: ""
    property string userIcon: "user-identity"
    property string osReleaseId: "kubuntu"
    property string osPrettyName: "Kubuntu"
    /** Populated by PlasmaNative (Kickoff-aligned) */
    property var runnerResults: []
    property var plasmaRecentApps: []
    property var plasmaFavoriteIds: []
    property var plasmaPlaces: []
    property var appsBackend: null

    /** Visible apps sorted once — shared by every layout's "all" view */
    readonly property var sortedVisibleApps: AppsModel.sortAppsByName(AppsModel.filterVisibleApps(allApps))
    /** A–Z forms are prepared once when the catalog changes and shared by every layout. */
    readonly property var sortedVisibleAppsAzSections: AppsModel.appsAzSectionsFromSorted(sortedVisibleApps)
    readonly property var sortedVisibleAppsAzRows: AppsModel.appsAzRowsFromSections(sortedVisibleAppsAzSections)

    readonly property var categories: {
        var _apps = allApps || [];
        var base = (rawCategories && rawCategories.length) ? rawCategories : AppsModel.defaultCategories();
        // single pass: bucket each visible app into every matching category
        var buckets = {};
        for (var b = 0; b < base.length; ++b)
            buckets[base[b].id] = [];
        for (var a = 0; a < _apps.length; ++a) {
            var app = _apps[a];
            if (!app || app.noDisplay)
                continue;
            for (var m = 0; m < base.length; ++m) {
                if (AppsModel.categoryMatches(app.categories, base[m].id))
                    buckets[base[m].id].push(app);
            }
        }
        // attach counts + translate default English names (keep already-localized Kickoff names)
        var withCounts = [];
        for (var i = 0; i < base.length; ++i) {
            var c = Object.assign({}, base[i]);
            var originalName = String(c.name || "");
            var translated = root.tr(originalName);
            c.name = translated || originalName || c.id;
            if (!CategoryIcons.isBundled(c.icon))
                c.icon = CategoryIcons.defaultIcon(c.id);
            c.apps = AppsModel.sortAppsByName(buckets[c.id]);
            c.appCount = c.apps.length;
            withCounts.push(c);
        }
        // prepend All
        var all = {
            id: "all",
            name: root.tr("All Applications"),
            icon: "arcmenu-cat-other-apps",
            apps: root.sortedVisibleApps,
            appCount: _apps.length
        };
        var customized = AppsModel.applyCategoryCustomization(
            withCounts,
            cfg("Order", []),
            cfg("Hidden", []),
            cfgStr("CustomNames", "{}"),
            cfgStr("CustomIcons", "{}"),
            showEmptyCategories
        );
        return [all].concat(customized);
    }

    readonly property var categoryApps: AppsModel.appsInCategory(allApps, currentCategoryId)

    /** Config list, or defaults when never saved — used by display + toggle */
    function effectivePinnedIds() {
        var local = IdList.normalizeIdList(cfg("PinnedApps", []));
        // Sync with Plasma global favorites (Kickoff / KAStats)
        if (root.syncFavorites && root.plasmaFavoriteIds && root.plasmaFavoriteIds.length) {
            var merged = [];
            var seen = {};
            // Keep ArcMenu-only pins from local config first
            for (var i = 0; i < local.length; ++i) {
                var lid = String(local[i] || "");
                if (!lid)
                    continue;
                if (lid === "arcmenu-settings" || lid.indexOf("custom:") === 0
                    || lid.indexOf("shortcut-") === 0) {
                    if (!seen[lid]) {
                        seen[lid] = true;
                        merged.push(lid);
                    }
                }
            }
            for (var p = 0; p < root.plasmaFavoriteIds.length; ++p) {
                var pid = String(root.plasmaFavoriteIds[p] || "");
                if (!pid || seen[pid])
                    continue;
                seen[pid] = true;
                merged.push(pid);
            }
            // Local desktop pins not yet in Plasma (migration)
            for (var j = 0; j < local.length; ++j) {
                var id = String(local[j] || "");
                if (!id || seen[id])
                    continue;
                if (id === "arcmenu-settings" || id.indexOf("custom:") === 0
                    || id.indexOf("shortcut-") === 0)
                    continue;
                seen[id] = true;
                merged.push(id);
            }
            if (merged.length)
                return merged;
        }
        if (local.length === 0)
            return IdList.defaultPinnedIds().slice();
        return local;
    }

    /** Map sidebar shortcuts → pin ids (prefer real .desktop when known) */
    function resolvePinId(app) {
        if (!app)
            return "";
        var id = String(app.id || "");
        if (app.action === "discover" || id === "shortcut-software") {
            var disc = AppsModel.findAppById(allApps, "org.kde.discover.desktop")
                || AppsModel.findAppById(allApps, "plasma-discover.desktop");
            return disc ? disc.id : "org.kde.discover.desktop";
        }
        if (app.action === "settings" || id === "shortcut-settings") {
            var set = AppsModel.findAppById(allApps, "systemsettings.desktop")
                || AppsModel.findAppById(allApps, "org.kde.systemsettings.desktop");
            return set ? set.id : "systemsettings.desktop";
        }
        if (id === "shortcut-tweaks" || (app.exec && String(app.exec).indexOf("kcm_lookandfeel") >= 0))
            return "shortcut-tweaks";
        return id;
    }

    function shortcutById(id) {
        var lang = root.uiLang;
        var list = root.systemShortcuts || [];
        for (var i = 0; i < list.length; ++i) {
            if (list[i].id === id) {
                var s = Object.assign({}, list[i]);
                s.noDisplay = false;
                return s;
            }
        }
        if (id === "shortcut-tweaks") {
            return {
                id: id,
                name: Locale.tr("Tweaks", lang),
                icon: "preferences-desktop-display",
                exec: "systemsettings kcm_lookandfeel",
                noDisplay: false
            };
        }
        return null;
    }

    readonly property var pinnedApps: {
        var lang = root.uiLang; // binding dependency
        var ids = root.effectivePinnedIds();
        var result = [];
        for (var i = 0; i < ids.length; ++i) {
            var id = ids[i];
            if (id === "arcmenu-settings") {
                result.push({
                    id: "arcmenu-settings",
                    name: Locale.tr("ArcMenu Settings", lang),
                    icon: "preferences-system-windows",
                    exec: "",
                    action: "configure",
                    categories: ["Settings"],
                    keywords: ["arcmenu", "settings"],
                    genericName: Locale.tr("Configure Arc Menu", lang),
                    noDisplay: false
                });
                continue;
            }
            if (String(id).indexOf("shortcut-") === 0) {
                var sc = root.shortcutById(id);
                if (sc)
                    result.push(sc);
                continue;
            }
            if (String(id).indexOf("custom:") === 0) {
                var rest = String(id).substring(7).split("|");
                result.push({
                    id: id,
                    name: rest[0] || Locale.tr("Custom shortcut", lang),
                    icon: rest[1] || "application-x-executable",
                    exec: rest[2] || "",
                    categories: [],
                    keywords: [],
                    genericName: "",
                    noDisplay: false
                });
                continue;
            }
            var app = AppsModel.findAppById(allApps, id);
            if (app) {
                var copy = Object.assign({}, app);
                if (id.indexOf("dolphin") >= 0 || id === "org.kde.dolphin.desktop") {
                    copy.name = Locale.tr("Files", lang);
                    copy.genericName = Locale.tr("File Manager", lang);
                }
                result.push(copy);
            } else if (id.indexOf("dolphin") >= 0 || id === "org.kde.dolphin.desktop") {
                result.push({
                    id: "org.kde.dolphin.desktop",
                    name: Locale.tr("Files", lang),
                    icon: "system-file-manager",
                    exec: "dolphin",
                    categories: ["System", "Utility"],
                    keywords: ["files", "folder"],
                    genericName: Locale.tr("File Manager", lang),
                    noDisplay: false
                });
            }
        }
        if (result.length === 0) {
            result = [
                {
                    id: "org.kde.dolphin.desktop",
                    name: Locale.tr("Files", lang),
                    icon: "system-file-manager",
                    exec: "dolphin",
                    noDisplay: false
                },
                {
                    id: "arcmenu-settings",
                    name: Locale.tr("ArcMenu Settings", lang),
                    icon: "preferences-system-windows",
                    exec: "",
                    action: "configure",
                    noDisplay: false
                }
            ];
        }
        return result;
    }

    readonly property var recentApps: {
        if (!recentEnabled) {
            return [];
        }
        // Prefer KAStats recent apps (same as Kickoff)
        if (plasmaRecentApps && plasmaRecentApps.length)
            return plasmaRecentApps.slice(0, recentMax || 10);
        var ids = cfg("RecentApps", []);
        return AppsModel.resolveAppsByIds(allApps, ids);
    }

    readonly property bool isSearching: searchQuery.trim().length > 0

    readonly property var searchResults: {
        if (!isSearching) {
            return [];
        }
        var _cfg = searchConfigEpoch;
        var _rf = recentFilesEpoch;
        var _rr = runnerResults;
        var q = searchQuery.trim();
        var trFn = function (m) { return root.tr(m); };
        // Plasma Search (RunnerModel) first — Kickoff path
        var runners = runnerResults || [];
        var merged;
        if (runners.length) {
            var extrasR = [];
            if (searchRecentFiles)
                extrasR = extrasR.concat(SearchExtras.filterByQuery(recentFileResults || [], q));
            if (searchWindows)
                extrasR = extrasR.concat(SearchExtras.filterByQuery(openWindowResults || [], q));
            merged = SearchExtras.mergeSearchResults(runners, extrasR, maxSearchResults);
        } else {
            // Fallback: in-memory app filter
            var appCap = Math.max(maxSearchResults * 2, maxSearchResults + 8);
            var apps = AppsModel.searchApps(allApps, q, appCap);
            var extras = [];
            if (searchRecentFiles) {
                extras = extras.concat(SearchExtras.filterByQuery(recentFileResults || [], q));
            }
            if (searchWindows) {
                extras = extras.concat(SearchExtras.filterByQuery(openWindowResults || [], q));
            }
            merged = SearchExtras.mergeSearchResults(apps, extras, maxSearchResults);
        }
        // ArcMenu-style section headers (Applications / Files / Windows / …)
        return SearchExtras.groupSearchResults(merged, maxSearchResults, trFn);
    }

    /** Same as searchResults but without section header rows (for AppGrid layouts). */
    readonly property var searchResultsFlat: {
        var g = root.searchResults || [];
        var out = [];
        for (var i = 0; i < g.length; ++i) {
            if (g[i] && !g[i].isSection)
                out.push(g[i]);
        }
        return out;
    }

    readonly property string buttonIcon: {
        var raw = Distro.resolveButtonIcon(
            cfgStr("ButtonIcon", "auto-distro"),
            cfgStr("CustomButtonIcon", ""),
            osReleaseId,
            osPrettyName
        );
        if (String(raw).indexOf("preset:") === 0)
            return Qt.resolvedUrl("../icons/menu-button/" + String(raw).slice(7) + ".svg");
        if (Distro.isLikelyImagePath(raw)) {
            if (String(raw).indexOf("file://") === 0)
                return raw;
            if (String(raw).indexOf("/") === 0)
                return "file://" + raw;
        }
        return raw;
    }

    readonly property bool buttonIconIsMask: Distro.buttonIconIsMask(
        cfgStr("ButtonIcon", "auto-distro"),
        cfgStr("CustomButtonIcon", "")
    )

    signal launchApp(var app)
    signal requestClose()
    signal requestPowerAction(string actionId)
    signal requestConfigure()

    function resetView() {
        searchQuery = "";
        currentCategoryId = "all";
        kickoffTab = 0;
        categoriesCollapsed = false;
        showAllApps = false;
        currentPage = "home";
        focusedApp = null;
    }

    function navigateTo(pageId) {
        searchQuery = "";
        if (pageId === "apps") {
            currentPage = "apps";
            showAllApps = true;
            // Category browser first (ArcMenu apps page), not an app list
            currentCategoryId = "all";
            return;
        }
        currentPage = "home";
        showAllApps = false;
        currentCategoryId = "all";
    }

    function selectCategory(id) {
        currentCategoryId = id || "all";
        searchQuery = "";
        currentPage = "apps";
        showAllApps = true;
    }

    /** ArcMenu back from app list → category list (without leaving apps page) */
    function backToAppCategories() {
        currentCategoryId = "all";
        searchQuery = "";
        currentPage = "apps";
        showAllApps = true;
    }

    function setSearch(text) {
        searchQuery = text;
        if (text && text.trim().length > 0) {
            currentPage = "search";
            showAllApps = true;
        } else if (showAllApps) {
            currentPage = "apps";
        } else {
            currentPage = "home";
        }
    }

    function toggleAllApps() {
        if (currentPage === "apps" || showAllApps) {
            navigateTo("home");
        } else {
            navigateTo("apps");
        }
    }

    readonly property var directoryShortcutIds: {
        return ShortcutsConfig.normalizeList(cfg("DirectoryShortcuts", ShortcutsConfig.DEFAULT_DIRS), ShortcutsConfig.DEFAULT_DIRS);
    }
    readonly property var applicationShortcutIds: {
        return ShortcutsConfig.normalizeList(cfg("ApplicationShortcuts", ShortcutsConfig.DEFAULT_APPS), ShortcutsConfig.DEFAULT_APPS);
    }
    readonly property bool extraCategoriesUserSet: {
        var _ = root.structureEpoch;
        if (extraCategoriesUserSetRaw === true || extraCategoriesUserSetRaw === 1)
            return true;
        return cfgBool("ExtraCategoriesUserSet", false);
    }
    readonly property var extraCategoriesOrder: {
        var _ = root.structureEpoch;
        var raw = (extraCategoriesOrderRaw !== undefined && extraCategoriesOrderRaw !== null)
            ? extraCategoriesOrderRaw
            : (plasmoidConfig ? plasmoidConfig.ExtraCategoriesOrder : undefined);
        return ShortcutsConfig.normalizeList(raw, ShortcutsConfig.DEFAULT_EXTRA_ORDER);
    }
    readonly property var extraCategoriesEnabled: {
        var _ = root.structureEpoch;
        var raw = (extraCategoriesEnabledRaw !== undefined && extraCategoriesEnabledRaw !== null)
            ? extraCategoriesEnabledRaw
            : (plasmoidConfig ? plasmoidConfig.ExtraCategoriesEnabled : undefined);
        return ShortcutsConfig.effectiveExtraEnabled(raw, root.extraCategoriesUserSet);
    }
    readonly property var contextMenuItems: {
        return ShortcutsConfig.normalizeList(cfg("ContextMenuItems", ShortcutsConfig.DEFAULT_CTX), ShortcutsConfig.DEFAULT_CTX);
    }

    function isExtraCategoryEnabled(id) {
        return (extraCategoriesEnabled || []).indexOf(id) >= 0;
    }

    function bumpStructure() {
        structureEpoch++;
    }

    readonly property var enabledExtraCategories: {
        var _ = root.structureEpoch;
        var order = extraCategoriesOrder;
        var enabled = extraCategoriesEnabled;
        var out = [];
        for (var i = 0; i < order.length; ++i) {
            var id = order[i];
            if (!id || enabled.indexOf(id) < 0)
                continue;
            var name = id;
            var icon = "application-x-executable";
            if (id === "favorites") { name = root.tr("Favorites"); icon = "emblem-favorite"; }
            else if (id === "frequent") { name = root.tr("Frequent Apps"); icon = "view-calendar"; }
            else if (id === "all-apps") { name = root.tr("All Applications"); icon = "view-app-grid-symbolic"; }
            else if (id === "pinned") { name = root.tr("Pinned Applications"); icon = "pin"; }
            else if (id === "recent-files") { name = root.tr("Recent Files"); icon = "document-open-recent"; }
            out.push({ id: id, name: name, icon: icon, extra: true });
        }
        return out;
    }

    /** String signature so UI bindings re-run when extras change (var host.* is not tracked). */
    readonly property string extrasSignature: {
        var e = extraCategoriesEnabled || [];
        var o = extraCategoriesOrder || [];
        return String(structureEpoch) + "|e:" + e.join(",") + "|o:" + o.join(",");
    }

    /**
     * Configurable directory shortcuts (sidebar places).
     */
    readonly property var places: {
        var _ = root.uiLang;
        // Prefer KFilePlacesModel (Dolphin / Kickoff places)
        if (plasmaPlaces && plasmaPlaces.length) {
            var kp = plasmaPlaces.slice();
            if (root.showBookmarks) {
                kp.push({
                    id: "place-bookmarks", name: root.tr("Bookmarks"), icon: "bookmarks",
                    special: "bookmarks",
                    categories: ["Places"], keywords: [], genericName: root.tr("Bookmarks"), noDisplay: false
                });
            }
            if (root.showExternalDevices) {
                kp.push({
                    id: "place-devices", name: root.tr("External devices"), icon: "drive-removable-media",
                    special: "devices",
                    categories: ["Places"], keywords: [], genericName: root.tr("External devices"), noDisplay: false
                });
            }
            return kp;
        }
        var raw = ShortcutsConfig.resolveDirectories(directoryShortcutIds, function (m) { return root.tr(m); });
        var out = [];
        for (var i = 0; i < raw.length; ++i) {
            var it = raw[i];
            if (it.invalid)
                continue;
            out.push({
                id: it.id,
                name: it.name,
                icon: it.icon,
                place: it.place || "",
                exec: it.exec || "",
                path: it.path || "",
                categories: ["Places"],
                keywords: [],
                genericName: it.name,
                noDisplay: false
            });
        }
        if (root.showBookmarks) {
            out.push({
                id: "place-bookmarks", name: root.tr("Bookmarks"), icon: "bookmarks",
                special: "bookmarks",
                categories: ["Places"], keywords: [], genericName: root.tr("Bookmarks"), noDisplay: false
            });
        }
        if (root.showExternalDevices) {
            out.push({
                id: "place-devices", name: root.tr("External devices"), icon: "drive-removable-media",
                special: "devices",
                categories: ["Places"], keywords: [], genericName: root.tr("External devices"), noDisplay: false
            });
        }
        return out;
    }

    readonly property var systemShortcuts: {
        var _ = root.uiLang;
        var findApp = function (id) {
            return AppsModel.findAppById(root.allApps, id);
        };
        var raw = ShortcutsConfig.resolveApplications(applicationShortcutIds, function (m) { return root.tr(m); }, findApp);
        var out = [];
        for (var i = 0; i < raw.length; ++i) {
            var it = raw[i];
            if (it.invalid)
                continue;
            out.push({
                id: it.id,
                name: it.name,
                icon: it.icon,
                exec: it.exec || "",
                action: it.action || "",
                kickerUrl: it.kickerUrl,
                entryPath: it.entryPath,
                categories: ["System"],
                keywords: [],
                genericName: it.name,
                noDisplay: false
            });
        }
        return out;
    }

    function toggleFavorite(app) {
        if (!app || !plasmoidConfig) {
            return;
        }
        var pinId = root.resolvePinId(app);
        if (!pinId)
            pinId = app.id;
        var favId = app.favoriteId || pinId;
        var isSpecial = String(pinId).indexOf("custom:") === 0
            || String(pinId).indexOf("shortcut-") === 0
            || pinId === "arcmenu-settings";

        // Kickoff path: KAStats global favorites for real apps
        if (root.syncFavorites && !isSpecial && appsBackend
            && appsBackend.togglePlasmaFavorite) {
            var wasFav = appsBackend.isPlasmaFavorite
                ? appsBackend.isPlasmaFavorite(favId) : false;
            if (appsBackend.togglePlasmaFavorite(favId)) {
                var cur = IdList.normalizeIdList(cfg("PinnedApps", []));
                if (cur.length === 0)
                    cur = IdList.defaultPinnedIds().slice();
                var nowFav = !wasFav;
                var locally = Favorites.isFavorite(cur, pinId);
                if (nowFav !== locally)
                    plasmoidConfig.PinnedApps = Favorites.toggleFavorite(cur, pinId);
                return;
            }
        }

        var current = IdList.normalizeIdList(cfg("PinnedApps", []));
        if (current.length === 0)
            current = IdList.defaultPinnedIds().slice();
        plasmoidConfig.PinnedApps = Favorites.toggleFavorite(current, pinId);
    }

    function isFavorite(appOrId) {
        var ids = root.effectivePinnedIds();
        if (appOrId && typeof appOrId === "object") {
            var pinId = root.resolvePinId(appOrId);
            var favId = appOrId.favoriteId || pinId;
            if (root.syncFavorites && appsBackend && appsBackend.isPlasmaFavorite
                && favId && appsBackend.isPlasmaFavorite(favId))
                return true;
            return Favorites.isFavorite(ids, pinId)
                || Favorites.isFavorite(ids, appOrId.id);
        }
        if (root.syncFavorites && appsBackend && appsBackend.isPlasmaFavorite
            && appsBackend.isPlasmaFavorite(appOrId))
            return true;
        return Favorites.isFavorite(ids, appOrId);
    }

    /** Keep ArcMenu Settings in the pinned list when config was previously wiped */
    function ensureArcMenuSettingsPinned() {
        if (!plasmoidConfig)
            return;
        var current = IdList.normalizeIdList(cfg("PinnedApps", []));
        if (current.length === 0)
            return; // display already uses defaults including ArcMenu Settings
        if (current.indexOf("arcmenu-settings") < 0) {
            current.push("arcmenu-settings");
            plasmoidConfig.PinnedApps = current;
        }
    }

    function reorderPinned(from, to) {
        if (!plasmoidConfig) {
            return;
        }
        var current = root.effectivePinnedIds();
        plasmoidConfig.PinnedApps = Favorites.moveItem(current, from, to);
    }

    function recordLaunch(app) {
        if (!app || !plasmoidConfig) {
            return;
        }
        if (recentEnabled) {
            plasmoidConfig.RecentApps = Favorites.pushRecent(plasmoidConfig.RecentApps, app.id, recentMax);
        }
    }

    function clearRecent() {
        if (plasmoidConfig) {
            plasmoidConfig.RecentApps = Favorites.clearRecent();
        }
    }

    function seedDemoApps(force) {
        // Used when desktop scan is unavailable (dev / packaging checks).
        if (!force && allApps.length > 0) {
            return;
        }
        allApps = [
            { id: "org.kde.dolphin.desktop", name: "Dolphin", icon: "system-file-manager", exec: "dolphin", categories: ["System", "Utility"], keywords: ["files", "folder"], genericName: "File Manager", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/org.kde.dolphin.desktop" },
            { id: "org.kde.konsole.desktop", name: "Konsole", icon: "utilities-terminal", exec: "konsole", categories: ["System", "Utility"], keywords: ["terminal", "shell"], genericName: "Terminal", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/org.kde.konsole.desktop" },
            { id: "org.kde.kate.desktop", name: "Kate", icon: "accessories-text-editor", exec: "kate", categories: ["Utility", "Development"], keywords: ["editor", "text"], genericName: "Advanced Text Editor", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/org.kde.kate.desktop" },
            { id: "firefox.desktop", name: "Firefox", icon: "firefox", exec: "firefox", categories: ["Network"], keywords: ["browser", "web"], genericName: "Web Browser", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/firefox.desktop" },
            { id: "org.kde.discover.desktop", name: "Discover", icon: "plasmadiscover", exec: "plasma-discover", categories: ["System"], keywords: ["software", "store"], genericName: "Software Center", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/org.kde.discover.desktop" },
            { id: "systemsettings.desktop", name: "System Settings", icon: "preferences-system", exec: "systemsettings", categories: ["Settings"], keywords: ["configure"], genericName: "System Settings", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/systemsettings.desktop" },
            { id: "org.kde.gwenview.desktop", name: "Gwenview", icon: "gwenview", exec: "gwenview", categories: ["Graphics"], keywords: ["image", "viewer"], genericName: "Image Viewer", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/org.kde.gwenview.desktop" },
            { id: "org.kde.okular.desktop", name: "Okular", icon: "okular", exec: "okular", categories: ["Office"], keywords: ["pdf", "document"], genericName: "Document Viewer", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/org.kde.okular.desktop" },
            { id: "org.kde.kcalc.desktop", name: "KCalc", icon: "accessories-calculator", exec: "kcalc", categories: ["Utility", "Accessories"], keywords: ["calculator"], genericName: "Calculator", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/org.kde.kcalc.desktop" },
            { id: "org.kde.kmines.desktop", name: "KMines", icon: "kmines", exec: "kmines", categories: ["Game"], keywords: ["minesweeper"], genericName: "Minesweeper-like Game", isFavorite: false, noDisplay: false, entryPath: "/usr/share/applications/org.kde.kmines.desktop" }
        ];
        userName = "kubuntu";
        osReleaseId = "kubuntu";
        osPrettyName = "Kubuntu";
    }

    // Apps come from AppsBackend — no demo seed on startup
}
