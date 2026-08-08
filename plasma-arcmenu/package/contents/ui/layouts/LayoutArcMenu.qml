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
 */
LayoutBase {
    id: root

    /** Local UI mode — avoids flaky QtObject currentPage bindings */
    property bool showingApps: false

    readonly property bool searching: menuData ? menuData.isSearching : false
    readonly property string activePageId: {
        if (root.searching)
            return "search";
        if (root.showingApps)
            return "apps";
        return "home";
    }

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
        root.activateItem(item);
    }

    function resolveCatalog() {
        if (root.menuData)
            return root.menuData;
        // Fallback if LayoutHost passed null (fullRepresentation scope bug)
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
        root.showingApps = true;
        if (appsLoader.item && appsLoader.item.resetToCategories)
            appsLoader.item.resetToCategories();
        if (menuData)
            menuData.navigateTo("apps");
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

    // Single RowLayout: columns run full height (search under left, power under right)
    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- LEFT column ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 14
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Components.PinnedAppsList {
                    anchors.fill: parent
                    visible: root.activePageId === "home"
                    enabled: visible
                    z: visible ? 2 : 0
                    menuData: root.menuData
                    apps: menuData ? menuData.pinnedApps : []
                    iconSize: Math.max(root.appIconSize, 28)
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    fg: root.fg
                    onAppActivated: (app) => root.activateShortcut(app)
                    onAppContextMenu: (app, x, y) => root.appContextMenu(app, x, y)
                }

                Loader {
                    id: appsLoader
                    anchors.fill: parent
                    visible: root.activePageId === "apps"
                    enabled: true
                    z: visible ? 2 : 0
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
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                z: 2
                menuData: root.menuData
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

            Components.SearchField {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
            }
        }

        // ---- RIGHT column ----
        ColumnLayout {
            Layout.preferredWidth: Math.max(Kirigami.Units.gridUnit * 11, parent.width * 0.36)
            Layout.maximumWidth: Kirigami.Units.gridUnit * 16
            Layout.fillHeight: true
            Layout.fillWidth: false
            spacing: Kirigami.Units.smallSpacing

            Components.PlacesSidebar {
                Layout.fillWidth: true
                Layout.fillHeight: true
                menuData: root.menuData
                iconSize: root.categoryIconSize
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onUserClicked: root.userMenu()
                onItemActivated: (item) => root.activateShortcut(item)
                onItemContextMenu: (item, x, y) => root.appContextMenu(item, x, y)
            }

            Components.SessionButtons {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                menuData: root.menuData
                enabledOptions: root.powerOptions
                onActionRequested: (id) => root.powerAction(id)
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
