import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/CatalogBridge.js" as CatalogBridge

/**
 * Official ArcMenu shell — true left/right columns to the bottom edge.
 *
 * Left:  content | 所有应用程序/返回 | search
 * Right: places / shortcuts | session buttons
 * Outer size + sidebar width are drag-resizable (see MenuResizeHandles / split handle).
 */
LayoutBase {
    id: root

    /** Local UI mode — avoids flaky QtObject currentPage bindings */
    property bool showingApps: false

    readonly property string activePageId: {
        if (root.searching)
            return "search";
        if (root.showingApps)
            return "apps";
        return "home";
    }
    readonly property bool showVerticalSep: menuData ? menuData.showVerticalSeparator : false
    readonly property string quickLinkPos: menuData ? menuData.quickLinkPosition : "bottom"
    readonly property var homeQuickLinks: menuData ? menuData.enabledQuickLinks : []

    readonly property var powerOptions: {
        if (!menuData) {
            return ["logout", "lock", "restart", "shutdown"];
        }
        var opts = menuData.powerOptions;
        if (!opts || (opts.length !== undefined && opts.length === 0)) {
            return ["logout", "lock", "restart", "shutdown"];
        }
        return opts;
    }

    function activateShortcut(item) {
        if (!item || item.isSection)
            return;
        if (item.action && String(item.action).indexOf("quicklink:") === 0) {
            root.handleQuickLink(String(item.action).substring(10));
            return;
        }
        // Bookmarks → in-menu list from GTK bookmarks (not bookmarks:/ KIO)
        if (item && (item.special === "bookmarks" || item.id === "place-bookmarks")) {
            root.showingApps = true;
            if (menuData) {
                menuData.navigateTo("apps");
                if (menuData.requestBookmarksRefresh)
                    menuData.requestBookmarksRefresh();
            }
            Qt.callLater(function () {
                if (appsLoader.item)
                    appsLoader.item.openCategory("bookmarks");
            });
            return;
        }
        // External devices → in-menu device list (computer:/ does not exist
        // on Plasma 5/6, so never launch it as a URL)
        if (item && (item.special === "devices" || item.id === "place-devices")) {
            root.showingApps = true;
            if (menuData) {
                menuData.navigateTo("apps");
                if (menuData.requestDevicesRefresh)
                    menuData.requestDevicesRefresh();
            }
            Qt.callLater(function () {
                if (appsLoader.item)
                    appsLoader.item.openCategory("devices");
            });
            return;
        }
        root.activateItem(item);
    }

    function handleQuickLink(id) {
        if (id === "recent-files") {
            root.showingApps = true;
            if (menuData)
                menuData.navigateTo("apps");
            Qt.callLater(function () {
                if (appsLoader.item)
                    appsLoader.item.openCategory("recent-files");
            });
            return;
        }
        if (id === "pinned") {
            root.showingApps = false;
            if (menuData)
                menuData.navigateTo("home");
            return;
        }
        // Custom quick link group → in-menu app list from the group's member ids
        if (String(id).indexOf("qgrp-") === 0) {
            root.showingApps = true;
            if (menuData)
                menuData.navigateTo("apps");
            Qt.callLater(function () {
                if (appsLoader.item)
                    appsLoader.item.openSpecialList(id);
            });
            return;
        }
        // favorites / frequent / all-apps → apps page
        root.showingApps = true;
        if (menuData)
            menuData.navigateTo("apps");
        Qt.callLater(function () {
            if (!appsLoader.item)
                return;
            if (id === "all-apps") {
                if (menuData && menuData.allAppsButtonAction === "all-apps")
                    appsLoader.item.openCategory("all");
                else
                    appsLoader.item.resetToCategories();
            } else if (id === "favorites") {
                appsLoader.item.openSpecialList("favorites");
            } else if (id === "frequent") {
                appsLoader.item.openSpecialList("frequent");
            }
        });
    }

    function resolveCatalog() {
        if (root.menuData)
            return root.menuData;
        try {
            return CatalogBridge.menuData();
        } catch (e) {
            return null;
        }
    }

    function wirePage(loader) {
        var item = loader.item;
        if (!item)
            return;
        var md = root.resolveCatalog();
        item.menuData = md;
        item.themeStyle = root.themeStyle;
        if (item.appActivated) {
            try { item.appActivated.disconnect(root.activateShortcut); } catch (e) {}
            item.appActivated.connect(root.activateShortcut);
        }
        if (item.appContextMenu) {
            try { item.appContextMenu.disconnect(root._ctx); } catch (e2) {}
            item.appContextMenu.connect(root._ctx);
        }
        var n = (md && md.allApps) ? md.allApps.length : 0;
        console.log("ArcMenu wirePage", loader.source, "catalog=", n);
    }

    function reattachCatalog() {
        if (!root.menuData) {
            var bridged = root.resolveCatalog();
            if (bridged)
                root.menuData = bridged;
        }
        root.wirePage(appsLoader);
        root.wirePage(searchLoader);
    }

    function _ctx(app, x, y) {
        if (app && !app.action) {
            root.appContextMenu(app, x, y);
        }
    }

    function openAppsPage() {
        if (menuData)
            menuData.navigateTo("apps");

        // The apps page is kept loaded and prewarmed behind Home. Select the
        // destination synchronously before revealing it, so the click frame
        // never paints the category page or waits for Qt.callLater.
        if (appsLoader.item) {
            if (menuData && menuData.allAppsButtonAction === "all-apps")
                appsLoader.item.openCategory("all");
            else
                appsLoader.item.resetToCategories();
            root.showingApps = true;
            return;
        }

        // Defensive fallback for an unexpected loader delay.
        Qt.callLater(function () {
            if (appsLoader.item) {
                if (menuData && menuData.allAppsButtonAction === "all-apps")
                    appsLoader.item.openCategory("all");
                else
                    appsLoader.item.resetToCategories();
            }
            root.showingApps = true;
        });
    }

    function handleBack() {
        if (root.searching) {
            if (menuData) {
                menuData.setSearch("");
            }
            return;
        }
        if (root.showingApps) {
            if (appsLoader.item && appsLoader.item.canGoBackToCategories) {
                appsLoader.item.goBackToCategories();
                if (menuData)
                    menuData.backToAppCategories();
            } else {
                root.showingApps = false;
                if (menuData)
                    menuData.navigateTo("home");
            }
        }
    }

    component QuickLinksBlock: Column {
        id: qblock
        property var links: []
        width: parent ? parent.width : 0
        spacing: 0
        visible: links && links.length > 0
        height: visible ? implicitHeight : 0

        Repeater {
            model: qblock.links
            Components.ShortcutRow {
                required property var modelData
                width: qblock.width
                iconName: modelData.icon
                label: modelData.name
                iconSize: Math.max(root.appIconSize, 24)
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                preferSymbolic: root.shortcutIconsSymbolic
                showTooltips: root.showTooltips
                onActivated: root.activateShortcut(modelData)
            }
        }
    }

    // Single RowLayout: columns run full height (search under left, power under right)
    RowLayout {
        id: columns
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: root.showVerticalSep ? Kirigami.Units.smallSpacing : 0
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- LEFT column ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Kept small so narrowing the menu shrinks this column instead
            // of pushing the right column outside the menu surface (its old
            // 12-gridUnit minimum made the combined column minimums exceed
            // the 400px menu minimum → overflow).
            Layout.minimumWidth: Kirigami.Units.gridUnit * 8
            spacing: Kirigami.Units.smallSpacing

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
                visible: root.searchOnTop
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // Never paint pages outside this box when the menu is
                // dragged shorter than their natural height.
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing
                    visible: root.activePageId === "home"
                    enabled: visible
                    z: visible ? 2 : 0

                    QuickLinksBlock {
                        Layout.fillWidth: true
                        links: root.quickLinkPos === "top" ? root.homeQuickLinks : []
                    }

                    Components.PinnedAppsList {
                        menuData: root.menuData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        apps: menuData ? menuData.pinnedApps : []
                        iconSize: Math.max(root.appIconSize, 28)
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        showDescription: root.showAppDescriptions
                        showGenericNames: root.showGenericNames
                        multiLineLabels: root.multiLineLabels
                        onAppActivated: (app) => root.activateShortcut(app)
                        onAppContextMenu: (app, x, y) => root.appContextMenu(app, x, y)
                    }

                    QuickLinksBlock {
                        Layout.fillWidth: true
                        links: root.quickLinkPos !== "top" ? root.homeQuickLinks : []
                    }
                }

                Loader {
                    id: appsLoader
                    anchors.fill: parent
                    // Keep the loader effectively visible behind Home so Qt
                    // can build the virtualized first viewport before the
                    // user's first All Applications click.
                    visible: true
                    opacity: root.activePageId === "apps" ? 1 : 0
                    enabled: root.activePageId === "apps"
                    z: enabled ? 2 : 0
                    active: true
                    asynchronous: false
                    source: Qt.resolvedUrl("../pages/ArcAppsPage.qml")
                    onLoaded: root.wirePage(appsLoader)
                    onStatusChanged: {
                        if (status === Loader.Error)
                            console.error("ArcMenu: failed to load ArcAppsPage", source);
                    }
                }

                Loader {
                    id: searchLoader
                    anchors.fill: parent
                    visible: root.activePageId === "search"
                    enabled: visible
                    z: visible ? 2 : 0
                    active: true
                    asynchronous: false
                    source: Qt.resolvedUrl("../pages/ArcSearchPage.qml")
                    onLoaded: root.wirePage(searchLoader)
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                opacity: 0.35
            }

            Components.AllAppsButton {
                id: allAppsBtn
                menuData: root.menuData
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                z: 2
                iconSize: Math.max(root.appIconSize, 24)
                showBack: root.activePageId === "apps" || root.activePageId === "search"
                highlighted: false
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onClicked: {
                    console.log("ArcMenu AllAppsButton click, page=", root.activePageId, "showingApps=", root.showingApps);
                    if (root.activePageId === "home") {
                        root.openAppsPage();
                    } else {
                        root.handleBack();
                    }
                }
            }

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
                visible: !root.searchOnTop
            }
        }

        Kirigami.Separator {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            visible: root.showVerticalSep
            opacity: 0.45
        }

        Components.ColumnSplitHandle {
            Layout.fillHeight: true
            Layout.preferredWidth: implicitWidth
            z: 5
            fg: root.fg
            currentWidth: root.sidebarW
            minWidth: root.sidebarMin
            maxWidth: root.sidebarMax
            sidebarOnRight: true
            flipped: root.flip
            onWidthDragged: (w) => root.setSidebarFromDrag(w)
        }

        // ---- RIGHT column ----
        ColumnLayout {
            Layout.preferredWidth: root.sidebarW
            // Responsive floor: never demand more than ~30% of the menu so
            // the two columns always fit side by side at any dragged width.
            Layout.minimumWidth: root.elasticColumnMin
            Layout.maximumWidth: root.sidebarMax
            Layout.fillHeight: true
            Layout.fillWidth: false
            spacing: Kirigami.Units.smallSpacing

            Components.PlacesSidebar {
                menuData: root.menuData
                Layout.fillWidth: true
                Layout.fillHeight: true
                iconSize: root.shortcutIconSize
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                separatorColor: root.separatorColor
                fg: root.fg
                preferSymbolic: root.shortcutIconsSymbolic
                showTooltips: root.showTooltips
                onUserClicked: root.userMenu()
                onItemActivated: (item) => root.activateShortcut(item)
                onItemContextMenu: (item, x, y) => root.appContextMenu(item, x, y)
            }

            // ArcMenu power-display-style: buttons (default) | list
            Components.SessionButtons {
                menuData: root.menuData
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                visible: !menuData || menuData.powerDisplayStyle !== "list"
                iconSize: root.buttonIconSize
                enabledOptions: root.powerOptions
                onActionRequested: (id) => root.powerAction(id)
            }

            Column {
                Layout.fillWidth: true
                visible: !!(menuData && menuData.powerDisplayStyle === "list")
                spacing: 0
                Repeater {
                    model: root.powerOptions
                    Components.ShortcutRow {
                        required property var modelData
                        width: parent.width
                        readonly property var def: {
                            var map = {
                                "logout": { name: root.tr("Log Out"), icon: "system-log-out" },
                                "lock": { name: root.tr("Lock"), icon: "system-lock-screen" },
                                "restart": { name: root.tr("Restart"), icon: "system-reboot" },
                                "shutdown": { name: root.tr("Shut Down"), icon: "system-shutdown" },
                                "suspend": { name: root.tr("Suspend"), icon: "system-suspend" },
                                "hybridsleep": { name: root.tr("Hybrid Sleep"), icon: "system-suspend-hibernate" },
                                "hibernate": { name: root.tr("Hibernate"), icon: "system-hibernate" },
                                "switchuser": { name: root.tr("Switch User"), icon: "system-switch-user" }
                            };
                            return map[modelData] || { name: String(modelData), icon: "system-run" };
                        }
                        iconName: def.icon
                        label: def.name
                        iconSize: root.buttonIconSize
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        preferSymbolic: root.shortcutIconsSymbolic
                        showTooltips: root.showTooltips
                        onActivated: root.powerAction(modelData)
                    }
                }
            }
        }
    }

    onMenuDataChanged: {
        root.reattachCatalog();
    }

    Component.onCompleted: {
        root.reattachCatalog();
    }
}
