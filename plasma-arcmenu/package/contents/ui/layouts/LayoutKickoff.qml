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
        case 3: return [
            { id: "place-home", name: i18n("Home"), icon: "user-home", exec: "xdg-open $HOME", categories: ["Places"], keywords: [], genericName: i18n("Home folder"), noDisplay: false },
            { id: "place-docs", name: i18n("Documents"), icon: "folder-documents", exec: "xdg-open xdg:Documents", categories: ["Places"], keywords: [], genericName: i18n("Documents"), noDisplay: false },
            { id: "place-dl", name: i18n("Downloads"), icon: "folder-download", exec: "xdg-open xdg:Download", categories: ["Places"], keywords: [], genericName: i18n("Downloads"), noDisplay: false },
            { id: "place-root", name: i18n("Root"), icon: "folder-root", exec: "xdg-open /", categories: ["Places"], keywords: [], genericName: i18n("File system"), noDisplay: false }
        ];
        case 4: return [
            { id: "leave-lock", name: i18n("Lock"), icon: "system-lock-screen", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "lock" },
            { id: "leave-logout", name: i18n("Log Out"), icon: "system-log-out", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "logout" },
            { id: "leave-suspend", name: i18n("Suspend"), icon: "system-suspend", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "suspend" },
            { id: "leave-restart", name: i18n("Restart"), icon: "system-reboot", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "restart" },
            { id: "leave-shutdown", name: i18n("Shut Down"), icon: "system-shutdown", exec: "", categories: ["Leave"], keywords: [], genericName: "", noDisplay: false, action: "shutdown" }
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
            placeholder: menuData ? menuData.searchPlaceholder : i18n("Search applications…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing / 2

                Repeater {
                    model: [
                        { id: 0, name: i18n("Favorites"), icon: "bookmarks" },
                        { id: 1, name: i18n("Recent"), icon: "view-history" },
                        { id: 2, name: i18n("Applications"), icon: "applications-all" },
                        { id: 3, name: i18n("Places"), icon: "folder" },
                        { id: 4, name: i18n("Leave"), icon: "system-shutdown" }
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
                    onActivated: {
                        if (model.action) {
                            root.powerAction(model.action);
                        } else {
                            root.appActivated(model);
                        }
                    }
                    onContextMenuRequested: (x, y) => {
                        if (!model.action) {
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
