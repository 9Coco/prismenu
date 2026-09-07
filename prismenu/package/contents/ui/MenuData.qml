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
import "../code/SidebarModel.js" as SidebarModel

QtObject {
    id: root

    // ---- Config bindings (set from main.qml) ----
    property var plasmoidConfig: null
    /** Width ceiling, bound from main.qml to a screen-fit value (MenuData is
     *  a QtObject without a window, so it cannot read Screen itself). */
    property int maxMenuWidth: 900
    property int maxMenuHeight: 800
    property var layoutSizesRaw
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
    property var customTypeGroupsRaw
    property var customGroupAppsRaw
    property var groupViewOptionsRaw
    property var appListOrderRaw
    property var homeGroupIdRaw
    property var sidebarOrderRaw
    property var sidebarHiddenRaw

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
    /** User-created KDE Places, supplied by Kicker.ComputerModel. */
    readonly property var bookmarkResults: {
        var source = plasmaPlaces || [];
        var out = [];
        for (var i = 0; i < source.length; ++i) {
            var place = source[i];
            if (place && !place.isDevice && place.isSystemPlace !== true)
                out.push(place);
        }
        return out;
    }
    /** Bumped when recent-file list is refreshed — forces UI list bindings */
    property int recentFilesEpoch: 0
    /** Increment to ask AppsBackend to re-read recently-used.xbel */
    property int recentFilesRequest: 0

    function requestRecentFilesRefresh() {
        recentFilesRequest++;
    }
    /** Device list supplied by Kicker.ComputerModel/KFilePlacesModel. */
    readonly property var deviceEntries: {
        if (plasmaPlaces && plasmaPlaces.length) {
            var out = [];
            for (var i = 0; i < plasmaPlaces.length; ++i) {
                if (plasmaPlaces[i].isDevice)
                    out.push(plasmaPlaces[i]);
            }
            return out;
        }
        return [];
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
    readonly property var quickLinksOrder: {
        var o = (quickLinksOrderRaw !== undefined && quickLinksOrderRaw !== null)
            ? quickLinksOrderRaw
            : cfg("QuickLinksOrder", ["frequent", "all-apps", "pinned", "recent-files"]);
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
    readonly property var sidebarOrder: SidebarModel.normalizeList(
        sidebarOrderRaw !== undefined && sidebarOrderRaw !== null
            ? sidebarOrderRaw : cfg("SidebarOrder", []))
    readonly property var sidebarHidden: SidebarModel.normalizeList(
        sidebarHiddenRaw !== undefined && sidebarHiddenRaw !== null
            ? sidebarHiddenRaw : cfg("SidebarHidden", []))
    readonly property string quickLinkPosition: {
        if (quickLinkPositionRaw !== undefined && quickLinkPositionRaw !== null && String(quickLinkPositionRaw).length)
            return String(quickLinkPositionRaw);
        return cfgStr("QuickLinkPosition", "bottom");
    }

    function isQuickLinkEnabled(id) {
        return (quickLinksEnabled || []).indexOf(id) >= 0;
    }
    
    // ---- Custom quick link groups (user-defined app collections) ----
    function parseGroupDefs(raw) {
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

    readonly property var customQuickLinkDefs: {
        var raw = (customQuickLinksRaw !== undefined && customQuickLinksRaw !== null)
            ? customQuickLinksRaw : cfg("CustomQuickLinks", []);
        return root.parseGroupDefs(raw);
    }

    readonly property var customTypeGroupDefs: {
        var raw = (customTypeGroupsRaw !== undefined && customTypeGroupsRaw !== null)
            ? customTypeGroupsRaw : cfg("CustomTypeGroups", []);
        return root.parseGroupDefs(raw);
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

    /** Resolve search/sidebar variants to the id used by the live app catalog. */
    function customGroupAppId(app) {
        if (!app)
            return "";
        var id = String(app.id || "");
        var direct = AppsModel.findAppById(root.allApps, id);
        if (direct)
            return String(direct.id || id);
        var source = root.appForPlasmaFavoriteId(app.favoriteId || id);
        return String((source && source.id) || id);
    }

    /** Accept current catalog ids and older Kicker/favorite id spellings. */
    function customGroupAppByStoredId(storedId) {
        var id = String(storedId || "");
        if (!id)
            return null;
        var direct = AppsModel.findAppById(root.allApps, id);
        if (direct)
            return direct;
        var favorite = root.appForPlasmaFavoriteId(id);
        if (favorite)
            return favorite;
        var plain = id.indexOf("applications:") === 0
            ? id.substring("applications:".length) : id;
        for (var i = 0; i < (root.allApps || []).length; ++i) {
            var app = root.allApps[i];
            if (!app)
                continue;
            var appId = String(app.id || "");
            var favId = String(app.favoriteId || "");
            var url = String(app.kickerUrl || app.entryPath || "");
            if (appId === plain || favId === id || favId === plain
                    || url === id || url === "applications:" + plain)
                return app;
        }
        return null;
    }
    
    function isAppInCustomGroup(groupId, appId) {
        var wanted = String(appId || "");
        var ids = root.customGroupAppIds(groupId);
        for (var i = 0; i < ids.length; ++i) {
            if (String(ids[i]) === wanted)
                return true;
            var app = root.customGroupAppByStoredId(ids[i]);
            if (app && String(app.id || "") === wanted)
                return true;
        }
        return false;
    }
    
    function setCustomGroupApps(groupId, ids) {
        if (!groupId || !plasmoidConfig)
            return;
        var map = JSON.parse(JSON.stringify(root.customGroupMap));
        map[groupId] = ids || [];
        plasmoidConfig.CustomGroupApps = JSON.stringify(map);
        console.log("Prismenu setCustomGroupApps", groupId, "->", JSON.stringify(ids || []));
    }
    
    function addToCustomGroup(groupId, appId) {
        if (!appId)
            return;
        var ids = root.customGroupAppIds(groupId).slice();
        if (root.isAppInCustomGroup(groupId, appId))
            return;
        ids.push(appId);
        root.setCustomGroupApps(groupId, ids);
    }
    
    function removeFromCustomGroup(groupId, appId) {
        var ids = root.customGroupAppIds(groupId).slice();
        var wanted = String(appId || "");
        var kept = ids.filter(function (storedId) {
            if (String(storedId) === wanted)
                return false;
            var app = root.customGroupAppByStoredId(storedId);
            return !app || String(app.id || "") !== wanted;
        });
        if (kept.length !== ids.length)
            root.setCustomGroupApps(groupId, kept);
    }
    
    /** Resolve a group's app ids to real app objects (unknown ids skipped). */
    function customGroupApps(groupId) {
        var ids = root.customGroupAppIds(groupId);
        var out = [];
        var seen = {};
        for (var i = 0; i < ids.length; ++i) {
            var app = root.customGroupAppByStoredId(ids[i]);
            var key = app ? String(app.id || ids[i]) : "";
            if (app && !seen[key]) {
                seen[key] = true;
                out.push(app);
            }
        }
        return out;
    }
    
    readonly property var enabledQuickLinks: {
        var order = quickLinksOrder.length
            ? quickLinksOrder
            : ["frequent", "all-apps", "pinned", "recent-files"];
        var out = [];
        for (var i = 0; i < order.length; ++i) {
            var id = order[i];
            // Retired: the sidebar AllAppsButton already navigates to the all-apps view,
            // so a duplicate quick link only confused the menu (removed 2026-08).
            if (id === "all-apps" || id === "favorites")
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
            else if (id === "frequent") { name = root.tr("Recent Apps"); icon = "view-history"; }
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
    readonly property int menuWidth: {
        var stored = (plasmoidConfig && plasmoidConfig.MenuWidth !== undefined
            && plasmoidConfig.MenuWidth !== null)
            ? plasmoidConfig.MenuWidth : LayoutRegistry.SHARED_DEFAULT_WIDTH;
        var fromPanels = leftPanelWidth + rightPanelWidth + 24 + widthOffset;
        var w = stored > 0 ? stored : fromPanels;
        return LayoutRegistry.clampSize(w, 400, root.maxMenuWidth, LayoutRegistry.SHARED_DEFAULT_WIDTH);
    }
    readonly property int menuHeight: {
        var stored = (plasmoidConfig && plasmoidConfig.MenuHeight !== undefined
            && plasmoidConfig.MenuHeight !== null)
            ? plasmoidConfig.MenuHeight : LayoutRegistry.SHARED_DEFAULT_HEIGHT;
        return LayoutRegistry.clampSize(stored, 400, root.maxMenuHeight,
            LayoutRegistry.SHARED_DEFAULT_HEIGHT);
    }
    /** Places / categories side column — synced with right panel for ArcMenu-style shells */
    readonly property int sidebarWidth: LayoutRegistry.clampSize(
        cfgInt("SidebarWidth", cfgInt("RightPanelWidth", 220)), 160, 360, 220)
    /** Zest middle categories column */
    readonly property int categoryColumnWidth: LayoutRegistry.clampSize(cfgInt("CategoryColumnWidth", 220), 160, 360, 220)
    readonly property string overrideMenuPosition: cfgStr("OverrideMenuPosition", "off")
    readonly property bool overrideMenuRise: cfgBool("OverrideMenuRise", false)
    readonly property int menuRiseDistance: LayoutRegistry.clampSize(cfgInt("MenuRiseDistance", 6), 0, 64, 6)
    readonly property int defaultMenuWidth: LayoutRegistry.SHARED_DEFAULT_WIDTH
    readonly property int defaultMenuHeight: LayoutRegistry.SHARED_DEFAULT_HEIGHT
    readonly property int defaultSidebarWidth: {
        var meta = layoutInfo;
        return meta && meta.defaultSidebarWidth ? meta.defaultSidebarWidth : 220;
    }
    readonly property int defaultCategoryColumnWidth: 220

    function layoutSizesJson() {
        if (layoutSizesRaw !== undefined && layoutSizesRaw !== null)
            return String(layoutSizesRaw);
        return cfgStr("LayoutSizes", "{}");
    }

    function currentSizeSnapshot() {
        return {
            w: root.menuWidth,
            h: root.menuHeight,
            sidebar: root.sidebarWidth,
            category: root.categoryColumnWidth,
            left: root.leftPanelWidth,
            right: root.rightPanelWidth,
            offset: root.widthOffset
        };
    }

    function snapshotLayoutSize(layoutId) {
        if (!plasmoidConfig || !layoutId)
            return;
        var s = LayoutRegistry.setSizeForLayout(root.layoutSizesJson(), layoutId, root.currentSizeSnapshot());
        plasmoidConfig.LayoutSizes = s;
        try { plasmoidConfig.writeConfig(); } catch (e) {}
    }

    function applyLayoutSize(layoutId) {
        if (!plasmoidConfig || !layoutId)
            return;
        var size = LayoutRegistry.sizeForLayout(root.layoutSizesJson(), layoutId);
        plasmoidConfig.MenuWidth = size.w;
        plasmoidConfig.MenuHeight = size.h;
        plasmoidConfig.SidebarWidth = size.sidebar;
        plasmoidConfig.CategoryColumnWidth = size.category;
        plasmoidConfig.LeftPanelWidth = size.left;
        plasmoidConfig.RightPanelWidth = size.right;
        plasmoidConfig.WidthOffset = size.offset;
        try { plasmoidConfig.writeConfig(); } catch (e) {}
    }

    function setMenuWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 400, root.maxMenuWidth, LayoutRegistry.SHARED_DEFAULT_WIDTH);
        plasmoidConfig.MenuWidth = c;
        // Keep right panel; adjust left so panels stay consistent with drag-resize
        var left = LayoutRegistry.clampSize(c - rightPanelWidth - 24 - widthOffset, 180, 1600, LayoutRegistry.SHARED_DEFAULT_LEFT);
        plasmoidConfig.LeftPanelWidth = left;
        // The left-panel clamp (180–1600) can leave the derived menuWidth short
        // of / beyond the requested width — absorb the remainder in widthOffset
        // so the persisted menuWidth lands exactly on the dragged size.
        var residual = c - (left + rightPanelWidth + 24 + widthOffset);
        if (residual !== 0)
            plasmoidConfig.WidthOffset = LayoutRegistry.clampSize(widthOffset + residual, -200, 400, 0);
        root.snapshotLayoutSize(root.currentLayoutId);
    }

    function setMenuHeight(h) {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.MenuHeight = LayoutRegistry.clampSize(h, 400, root.maxMenuHeight, LayoutRegistry.SHARED_DEFAULT_HEIGHT);
        root.snapshotLayoutSize(root.currentLayoutId);
    }

    function setSidebarWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 160, 360, 220);
        plasmoidConfig.SidebarWidth = c;
        plasmoidConfig.RightPanelWidth = c;
        root.snapshotLayoutSize(root.currentLayoutId);
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
        var size = LayoutRegistry.sharedDefaultSize();
        plasmoidConfig.MenuWidth = size.w;
        plasmoidConfig.MenuHeight = size.h;
        plasmoidConfig.SidebarWidth = size.sidebar;
        plasmoidConfig.CategoryColumnWidth = size.category;
        plasmoidConfig.LeftPanelWidth = size.left;
        plasmoidConfig.RightPanelWidth = size.right;
        plasmoidConfig.WidthOffset = size.offset;
        root.snapshotLayoutSize(root.currentLayoutId);
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
    readonly property bool recentEnabled: {
        var _ = root.structureEpoch;
        return cfgBool("Enabled", true);
    }
    readonly property int recentMax: {
        var _ = root.structureEpoch;
        return Math.max(0, cfgInt("MaxItems", 5));
    }
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
        return cfgBool("SearchWindows", true);
    }
    readonly property bool searchRecentFiles: {
        var _ = searchConfigEpoch;
        if (searchRecentFilesRaw !== undefined && searchRecentFilesRaw !== null)
            return searchRecentFilesRaw === true || searchRecentFilesRaw === 1;
        return cfgBool("SearchRecentFiles", true);
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
            ? parseInt(maxResultsRaw, 10) : cfgInt("MaxResults", 20);
        if (isNaN(n) || n < 1)
            n = 20;
        return n;
    }
    readonly property var searchProviders: {
        var p = cfg("Providers", ["applications", "places", "files"]);
        if (typeof p === "string")
            return p.length ? p.split(",") : ["applications", "places", "files"];
        if (!p || p.length === undefined)
            return ["applications", "places", "files"];
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
    readonly property var hiddenCategoryIds: {
        var _ = root.structureEpoch;
        return IdList.normalizeIdList(cfg("Hidden", []));
    }

    // ---- Application catalog (populated by AppsBackend / Kicker RootModel) ----
    property var allApps: []
    /** Bumped when allApps is replaced — forces UI bindings to refresh */
    property int catalogEpoch: 0
    /** Bumped when menu-structure config changes (extra categories, etc.) */
    property int structureEpoch: 0
    /** Drag sorting is previewed in memory.  Configuration is written only
     * after a drop is accepted by a pinned view. */
    property var pinnedPreviewIds: []
    property string pinnedPreviewSourceId: ""
    property bool pinnedPreviewCommitPending: false
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
    property bool _legacyFavoritesMigrationAttempted: false

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
            // Keep semantic backend icons for synthetic categories such as
            // Help and browser-hosted app groups. Only canonical categories
            // with a real bundled SVG should be replaced by our icon pack.
            if (!CategoryIcons.isBundled(c.icon) && CategoryIcons.hasCategory(c.id))
                c.icon = CategoryIcons.defaultIcon(c.id);
            c.apps = root.orderedAppsForGroup(c.id, AppsModel.sortAppsByName(buckets[c.id]));
            c.appCount = c.apps.length;
            withCounts.push(c);
        }
        // prepend All
        var all = {
            id: "all",
            name: root.tr("All Applications"),
            icon: "prismenu-cat-other-apps",
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

    function isPrismenuOnlyPinId(id) {
        id = String(id || "");
        return id === "prismenu-settings" || id.indexOf("shortcut-") === 0
            || id.indexOf("custom:") === 0;
    }

    function appForPlasmaFavoriteId(favoriteId) {
        var fid = String(favoriteId || "");
        var plain = fid.indexOf("applications:") === 0
            ? fid.substring("applications:".length) : fid;
        for (var i = 0; i < (allApps || []).length; ++i) {
            var app = allApps[i];
            if (!app)
                continue;
            if (String(app.favoriteId || "") === fid || String(app.id || "") === fid
                    || String(app.id || "") === plain)
                return app;
        }
        return null;
    }

    function plasmaFavoriteIdForApp(app) {
        if (!app)
            return "";
        var source = root.appForPlasmaFavoriteId(app.favoriteId || app.id);
        return String((source && source.favoriteId) || app.favoriteId || app.id || "");
    }

    /**
     * One-way compatibility migration: older Prismenu versions stored normal
     * applications in PinnedApps. Import real applications into Kicker's
     * global favorites, then retire the local list entirely. Prismenu no
     * longer owns a second, incompatible pinned-app store.
     */
    function migrateLegacyFavoritesToPlasma() {
        if (root._legacyFavoritesMigrationAttempted || !appsBackend
                || !appsBackend.setPlasmaFavorite || !(allApps || []).length)
            return;
        root._legacyFavoritesMigrationAttempted = true;
        var local = IdList.normalizeIdList(cfg("PinnedApps", []));
        for (var i = 0; i < local.length; ++i) {
            if (root.isPrismenuOnlyPinId(local[i]))
                continue;
            var app = AppsModel.findAppById(allApps, local[i])
                || root.appForPlasmaFavoriteId(local[i]);
            if (!app)
                continue;
            var favId = root.plasmaFavoriteIdForApp(app);
            if (favId)
                appsBackend.setPlasmaFavorite(favId, true);
        }
        if (local.length && plasmoidConfig) {
            plasmoidConfig.PinnedApps = [];
            try { plasmoidConfig.writeConfig(); } catch (e) {}
        }
    }

    /** Stored order without a drag preview. */
    function storedPinnedIds() {
        var out = [];
        var global = IdList.normalizeIdList(root.plasmaFavoriteIds || []);
        for (var i = 0; i < global.length; ++i) {
            var app = root.appForPlasmaFavoriteId(global[i]);
            var pinId = app ? String(app.id) : String(global[i] || "");
            if (pinId && out.indexOf(pinId) < 0)
                out.push(pinId);
        }
        return out;
    }

    /** The pinned list is exactly Plasma's global favorites. */
    function effectivePinnedIds() {
        if ((root.pinnedPreviewIds || []).length)
            return root.pinnedPreviewIds.slice();
        return root.storedPinnedIds();
    }

    function beginPinnedPreview(sourceId) {
        sourceId = String(sourceId || "");
        if (!sourceId)
            return false;
        if (root.pinnedPreviewSourceId === sourceId
                && (root.pinnedPreviewIds || []).length)
            return true;
        var base = root.storedPinnedIds();
        if (base.indexOf(sourceId) < 0)
            return false;
        root.pinnedPreviewSourceId = sourceId;
        root.pinnedPreviewIds = base.slice();
        root.pinnedPreviewCommitPending = false;
        return true;
    }

    /** Move a pin in the in-memory preview. `after` selects the target half. */
    function previewPinnedItem(sourceId, targetId, after) {
        sourceId = String(sourceId || "");
        targetId = String(targetId || "");
        if (!root.beginPinnedPreview(sourceId) || !targetId || sourceId === targetId)
            return false;
        var ids = root.pinnedPreviewIds.slice();
        var from = ids.indexOf(sourceId);
        var target = ids.indexOf(targetId);
        if (from < 0 || target < 0)
            return false;

        ids.splice(from, 1);
        target = ids.indexOf(targetId);
        if (after)
            target++;
        target = Math.max(0, Math.min(ids.length, target));
        ids.splice(target, 0, sourceId);
        if (ids.join("\u001f") === root.pinnedPreviewIds.join("\u001f"))
            return false;
        root.pinnedPreviewIds = ids;
        root.bumpStructure();
        return true;
    }

    function cancelPinnedPreview() {
        if (root.pinnedPreviewCommitPending)
            return;
        if (!(root.pinnedPreviewIds || []).length)
            return;
        root.pinnedPreviewIds = [];
        root.pinnedPreviewSourceId = "";
        root.bumpStructure();
    }

    /** Drop a live reorder overlay so Plasma favorite changes can show. */
    function dropPinnedPreviewForce() {
        root.pinnedPreviewCommitPending = false;
        if (!(root.pinnedPreviewIds || []).length && !root.pinnedPreviewSourceId)
            return;
        root.pinnedPreviewIds = [];
        root.pinnedPreviewSourceId = "";
        root.bumpStructure();
    }

    function finishPinnedPreviewCommit() {
        root.pinnedPreviewCommitPending = false;
        root.pinnedPreviewIds = [];
        root.pinnedPreviewSourceId = "";
        root.bumpStructure();
    }

    /** Persist the accepted preview order to Plasma favorites/local pins. */
    function commitPinnedPreview(sourceId) {
        sourceId = String(sourceId || "");
        if (sourceId !== root.pinnedPreviewSourceId
                || !(root.pinnedPreviewIds || []).length)
            return false;
        return root._persistPinnedOrder(root.pinnedPreviewIds.slice());
    }

    readonly property var appListOrderMap: {
        var _ = root.structureEpoch;
        var raw = (appListOrderRaw !== undefined && appListOrderRaw !== null)
            ? appListOrderRaw : cfg("AppListOrder", "{}");
        try {
            var obj = JSON.parse(String(raw || "{}"));
            return (obj && typeof obj === "object" && !Array.isArray(obj)) ? obj : {};
        } catch (e) {
            return {};
        }
    }

    function canReorderGroup(groupId) {
        return AppsModel.canReorderGroup(groupId);
    }

    function appListOrderIds(groupId) {
        var list = root.appListOrderMap[AppsModel.canonicalGroupId(groupId)];
        return Array.isArray(list) ? list : [];
    }

    function orderedAppsForGroup(groupId, apps) {
        var id = AppsModel.canonicalGroupId(groupId);
        if (!id || !AppsModel.canReorderGroup(id) || id === "pinned")
            return apps || [];
        if (id.indexOf("qgrp-") === 0 || id.indexOf("tgrp-") === 0)
            return apps || [];
        return AppsModel.applyAppListOrder(apps || [], root.appListOrderIds(id));
    }

    function _persistAppListOrder(groupId, ids) {
        groupId = AppsModel.canonicalGroupId(groupId);
        if (!groupId || !plasmoidConfig)
            return false;
        var map = JSON.parse(JSON.stringify(root.appListOrderMap));
        map[groupId] = ids || [];
        plasmoidConfig.AppListOrder = JSON.stringify(map);
        root.bumpStructure();
        return true;
    }

    /**
     * Persist a Kickoff-style live reorder for any reorderable group.
     * Pinned rows go through Plasma favorites; custom groups rewrite
     * CustomGroupApps; other lists store AppListOrder.
     */
    function commitGroupOrder(groupId, ids) {
        groupId = AppsModel.canonicalGroupId(groupId);
        if (!groupId || !AppsModel.canReorderGroup(groupId))
            return false;
        var clean = [];
        var seen = {};
        for (var i = 0; i < (ids || []).length; ++i) {
            var id = String(ids[i] || "");
            if (!id || seen[id] || AppsModel.isSectionId(id))
                continue;
            seen[id] = true;
            clean.push(id);
        }
        if (!clean.length)
            return false;
        if (groupId === "pinned")
            return root.commitPinnedOrder(clean);
        if (groupId.indexOf("qgrp-") === 0 || groupId.indexOf("tgrp-") === 0) {
            root.setCustomGroupApps(groupId, clean);
            return true;
        }
        return root._persistAppListOrder(groupId, clean);
    }

    /**
     * Commit a live Kickoff-style reorder: the view already moved its
     * ListModel, so persist that id order without rebuilding the source
     * until Plasma's favorites model catches up.
     */
    function commitPinnedOrder(ids) {
        if (!ids || !ids.length)
            return false;
        var desired = [];
        for (var i = 0; i < ids.length; ++i) {
            var id = String(ids[i] || "");
            if (id)
                desired.push(id);
        }
        if (!desired.length)
            return false;
        var stored = root.storedPinnedIds();
        if (desired.join("\u001f") === stored.join("\u001f"))
            return true;
        root.pinnedPreviewIds = desired;
        root.pinnedPreviewSourceId = desired[0];
        return root._persistPinnedOrder(desired);
    }

    function _persistPinnedOrder(desired) {
        root.pinnedPreviewCommitPending = true;

        var currentGlobals = root.storedPinnedIds();
        var desiredGlobals = desired.slice();
        if (appsBackend && appsBackend.movePlasmaFavorite) {
            for (var i = 0; i < desiredGlobals.length; ++i) {
                var from = currentGlobals.indexOf(desiredGlobals[i]);
                if (from < 0 || from === i)
                    continue;
                appsBackend.movePlasmaFavorite(from, i);
                var moved = currentGlobals.splice(from, 1)[0];
                currentGlobals.splice(i, 0, moved);
            }
        }

        // Plasma's favorites model refresh is queued as well; keeping the
        // preview for this event-loop turn avoids a one-frame snap backwards.
        Qt.callLater(root.finishPinnedPreviewCommit);
        return true;
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
            if (id === "prismenu-settings") {
                result.push({
                    id: "prismenu-settings",
                    name: Locale.tr("Prismenu Settings", lang),
                    icon: "preferences-system-windows",
                    exec: "",
                    action: "configure",
                    categories: ["Settings"],
                    keywords: ["prismenu", "settings"],
                    genericName: Locale.tr("Configure Prismenu", lang),
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
            } else if (id) {
                // Uninstalled favorite: keep the tile so Kickoff's
                // "Remove from Favorites" can drop it from the list.
                var favUrl = String(id).indexOf("applications:") === 0
                    ? String(id) : ("applications:" + id);
                result.push({
                    id: id,
                    name: String(id).replace(/^applications:/, "").replace(/\.desktop$/i, ""),
                    icon: "unknown",
                    favoriteId: id,
                    kickerUrl: favUrl,
                    entryPath: favUrl,
                    missingDesktop: true,
                    noDisplay: false
                });
            }
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

    /** Group selected for the layout's home application area. A stale custom
     * group id is deliberately healed at runtime so deleting a group can never
     * leave the menu on an inaccessible or permanently empty page. */
    readonly property string requestedHomeGroupId: {
        var value = (homeGroupIdRaw !== undefined && homeGroupIdRaw !== null)
            ? String(homeGroupIdRaw) : cfgStr("HomeGroupId", "pinned");
        return value || "pinned";
    }

    function homeGroupDefinition(groupId) {
        var id = String(groupId || "pinned");
        var special = {
            "pinned": { id: "pinned", name: root.tr("Pinned Applications"), icon: "favorite" },
            "all-apps": { id: "all-apps", name: root.tr("All Applications"), icon: "view-app-grid-symbolic" },
            "frequent": { id: "frequent", name: root.tr("Frequent"), icon: "view-history" },
            "recent-files": { id: "recent-files", name: root.tr("Recent Files"), icon: "document-open-recent" }
        };
        if (special[id])
            return special[id];
        var defs = (root.customQuickLinkDefs || []).concat(root.customTypeGroupDefs || []);
        for (var d = 0; d < defs.length; ++d) {
            if (String(defs[d].id) === id)
                return defs[d];
        }
        for (var c = 0; c < (root.categories || []).length; ++c) {
            var cat = root.categories[c];
            if (cat && String(cat.id) === id)
                return cat;
        }
        // Hidden system categories remain valid home choices. They are absent
        // from categories after customization, but still exist in the native
        // catalog supplied by Kicker.
        for (var r = 0; r < (root.rawCategories || []).length; ++r) {
            var raw = root.rawCategories[r];
            if (raw && String(raw.id) === id)
                return raw;
        }
        return null;
    }

    readonly property string homeGroupId: root.homeGroupDefinition(root.requestedHomeGroupId)
        ? root.requestedHomeGroupId : "pinned"
    readonly property var homeGroupDef: root.homeGroupDefinition(root.homeGroupId)
    readonly property string homeGroupName: root.homeGroupDef
        ? String(root.homeGroupDef.name || root.tr("Pinned Applications"))
        : root.tr("Pinned Applications")
    readonly property string homeGroupIcon: root.homeGroupDef
        ? String(root.homeGroupDef.icon || "favorite") : "favorite"
    readonly property var homeApps: {
        var id = root.homeGroupId;
        if (id === "pinned")
            return root.pinnedApps;
        if (id === "all-apps")
            return root.orderedAppsForGroup("all-apps", root.sortedVisibleApps);
        if (id === "frequent")
            return root.recentApps;
        if (id === "recent-files")
            return root.recentFileResults || [];
        if (id.indexOf("qgrp-") === 0 || id.indexOf("tgrp-") === 0)
            return root.customGroupApps(id);
        var def = root.homeGroupDefinition(id);
        var apps = def && def.apps ? def.apps : AppsModel.appsInCategory(root.allApps, id);
        return root.orderedAppsForGroup(id, apps);
    }

    readonly property bool isSearching: searchQuery.trim().length > 0

    readonly property var searchResults: {
        if (!isSearching) {
            return [];
        }
        var _cfg = searchConfigEpoch;
        var _rf = recentFilesEpoch;
        var _pl = plasmaPlaces;
        var _rr = runnerResults;
        var _ow = openWindowResults;
        var q = searchQuery.trim();
        var trFn = function (m) { return root.tr(m); };
        // Plasma Search (RunnerModel) first — Kickoff path (apps / locations /
        // windows / bookmarks / files). In-memory app filter is only a fallback
        // when no runner rows have arrived yet.
        var runners = runnerResults || [];
        var primary;
        if (runners.length) {
            primary = runners;
        } else {
            primary = AppsModel.searchApps(allApps, q, maxSearchResults * 2);
        }
        var placeSrc = (plasmaPlaces && plasmaPlaces.length) ? plasmaPlaces : (root.places || []);
        var searchPlaces = [];
        for (var i = 0; i < placeSrc.length; ++i) {
            if (placeSrc[i] && !placeSrc[i].special)
                searchPlaces.push(placeSrc[i]);
        }
        return SearchExtras.composeSearchResults(
            primary,
            searchPlaces,
            root.searchRecentFiles ? (recentFileResults || []) : [],
            root.searchWindows ? (openWindowResults || []) : [],
            runners.length ? [] : (bookmarkResults || []),
            q,
            maxSearchResults,
            trFn
        );
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

    /** Prismenu back from app list → category list (without leaving apps page) */
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
        var _ = root.structureEpoch;
        return ShortcutsConfig.normalizeList(cfg("DirectoryShortcuts", ShortcutsConfig.DEFAULT_DIRS), ShortcutsConfig.DEFAULT_DIRS);
    }
    readonly property var applicationShortcutIds: {
        var _ = root.structureEpoch;
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

    /** Preference custom groups that are currently switched on. */
    readonly property var enabledPreferenceGroups: {
        var _ = root.structureEpoch;
        var defs = root.customQuickLinkDefs || [];
        var enabled = extraCategoriesEnabled || [];
        var userSet = root.extraCategoriesUserSet;
        var out = [];
        for (var i = 0; i < defs.length; ++i) {
            if (!defs[i] || !defs[i].id)
                continue;
            if (userSet && enabled.indexOf(defs[i].id) < 0)
                continue;
            out.push(defs[i]);
        }
        return out;
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
            if (!id || id === "favorites" || enabled.indexOf(id) < 0)
                continue;
            var name = id;
            var icon = "application-x-executable";
            if (id === "frequent") { name = root.tr("Recent Apps"); icon = "view-history"; }
            else if (id === "all-apps") { name = root.tr("All Applications"); icon = "view-app-grid-symbolic"; }
            else if (id === "pinned") { name = root.tr("Pinned Applications"); icon = "pin"; }
            else if (id === "recent-files") { name = root.tr("Recent Files"); icon = "document-open-recent"; }
            else if (String(id).indexOf("qgrp-") === 0) {
                var grp = null;
                var defsEarly = root.customQuickLinkDefs;
                for (var g = 0; g < defsEarly.length; ++g) {
                    if (defsEarly[g].id === id) {
                        grp = defsEarly[g];
                        break;
                    }
                }
                if (!grp)
                    continue;
                name = grp.name;
                icon = grp.icon || "folder-favorites";
            } else {
                continue;
            }
            out.push({ id: id, name: name, icon: icon, extra: true });
        }
        var defs = root.customQuickLinkDefs;
        var seen = {};
        for (var s = 0; s < out.length; ++s)
            seen[out[s].id] = true;
        for (var c = 0; c < defs.length; ++c) {
            if (!defs[c] || !defs[c].id || seen[defs[c].id])
                continue;
            if (root.extraCategoriesUserSet && order.indexOf(defs[c].id) >= 0)
                continue;
            out.push({
                id: defs[c].id,
                name: defs[c].name,
                icon: defs[c].icon || "folder-favorites",
                extra: true
            });
        }
        return out;
    }

    /** String signature so UI bindings re-run when extras change (var host.* is not tracked). */
    readonly property string extrasSignature: {
        var e = extraCategoriesEnabled || [];
        var o = extraCategoriesOrder || [];
        var gids = [];
        var defs = root.customQuickLinkDefs || [];
        for (var i = 0; i < defs.length; ++i)
            gids.push(defs[i].id + ":" + defs[i].name + ":" + defs[i].icon);
        var tdefs = root.customTypeGroupDefs || [];
        for (var t = 0; t < tdefs.length; ++t)
            gids.push(tdefs[t].id + ":" + tdefs[t].name + ":" + tdefs[t].icon);
        var viewRaw = (groupViewOptionsRaw !== undefined && groupViewOptionsRaw !== null)
            ? String(groupViewOptionsRaw) : cfgStr("GroupViewOptions", "{}");
        var appsRaw = (customGroupAppsRaw !== undefined && customGroupAppsRaw !== null)
            ? String(customGroupAppsRaw) : cfgStr("CustomGroupApps", "{}");
        var orderRaw = (appListOrderRaw !== undefined && appListOrderRaw !== null)
            ? String(appListOrderRaw) : cfgStr("AppListOrder", "{}");
        var dirs = root.directoryShortcutIds || [];
        var apps = root.applicationShortcutIds || [];
        return String(structureEpoch) + "|e:" + e.join(",") + "|o:" + o.join(",")
            + "|g:" + gids.join(",") + "|v:" + viewRaw + "|a:" + appsRaw
            + "|l:" + orderRaw
            + "|d:" + dirs.join(",") + "|s:" + apps.join(",");
    }

    readonly property var groupViewOptions: {
        var _ = root.structureEpoch;
        var raw = (groupViewOptionsRaw !== undefined && groupViewOptionsRaw !== null)
            ? groupViewOptionsRaw : cfg("GroupViewOptions", "{}");
        return ShortcutsConfig.parseGroupViewOptions(raw);
    }

    function groupViewMode(id) {
        var _ = root.structureEpoch;
        var raw = (groupViewOptionsRaw !== undefined && groupViewOptionsRaw !== null)
            ? groupViewOptionsRaw : cfg("GroupViewOptions", "{}");
        return ShortcutsConfig.groupViewMode(raw, id);
    }

    function groupIconSize(id) {
        var _ = root.structureEpoch;
        var raw = (groupViewOptionsRaw !== undefined && groupViewOptionsRaw !== null)
            ? groupViewOptionsRaw : cfg("GroupViewOptions", "{}");
        return ShortcutsConfig.groupIconSize(raw, id);
    }

    function placeKey(item) {
        return String(item ? (item.customPlaceKey || item.kickerUrl || item.entryPath || item.id || "") : "");
    }

    function configuredPlaces(source, orderKey, hiddenKey) {
        var items = (source || []).slice();
        var order = ShortcutsConfig.normalizeList(cfg(orderKey, []), []);
        var hidden = ShortcutsConfig.normalizeList(cfg(hiddenKey, []), []);
        var rank = {};
        for (var r = 0; r < order.length; ++r)
            rank[String(order[r])] = r;
        items.sort(function (a, b) {
            var ak = root.placeKey(a), bk = root.placeKey(b);
            var ar = rank[ak] !== undefined ? rank[ak] : 100000;
            var br = rank[bk] !== undefined ? rank[bk] : 100000;
            return ar === br ? 0 : ar - br;
        });
        return items.filter(function (item) { return hidden.indexOf(root.placeKey(item)) < 0; });
    }

    readonly property var allSystemPlaces: {
        var _ = root.uiLang;
        var __ = root.structureEpoch;
        if (plasmaPlaces && plasmaPlaces.length) {
            var system = [];
            for (var i = 0; i < plasmaPlaces.length; ++i) {
                if (plasmaPlaces[i] && plasmaPlaces[i].isSystemPlace === true)
                    system.push(plasmaPlaces[i]);
            }
            return system;
        }
        // Defensive fallback for systems where the private Kicker model is
        // unavailable: use only standard XDG locations, never synthetic tabs.
        return ShortcutsConfig.resolveDirectories(
            ShortcutsConfig.DEFAULT_DIRS, function (m) { return root.tr(m); });
    }

    readonly property var systemPlaces: configuredPlaces(
        allSystemPlaces, "SystemPlaceOrder", "HiddenSystemPlaces")

    readonly property var allDolphinPlaces: {
        var _ = root.uiLang;
        var __ = root.structureEpoch;
        var out = [];
        var nativePlaces = root.plasmaPlaces || [];
        for (var p = 0; p < nativePlaces.length; ++p) {
            var nativePlace = nativePlaces[p];
            if (!nativePlace || nativePlace.isSystemPlace === true)
                continue;
            out.push(nativePlace);
        }
        return out;
    }

    readonly property var dolphinPlaces: configuredPlaces(
        allDolphinPlaces, "DolphinPlaceOrder", "HiddenDolphinPlaces")

    readonly property var allUserCustomPlaces: {
        var _ = root.uiLang;
        var __ = root.structureEpoch;
        var out = [];
        var ids = root.directoryShortcutIds || [];
        for (var i = 0; i < ids.length; ++i) {
            var shortcutId = String(ids[i] || "");
            if (shortcutId.indexOf("app:") === 0) {
                var appId = shortcutId.substring(4);
                var app = AppsModel.findAppById(root.allApps, appId);
                if (app) {
                    var appCopy = Object.assign({}, app);
                    appCopy.id = shortcutId;
                    appCopy.customPlaceKey = shortcutId;
                    out.push(appCopy);
                }
                continue;
            }
            if (shortcutId.indexOf("custom:") !== 0)
                continue;
            var it = ShortcutsConfig.resolveDirectory(shortcutId, function (m) { return root.tr(m); });
            if (!it || it.invalid)
                continue;
            var customUrl = it.kickerUrl || (it.path ? ("file://" + it.path) : "");
            out.push({
                id: it.id,
                customPlaceKey: it.id,
                name: it.name,
                icon: it.icon,
                place: it.place || "",
                exec: it.exec || "",
                path: it.path || "",
                kickerUrl: customUrl,
                categories: ["Places"],
                keywords: [],
                genericName: it.path || it.name,
                noDisplay: false
            });
        }
        return out;
    }

    readonly property var userCustomPlaces: configuredPlaces(
        allUserCustomPlaces, "DirectoryShortcuts", "HiddenCustomPlaces")

    /** Compatibility union for layouts that do not render the three sections. */
    readonly property var customPlaces: dolphinPlaces.concat(userCustomPlaces)

    readonly property var placeSections: {
        var _ = root.structureEpoch;
        var wanted = ShortcutsConfig.normalizeList(
            cfg("PlaceSectionOrder", ["system", "dolphin", "custom"]),
            ["system", "dolphin", "custom"]);
        var ids = [];
        for (var i = 0; i < wanted.length; ++i) {
            if (["system", "dolphin", "custom"].indexOf(wanted[i]) >= 0 && ids.indexOf(wanted[i]) < 0)
                ids.push(wanted[i]);
        }
        ["system", "dolphin", "custom"].forEach(function (id) {
            if (ids.indexOf(id) < 0) ids.push(id);
        });
        var map = { system: systemPlaces, dolphin: dolphinPlaces, custom: userCustomPlaces };
        return ids.map(function (id) { return { id: id, items: map[id] || [] }; });
    }

    readonly property var places: placeSections.reduce(function (out, section) {
        return out.concat(section.items || []);
    }, [])

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
        if (!app)
            return;
        var pinId = root.resolvePinId(app);
        if (!pinId)
            pinId = app.id;
        if (root.isPrismenuOnlyPinId(pinId))
            return;
        var favId = root.plasmaFavoriteIdForApp(app);
        if (!favId || !appsBackend)
            return;
        if (root.isFavorite(app) && appsBackend.removeFavoriteForApp)
            appsBackend.removeFavoriteForApp(app, { favoriteId: favId });
        else if (appsBackend.setPlasmaFavorite)
            appsBackend.setPlasmaFavorite(favId, true);
        root.dropPinnedPreviewForce();
        root.bumpStructure();
    }

    function isFavorite(appOrId) {
        if (appOrId && typeof appOrId === "object") {
            var pinId = root.resolvePinId(appOrId);
            if (root.isPrismenuOnlyPinId(pinId))
                return false;
            var favId = root.plasmaFavoriteIdForApp(appOrId);
            return !!(appsBackend && appsBackend.isPlasmaFavorite
                && appsBackend.isPlasmaFavorite(favId));
        }
        var app = AppsModel.findAppById(allApps, String(appOrId || ""));
        if (app)
            return root.isFavorite(app);
        return false;
    }

    /** Settings lives on the search bar — drop the old in-menu pin. */
    function dropInMenuSettingsPin() {
        if (!plasmoidConfig)
            return;
        var current = IdList.normalizeIdList(cfg("PinnedApps", []));
        var next = IdList.withoutMenuSettings(current);
        if (next.length !== current.length)
            plasmoidConfig.PinnedApps = next;
    }

    /** Index of an app id inside Plasma's global favorites list (-1 none). */
    function favoriteIndexForAppId(appId) {
        var favs = root.plasmaFavoriteIds || [];
        var id = String(appId || "");
        for (var i = 0; i < favs.length; ++i) {
            var app = root.appForPlasmaFavoriteId(favs[i]);
            if (app && String(app.id) === id)
                return i;
        }
        return -1;
    }

    function reorderPinned(from, to) {
        var ids = root.effectivePinnedIds();
        if (from < 0 || to < 0 || from >= ids.length || to >= ids.length)
            return;
        root.movePinnedItem(ids[from], ids[to]);
    }

    /**
     * Drag & drop entry point for pinned/favorite views. Reorders the
     * dragged entry next to targetId, or pins a not-yet-pinned app at that
     * position (Kickoff-style drop-to-pin). An empty targetId appends at
     * the end. Both membership and order belong to Plasma's global
     * KAStatsFavoritesModel.
     */
    function movePinnedItem(fromId, toId) {
        fromId = String(fromId || "");
        toId = String(toId || "");
        if (!fromId || fromId === toId)
            return false;

        var ids = root.effectivePinnedIds();
        var from = ids.indexOf(fromId);
        var to = toId ? ids.indexOf(toId) : ids.length; // "" → append
        if (from >= 0 && from === to)
            return false;

        if (from >= 0) {
            var fi = root.favoriteIndexForAppId(fromId);
            if (fi < 0 || !appsBackend || !appsBackend.movePlasmaFavorite)
                return false;
            var ti = to >= ids.length
                ? Math.max(0, ids.length - 1)
                : root.favoriteIndexForAppId(ids[to]);
            if (ti < 0)
                return false;
            appsBackend.movePlasmaFavorite(fi, ti);
            return true;
        }

        // fromId is not pinned yet → pin it (drop-to-pin, Kickoff parity)
        if (root.isPrismenuOnlyPinId(fromId))
            return false;
        var app = AppsModel.findAppById(allApps, fromId);
        if (!app)
            return false;
        var favId = root.plasmaFavoriteIdForApp(app);
        if (!favId || !appsBackend)
            return false;
        if (to >= 0 && to < ids.length && appsBackend.insertPlasmaFavorite) {
            var ti2 = root.favoriteIndexForAppId(ids[to]);
            if (ti2 >= 0)
                return appsBackend.insertPlasmaFavorite(favId, ti2);
        }
        if (appsBackend.setPlasmaFavorite) {
            appsBackend.setPlasmaFavorite(favId, true);
            return true;
        }
        return false;
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
