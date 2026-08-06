import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Enterprise layout (ArcMenu Enterprise style).
 *
 * Header: user | search
 * Left: pinned / all / categories + session buttons
 * Right: content (pinned as icon grid; lists otherwise)
 */
LayoutBase {
    id: root

    property string enterpriseSelectedId: "pinned"

    readonly property bool searching: menuData ? menuData.isSearching : false
    readonly property bool showPinnedGrid: !root.searching && enterpriseSelectedId === "pinned"
    readonly property int gridIconSize: Math.max(40, root.appIconSize + 12)
    readonly property int gridCellWidth: Kirigami.Units.gridUnit * 5.5
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 1.8

    readonly property var categories: [
        { id: "Office", name: i18n("Office"), icon: "applications-office" },
        { id: "Development", name: i18n("Development"), icon: "applications-development" },
        { id: "Accessories", name: i18n("Accessories"), icon: "applications-accessories" },
        { id: "Utility", name: i18n("Utilities"), icon: "applications-utilities" },
        { id: "Network", name: i18n("Internet"), icon: "applications-internet" },
        { id: "Graphics", name: i18n("Graphics"), icon: "applications-graphics" },
        { id: "System", name: i18n("System Tools"), icon: "applications-system" }
    ]

    readonly property var defaultPinned: [
        {
            id: "org.kde.dolphin.desktop",
            name: i18n("Files"),
            icon: "system-file-manager",
            exec: "dolphin",
            noDisplay: false
        },
        {
            id: "arcmenu-settings",
            name: i18n("ArcMenu Settings"),
            icon: "preferences-system-windows",
            exec: "",
            action: "configure",
            noDisplay: false
        }
    ]

    readonly property var contentItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        if (enterpriseSelectedId === "pinned") {
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (enterpriseSelectedId === "all") {
            if (menuData && menuData.allApps && menuData.allApps.length)
                return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
            return [];
        }
        if (menuData && menuData.allApps)
            return AppsModel.appsInCategory(menuData.allApps, enterpriseSelectedId);
        return [];
    }

    function activateItem(item) {
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

    function selectEnterprise(id) {
        enterpriseSelectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        if (id === "pinned") return;
        if (id === "all") {
            menuData.currentCategoryId = "all";
            return;
        }
        menuData.currentCategoryId = id;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header: user | search
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            spacing: Kirigami.Units.largeSpacing

            PlasmaComponents.ToolButton {
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                icon.width: Kirigami.Units.iconSizes.medium
                icon.height: Kirigami.Units.iconSizes.medium
                Accessible.name: i18n("User")
                onClicked: root.userMenu()
            }

            PlasmaComponents.Label {
                text: (menuData && menuData.userName) ? menuData.userName : i18n("User")
                elide: Text.ElideRight
                font.bold: true
                color: root.fg
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                Layout.maximumWidth: Kirigami.Units.gridUnit * 10
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userMenu()
                }
            }

            Components.SearchField {
                Layout.fillWidth: true
                placeholder: menuData ? menuData.searchPlaceholder : i18n("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            // Left sidebar
            ColumnLayout {
                Layout.preferredWidth: Math.max(Kirigami.Units.gridUnit * 11, parent.width * 0.32)
                Layout.maximumWidth: Kirigami.Units.gridUnit * 15
                Layout.fillHeight: true
                Layout.fillWidth: false
                spacing: Kirigami.Units.smallSpacing / 2

                Flickable {
                    id: sideFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: sideCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: sideCol
                        width: sideFlick.width
                        spacing: Kirigami.Units.smallSpacing / 2

                        Components.ShortcutRow {
                            width: sideCol.width
                            iconName: "pin"
                            label: i18n("Pinned Applications")
                            iconSize: root.categoryIconSize
                            selected: !root.searching && root.enterpriseSelectedId === "pinned"
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            fg: root.fg
                            onActivated: root.selectEnterprise("pinned")
                        }

                        Components.ShortcutRow {
                            width: sideCol.width
                            iconName: "view-app-grid-symbolic"
                            label: i18n("All Applications")
                            iconSize: root.categoryIconSize
                            selected: !root.searching && root.enterpriseSelectedId === "all"
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            fg: root.fg
                            onActivated: root.selectEnterprise("all")
                        }

                        Kirigami.Separator {
                            width: sideCol.width
                            opacity: 0.4
                        }

                        Repeater {
                            model: root.categories.length
                            Components.ShortcutRow {
                                required property int index
                                width: sideCol.width
                                iconName: root.categories[index].icon
                                label: root.categories[index].name
                                iconSize: root.categoryIconSize
                                selected: !root.searching && root.enterpriseSelectedId === root.categories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                fg: root.fg
                                onActivated: root.selectEnterprise(root.categories[index].id)
                            }
                        }
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    opacity: 0.4
                }

                Components.SessionButtons {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    enabledOptions: ["logout", "lock", "restart", "shutdown"]
                    onActionRequested: (id) => root.powerAction(id)
                }
            }

            // Right content
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Pinned icon grid
                Flow {
                    id: pinnedFlow
                    anchors.fill: parent
                    anchors.margins: 0
                    visible: root.showPinnedGrid
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: root.showPinnedGrid ? root.contentItems.length : 0
                        Item {
                            required property int index
                            readonly property var app: root.contentItems[index]
                            width: root.gridCellWidth
                            height: root.gridCellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Kirigami.Units.smallSpacing
                                color: pinMouse.containsMouse ? root.selectedBg : "transparent"
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - Kirigami.Units.smallSpacing * 2
                                spacing: Kirigami.Units.smallSpacing / 2

                                Kirigami.Icon {
                                    source: app.icon || "application-x-executable"
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: root.gridIconSize
                                    Layout.preferredHeight: root.gridIconSize
                                }

                                PlasmaComponents.Label {
                                    text: app.name || ""
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    color: pinMouse.containsMouse ? root.selectedFg : root.fg
                                }
                            }

                            MouseArea {
                                id: pinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (app && !app.action)
                                            root.appContextMenu(app, mouse.x, mouse.y);
                                    } else {
                                        root.activateItem(app);
                                    }
                                }
                            }
                        }
                    }
                }

                // List for all / categories / search
                Flickable {
                    id: listFlick
                    anchors.fill: parent
                    visible: !root.showPinnedGrid
                    contentWidth: width
                    contentHeight: listCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: listCol
                        width: listFlick.width
                        spacing: Kirigami.Units.smallSpacing / 2

                        Repeater {
                            model: root.showPinnedGrid ? 0 : root.contentItems.length
                            Components.AppListItem {
                                required property int index
                                width: listCol.width
                                app: root.contentItems[index]
                                iconSize: Math.max(root.appIconSize, 28)
                                showDescription: false
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                fg: root.fg
                                onActivated: root.activateItem(root.contentItems[index])
                                onContextMenuRequested: (x, y) => {
                                    var a = root.contentItems[index];
                                    if (a && !a.action) root.appContextMenu(a, x, y);
                                }
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.contentItems.length === 0
                    text: root.searching
                          ? i18n("No matching applications found")
                          : (root.enterpriseSelectedId === "pinned"
                             ? i18n("Pin applications from the context menu")
                             : i18n("No applications"))
                    opacity: 0.45
                    color: root.fg
                    width: parent.width * 0.8
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
