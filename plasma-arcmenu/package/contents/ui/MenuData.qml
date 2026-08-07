import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "../code/AppsModel.js" as AppsModel
import "../code/Favorites.js" as Favorites
import "../code/Distro.js" as Distro
import "../code/LayoutRegistry.js" as LayoutRegistry
import "../code/Theme.js" as ThemeHelper
import "../code/IdList.js" as IdList
import "../code/Locale.js" as Locale

QtObject {
    id: root

    // ---- Config bindings (set from main.qml) ----
    property var plasmoidConfig: null
    // Bound directly from main.qml → plasmoid.configuration.currentLayout
    // (do NOT read via plasmoidConfig.var — QML won't notify on nested changes)
    property string currentLayoutId: "arcmenu"

    // ---- Runtime state ----
    property string searchQuery: ""
    property string currentCategoryId: "all"
    property int kickoffTab: 0 // 0 favorites, 1 recent, 2 apps, 3 places, 4 leave
    property bool categoriesCollapsed: false
    property bool showAllApps: false // legacy toggle; prefer currentPage
    property string currentPage: "home" // home | apps | search
    property var focusedApp: null

    // ---- UI language (General → Menu language) ----
    readonly property string uiLanguagePref: plasmoidConfig ? (plasmoidConfig.uiLanguage || "zh_CN") : "zh_CN"
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function trf(msgid, arg1) {
        return Locale.trf(msgid, uiLang, arg1);
    }

    // ---- Derived config accessors ----
    readonly property var layoutInfo: LayoutRegistry.getLayout(currentLayoutId)
    readonly property bool flipHorizontal: plasmoidConfig ? plasmoidConfig.flipHorizontal : false
    readonly property string searchbarLocation: plasmoidConfig ? plasmoidConfig.searchbarLocation : "top"
    readonly property int menuWidth: LayoutRegistry.clampSize(plasmoidConfig ? plasmoidConfig.menuWidth : 600, 400, 900, 600)
    // Shared MenuHeight max is 800; Raven uses runtime fill height in main.qml instead
    readonly property int menuHeight: LayoutRegistry.clampSize(plasmoidConfig ? plasmoidConfig.menuHeight : 550, 400, 800, 550)
    readonly property int appIconSize: plasmoidConfig ? plasmoidConfig.appIconSize : 24
    readonly property int categoryIconSize: plasmoidConfig ? plasmoidConfig.categoryIconSize : 24
    readonly property int pinnedCols: plasmoidConfig ? plasmoidConfig.pinnedCols : 6
    readonly property bool recentEnabled: plasmoidConfig ? plasmoidConfig.enabled : true
    readonly property int recentMax: plasmoidConfig ? plasmoidConfig.maxItems : 5
    readonly property bool showSearchDescription: plasmoidConfig ? plasmoidConfig.showDescription : true
    readonly property int maxSearchResults: plasmoidConfig ? plasmoidConfig.maxResults : 20
    readonly property var searchProviders: plasmoidConfig ? plasmoidConfig.providers : ["applications"]
    readonly property string searchPlaceholder: {
        var p = plasmoidConfig ? plasmoidConfig.placeholder : "";
        if (!p || p === "Search…")
            return root.tr("Search…");
        return root.tr(p);
    }
    readonly property var powerOptions: {
        var fallback = ["shutdown", "restart", "logout", "lock"];
        if (!plasmoidConfig) {
            return fallback;
        }
        var opts = plasmoidConfig.options;
        if (opts === undefined || opts === null) {
            return fallback;
        }
        if (typeof opts === "string") {
            return opts.length ? opts.split(",") : fallback;
        }
        if (opts.length === 0) {
            return fallback;
        }
        return opts;
    }
    readonly property bool powerConfirm: plasmoidConfig ? plasmoidConfig.confirm : true
    readonly property string softwareCenterCmd: plasmoidConfig ? plasmoidConfig.softwareCenterCmd : "auto-detect"
    readonly property bool syncFavorites: plasmoidConfig ? plasmoidConfig.syncWithPlasma : true
    readonly property bool showEmptyCategories: plasmoidConfig ? plasmoidConfig.showEmpty : false

    // ---- Application catalog (populated by runner / demo fallback) ----
    property var allApps: []
    property var rawCategories: []
    property string userName: ""
    property string userIcon: "user-identity"
    property string osReleaseId: "kubuntu"
    property string osPrettyName: "Kubuntu"

    readonly property var categories: {
        var base = rawCategories.length ? rawCategories : AppsModel.defaultCategories();
        // attach counts + translate default English names
        var withCounts = [];
        for (var i = 0; i < base.length; ++i) {
            var c = Object.assign({}, base[i]);
            c.name = root.tr(c.name);
            c.apps = AppsModel.appsInCategory(allApps, c.id);
            c.appCount = c.apps.length;
            withCounts.push(c);
        }
        // prepend All
        var all = {
            id: "all",
            name: root.tr("All Applications"),
            icon: "applications-all",
            apps: AppsModel.sortAppsByName(AppsModel.filterVisibleApps(allApps)),
            appCount: allApps.length
        };
        var customized = AppsModel.applyCategoryCustomization(
            withCounts,
            plasmoidConfig ? plasmoidConfig.order : [],
            plasmoidConfig ? plasmoidConfig.hidden : [],
            plasmoidConfig ? plasmoidConfig.customNames : "{}",
            plasmoidConfig ? plasmoidConfig.customIcons : "{}",
            showEmptyCategories
        );
        return [all].concat(customized);
    }

    readonly property var categoryApps: AppsModel.appsInCategory(allApps, currentCategoryId)

    readonly property var pinnedApps: {
        var lang = root.uiLang; // binding dependency
        var ids = IdList.normalizeIdList(plasmoidConfig ? plasmoidConfig.pinnedApps : []);
        if (ids.length === 0) {
            ids = IdList.defaultPinnedIds();
        }
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
        var ids = plasmoidConfig ? plasmoidConfig.recentApps : [];
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
        plasmoidConfig ? plasmoidConfig.buttonIcon : "auto-distro",
        plasmoidConfig ? plasmoidConfig.customButtonIcon : "",
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
            return;
        }
        currentPage = "home";
        showAllApps = false;
        currentCategoryId = "all";
    }

    function selectCategory(id) {
        currentCategoryId = id;
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
        { id: "place-home", name: root.tr("Home"), icon: "user-home", exec: "xdg-open $HOME", categories: ["Places"], keywords: [], genericName: root.tr("Home folder"), noDisplay: false },
        { id: "place-docs", name: root.tr("Documents"), icon: "folder-documents", exec: "xdg-open xdg:Documents", categories: ["Places"], keywords: [], genericName: root.tr("Documents"), noDisplay: false },
        { id: "place-dl", name: root.tr("Downloads"), icon: "folder-download", exec: "xdg-open xdg:Download", categories: ["Places"], keywords: [], genericName: root.tr("Downloads"), noDisplay: false },
        { id: "place-music", name: root.tr("Music"), icon: "folder-music", exec: "xdg-open xdg:Music", categories: ["Places"], keywords: [], genericName: root.tr("Music"), noDisplay: false },
        { id: "place-pics", name: root.tr("Pictures"), icon: "folder-pictures", exec: "xdg-open xdg:Pictures", categories: ["Places"], keywords: [], genericName: root.tr("Pictures"), noDisplay: false },
        { id: "place-videos", name: root.tr("Videos"), icon: "folder-videos", exec: "xdg-open xdg:Videos", categories: ["Places"], keywords: [], genericName: root.tr("Videos"), noDisplay: false }
    ]

    readonly property var systemShortcuts: [
        { id: "shortcut-software", name: root.tr("Software"), icon: "plasmadiscover", exec: "", categories: ["System"], keywords: [], genericName: root.tr("Software Center"), noDisplay: false, action: "discover" },
        { id: "shortcut-settings", name: root.tr("Settings"), icon: "preferences-system", exec: "", categories: ["System"], keywords: [], genericName: root.tr("System Settings"), noDisplay: false, action: "settings" },
        { id: "shortcut-tweaks", name: root.tr("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel", categories: ["System"], keywords: [], genericName: root.tr("Appearance"), noDisplay: false },
        { id: "shortcut-overview", name: root.tr("Activities Overview"), icon: "overview", exec: "", categories: ["System"], keywords: [], genericName: root.tr("Overview"), noDisplay: false, action: "overview" }
    ]

    function isFavorite(appId) {
        var pinned = plasmoidConfig ? plasmoidConfig.pinnedApps : [];
        return Favorites.isFavorite(pinned, appId);
    }

    function toggleFavorite(app) {
        if (!app || !plasmoidConfig) {
            return;
        }
        plasmoidConfig.pinnedApps = Favorites.toggleFavorite(plasmoidConfig.pinnedApps, app.id);
    }

    function reorderPinned(from, to) {
        if (!plasmoidConfig) {
            return;
        }
        plasmoidConfig.pinnedApps = Favorites.moveItem(plasmoidConfig.pinnedApps, from, to);
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

    function seedDemoApps() {
        // Used when KService runner is unavailable (dev / packaging checks).
        if (allApps.length > 0) {
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

    Component.onCompleted: seedDemoApps()
}
