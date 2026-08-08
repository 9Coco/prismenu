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

QtObject {
    id: root

    // ---- Config bindings (set from main.qml) ----
    property var plasmoidConfig: null
    // Bound directly from main.qml → plasmoid.configuration.menuLayoutId
    property string currentLayoutId: "arcmenu"

    // ---- Runtime state ----
    property string searchQuery: ""
    property string currentCategoryId: "all"
    property int kickoffTab: 0 // 0 favorites, 1 recent, 2 apps, 3 places, 4 leave
    property bool categoriesCollapsed: false
    property bool showAllApps: false // legacy toggle; prefer currentPage
    property string currentPage: "home" // home | apps | search
    property var focusedApp: null

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
    readonly property string searchbarLocation: cfgStr("searchbarLocation", "top")
    readonly property int menuWidth: LayoutRegistry.clampSize(cfgInt("menuWidth", 620), 400, 900, 620)
    // Shared MenuHeight max is 800; Raven uses runtime fill height in main.qml instead
    readonly property int menuHeight: LayoutRegistry.clampSize(cfgInt("menuHeight", 540), 400, 800, 540)
    /** Places / categories side column width; default ~36% of 620 */
    readonly property int sidebarWidth: LayoutRegistry.clampSize(cfgInt("sidebarWidth", 220), 160, 360, 220)
    /** Zest middle categories column */
    readonly property int categoryColumnWidth: LayoutRegistry.clampSize(cfgInt("categoryColumnWidth", 220), 160, 360, 220)
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
        plasmoidConfig.menuWidth = LayoutRegistry.clampSize(w, 400, 900, 620);
    }

    function setMenuHeight(h) {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.menuHeight = LayoutRegistry.clampSize(h, 400, 800, 540);
    }

    function setSidebarWidth(w) {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.sidebarWidth = LayoutRegistry.clampSize(w, 160, 360, 220);
    }

    function setCategoryColumnWidth(w) {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.categoryColumnWidth = LayoutRegistry.clampSize(w, 160, 360, 220);
    }

    function resetLayoutSizesToDefaults() {
        if (!plasmoidConfig)
            return;
        plasmoidConfig.menuWidth = defaultMenuWidth;
        plasmoidConfig.menuHeight = defaultMenuHeight;
        plasmoidConfig.sidebarWidth = defaultSidebarWidth;
        plasmoidConfig.categoryColumnWidth = defaultCategoryColumnWidth;
    }
    readonly property int appIconSize: Math.max(16, cfgInt("appIconSize", 24))
    readonly property int categoryIconSize: Math.max(16, cfgInt("categoryIconSize", 24))
    readonly property int pinnedCols: Math.max(1, cfgInt("pinnedCols", 6))
    readonly property bool recentEnabled: cfgBool("enabled", true)
    readonly property int recentMax: Math.max(0, cfgInt("maxItems", 5))
    readonly property bool showSearchDescription: cfgBool("showDescription", true)
    readonly property int maxSearchResults: Math.max(1, cfgInt("maxResults", 20))
    readonly property var searchProviders: {
        var p = cfg("providers", ["applications"]);
        if (typeof p === "string")
            return p.length ? p.split(",") : ["applications"];
        if (!p || p.length === undefined)
            return ["applications"];
        return p;
    }
    readonly property string searchPlaceholder: {
        var p = cfgStr("placeholder", "Search…");
        if (!p || p === "Search…")
            return root.tr("Search…");
        return root.tr(p);
    }
    readonly property var powerOptions: {
        var fallback = ["shutdown", "restart", "logout", "lock"];
        var opts = cfg("options", fallback);
        if (opts === undefined || opts === null)
            return fallback;
        if (typeof opts === "string")
            return opts.length ? opts.split(",") : fallback;
        if (opts.length === 0)
            return fallback;
        return opts;
    }
    readonly property bool powerConfirm: cfgBool("confirm", true)
    readonly property string softwareCenterCmd: cfgStr("softwareCenterCmd", "auto-detect")
    readonly property bool syncFavorites: cfgBool("syncWithPlasma", true)
    readonly property bool showEmptyCategories: cfgBool("showEmpty", true)

    // ---- Application catalog (populated by AppsBackend / Kicker RootModel) ----
    property var allApps: []
    /** Bumped when allApps is replaced — forces UI bindings to refresh */
    property int catalogEpoch: 0
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
        var apps = AppsModel.searchApps(allApps, searchQuery.trim(), maxSearchResults);
        // Optionally include placeholder non-app runners when providers allow
        var includeOthers = false;
        var providers = searchProviders || [];
        for (var i = 0; i < providers.length; ++i) {
            if (providers[i] !== "applications") {
                includeOthers = true;
                break;
            }
        }
        if (includeOthers && apps.length < maxSearchResults) {
            // Soft secondary matches from genericName already covered;
            // keep structure ready for Plasma Search runners.
        }
        return apps;
    }

    readonly property string buttonIcon: Distro.resolveButtonIcon(
        cfgStr("buttonIcon", "auto-distro"),
        cfgStr("customButtonIcon", ""),
        osReleaseId,
        osPrettyName
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

    /**
     * XDG user dirs + Plasma equivalents of ArcMenu Places / Extra Shortcuts.
     */
    readonly property var places: [
        { id: "place-home", name: root.tr("Home"), icon: "user-home", place: "HOME", categories: ["Places"], keywords: [], genericName: root.tr("Home folder"), noDisplay: false },
        { id: "place-docs", name: root.tr("Documents"), icon: "folder-documents", place: "DOCUMENTS", categories: ["Places"], keywords: [], genericName: root.tr("Documents"), noDisplay: false },
        { id: "place-dl", name: root.tr("Downloads"), icon: "folder-download", place: "DOWNLOAD", categories: ["Places"], keywords: [], genericName: root.tr("Downloads"), noDisplay: false },
        { id: "place-music", name: root.tr("Music"), icon: "folder-music", place: "MUSIC", categories: ["Places"], keywords: [], genericName: root.tr("Music"), noDisplay: false },
        { id: "place-pics", name: root.tr("Pictures"), icon: "folder-pictures", place: "PICTURES", categories: ["Places"], keywords: [], genericName: root.tr("Pictures"), noDisplay: false },
        { id: "place-videos", name: root.tr("Videos"), icon: "folder-videos", place: "VIDEOS", categories: ["Places"], keywords: [], genericName: root.tr("Videos"), noDisplay: false }
    ]

    // Extra shortcuts — Overview omitted (no useful KDE equivalent)
    readonly property var systemShortcuts: [
        { id: "shortcut-software", name: root.tr("Software"), icon: "plasmadiscover", exec: "", categories: ["System"], keywords: [], genericName: root.tr("Software Center"), noDisplay: false, action: "discover" },
        { id: "shortcut-settings", name: root.tr("Settings"), icon: "preferences-system", exec: "", categories: ["System"], keywords: [], genericName: root.tr("System Settings"), noDisplay: false, action: "settings" },
        { id: "shortcut-tweaks", name: root.tr("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel", categories: ["System"], keywords: [], genericName: root.tr("Appearance"), noDisplay: false }
    ]

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
