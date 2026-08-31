import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Eleven layout (Windows 11 Start / ArcMenu Eleven style).
 *
 * Search
 * 已固�?header + All apps link | pinned icon grid
 * 常用 | two-column recent list
 * Footer: user | files, settings, power
 */
LayoutBase {
    id: root

    property bool showAllApps: false

    readonly property int pinnedIconSize: Math.max(36, root.appIconSize + 8)
    readonly property int pinnedCellWidth: Kirigami.Units.gridUnit * 5.5
    readonly property int pinnedCellHeight: pinnedIconSize + Kirigami.Units.gridUnit * 1.8


    readonly property var defaultFrequent: [
        {
            id: "firefox.desktop",
            name: "Firefox",
            icon: "firefox",
            exec: "firefox",
            noDisplay: false
        },
        {
            id: "shortcut-settings",
            name: root.tr("Settings"),
            icon: "preferences-system",
            exec: "",
            action: "settings",
            noDisplay: false
        },
        {
            id: "org.kde.konsole.desktop",
            name: root.tr("Terminal"),
            icon: "utilities-terminal",
            exec: "konsole",
            noDisplay: false
        }
    ]

    readonly property var pinnedItems: {
        return root.homeItems;
    }

    function resetForOpen() { root.showAllApps = false; }

    readonly property var frequentItems: {
        if (menuData && menuData.recentApps && menuData.recentApps.length)
            return menuData.recentApps;
        // Prefer a few visible apps from catalog when recents empty
        if (root.allApplications.length)
            return root.allApplications.slice(0, Math.min(6, root.allApplications.length));
        return root.defaultFrequent;
    }

    readonly property var allAppsItems: {
        if (root.searching)
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        return root.allApplications;
    }


    function openFiles() {
        root.appActivated({
            id: "org.kde.dolphin.desktop",
            name: root.tr("Files"),
            icon: "system-file-manager",
            exec: "dolphin"
        });
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
            onTextChanged: {
                if (text && text.length)
                    root.showAllApps = false;
            }
        }

        // ---- Home: pinned + frequent (top-packed; leftover space below) ----
        ColumnLayout {
            visible: !root.searching && !root.showAllApps
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    text: root.tr("Pinned")
                    font.bold: true
                    color: root.fg
                    Layout.fillWidth: true
                }
                PlasmaComponents.ToolButton {
                    flat: true
                    text: root.tr("All Applications") + " >"
                    onClicked: root.showAllApps = true
                }
            }

            // Fixed cell size, left-packed (Win11 style).
            Components.LayoutAppGrid {
                id: pinnedGrid
                Layout.fillWidth: true
                Layout.preferredHeight: Math.ceil(Math.max(1, root.pinnedItems.length)
                    / Math.max(1, Math.floor(width / root.pinnedCellWidth)))
                    * root.pinnedCellHeight
                Layout.maximumHeight: root.pinnedCellHeight * 3
                layoutRoot: root
                items: root.pinnedItems
                reorderEnabled: root.isPinnedGroup(root.homeGroupId)
                columns: Math.max(1, Math.floor(width / root.pinnedCellWidth))
                cellWidth: root.pinnedCellWidth
                cellHeight: root.pinnedCellHeight
                iconSize: root.pinnedIconSize
                multiLineLabels: false
            }

            PlasmaComponents.Label {
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: root.tr("Frequent")
                font.bold: true
                color: root.fg
            }

            // Two-column frequent list �?content-sized, does not eat leftover height
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing / 2
                columnSpacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: root.frequentItems.length
                    Components.AppListItem {
                        required property int index
                        menuData: menuData
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                        app: root.frequentItems[index]
                        iconSize: Math.max(root.appIconSize, 28)
                        showDescription: root.showAppDescriptions
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.activateItem(root.frequentItems[index])
                        onContextMenuRequested: (x, y, anchor) => {
                            var a = root.frequentItems[index];
                            if (a && !a.action) root.appContextMenu(a, x, y, anchor);
                        }
                    }
                }
            }

            // Absorb leftover height under content (Win11 empty lower area)
            Item { Layout.fillHeight: true }
        }

        // ---- All apps / search ----
        ColumnLayout {
            visible: root.searching || root.showAllApps
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                visible: !root.searching
                PlasmaComponents.ToolButton {
                    flat: true
                    icon.name: "go-previous"
                    text: root.tr("Back")
                    onClicked: root.showAllApps = false
                }
                PlasmaComponents.Label {
                    text: root.tr("All Applications")
                    font.bold: true
                    color: root.fg
                    Layout.fillWidth: true
                }
            }

            Components.LayoutAppList {
                layoutRoot: root
                Layout.fillWidth: true
                Layout.fillHeight: true
                items: root.allAppsItems
                iconSize: Math.max(root.appIconSize, 28)
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: root.allAppsItems.length === 0
                text: root.searching
                      ? root.tr("No matching applications found")
                      : root.tr("No applications")
                opacity: 0.45
                color: root.fg
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ---- Footer ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.8
            Layout.leftMargin: -Kirigami.Units.largeSpacing
            Layout.rightMargin: -Kirigami.Units.largeSpacing
            Layout.bottomMargin: -Kirigami.Units.largeSpacing
            color: Qt.rgba(0, 0, 0, 0.22)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
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

                PlasmaComponents.Label {
                    text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                    elide: Text.ElideRight
                    color: root.fg
                    Layout.fillWidth: true
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.userMenu()
                    }
                }

                PlasmaComponents.ToolButton {
                    flat: true
                    icon.name: "system-file-manager"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    Accessible.name: root.tr("Files")
                    onClicked: root.openFiles()
                    PlasmaComponents.ToolTip.text: root.tr("Files")
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }

                PlasmaComponents.ToolButton {
                    flat: true
                    icon.name: "preferences-system"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    Accessible.name: root.tr("Settings")
                    onClicked: root.powerAction("settings")
                    PlasmaComponents.ToolTip.text: root.tr("Settings")
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }

                PlasmaComponents.ToolButton {
                    flat: true
                    icon.name: "system-shutdown"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    Accessible.name: root.tr("Shut Down")
                    onClicked: root.powerAction("shutdown")
                    PlasmaComponents.ToolTip.text: root.tr("Shut Down")
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }
}
