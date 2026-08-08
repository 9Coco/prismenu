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
    // Bound directly from main.qml → plasmoid.configuration.menuLayoutId
    property string currentLayoutId: "arcmenu"
    /**
     * Bound from main.qml as real QML bindings (not via var/cfg()), so toggles
     * in the config dialog refresh the open menu immediately.
     */
    property var extraCategoriesEnabledRaw
    property var extraCategoriesOrderRaw
    property bool extraCategoriesUserSetRaw: false

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
    /** Bumped when recent-file list is refreshed — forces UI list bindings */
    property int recentFilesEpoch: 0
    property int bookmarksEpoch: 0
    /** Increment to ask AppsBackend to re-read recently-used.xbel */
    property int recentFilesRequest: 0
    property int bookmarksRequest: 0

    function requestRecentFilesRefresh() {
        recentFilesRequest++;
    }
    function requestBookmarksRefresh() {
        bookmarksRequest++;
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
    readonly property string uiLanguagePref: cfgStr("uiLanguage", "zh_CN")
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function trf(msgid, arg1) {
        return Locale.trf(msgid, uiLang, arg1);
    }

    // ---- Derived config accessors ----
    readonly property var layoutInfo: LayoutRegistry.getLayout(currentLayoutId)
    readonly property bool flipHorizontal: cfgBool("flipHorizontal", false)
    readonly property string searchbarLocation: cfgStr("searchbarLocation", "bottom")
    readonly property string allAppsButtonAction: cfgStr("allAppsButtonAction", "category-list")
    readonly property bool showUserAvatar: cfgBool("showUserAvatar", true)
    readonly property string avatarShape: cfgStr("avatarShape", "circle")
    readonly property bool showVerticalSeparator: cfgBool("showVerticalSeparator", false)
    readonly property bool showExternalDevices: cfgBool("showExternalDevices", false)
    readonly property bool showBookmarks: cfgBool("showBookmarks", true)
    readonly property var quickLinksOrder: {
        var o = cfg("quickLinksOrder", ["favorites", "frequent", "all-apps", "pinned", "recent-files"]);
        if (typeof o === "string")
            return o.length ? o.split(",") : [];
        return o || [];
    }
    readonly property var quickLinksEnabled: {
        var o = cfg("quickLinksEnabled", []);
        if (typeof o === "string")
            return o.length ? o.split(",") : [];
        return o || [];
    }
    readonly property string quickLinkPosition: cfgStr("quickLinkPosition", "bottom")

    function isQuickLinkEnabled(id) {
        return (quickLinksEnabled || []).indexOf(id) >= 0;
    }

    readonly property var enabledQuickLinks: {
        var order = quickLinksOrder.length
            ? quickLinksOrder
            : ["favorites", "frequent", "all-apps", "pinned", "recent-files"];
        var out = [];
        for (var i = 0; i < order.length; ++i) {
            var id = order[i];
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
        return out;
    }
    readonly property int leftPanelWidth: LayoutRegistry.clampSize(cfgInt("leftPanelWidth", 380), 180, 600, 380)
    readonly property int rightPanelWidth: LayoutRegistry.clampSize(cfgInt("rightPanelWidth", 220), 160, 360, 220)
    readonly property int widthOffset: LayoutRegistry.clampSize(cfgInt("widthOffset", 0), -200, 400, 0)
    /** Traditional panels (+ chrome) + optional width offset for non-traditional layouts */
    readonly property int menuWidth: LayoutRegistry.clampSize(
        leftPanelWidth + rightPanelWidth + 24 + widthOffset, 400, 900, 620)
    // Shared MenuHeight max is 800; Raven uses runtime fill height in main.qml instead
    readonly property int menuHeight: LayoutRegistry.clampSize(cfgInt("menuHeight", 540), 400, 800, 540)
    /** Places / categories side column — synced with right panel for ArcMenu-style shells */
    readonly property int sidebarWidth: LayoutRegistry.clampSize(
        cfgInt("sidebarWidth", cfgInt("rightPanelWidth", 220)), 160, 360, 220)
    /** Zest middle categories column */
    readonly property int categoryColumnWidth: LayoutRegistry.clampSize(cfgInt("categoryColumnWidth", 220), 160, 360, 220)
    readonly property string overrideMenuPosition: cfgStr("overrideMenuPosition", "off")
    readonly property bool overrideMenuRise: cfgBool("overrideMenuRise", false)
    readonly property int menuRiseDistance: LayoutRegistry.clampSize(cfgInt("menuRiseDistance", 6), 0, 64, 6)
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
        var c = LayoutRegistry.clampSize(w, 400, 900, 620);
        plasmoidConfig.menuWidth = c;
        // Keep right panel; adjust left so panels stay consistent with drag-resize
        var left = c - rightPanelWidth - 24 - widthOffset;
        plasmoidConfig.leftPanelWidth = LayoutRegistry.clampSize(left, 180, 600, 380);
    }

    function setMenuHeight(h) {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.menuHeight = LayoutRegistry.clampSize(h, 400, 800, 540);
    }

    function setSidebarWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 160, 360, 220);
        plasmoidConfig.sidebarWidth = c;
        plasmoidConfig.rightPanelWidth = c;
    }

    function setCategoryColumnWidth(w) {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.categoryColumnWidth = LayoutRegistry.clampSize(w, 160, 360, 220);
    }

    function setLeftPanelWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 180, 600, 290);
        plasmoidConfig.leftPanelWidth = c;
        plasmoidConfig.menuWidth = LayoutRegistry.clampSize(
            c + rightPanelWidth + 24, 400, 900, 620);
    }

    function setRightPanelWidth(w) {
        if (!plasmoidConfig)
            return;
        var c = LayoutRegistry.clampSize(w, 160, 360, 205);
        plasmoidConfig.rightPanelWidth = c;
        plasmoidConfig.sidebarWidth = c;
        plasmoidConfig.menuWidth = LayoutRegistry.clampSize(
            leftPanelWidth + c + 24, 400, 900, 620);
    }

    function resetLayoutSizesToDefaults() {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.menuWidth = defaultMenuWidth;
        plasmoidConfig.menuHeight = defaultMenuHeight;
        plasmoidConfig.sidebarWidth = defaultSidebarWidth;
        plasmoidConfig.categoryColumnWidth = defaultCategoryColumnWidth;
        plasmoidConfig.leftPanelWidth = 380;
        plasmoidConfig.rightPanelWidth = 220;
        plasmoidConfig.widthOffset = 0;
    }

    readonly property int baseAppIconSize: Math.max(16, cfgInt("appIconSize", 24))
    readonly property int baseCategoryIconSize: Math.max(16, cfgInt("categoryIconSize", 24))
    readonly property bool gridIconOverride: cfgInt("iconSizeGrid", -1) >= 0
    readonly property bool appsIconOverride: cfgInt("iconSizeApps", -1) >= 0
    readonly property bool shortcutsIconOverride: cfgInt("iconSizeShortcuts", -1) >= 0
    readonly property bool categoriesIconOverride: cfgInt("iconSizeCategories", -1) >= 0
    readonly property bool buttonsIconOverride: cfgInt("iconSizeButtons", -1) >= 0
    readonly property bool otherIconOverride: cfgInt("iconSizeOther", -1) >= 0
    readonly property int appIconSize: IconSizes.resolve(cfgInt("iconSizeApps", -1), baseAppIconSize)
    readonly property int categoryIconSize: IconSizes.resolve(cfgInt("iconSizeCategories", -1), baseCategoryIconSize)
    readonly property int gridIconSize: IconSizes.resolve(cfgInt("iconSizeGrid", -1), Math.max(baseAppIconSize + 12, 36))
    readonly property int shortcutIconSize: IconSizes.resolve(cfgInt("iconSizeShortcuts", -1), categoryIconSize)
    readonly property int buttonIconSize: IconSizes.resolve(cfgInt("iconSizeButtons", -1), 22)
    readonly property int otherIconSize: IconSizes.resolve(cfgInt("iconSizeOther", -1), 22)
    readonly property int pinnedCols: Math.max(1, cfgInt("pinnedCols", 6))
    readonly property bool recentEnabled: cfgBool("enabled", true)
    readonly property int recentMax: Math.max(0, cfgInt("maxItems", 5))
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
        return cfgBool("showDescription", true);
    }
    readonly property bool hideSearchBar: {
        var _ = searchConfigEpoch;
        if (hideSearchBarRaw !== undefined && hideSearchBarRaw !== null)
            return hideSearchBarRaw === true || hideSearchBarRaw === 1;
        return cfgBool("hideSearchBar", false);
    }
    readonly property bool highlightSearchTerms: {
        var _ = searchConfigEpoch;
        if (highlightSearchTermsRaw !== undefined && highlightSearchTermsRaw !== null)
            return highlightSearchTermsRaw === true || highlightSearchTermsRaw === 1;
        return cfgBool("highlightSearchTerms", true);
    }
    readonly property bool searchBoxRadiusEnabled: {
        var _ = searchConfigEpoch;
        if (searchBoxRadiusEnabledRaw !== undefined && searchBoxRadiusEnabledRaw !== null)
            return searchBoxRadiusEnabledRaw === true || searchBoxRadiusEnabledRaw === 1;
        return cfgBool("searchBoxRadiusEnabled", true);
    }
    readonly property int searchBoxRadius: {
        var _ = searchConfigEpoch;
        var n = (searchBoxRadiusRaw !== undefined && searchBoxRadiusRaw !== null)
            ? parseInt(searchBoxRadiusRaw, 10) : cfgInt("searchBoxRadius", 25);
        return Math.max(0, isNaN(n) ? 25 : n);
    }
    readonly property bool searchWindows: {
        var _ = searchConfigEpoch;
        if (searchWindowsRaw !== undefined && searchWindowsRaw !== null)
            return searchWindowsRaw === true || searchWindowsRaw === 1;
        return cfgBool("searchWindows", false);
    }
    readonly property bool searchRecentFiles: {
        var _ = searchConfigEpoch;
        if (searchRecentFilesRaw !== undefined && searchRecentFilesRaw !== null)
            return searchRecentFilesRaw === true || searchRecentFilesRaw === 1;
        return cfgBool("searchRecentFiles", false);
    }

    // ---- Fine-tuning ----
    readonly property bool showCategorySubmenus: cfgBool("showCategorySubmenus", false)
    readonly property bool showAppDescriptions: cfgBool("showAppDescriptions", false)
    readonly property bool showGenericNames: cfgBool("showGenericNames", false)
    readonly property bool showHiddenRecentFiles: cfgBool("showHiddenRecentFiles", false)
    readonly property bool multiLineLabels: cfgBool("multiLineLabels", true)
    readonly property bool showTooltips: cfgBool("showTooltips", true)
    readonly property bool groupAppsAlphabeticallyList: cfgBool("groupAppsAlphabeticallyList", true)
    readonly property bool groupAppsAlphabeticallyGrid: cfgBool("groupAppsAlphabeticallyGrid", false)
    readonly property bool activateExistingWindow: cfgBool("activateExistingWindow", false)
    readonly property bool keepOpenOnCtrlClick: cfgBool("keepOpenOnCtrlClick", true)
    readonly property bool scrollviewFadeEffects: cfgBool("scrollviewFadeEffects", true)
    readonly property bool showScrollbars: cfgBool("showScrollbars", true)
    readonly property bool overlayScrollbars: cfgBool("overlayScrollbars", true)
    readonly property string categoryIconType: cfgStr("categoryIconType", "symbolic")
    readonly property string shortcutIconType: cfgStr("shortcutIconType", "symbolic")
    readonly property bool categoryIconsSymbolic: categoryIconType !== "fullcolor"
    readonly property bool shortcutIconsSymbolic: shortcutIconType !== "fullcolor"
    readonly property int maxSearchResults: {
        var _ = searchConfigEpoch;
        var n = (maxResultsRaw !== undefined && maxResultsRaw !== null)
            ? parseInt(maxResultsRaw, 10) : cfgInt("maxResults", 5);
        if (isNaN(n) || n < 1)
            n = 5;
        return n;
    }
    readonly property var searchProviders: {
        var p = cfg("providers", ["applications"]);
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
        var p = cfgStr("placeholder", "Search…");
        if (!p || p === "Search…")
            return root.tr("Search…");
        return root.tr(p);
    }
    readonly property var powerOptionsOrder: {
        var fallback = ["logout", "lock", "restart", "shutdown", "suspend", "hybridsleep", "hibernate", "switchuser"];
        var opts = cfg("powerOptionsOrder", fallback);
        if (typeof opts === "string")
            return opts.length ? opts.split(",") : fallback;
        if (!opts || !opts.length)
            return fallback;
        return opts;
    }
    readonly property var powerOptions: {
        var fallback = ["logout", "lock", "restart", "shutdown"];
        var opts = cfg("options", fallback);
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
    readonly property bool powerConfirm: cfgBool("confirm", true)
    readonly property string softwareCenterCmd: cfgStr("softwareCenterCmd", "auto-detect")
    readonly property string powerDisplayStyle: cfgStr("powerDisplayStyle", "off")
    readonly property bool syncFavorites: cfgBool("syncWithPlasma", true)
    readonly property bool showEmptyCategories: cfgBool("showEmpty", true)

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

    readonly property var categories: {
        var _apps = allApps || [];
        var base = (rawCategories && rawCategories.length) ? rawCategories : AppsModel.defaultCategories();
        // attach counts + translate default English names (keep already-localized Kickoff names)
        var withCounts = [];
        for (var i = 0; i < base.length; ++i) {
            var c = Object.assign({}, base[i]);
            var originalName = String(c.name || "");
            var translated = root.tr(originalName);
            c.name = translated || originalName || c.id;
            if (!CategoryIcons.isBundled(c.icon))
                c.icon = CategoryIcons.defaultIcon(c.id);
            c.apps = AppsModel.appsInCategory(_apps, c.id);
            c.appCount = c.apps.length;
            withCounts.push(c);
        }
        // prepend All
        var all = {
            id: "all",
            name: root.tr("All Applications"),
            icon: "arcmenu-cat-other-apps",
            apps: AppsModel.sortAppsByName(AppsModel.filterVisibleApps(_apps)),
            appCount: _apps.length
        };
        var customized = AppsModel.applyCategoryCustomization(
            withCounts,
            cfg("order", []),
            cfg("hidden", []),
            cfgStr("customNames", "{}"),
            cfgStr("customIcons", "{}"),
            showEmptyCategories
        );
        return [all].concat(customized);
    }

    readonly property var categoryApps: AppsModel.appsInCategory(allApps, currentCategoryId)

    /** Config list, or defaults when never saved — used by display + toggle */
    function effectivePinnedIds() {
        var ids = IdList.normalizeIdList(cfg("pinnedApps", []));
        if (ids.length === 0)
            return IdList.defaultPinnedIds().slice();
        return ids;
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
        var ids = cfg("recentApps", []);
        return AppsModel.resolveAppsByIds(allApps, ids);
    }

    readonly property bool isSearching: searchQuery.trim().length > 0

    readonly property var searchResults: {
        if (!isSearching) {
            return [];
        }
        var _cfg = searchConfigEpoch;
        var _rf = recentFilesEpoch;
        var q = searchQuery.trim();
        // Fetch more apps than max so extras still have room after merge
        var appCap = Math.max(maxSearchResults * 2, maxSearchResults + 8);
        var apps = AppsModel.searchApps(allApps, q, appCap);
        var extras = [];
        if (searchRecentFiles) {
            extras = extras.concat(SearchExtras.filterByQuery(recentFileResults || [], q));
        }
        if (searchWindows) {
            extras = extras.concat(SearchExtras.filterByQuery(openWindowResults || [], q));
        }
        return SearchExtras.mergeSearchResults(apps, extras, maxSearchResults);
    }

    readonly property string buttonIcon: {
        var raw = Distro.resolveButtonIcon(
            cfgStr("buttonIcon", "auto-distro"),
            cfgStr("customButtonIcon", ""),
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
        cfgStr("buttonIcon", "auto-distro"),
        cfgStr("customButtonIcon", "")
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
        return ShortcutsConfig.normalizeList(cfg("directoryShortcuts", ShortcutsConfig.DEFAULT_DIRS), ShortcutsConfig.DEFAULT_DIRS);
    }
    readonly property var applicationShortcutIds: {
        return ShortcutsConfig.normalizeList(cfg("applicationShortcuts", ShortcutsConfig.DEFAULT_APPS), ShortcutsConfig.DEFAULT_APPS);
    }
    readonly property bool extraCategoriesUserSet: {
        var _ = root.structureEpoch;
        if (extraCategoriesUserSetRaw === true || extraCategoriesUserSetRaw === 1)
            return true;
        return cfgBool("extraCategoriesUserSet", false);
    }
    readonly property var extraCategoriesOrder: {
        var _ = root.structureEpoch;
        var raw = (extraCategoriesOrderRaw !== undefined && extraCategoriesOrderRaw !== null)
            ? extraCategoriesOrderRaw
            : (plasmoidConfig ? plasmoidConfig.extraCategoriesOrder : undefined);
        return ShortcutsConfig.normalizeList(raw, ShortcutsConfig.DEFAULT_EXTRA_ORDER);
    }
    readonly property var extraCategoriesEnabled: {
        var _ = root.structureEpoch;
        var raw = (extraCategoriesEnabledRaw !== undefined && extraCategoriesEnabledRaw !== null)
            ? extraCategoriesEnabledRaw
            : (plasmoidConfig ? plasmoidConfig.extraCategoriesEnabled : undefined);
        return ShortcutsConfig.effectiveExtraEnabled(raw, root.extraCategoriesUserSet);
    }
    readonly property var contextMenuItems: {
        return ShortcutsConfig.normalizeList(cfg("contextMenuItems", ShortcutsConfig.DEFAULT_CTX), ShortcutsConfig.DEFAULT_CTX);
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
                // In-menu GTK bookmarks list — bookmarks:/ KIO is unreliable on Plasma
                special: "bookmarks",
                categories: ["Places"], keywords: [], genericName: root.tr("Bookmarks"), noDisplay: false
            });
        }
        if (root.showExternalDevices) {
            out.push({
                id: "place-devices", name: root.tr("External devices"), icon: "drive-removable-media",
                exec: "kioclient exec computer:/ || dolphin computer:/ || xdg-open computer:/",
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

    function isFavorite(appOrId) {
        var ids = root.effectivePinnedIds();
        if (appOrId && typeof appOrId === "object") {
            var pinId = root.resolvePinId(appOrId);
            return Favorites.isFavorite(ids, pinId)
                || Favorites.isFavorite(ids, appOrId.id);
        }
        return Favorites.isFavorite(ids, appOrId);
    }

    function toggleFavorite(app) {
        if (!app || !plasmoidConfig) {
            return;
        }
        // Seed defaults on first edit so pinning does not wipe Files / ArcMenu Settings
        var current = IdList.normalizeIdList(cfg("pinnedApps", []));
        if (current.length === 0)
            current = IdList.defaultPinnedIds().slice();
        var pinId = root.resolvePinId(app);
        if (!pinId)
            pinId = app.id;
        plasmoidConfig.pinnedApps = Favorites.toggleFavorite(current, pinId);
    }

    /** Keep ArcMenu Settings in the pinned list when config was previously wiped */
    function ensureArcMenuSettingsPinned() {
        if (!plasmoidConfig)
            return;
        var current = IdList.normalizeIdList(cfg("pinnedApps", []));
        if (current.length === 0)
            return; // display already uses defaults including ArcMenu Settings
        if (current.indexOf("arcmenu-settings") < 0) {
            current.push("arcmenu-settings");
            plasmoidConfig.pinnedApps = current;
        }
    }

    function reorderPinned(from, to) {
        if (!plasmoidConfig) {
            return;
        }
        var current = root.effectivePinnedIds();
        plasmoidConfig.pinnedApps = Favorites.moveItem(current, from, to);
    }

    function recordLaunch(app) {
        if (!app || !plasmoidConfig) {
            return;
        }
        if (recentEnabled) {
            plasmoidConfig.recentApps = Favorites.pushRecent(plasmoidConfig.recentApps, app.id, recentMax);
        }
    }

    function clearRecent() {
        if (plasmoidConfig) {
            plasmoidConfig.recentApps = Favorites.clearRecent();
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
