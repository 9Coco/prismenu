import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

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
        if (menuData && menuData.pinnedApps && menuData.pinnedApps.length)
            return menuData.pinnedApps;
        return root.defaultPinned;
    }

    readonly property var frequentItems: {
        if (menuData && menuData.recentApps && menuData.recentApps.length)
            return menuData.recentApps;
        // Prefer a few visible apps from catalog when recents empty
        if (menuData && menuData.allApps && menuData.allApps.length) {
            var vis = AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
            if (vis.length)
                return vis.slice(0, Math.min(6, vis.length));
        }
        return root.defaultFrequent;
    }

    readonly property var allAppsItems: {
        if (root.searching)
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        if (menuData && menuData.allApps && menuData.allApps.length)
            return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
        return [];
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

        Components.SearchField {
            Layout.fillWidth: true
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: {
                if (menuData) menuData.setSearch(text);
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

            // Fixed cell size, left-packed (Win11 style �?not stretched to 6 columns)
            Flow {
                id: pinnedFlow
                Layout.fillWidth: true
                Layout.preferredHeight: Math.ceil(Math.max(1, root.pinnedItems.length)
                    / Math.max(1, Math.floor(width / root.pinnedCellWidth)))
                    * root.pinnedCellHeight
                Layout.maximumHeight: root.pinnedCellHeight * 3
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.pinnedItems.length
                    Item {
                        required property int index
                        readonly property var app: root.pinnedItems[index]
                        width: root.pinnedCellWidth
                        height: root.pinnedCellHeight

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
                                Layout.preferredWidth: root.pinnedIconSize
                                Layout.preferredHeight: root.pinnedIconSize
                            }

                            PlasmaComponents.Label {
                                text: app.name || ""
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                maximumLineCount: 1
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
                        onContextMenuRequested: (x, y) => {
                            var a = root.frequentItems[index];
                            if (a && !a.action) root.appContextMenu(a, x, y);
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

            Flickable {
                id: allFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: allCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: allCol
                    width: allFlick.width
                    spacing: Kirigami.Units.smallSpacing / 2

                    Repeater {
                        model: root.allAppsItems.length
                        Components.AppListItem {
                            required property int index
                            menuData: menuData
                            width: allCol.width
                            app: root.allAppsItems[index]
                            iconSize: Math.max(root.appIconSize, 28)
                            showDescription: root.showAppDescriptions
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.activateItem(root.allAppsItems[index])
                            onContextMenuRequested: (x, y) => {
                                var a = root.allAppsItems[index];
                                if (a && !a.action) root.appContextMenu(a, x, y);
                            }
                        }
                    }
                }
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
