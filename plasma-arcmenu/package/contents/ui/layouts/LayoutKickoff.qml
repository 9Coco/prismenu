import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

LayoutBase {
    id: root

    readonly property int tab: menuData ? menuData.kickoffTab : 0

    function tabApps() {
        if (!menuData) return [];
        if (menuData.isSearching) return menuData.searchResults;
        switch (tab) {
        case 0: return menuData.pinnedApps;
        case 1: return menuData.recentApps;
        case 2: return menuData.categoryApps;
        case 3: {
            var places = (menuData.places || []).slice();
            places.push({
                id: "place-root",
                name: root.tr("Root"),
                icon: "folder-root",
                exec: "xdg-open /",
                categories: ["Places"],
                keywords: [],
                genericName: root.tr("File system"),
                noDisplay: false
            });
            return places;
        }
        case 4: return [
            { id: "leave-lock", name: root.tr("Lock"), icon: "system-lock-screen", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "lock" },
            { id: "leave-logout", name: root.tr("Log Out"), icon: "system-log-out", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "logout" },
            { id: "leave-suspend", name: root.tr("Suspend"), icon: "system-suspend", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "suspend" },
            { id: "leave-restart", name: root.tr("Restart"), icon: "system-reboot", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "restart" },
            { id: "leave-shutdown", name: root.tr("Shut Down"), icon: "system-shutdown", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "shutdown" }
        ];
        }
        return menuData.categoryApps;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.SearchField {
            Layout.fillWidth: true
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            ColumnLayout {
                Layout.preferredWidth: root.sidebarW
                Layout.minimumWidth: 120
                Layout.maximumWidth: Math.min(root.sidebarMax, 280)
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing / 2

                Repeater {
                    model: [
                        { id: 0, name: root.tr("Favorites"), icon: "bookmarks" },
                        { id: 1, name: root.tr("Recent"), icon: "view-history" },
                        { id: 2, name: root.tr("Applications"), icon: "applications-all" },
                        { id: 3, name: root.tr("Places"), icon: "folder" },
                        { id: 4, name: root.tr("Leave"), icon: "system-shutdown" }
                    ]
                    PlasmaComponents.ToolButton {
                        required property var model
                        Layout.fillWidth: true
                        text: model.name
                        icon.name: model.icon
                        checkable: true
                        checked: root.tab === model.id
                        onClicked: if (menuData) menuData.kickoffTab = model.id
                        Accessible.name: model.name
                    }
                }
                Item { Layout.fillHeight: true }
            }

            Components.ColumnSplitHandle {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                z: 5
                fg: root.fg
                currentWidth: root.sidebarW
                minWidth: 120
                maxWidth: Math.min(root.sidebarMax, 280)
                sidebarOnRight: false
                flipped: false
                onWidthDragged: (w) => root.setSidebarFromDrag(w)
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: appModel
                delegate: Components.AppListItem {
                    width: appList.width
                    app: model
                    iconSize: root.appIconSize
                    showDescription: menuData ? menuData.showSearchDescription : true
                    selected: appList.currentIndex === index
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    fg: root.fg
                    onActivated: root.activateItem(model)
                    onContextMenuRequested: (x, y) => {
                        if (!model.action && !model.place) {
                            root.appContextMenu(model, x, y);
                        }
                    }
                }
            }
        }

        Components.SystemActionsBar {
            Layout.fillWidth: true
            enabledOptions: menuData ? menuData.powerOptions : []
            userName: menuData ? menuData.userName : ""
            userIcon: menuData ? menuData.userIcon : "user-identity"
            onActionRequested: (id) => root.powerAction(id)
            onUserMenuRequested: root.userMenu()
        }
    }

    Ui.ListModelBridge { id: appModel; source: root.tabApps() }
}
