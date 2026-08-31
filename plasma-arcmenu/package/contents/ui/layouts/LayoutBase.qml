import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui
import "../../code/Locale.js" as Locale
import "../../code/AppsModel.js" as AppsModel

Item {
    id: root

    // Safety net: when the menu is dragged narrower than the columns'
    // combined minimums, never paint content outside the menu surface.
    clip: true

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y, var anchor)
    signal powerAction(string actionId)
    signal userMenu()

    // Explicit language — layout string lists must depend on this to rebind
    readonly property string uiLang: {
        if (menuData && menuData.uiLang)
            return menuData.uiLang;
        return Locale.resolveLanguage("system", Qt.locale().name, Qt.locale().uiLanguages);
    }

    readonly property color bg: themeStyle.bg || "#2a2e32"
    readonly property color fg: {
        var c = themeStyle.fg || "#f2f2f2";
        var b = root.bg;
        var lumF = c.r * 0.299 + c.g * 0.587 + c.b * 0.114;
        var lumB = b.r * 0.299 + b.g * 0.587 + b.b * 0.114;
        if (Math.abs(lumF - lumB) < 0.28)
            return lumB < 0.5 ? "#f2f2f2" : "#1c1c1c";
        return c;
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.backgroundColor: root.bg
    Kirigami.Theme.textColor: root.fg
    Kirigami.Theme.highlightColor: root.activeBg
    Kirigami.Theme.highlightedTextColor: root.activeFg
    readonly property color borderColor: themeStyle.border || Kirigami.Theme.disabledTextColor
    readonly property int borderWidth: themeStyle.borderWidth !== undefined ? themeStyle.borderWidth : 1
    readonly property real radius: themeStyle.radius !== undefined ? themeStyle.radius : Kirigami.Units.cornerRadius
    readonly property color separatorColor: themeStyle.separator || Kirigami.Theme.disabledTextColor
    readonly property color hoverBg: themeStyle.hoverBg || themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color hoverFg: themeStyle.hoverFg || themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    readonly property color activeBg: themeStyle.activeBg || themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color activeFg: themeStyle.activeFg || themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    /** selected* kept as aliases of active* for existing layout bindings */
    readonly property color selectedBg: root.activeBg
    readonly property color selectedFg: root.activeFg
    readonly property int menuFontSize: {
        var n = themeStyle.fontSize;
        return (n !== undefined && n > 0) ? n : Kirigami.Theme.defaultFont.pointSize;
    }
    readonly property int appIconSize: menuData ? menuData.appIconSize : 24
    readonly property int categoryIconSize: menuData ? menuData.categoryIconSize : 24
    readonly property int gridIconSize: menuData && menuData.gridIconSize ? menuData.gridIconSize : Math.max(appIconSize + 12, 36)
    readonly property int shortcutIconSize: menuData && menuData.shortcutIconSize ? menuData.shortcutIconSize : categoryIconSize
    readonly property int buttonIconSize: menuData && menuData.buttonIconSize ? menuData.buttonIconSize : 22
    readonly property int otherIconSize: menuData && menuData.otherIconSize ? menuData.otherIconSize : 22
    readonly property bool showAppDescriptions: menuData ? menuData.showAppDescriptions : false
    readonly property bool showGenericNames: menuData ? menuData.showGenericNames : false
    readonly property bool multiLineLabels: !menuData || menuData.multiLineLabels
    readonly property bool showTooltips: !menuData || menuData.showTooltips
    readonly property bool categoryIconsSymbolic: !menuData || menuData.categoryIconsSymbolic
    readonly property bool shortcutIconsSymbolic: !menuData || menuData.shortcutIconsSymbolic
    readonly property bool flip: menuData ? menuData.flipHorizontal : false
    /** Layout default when SearchbarLocation was never changed (global config
     * default is "bottom"): upstream brisk/budgie/mint/whisker show the
     * search bar on top. Layouts override this to true. */
    property bool defaultSearchOnTop: !!(menuData && menuData.layoutInfo
        && menuData.layoutInfo.searchbarDefaultTop)
    readonly property bool searchOnTop: {
        if (menuData && menuData.searchbarLocationUserSet)
            return menuData.searchbarLocation !== "bottom";
        // Never touched — fall back to the layout's own default
        return root.defaultSearchOnTop;
    }
    readonly property bool searching: menuData ? menuData.isSearching : false

    /** Shared catalog projections. Layouts must not sort/group allApps again. */
    readonly property var allApplications: (menuData && menuData.sortedVisibleApps)
        ? menuData.sortedVisibleApps : []
    readonly property var allApplicationSections: (menuData && menuData.sortedVisibleAppsAzSections)
        ? menuData.sortedVisibleAppsAzSections : []
    readonly property var allApplicationRows: (menuData && menuData.sortedVisibleAppsAzRows)
        ? menuData.sortedVisibleAppsAzRows : []
    /** The configured home projection is shared, while each layout decides
     * where its home application area lives. */
    readonly property string homeGroupId: menuData ? menuData.homeGroupId : "pinned"
    readonly property string homeGroupName: menuData ? menuData.homeGroupName : root.tr("Pinned Applications")
    readonly property string homeGroupIcon: menuData ? menuData.homeGroupIcon : "favorite"
    readonly property var homeItems: {
        var _epoch = menuData ? menuData.structureEpoch : 0;
        var items = menuData && menuData.homeApps ? menuData.homeApps : [];
        if (root.homeGroupId === "pinned" && (!items || !items.length))
            return root.defaultPinned;
        return items || [];
    }

    /** Only Plasma's favorite projection has a persistent mutable order. */
    function isPinnedGroup(groupId) {
        return groupId === "pinned" || groupId === "favorites";
    }

    /** Shared column widths. During a split-handle drag these use an in-memory
     * preview so pointer motion never performs synchronous KConfig writes. */
    property int liveSidebarW: -1
    property int liveCategoryColW: -1
    readonly property int storedSidebarW: (menuData && menuData.sidebarWidth) ? menuData.sidebarWidth : 220
    readonly property int storedCategoryColW: (menuData && menuData.categoryColumnWidth)
        ? menuData.categoryColumnWidth : 220
    readonly property int sidebarW: liveSidebarW >= 0 ? liveSidebarW : storedSidebarW
    readonly property int categoryColW: liveCategoryColW >= 0 ? liveCategoryColW : storedCategoryColW
    readonly property int sidebarMin: 160
    readonly property int sidebarMax: 360
    /** Elastic column floor: sidebarMin clamped to ~30% of the menu width so
     * multi-column layouts always fit side by side at any dragged width
     * (fixed 160 minimums pushed columns outside the menu when narrowed). */
    readonly property int elasticColumnMin: Math.min(sidebarMin, Math.max(96, Math.round(root.width * 0.3)))

    Timer {
        id: sidebarDragCommitTimer
        interval: 250
        repeat: false
        onTriggered: {
            var width = root.liveSidebarW;
            if (width < 0)
                return;
            if (menuData && menuData.setSidebarWidth)
                menuData.setSidebarWidth(width);
            root.liveSidebarW = -1;
        }
    }

    Timer {
        id: categoryDragCommitTimer
        interval: 250
        repeat: false
        onTriggered: {
            var width = root.liveCategoryColW;
            if (width < 0)
                return;
            if (menuData && menuData.setCategoryColumnWidth)
                menuData.setCategoryColumnWidth(width);
            root.liveCategoryColW = -1;
        }
    }

    function setSidebarFromDrag(w) {
        root.liveSidebarW = Math.round(w);
        sidebarDragCommitTimer.restart();
    }

    function setCategoryColumnFromDrag(w) {
        root.liveCategoryColW = Math.round(w);
        categoryDragCommitTimer.restart();
    }

    function tr(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    /** Called by LayoutHost whenever the Plasma popup opens. Layouts with
     * local navigation state override this; shared MenuData is reset by main. */
    function resetForOpen() {}

    /** Fallback pinned list shown until the catalog / user pins are ready */
    property var defaultPinned: [
        {
            id: "org.kde.dolphin.desktop",
            name: root.tr("Files"),
            icon: "system-file-manager",
            exec: "dolphin",
            noDisplay: false
        }
    ]

    /** Nav id the shared contentItems binding follows (layouts bind their own
     * selection property here; layouts with custom panes may ignore it). */
    property string activeNavId: ""

    /** Standard content pane model: search > pinned > all > extra > category */
    readonly property var contentItems: root.computeContentItems(root.activeNavId)

    function mergeExtraApps(navId, base) {
        if (!menuData || !menuData.customGroupApps || !navId)
            return base || [];
        var extra = menuData.customGroupApps(navId) || [];
        if (!extra.length)
            return base || [];
        var seen = {};
        var out = [];
        var i;
        var list = base || [];
        for (i = 0; i < list.length; ++i) {
            if (!list[i])
                continue;
            seen[String(list[i].id || "")] = true;
            out.push(list[i]);
        }
        for (i = 0; i < extra.length; ++i) {
            if (!extra[i] || seen[String(extra[i].id || "")])
                continue;
            seen[String(extra[i].id || "")] = true;
            out.push(extra[i]);
        }
        return out;
    }

    function groupViewMode(navId) {
        var _sig = menuData ? menuData.extrasSignature : "";
        if (menuData && menuData.groupViewMode)
            return menuData.groupViewMode(navId);
        return (navId === "pinned" || navId === "favorites") ? "grid" : "list";
    }

    function usesGridView(navId) {
        return root.groupViewMode(navId) === "grid";
    }

    function groupIconSize(navId) {
        var _sig = menuData ? menuData.extrasSignature : "";
        if (menuData && menuData.groupIconSize)
            return menuData.groupIconSize(navId);
        return 48;
    }

    function computeContentItems(navId) {
        if (root.searching)
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        if (navId === "pinned" || navId === "favorites") {
            // Same pin list (Plasma favorites sync); labels differ upstream
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (navId === "all" || navId === "all-apps") {
            var allApps = (menuData && menuData.sortedVisibleApps) ? menuData.sortedVisibleApps : [];
            return root.mergeExtraApps("all-apps", allApps);
        }
        if (navId === "frequent") {
            var recents = (menuData && menuData.recentApps) ? menuData.recentApps : [];
            return root.mergeExtraApps("frequent", recents);
        }
        if (navId === "recent-files") {
            var files = (menuData && menuData.recentFileResults) ? menuData.recentFileResults : [];
            return root.mergeExtraApps("recent-files", files);
        }
        if (String(navId).indexOf("qgrp-") === 0 || String(navId).indexOf("tgrp-") === 0) {
            var _map = menuData ? menuData.customGroupMap : null;
            return (menuData && menuData.customGroupApps)
                ? menuData.customGroupApps(navId) : [];
        }
        if (menuData && menuData.allApps)
            return root.mergeExtraApps(navId, AppsModel.appsInCategory(menuData.allApps, navId));
        return [];
    }

    /** Call when a layout switches to a nav id — asks the backend for fresh
     * recent-file data (side effect kept out of bindings on purpose). */
    function refreshNavData(navId) {
        if (navId === "recent-files" && menuData && menuData.requestRecentFilesRefresh)
            menuData.requestRecentFilesRefresh();
    }

    /** menuData.categories (user order/hidden/renames applied) restricted to
     * the ids a layout wants; pass [] for everything except "all". */
    function categorySubset(allowedIds) {
        if (!menuData || !menuData.categories)
            return [];
        var allowed = {};
        for (var i = 0; i < (allowedIds || []).length; ++i)
            allowed[allowedIds[i]] = true;
        var out = [];
        for (var j = 0; j < menuData.categories.length; ++j) {
            var c = menuData.categories[j];
            if (c.id === "all")
                continue;
            if (!(allowedIds || []).length || allowed[c.id])
                out.push(c);
        }
        return out;
    }

    /** Full system category list (Kickoff / Kicker source), minus synthetic "all". */
    readonly property var standardCategories: root.categorySubset([])

    /** System categories plus user type-groups (bottom section of menu groups). */
    readonly property var typeCategories: {
        var _sig = menuData ? menuData.extrasSignature : "";
        var hidden = (menuData && menuData.hiddenCategoryIds) ? menuData.hiddenCategoryIds : [];
        var cats = root.standardCategories.slice();
        var groups = (menuData && menuData.customTypeGroupDefs)
            ? menuData.customTypeGroupDefs : [];
        var _map = menuData ? menuData.customGroupMap : null;
        for (var i = 0; i < groups.length; ++i) {
            if (!groups[i] || !groups[i].id)
                continue;
            if (hidden.indexOf(groups[i].id) >= 0)
                continue;
            cats.push(groups[i]);
        }
        return cats;
    }

    /** Preference groups (pinned / all-apps / frequent / recent / custom). */
    readonly property var preferenceGroups: {
        var _sig = menuData ? menuData.extrasSignature : "";
        if (menuData && menuData.enabledExtraCategories && menuData.enabledExtraCategories.length)
            return menuData.enabledExtraCategories;
        return [
            { id: "pinned", name: root.tr("Pinned Applications"), icon: "pin" },
            { id: "all-apps", name: root.tr("All Applications"), icon: "view-app-grid-symbolic" }
        ];
    }

    /** Places from Frequent Locations settings (folders and custom files). */
    readonly property var placeShortcuts: {
        var _ = root.uiLang;
        var _sig = menuData ? menuData.extrasSignature : "";
        var places = (menuData && menuData.places && menuData.places.length)
            ? menuData.places : [];
        if (places.length)
            return places;
        return [
            { id: "place-home", name: root.tr("Home"), icon: "user-home", place: "HOME" },
            { id: "place-docs", name: root.tr("Documents"), icon: "folder-documents", place: "DOCUMENTS" },
            { id: "place-dl", name: root.tr("Downloads"), icon: "folder-download", place: "DOWNLOAD" },
            { id: "place-music", name: root.tr("Music"), icon: "folder-music", place: "MUSIC" },
            { id: "place-pics", name: root.tr("Pictures"), icon: "folder-pictures", place: "PICTURES" },
            { id: "place-videos", name: root.tr("Videos"), icon: "folder-videos", place: "VIDEOS" }
        ];
    }

    /** Application shortcuts from settings. */
    readonly property var applicationShortcuts: {
        var _ = root.uiLang;
        var _sig = menuData ? menuData.extrasSignature : "";
        var apps = (menuData && menuData.systemShortcuts && menuData.systemShortcuts.length)
            ? menuData.systemShortcuts : [];
        if (apps.length)
            return apps;
        return [
            { id: "shortcut-software", name: root.tr("Software"), icon: "plasmadiscover", action: "discover" },
            { id: "shortcut-settings", name: root.tr("Settings"), icon: "preferences-system", action: "settings" },
            { id: "shortcut-tweaks", name: root.tr("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel" }
        ];
    }

    /** Places + application shortcuts from settings (Directory / Application Shortcuts). */
    readonly property var sidebarShortcuts: {
        return root.placeShortcuts.concat(root.applicationShortcuts);
    }

    /** Icon-rail copy of a shortcut list (tip from name). */
    function asRailItems(list) {
        var out = [];
        for (var i = 0; i < (list || []).length; ++i) {
            var it = list[i];
            if (!it)
                continue;
            out.push({
                id: it.id,
                name: it.name || "",
                icon: it.icon || "folder",
                tip: it.name || it.tip || "",
                place: it.place || "",
                exec: it.exec || "",
                action: it.action || "",
                path: it.path || "",
                kickerUrl: it.kickerUrl || ""
            });
        }
        return out;
    }

    function appsModel() {
        if (!menuData) {
            return [];
        }
        // Prefer flat results for shared grid helpers; list layouts that want
        // section headers bind menuData.searchResults directly.
        return searching
            ? (menuData.searchResultsFlat || menuData.searchResults)
            : menuData.categoryApps;
    }

    function openArcMenuSettings() {
        if (menuData)
            menuData.requestConfigure();
    }

    /**
     * Shared launcher for pinned / places / shortcuts across all layouts.
     * Handles configure, power actions, place: keys, and normal apps.
     */
    function activateItem(item) {
        if (!item || item.isSection)
            return;
        if (item.action === "configure" || item.id === "arcmenu-settings") {
            root.openArcMenuSettings();
            return;
        }
        if (item.action) {
            powerAction(item.action);
            return;
        }
        appActivated(item);
    }

    Rectangle {
        anchors.fill: parent
        z: -2
        color: root.bg
        border.color: root.borderColor
        border.width: root.borderWidth
        radius: root.radius
    }

    // Catch right-clicks on layout empty space (not on app/shortcut MouseAreas)
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.RightButton
        onPressed: (mouse) => { mouse.accepted = true; }
        onClicked: (mouse) => { mouse.accepted = true; }
    }

    // Every layout inherits one off-screen virtualized viewport. It prepares
    // the shared delegate type and first application icons while the desktop is
    // idle, so layouts do not each maintain their own cold-start workaround.
    Components.LayoutAppList {
        id: sharedAppListPreloader
        layoutRoot: root
        anchors.fill: parent
        z: -3
        opacity: 0
        enabled: false
        items: root.allApplications
    }
}
