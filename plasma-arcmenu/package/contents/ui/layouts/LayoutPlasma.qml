import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Plasma layout (ArcMenu Plasma style).
 *
 * Header: avatar + username + search
 * Middle: list for active tab (top-aligned)
 * Footer: compact Pinned | Applications | Computer | Leave
 */
LayoutBase {
    id: root

    property int plasmaTab: 0 // 0 pinned, 1 apps, 2 computer, 3 leave

    readonly property bool searching: menuData ? menuData.isSearching : false
    readonly property int footerHeight: Kirigami.Units.gridUnit * 3.8

    readonly property var defaultPinned: [
        {
            id: "org.kde.dolphin.desktop",
            name: root.tr("Files"),
            icon: "system-file-manager",
            exec: "dolphin",
            noDisplay: false
        },
        {
            id: "arcmenu-settings",
            name: root.tr("ArcMenu Settings"),
            icon: "preferences-system-windows",
            exec: "",
            action: "configure",
            noDisplay: false
        }
    ]

    readonly property var leaveItems: [
        { id: "leave-lock", name: root.tr("Lock"), icon: "system-lock-screen", action: "lock", noDisplay: false },
        { id: "leave-logout", name: root.tr("Log Out"), icon: "system-log-out", action: "logout", noDisplay: false },
        { id: "leave-suspend", name: root.tr("Suspend"), icon: "system-suspend", action: "suspend", noDisplay: false },
        { id: "leave-restart", name: root.tr("Restart"), icon: "system-reboot", action: "restart", noDisplay: false },
        { id: "leave-shutdown", name: root.tr("Shut Down"), icon: "system-shutdown", action: "shutdown", noDisplay: false }
    ]

    readonly property var tabs: [
        { id: 0, name: root.tr("Pinned"), icon: "preferences-system-windows" },
        { id: 1, name: root.tr("Applications"), icon: "view-app-grid-symbolic" },
        { id: 2, name: root.tr("Computer"), icon: "computer" },
        { id: 3, name: root.tr("Leave"), icon: "system-shutdown" }
    ]

    readonly property var contentItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        if (plasmaTab === 0) {
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (plasmaTab === 1) {
            if (menuData && menuData.allApps && menuData.allApps.length)
                return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
            return [];
        }
        if (plasmaTab === 2) {
            return (menuData && menuData.places) ? menuData.places : [];
        }
        return root.leaveItems;
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

    function selectTab(id) {
        plasmaTab = id;
        if (menuData)
            menuData.setSearch("");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header: avatar | (username above search)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3.2
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.8
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.8
                Layout.alignment: Qt.AlignVCenter
                Components.UserFace {
                    anchors.fill: parent
                    userIcon: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                    fallbackColor: root.fg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    Accessible.name: root.tr("User")
                    onClicked: root.userMenu()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                spacing: 2

                PlasmaComponents.Label {
                    text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                    elide: Text.ElideRight
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: root.fg
                    opacity: 0.85
                    Layout.fillWidth: true
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.userMenu()
                    }
                }

                Components.SearchField {
                    Layout.fillWidth: true
                    placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
                    text: menuData ? menuData.searchQuery : ""
                    onTextChanged: if (menuData) menuData.setSearch(text)
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.fillHeight: false
            opacity: 0.35
        }

        // Middle content — takes all leftover height
        Flickable {
            id: listFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 8
            contentWidth: width
            contentHeight: Math.max(height, listCol.height)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: listCol
                width: listFlick.width
                spacing: Kirigami.Units.smallSpacing / 2

                Repeater {
                    model: root.contentItems.length
                    Components.AppListItem {
                        required property int index
                        width: listCol.width
                        app: root.contentItems[index]
                        iconSize: Math.max(root.appIconSize, 28)
                        showDescription: root.showAppDescriptions
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.activateItem(root.contentItems[index])
                        onContextMenuRequested: (x, y) => {
                            var a = root.contentItems[index];
                            if (a && !a.action) root.appContextMenu(a, x, y);
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                anchors.centerIn: parent
                visible: root.contentItems.length === 0
                text: root.searching
                      ? root.tr("No matching applications found")
                      : (root.plasmaTab === 0
                         ? root.tr("Pin applications from the context menu")
                         : root.tr("No applications"))
                opacity: 0.45
                color: root.fg
                width: parent.width * 0.8
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.fillHeight: false
            opacity: 0.35
        }

        // Compact footer tabs — fixed height, never stretch
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: root.footerHeight
            Layout.maximumHeight: root.footerHeight
            Layout.minimumHeight: root.footerHeight

            Row {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.tabs.length

                    Item {
                        required property int index
                        readonly property var tab: root.tabs[index]
                        readonly property bool selected: !root.searching && root.plasmaTab === tab.id

                        width: (parent.width - parent.spacing * (root.tabs.length - 1)) / root.tabs.length
                        height: parent.height

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 2
                            height: parent.height - 4
                            radius: Kirigami.Units.smallSpacing
                            color: selected ? root.selectedBg
                                   : (tabMouse.containsMouse ? Qt.rgba(root.selectedBg.r, root.selectedBg.g, root.selectedBg.b, 0.35)
                                                             : "transparent")
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Kirigami.Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: tab.icon
                                width: Kirigami.Units.iconSizes.smallMedium
                                height: Kirigami.Units.iconSizes.smallMedium
                            }

                            PlasmaComponents.Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tab.name
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                color: selected ? root.selectedFg : root.fg
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.selectTab(tab.id)
                        }

                        Accessible.name: tab.name
                        Accessible.role: Accessible.Button
                        Accessible.onPressAction: root.selectTab(tab.id)
                    }
                }
            }
        }
    }
}
