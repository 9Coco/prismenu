import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel
import "../../code/Locale.js" as Locale
import "../../code/CatalogBridge.js" as CatalogBridge

/**
 * ArcMenu apps page (reference):
 * Header "所有应用程序" + fixed category rows (always shown).
 * Click a category → app list; Back returns to categories.
 */
Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    property string drillCategoryId: ""

    readonly property bool showingCategories: drillCategoryId.length === 0
    readonly property bool canGoBackToCategories: drillCategoryId.length > 0

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
    readonly property color selectedBg: themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color selectedFg: themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
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
        var tick = root.refreshTick;
        var _ = root.uiLang;
        var allApps = host && host.allApps ? host.allApps : [];
        var allAppsLen = allApps.length;
        var fromData = (host && host.categories) ? host.categories : [];
        var out = [];
        var i;

        for (i = 0; i < fromData.length; ++i) {
            var c = fromData[i];
            if (!c || !c.id || c.id === "all")
                continue;
            var catName = String(c.name || "").trim();
            if (!catName)
                continue;
            var apps = AppsModel.appsInCategory(allApps, c.id);
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

        if (out.length > 0)
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
        if (root.drillCategoryId.length === 0)
            return [];
        var host = root.dataHost;
        var epoch = host ? host.catalogEpoch : 0;
        var tick = root.refreshTick;
        var _apps = host && host.allApps ? host.allApps : [];
        var cats = root.categoryItems;
        for (var i = 0; i < cats.length; ++i) {
            if (cats[i].id === root.drillCategoryId) {
                if (cats[i].apps && cats[i].apps.length)
                    return cats[i].apps;
                break;
            }
        }
        if (root.drillCategoryId === "all")
            return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(_apps));
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
        var host = root.dataHost;
        if (host)
            host.currentCategoryId = "all";
    }

    function resetToCategories() {
        drillCategoryId = "";
    }

    function openCategory(id) {
        if (!id)
            return;
        // Ensure we hold the live catalog before filtering
        var bridged = CatalogBridge.menuData();
        if (bridged)
            root.menuData = bridged;
        drillCategoryId = id;
        var host = root.dataHost;
        if (host && host.selectCategory)
            host.selectCategory(id);
        var n = root.drilledApps.length;
        var total = (host && host.allApps) ? host.allApps.length : 0;
        console.log("ArcMenu openCategory", id, "→", n, "apps (catalog", total, ")");
    }

    function categoryTitle() {
        // Always keep "All Applications" as the clickable header label
        // (category name is clear from the list context / back target)
        if (root.showingCategories || root.drillCategoryId === "all" || root.drillCategoryId.length === 0)
            return Locale.tr("All Applications", root.uiLang);
        var cats = root.categoryItems;
        for (var i = 0; i < cats.length; ++i) {
            if (cats[i].id === root.drillCategoryId)
                return cats[i].name || Locale.tr("All Applications", root.uiLang);
        }
        return Locale.tr("All Applications", root.uiLang);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header: click "所有应用程序" → list every app (GNOME ArcMenu)
        Item {
            id: appsHeader
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
            Layout.bottomMargin: Kirigami.Units.smallSpacing / 2

            readonly property bool headerClickable: root.showingCategories
                || root.drillCategoryId !== "all"
            readonly property bool headerActive: root.drillCategoryId === "all"
            readonly property bool headerHot: headerMouse.containsMouse || headerActive

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Kirigami.Units.smallSpacing
                color: appsHeader.headerHot ? root.selectedBg : "transparent"
                opacity: appsHeader.headerHot ? 1 : 0
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "view-app-grid-symbolic"
                    Layout.preferredWidth: Math.max(root.categoryIconSize, 24)
                    Layout.preferredHeight: Math.max(root.categoryIconSize, 24)
                    color: appsHeader.headerHot ? root.selectedFg : root.fg
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.categoryTitle()
                    elide: Text.ElideRight
                    font.weight: Font.Medium
                    color: appsHeader.headerHot ? root.selectedFg : root.fg
                }
            }

            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: appsHeader.headerClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: appsHeader.headerClickable
                Accessible.name: Locale.tr("All Applications", root.uiLang)
                Accessible.role: Accessible.Button
                onClicked: {
                    if (root.drillCategoryId !== "all")
                        root.openCategory("all");
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: root.showingCategories
            opacity: 0.35
            Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
        }

        // Category list
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: catColumn.height
            visible: root.showingCategories
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

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
                        visible: !!(catDel.cat && catDel.cat.name)
                        width: catColumn.width
                        height: visible ? Math.max(root.categoryIconSize + Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 2.1) : 0

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: Kirigami.Units.smallSpacing
                            color: catMouse.containsMouse ? root.selectedBg : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Kirigami.Units.smallSpacing
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Components.ResolvedIcon {
                                iconName: (catDel.cat && catDel.cat.icon) ? catDel.cat.icon : "arcmenu-cat-other-apps"
                                tintColor: catMouse.containsMouse ? root.selectedFg : root.fg
                                Layout.preferredWidth: root.categoryIconSize
                                Layout.preferredHeight: root.categoryIconSize
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: (catDel.cat && catDel.cat.name) ? catDel.cat.name : ""
                                elide: Text.ElideRight
                                color: catMouse.containsMouse ? root.selectedFg : root.fg
                            }
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !!(catDel.cat && catDel.cat.id)
                            onClicked: root.openCategory(catDel.cat ? catDel.cat.id : "")
                        }
                    }
                }
            }
        }

        // Apps in selected category
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: appColumn.height
            visible: !root.showingCategories
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: appColumn
                width: parent.width
                spacing: Kirigami.Units.smallSpacing / 2

                Repeater {
                    model: root.drilledApps.length

                    Components.AppListItem {
                        required property int index
                        width: appColumn.width
                        app: root.drilledApps[index]
                        iconSize: root.appIconSize
                        showDescription: false
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.appActivated(root.drilledApps[index])
                        onContextMenuRequested: (x, y) => root.appContextMenu(root.drilledApps[index], x, y)
                    }
                }

                PlasmaComponents.Label {
                    visible: root.drilledApps.length === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.55
                    text: Locale.tr("No applications", root.uiLang)
                    color: root.fg
                }
            }
        }
    }
}
