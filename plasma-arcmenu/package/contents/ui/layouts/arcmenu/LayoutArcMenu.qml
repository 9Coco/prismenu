import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Official ArcMenu shell.
 *
 * Left  = page display (home pins / apps / search)
 * Right = functional PlacesSidebar
 * Bottom = search + session buttons
 */
LayoutBase {
    id: root

    readonly property string activePageId: {
        if (!menuData) return "home";
        if (menuData.isSearching) return "search";
        if (menuData.currentPage === "apps" || menuData.showAllApps) return "apps";
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

    function wireLoader(loader) {
        var item = loader.item;
        if (!item) return;
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            // ---- LEFT: page display ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 14
                spacing: Kirigami.Units.smallSpacing

                // Home page (pinned) — direct component, always reliable
                Components.PinnedAppsList {
                    visible: root.activePageId === "home"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    menuData: root.menuData
                    apps: menuData ? menuData.pinnedApps : []
                    iconSize: Math.max(root.appIconSize, 28)
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    hoverBg: root.hoverBg
                    hoverFg: root.hoverFg
                    fg: root.fg
                    onAppActivated: (app) => root.activateShortcut(app)
                    onAppContextMenu: (app, x, y) => root.appContextMenu(app, x, y)
                }

                // Apps page
                Loader {
                    id: appsLoader
                    visible: root.activePageId === "apps"
                    active: root.activePageId === "apps" || status === Loader.Ready
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    asynchronous: false
                    source: Qt.resolvedUrl("../pages/ArcAppsPage.qml")
                    onLoaded: root.wireLoader(appsLoader)
                }

                // Search page
                Loader {
                    id: searchLoader
                    visible: root.activePageId === "search"
                    active: root.activePageId === "search" || status === Loader.Ready
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    asynchronous: false
                    source: Qt.resolvedUrl("../pages/ArcSearchPage.qml")
                    onLoaded: root.wireLoader(searchLoader)
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    opacity: 0.35
                }

                Components.AllAppsButton {
                    menuData: root.menuData
                    iconSize: Math.max(root.appIconSize, 24)
                    showBack: root.activePageId === "apps"
                    highlighted: root.activePageId === "apps"
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    hoverBg: root.hoverBg
                    hoverFg: root.hoverFg
                    fg: root.fg
                    onClicked: {
                        if (!menuData) return;
                        if (root.activePageId === "search") {
                            menuData.setSearch("");
                            menuData.navigateTo("home");
                        } else if (root.activePageId === "apps") {
                            menuData.navigateTo("home");
                        } else {
                            menuData.navigateTo("apps");
                        }
                    }
                }
            }

            // ---- RIGHT: functional sidebar ----
            Components.PlacesSidebar {
                Layout.preferredWidth: Math.max(Kirigami.Units.gridUnit * 11, parent.width * 0.36)
                Layout.maximumWidth: Kirigami.Units.gridUnit * 16
                Layout.fillHeight: true
                Layout.fillWidth: false
                menuData: root.menuData
                iconSize: root.categoryIconSize
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                onUserClicked: root.userMenu()
                onItemActivated: (item) => root.activateShortcut(item)
            }
        }

        // ---- BOTTOM ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Components.SearchField {
                Layout.fillWidth: true
                placeholder: menuData ? menuData.searchPlaceholder : i18n("Search…")
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
        wireLoader(appsLoader);
        wireLoader(searchLoader);
    }

    onThemeStyleChanged: {
        wireLoader(appsLoader);
        wireLoader(searchLoader);
    }
}
