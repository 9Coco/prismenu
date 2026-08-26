import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel
import "../../code/Locale.js" as Locale
import "../../code/CatalogBridge.js" as CatalogBridge
import "../../code/ShortcutsConfig.js" as ShortcutsConfig

/**
 * ArcMenu apps page (reference):
 * Extra categories (from settings) sit above normal categories, then a separator.
 * “All Applications” is an optional extra-category row — not a permanent header.
 * Header chrome appears only when drilled into a list (back + title).
 */
Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    property string drillCategoryId: ""
    /** favorites | frequent | empty — special lists outside normal categories */
    property string specialListId: ""

    readonly property bool showingCategories: drillCategoryId.length === 0 && specialListId.length === 0
    readonly property bool canGoBackToCategories: drillCategoryId.length > 0 || specialListId.length > 0

    /** Always prefer live catalog (property or CatalogBridge) */
    readonly property var dataHost: {
        var local = root.menuData;
        if (local && local.allApps && local.allApps.length)
            return local;
        var bridged = CatalogBridge.menuData();
        if (bridged)
            return bridged;
        return local;
    }

    readonly property color fg: themeStyle.fg || Kirigami.Theme.textColor
    readonly property color selectedBg: themeStyle.activeBg || themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color selectedFg: themeStyle.activeFg || themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    readonly property color hoverBg: themeStyle.hoverBg || root.selectedBg
    readonly property color hoverFg: themeStyle.hoverFg || root.selectedFg
    readonly property color separatorColor: themeStyle.separator || Kirigami.Theme.disabledTextColor
    readonly property int appIconSize: {
        var n = dataHost ? dataHost.appIconSize : 24;
        n = parseInt(n, 10);
        return (!n || isNaN(n)) ? 24 : Math.max(16, n);
    }
    readonly property int categoryIconSize: {
        var n = dataHost ? dataHost.categoryIconSize : 24;
        n = parseInt(n, 10);
        return (!n || isNaN(n)) ? 24 : Math.max(16, n);
    }
    readonly property string uiLang: (dataHost && dataHost.uiLang) ? dataHost.uiLang : "zh_CN"

    // Prefer MenuData categories; fall back to a short fixed list while scanning.
    readonly property var categoryItems: {
        var host = root.dataHost;
        var epoch = host ? host.catalogEpoch : 0; // binding dependency
        var structure = host ? host.structureEpoch : 0;
        var extrasSig = host ? host.extrasSignature : "";
        // Also bind plasmoid.configuration directly (config dialog → live menu)
        var liveEnabled = plasmoid.configuration.ExtraCategoriesEnabled;
        var liveOrder = plasmoid.configuration.ExtraCategoriesOrder;
        var liveUserSet = plasmoid.configuration.ExtraCategoriesUserSet;
        var tick = root.refreshTick;
        var _ = root.uiLang;
        var allApps = host && host.allApps ? host.allApps : [];
        var allAppsLen = allApps.length;
        var fromData = (host && host.categories) ? host.categories : [];
        var out = [];
        var i;

        // Prefer live config; until userSet, empty/missing lists use GNOME defaults
        var extras = [];
        var userSet = false;
        try { userSet = !!plasmoid.configuration.ExtraCategoriesUserSet; } catch (e0) {}
        var order = ShortcutsConfig.normalizeList(liveOrder, ShortcutsConfig.DEFAULT_EXTRA_ORDER);
        var enabled = ShortcutsConfig.effectiveExtraEnabled(liveEnabled, userSet);
        for (i = 0; i < order.length; ++i) {
            var eid = order[i];
            if (!eid || eid === "favorites" || enabled.indexOf(eid) < 0)
                continue;
            var ename = eid;
            var eicon = "applications-other";
            if (eid === "frequent") { ename = Locale.tr("Frequent Apps", _); eicon = "view-calendar"; }
            else if (eid === "all-apps") { ename = Locale.tr("All Applications", _); eicon = "view-app-grid-symbolic"; }
            else if (eid === "pinned") { ename = Locale.tr("Pinned Applications", _); eicon = "pin"; }
            else if (eid === "recent-files") { ename = Locale.tr("Recent Files", _); eicon = "document-open-recent"; }
            extras.push({ id: eid, name: ename, icon: eicon, extra: true });
        }
        if (!extras.length && host && host.enabledExtraCategories)
            extras = host.enabledExtraCategories;
        var extrasShown = 0;
        for (i = 0; i < extras.length; ++i) {
            var ex = extras[i];
            if (!ex || !ex.id)
                continue;
            out.push({
                id: ex.id,
                name: ex.name,
                icon: ex.icon || "applications-other",
                apps: [],
                appCount: 0,
                extra: true
            });
            extrasShown++;
        }
        if (extrasShown > 0) {
            out.push({
                id: "__extra_sep__",
                name: "",
                icon: "",
                apps: [],
                appCount: 0,
                separator: true
            });
        }

        for (i = 0; i < fromData.length; ++i) {
            var c = fromData[i];
            if (!c || !c.id || c.id === "all")
                continue;
            var catName = String(c.name || "").trim();
            if (!catName)
                continue;
            // MenuData already buckets and sorts each category. Reuse that
            // cached result instead of filtering and sorting the full catalog
            // again every time this page binding is evaluated.
            var apps = (c.apps !== undefined && c.apps !== null)
                ? c.apps
                : AppsModel.appsInCategory(allApps, c.id);
            if (apps.length === 0 && allAppsLen > 0)
                continue;
            out.push({
                id: c.id,
                name: catName,
                icon: c.icon || "arcmenu-cat-other-apps",
                apps: apps,
                appCount: apps.length
            });
        }

        if (out.length > extrasShown + (extrasShown > 0 ? 1 : 0))
            return out;

        var preferred = [
            { id: "Office", name: Locale.tr("Office", _), icon: "arcmenu-cat-office-barchart" },
            { id: "Development", name: Locale.tr("Programming", _), icon: "arcmenu-cat-dev-brush" },
            { id: "Utility", name: Locale.tr("Tools", _), icon: "arcmenu-cat-tools-build" },
            { id: "Network", name: Locale.tr("Internet", _), icon: "arcmenu-cat-internet-public" },
            { id: "Graphics", name: Locale.tr("Graphics", _), icon: "arcmenu-cat-graphics-image" },
            { id: "System", name: Locale.tr("System Tools", _), icon: "arcmenu-cat-system-settings" }
        ];
        for (i = 0; i < preferred.length; ++i) {
            var def = preferred[i];
            var list = AppsModel.appsInCategory(allApps, def.id);
            if (allAppsLen > 0 && list.length === 0)
                continue;
            out.push({
                id: def.id,
                name: def.name,
                icon: def.icon,
                apps: list,
                appCount: list.length
            });
        }
        return out;
    }

    readonly property var drilledApps: {
        var host = root.dataHost;
        var epoch = host ? host.catalogEpoch : 0;
        var tick = root.refreshTick;
        if (root.specialListId === "favorites" || root.specialListId === "pinned") {
            // Same pin list for now (Plasma favorites sync); labels differ by specialListId
            var _pl = (host && host.pinnedApps) ? host.pinnedApps : [];
            var _ids = [];
            for (var pi = 0; pi < _pl.length; ++pi)
                _ids.push(_pl[pi] ? _pl[pi].id : "?");
            console.log("ArcMenu drilled", root.specialListId, "→", _pl.length, "pinned:", _ids.join(","));
            return _pl;
        }
        if (root.specialListId === "frequent") {
            return (host && host.recentApps) ? host.recentApps : [];
        }
        if (root.specialListId.indexOf("qgrp-") === 0) {
            // Custom quick link group — resolve member ids via the live catalog
            var _gl = (host && host.customGroupApps) ? host.customGroupApps(root.specialListId) : [];
            console.log("ArcMenu drilled", root.specialListId, "→", _gl.length, "group apps");
            return _gl;
        }
        if (root.specialListId === "recent-files") {
            var _rf = host ? host.recentFilesEpoch : 0;
            // Prefer MenuData cache; also ask backend refresh via request on open
            var list = (host && host.recentFileResults) ? host.recentFileResults : [];
            return list;
        }
        if (root.specialListId === "bookmarks") {
            var _bm = host ? host.bookmarksEpoch : 0;
            return (host && host.bookmarkResults) ? host.bookmarkResults : [];
        }
        if (root.specialListId === "devices") {
            var _dv = host ? host.devicesEpoch : 0;
            return (host && host.deviceEntries) ? host.deviceEntries : [];
        }
        if (root.drillCategoryId.length === 0)
            return [];
        var _apps = host && host.allApps ? host.allApps : [];
        var cats = root.categoryItems;
        for (var i = 0; i < cats.length; ++i) {
            if (cats[i].id === root.drillCategoryId) {
                if (cats[i].apps && cats[i].apps.length)
                    return cats[i].apps;
                break;
            }
        }
        if (root.drillCategoryId === "all") {
            if (host && host.sortedVisibleApps)
                return host.sortedVisibleApps;
            return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(_apps));
        }
        return AppsModel.appsInCategory(_apps, root.drillCategoryId);
    }

    property int refreshTick: 0

    // Pragma-library bridge is not a QML notify source — poll until catalog arrives
    Timer {
        id: bridgePoll
        interval: 250
        repeat: true
        running: true
        property int lastEpoch: -1
        onTriggered: {
            var host = CatalogBridge.menuData();
            var ep = host ? host.catalogEpoch : 0;
            var n = host && host.allApps ? host.allApps.length : 0;
            if (ep !== lastEpoch || (n > 0 && root.menuData !== host)) {
                lastEpoch = ep;
                if (host)
                    root.menuData = host;
                root.refreshTick++;
            }
            if (n > 0 && ep > 0) {
                bridgePoll.stop();
                console.log("ArcMenu ArcAppsPage catalog ready:", n, "epoch", ep);
            }
        }
    }

    function goBackToCategories() {
        drillCategoryId = "";
        specialListId = "";
        var host = root.dataHost;
        if (host)
            host.currentCategoryId = "all";
    }

    function resetToCategories() {
        drillCategoryId = "";
        specialListId = "";
    }

    function openSpecialList(id) {
        var bridged = CatalogBridge.menuData();
        if (bridged)
            root.menuData = bridged;
        specialListId = id || "";
        drillCategoryId = "";
    }

    function openCategory(id) {
        if (!id)
            return;
        // Ensure we hold the live catalog before filtering
        var bridged = CatalogBridge.menuData();
        if (bridged)
            root.menuData = bridged;

        if (id === "__extra_sep__")
            return;
        if (id === "pinned") {
            root.openSpecialList("pinned");
            return;
        }
        if (id === "favorites") {
            root.openSpecialList("favorites");
            return;
        }
        if (id === "frequent") {
            root.openSpecialList("frequent");
            return;
        }
        if (id === "all-apps" || id === "all") {
            specialListId = "";
            drillCategoryId = "all";
            var hostAll = root.dataHost;
            if (hostAll && hostAll.selectCategory)
                hostAll.selectCategory("all");
            return;
        }
        if (id === "recent-files") {
            // Show GTK recently-used.xbel list inside the menu (recent:/ KIO often fails on Plasma)
            if (bridged && bridged.requestRecentFilesRefresh)
                bridged.requestRecentFilesRefresh();
            root.openSpecialList("recent-files");
            return;
        }
        if (id === "bookmarks" || id === "place-bookmarks") {
            if (bridged && bridged.requestBookmarksRefresh)
                bridged.requestBookmarksRefresh();
            root.openSpecialList("bookmarks");
            return;
        }
        if (id === "devices" || id === "place-devices") {
            // computer:/ does not exist on Plasma 5/6 — drill into the
            // live device list (KFilePlacesModel devices or /media scan)
            if (bridged && bridged.requestDevicesRefresh)
                bridged.requestDevicesRefresh();
            root.openSpecialList("devices");
            return;
        }

        specialListId = "";
        drillCategoryId = id;
        var host = root.dataHost;
        if (host && host.selectCategory)
            host.selectCategory(id);
        var n = root.drilledApps.length;
        var total = (host && host.allApps) ? host.allApps.length : 0;
        console.log("ArcMenu openCategory", id, "→", n, "apps (catalog", total, ")");
    }

    function categoryTitle() {
        if (root.specialListId === "pinned")
            return Locale.tr("Pinned Applications", root.uiLang);
        if (root.specialListId === "favorites")
            return Locale.tr("Favorites", root.uiLang);
        if (root.specialListId === "frequent")
            return Locale.tr("Frequent Apps", root.uiLang);
        if (root.specialListId === "recent-files")
            return Locale.tr("Recent Files", root.uiLang);
        if (root.specialListId === "bookmarks")
            return Locale.tr("Bookmarks", root.uiLang);
        if (root.specialListId === "devices")
            return Locale.tr("External devices", root.uiLang);
        if (root.specialListId.indexOf("qgrp-") === 0) {
            var qHost = root.dataHost;
            if (qHost && qHost.customQuickLinkDefs) {
                for (var qi = 0; qi < qHost.customQuickLinkDefs.length; ++qi) {
                    if (qHost.customQuickLinkDefs[qi].id === root.specialListId)
                        return qHost.customQuickLinkDefs[qi].name;
                }
            }
            return "";
        }
        if (root.drillCategoryId === "all")
            return Locale.tr("All Applications", root.uiLang);
        if (root.showingCategories)
            return "";
        var cats = root.categoryItems;
        for (var i = 0; i < cats.length; ++i) {
            if (cats[i].id === root.drillCategoryId)
                return cats[i].name || Locale.tr("All Applications", root.uiLang);
        }
        return Locale.tr("All Applications", root.uiLang);
    }

    function categoryHeaderIcon() {
        if (root.specialListId === "pinned")
            return "pin";
        if (root.specialListId === "favorites")
            return "emblem-favorite";
        if (root.specialListId === "frequent")
            return "view-calendar";
        if (root.specialListId === "recent-files")
            return "document-open-recent";
        if (root.specialListId === "bookmarks")
            return "bookmarks";
        if (root.specialListId === "devices")
            return "drive-removable-media";
        if (root.specialListId.indexOf("qgrp-") === 0) {
            var iHost = root.dataHost;
            if (iHost && iHost.customQuickLinkDefs) {
                for (var ii = 0; ii < iHost.customQuickLinkDefs.length; ++ii) {
                    if (iHost.customQuickLinkDefs[ii].id === root.specialListId)
                        return iHost.customQuickLinkDefs[ii].icon || "folder-favorites";
                }
            }
            return "folder-favorites";
        }
        if (root.drillCategoryId === "all")
            return "view-app-grid-symbolic";
        if (root.showingCategories)
            return "";
        var cats = root.categoryItems;
        for (var i = 0; i < cats.length; ++i) {
            if (cats[i].id === root.drillCategoryId)
                return cats[i].icon || "applications-other";
        }
        return "applications-other";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header only when drilled — category list has no permanent “All Applications” chrome.
        Item {
            id: appsHeader
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? Kirigami.Units.gridUnit * 2.0 : 0
            Layout.bottomMargin: visible ? Kirigami.Units.smallSpacing : 0
            visible: !root.showingCategories

            readonly property bool headerHot: headerMouse.containsMouse

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Kirigami.Units.smallSpacing
                color: appsHeader.headerHot
                    ? root.selectedBg
                    : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "go-previous-symbolic"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    color: appsHeader.headerHot ? root.selectedFg : root.fg
                    opacity: appsHeader.headerHot ? 1 : 0.75
                }

                Components.ResolvedIcon {
                    iconName: root.categoryHeaderIcon()
                    tintColor: appsHeader.headerHot ? root.selectedFg : root.fg
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    opacity: appsHeader.headerHot ? 1 : 0.9
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.categoryTitle()
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                    opacity: appsHeader.headerHot ? 1 : 0.85
                    color: appsHeader.headerHot ? root.selectedFg : root.fg
                }
            }

            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.name: Locale.tr("Back", root.uiLang) + " — " + root.categoryTitle()
                Accessible.role: Accessible.Button
                onClicked: root.goBackToCategories()
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            opacity: 0.4
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            visible: !root.showingCategories
        }

        // Both views share the same geometry. Keeping them instantiated and
        // switching opacity avoids a cold layout/delegate pass on first use.
        Item {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Category list
            Flickable {
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: catColumn.height
                visible: true
                opacity: root.showingCategories ? 1 : 0
                enabled: root.showingCategories
                z: enabled ? 1 : 0
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.dataHost }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

                Column {
                    id: catColumn
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: root.categoryItems.length

                        Item {
                            id: catDel
                            required property int index
                            readonly property var cat: root.categoryItems[index]
                            readonly property bool isSep: !!(catDel.cat && catDel.cat.separator)
                            visible: !!(catDel.cat && (catDel.cat.separator || catDel.cat.name))
                            width: catColumn.width
                            height: {
                                if (!visible)
                                    return 0;
                                if (catDel.isSep)
                                    return Kirigami.Units.smallSpacing * 3;
                                return Math.max(root.categoryIconSize + Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 2.1);
                            }

                            Kirigami.Separator {
                                visible: catDel.isSep
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Kirigami.Units.smallSpacing
                                anchors.rightMargin: Kirigami.Units.smallSpacing
                                opacity: 0.45
                            }

                            Rectangle {
                                visible: !catDel.isSep
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Kirigami.Units.smallSpacing
                                color: catMouse.containsMouse ? root.hoverBg : "transparent"
                            }

                            RowLayout {
                                visible: !catDel.isSep
                                anchors.fill: parent
                                anchors.leftMargin: Kirigami.Units.smallSpacing
                                anchors.rightMargin: Kirigami.Units.smallSpacing
                                spacing: Kirigami.Units.smallSpacing

                                Components.ResolvedIcon {
                                    iconName: (catDel.cat && catDel.cat.icon) ? catDel.cat.icon : "arcmenu-cat-other-apps"
                                    tintColor: catMouse.containsMouse ? root.hoverFg : root.fg
                                    preferSymbolic: !(root.dataHost) || root.dataHost.categoryIconsSymbolic !== false
                                    Layout.preferredWidth: root.categoryIconSize
                                    Layout.preferredHeight: root.categoryIconSize
                                }

                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: (catDel.cat && catDel.cat.name) ? catDel.cat.name : ""
                                    elide: Text.ElideRight
                                    color: catMouse.containsMouse ? root.hoverFg : root.fg
                                }
                            }

                            MouseArea {
                                id: catMouse
                                anchors.fill: parent
                                hoverEnabled: !catDel.isSep
                                cursorShape: catDel.isSep ? Qt.ArrowCursor : Qt.PointingHandCursor
                                enabled: !catDel.isSep && !!(catDel.cat && catDel.cat.id)
                                onClicked: root.openCategory(catDel.cat ? catDel.cat.id : "")
                            }
                        }
                    }
                }
            }

            // Apps in selected category. A single virtualized ListView is important
            // here: the old nested Repeaters created every icon/row at once and
            // synchronously destroyed all of them when Back cleared drilledApps.
            Components.VirtualizedAppList {
                id: appList
                anchors.fill: parent
                visible: true
                opacity: root.showingCategories ? 0 : 1
                enabled: !root.showingCategories
                z: enabled ? 1 : 0
                Accessible.name: root.categoryTitle()

                readonly property bool useAz: {
                    var host = root.dataHost;
                    return !!(host && host.groupAppsAlphabeticallyList
                        && (root.drillCategoryId === "all" || root.specialListId === "frequent"));
                }
                readonly property var displayRows: {
                    var host = root.dataHost;

                    // Keep the default all-apps model attached while the category
                    // browser/home page is showing. After a fresh Plasma start this
                    // lets ListView prepare its first viewport during idle time,
                    // instead of building the model and delegates on the first click.
                    // It also keeps those delegates warm when navigating Back.
                    if (root.showingCategories) {
                        if (!host)
                            return [];
                        return host.groupAppsAlphabeticallyList
                            ? (host.sortedVisibleAppsAzRows || [])
                            : (host.sortedVisibleApps || []);
                    }

                    if (!useAz)
                        return root.drilledApps;
                    if (root.drillCategoryId === "all" && host && host.sortedVisibleAppsAzRows)
                        return host.sortedVisibleAppsAzRows;
                    return AppsModel.appsAzRowsFromSorted(root.drilledApps);
                }

                items: displayRows
                menuData: root.menuData || root.dataHost
                iconSize: root.appIconSize
                showDescription: !!(root.dataHost && root.dataHost.showAppDescriptions)
                showGenericNames: !!(root.dataHost && root.dataHost.showGenericNames)
                multiLineLabels: !(root.dataHost) || root.dataHost.multiLineLabels !== false
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                onAppActivated: (app) => root.appActivated(app)
                onAppContextMenu: (app, x, y) => root.appContextMenu(app, x, y)

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.drilledApps.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.55
                    text: Locale.tr("No applications", root.uiLang)
                    color: root.fg
                }
            }
        }
    }
}
