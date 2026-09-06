import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

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

    readonly property int footerHeight: Kirigami.Units.gridUnit * 3.8


    readonly property var leaveItems: [
        { id: "leave-lock", name: root.tr("Lock"), icon: "system-lock-screen", action: "lock", noDisplay: false },
        { id: "leave-logout", name: root.tr("Log Out"), icon: "system-log-out", action: "logout", noDisplay: false },
        { id: "leave-suspend", name: root.tr("Suspend"), icon: "system-suspend", action: "suspend", noDisplay: false },
        { id: "leave-restart", name: root.tr("Restart"), icon: "system-reboot", action: "restart", noDisplay: false },
        { id: "leave-shutdown", name: root.tr("Shut Down"), icon: "system-shutdown", action: "shutdown", noDisplay: false }
    ]

    readonly property var tabs: [
        { id: 0, name: root.homeGroupName, icon: root.homeGroupIcon },
        { id: 1, name: root.tr("Applications"), icon: "view-app-grid-symbolic" },
        { id: 2, name: root.tr("Computer"), icon: "computer" },
        { id: 3, name: root.tr("Leave"), icon: "system-shutdown" }
    ]

    readonly property var contentItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        if (plasmaTab === 0) {
            return root.homeItems;
        }
        if (plasmaTab === 1) {
            return root.allApplications;
        }
        if (plasmaTab === 2) {
            return (menuData && menuData.places) ? menuData.places : [];
        }
        return root.leaveItems;
    }

    function resetForOpen() { root.plasmaTab = 0; }


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
                            userName: (menuData && menuData.userName) ? menuData.userName : ""
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

                Components.LayoutSearchField {
                    layoutRoot: root
                    Layout.fillWidth: true
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.fillHeight: false
            opacity: 0.35
        }

        // Middle content �?takes all leftover height
        Components.LayoutGroupPane {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 8
            layoutRoot: root
            items: root.contentItems
            navId: root.searching ? "" : (root.plasmaTab === 0
                ? root.homeGroupId : (root.plasmaTab === 1 ? "all-apps" : ""))
            useGrid: !root.searching && ((root.plasmaTab === 0 && root.usesGridView(root.homeGroupId))
                     || (root.plasmaTab === 1 && root.usesGridView("all-apps")))
            showDescription: root.showAppDescriptions
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.fillHeight: false
            opacity: 0.35
        }

        // Compact footer tabs �?fixed height, never stretch
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
