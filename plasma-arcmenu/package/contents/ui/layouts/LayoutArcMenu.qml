import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Official ArcMenu shell.
 *
 * Home:  pinned left + places right + "所有应用程序"
 * Apps:  categories left + places right + "返回"
 * Bottom: search + session
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
        if (!item) return;
        if (item.action === "configure") {
            if (menuData) menuData.requestConfigure();
            return;
        }
        if (item.action) {
            root.powerAction(item.action);
            return;
        }
        root.appActivated(item);
    }

    function wirePage(loader) {
        var item = loader.item;
        if (!item)
            return;
        item.menuData = root.menuData;
        item.themeStyle = root.themeStyle;
        if (item.appActivated) {
            try { item.appActivated.disconnect(root.activateShortcut); } catch (e) {}
            item.appActivated.connect(root.activateShortcut);
        }
        if (item.appContextMenu) {
            try { item.appContextMenu.disconnect(root._ctx); } catch (e2) {}
            item.appContextMenu.connect(root._ctx);
        }
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            // ---- LEFT ----
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

                    // Always loaded so first click is instant / no import issues
                    Loader {
                        id: appsLoader
                        anchors.fill: parent
                        visible: root.activePageId === "apps"
                        enabled: visible
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
            }

            // ---- RIGHT ----
            Components.PlacesSidebar {
                Layout.preferredWidth: Math.max(Kirigami.Units.gridUnit * 11, parent.width * 0.36)
                Layout.maximumWidth: Kirigami.Units.gridUnit * 16
                Layout.fillHeight: true
                Layout.fillWidth: false
                menuData: root.menuData
                iconSize: root.categoryIconSize
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onUserClicked: root.userMenu()
                onItemActivated: (item) => root.activateShortcut(item)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Components.SearchField {
                Layout.fillWidth: true
                placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
            }

            Components.SessionButtons {
                menuData: root.menuData
                enabledOptions: root.powerOptions
                onActionRequested: (id) => root.powerAction(id)
            }
        }
    }

    onMenuDataChanged: {
        root.showingApps = false;
        root.wirePage(appsLoader);
        root.wirePage(searchLoader);
    }

    Component.onCompleted: {
        root.wirePage(appsLoader);
        root.wirePage(searchLoader);
    }
}
