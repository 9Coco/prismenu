import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * A-Z layout (ArcMenu Az style).
 *
 * Compact Win11-like: search + pinned grid + footer (no frequent section).
 * "All Applications" opens an alphabetical A–Z list with letter headers.
 */
LayoutBase {
    id: root

    property bool showAllApps: false

    readonly property int pinnedIconSize: Math.max(32, root.appIconSize + 4)
    readonly property int pinnedCellWidth: Kirigami.Units.gridUnit * 5
    readonly property int pinnedCellHeight: pinnedIconSize + Kirigami.Units.gridUnit * 1.6


    readonly property var pinnedItems: {
        if (menuData && menuData.pinnedApps && menuData.pinnedApps.length)
            return menuData.pinnedApps;
        return root.defaultPinned;
    }

    readonly property var azSections: {
        if (root.searching)
            return [];
        return root.allApplicationSections;
    }

    readonly property var searchItems: {
        if (!root.searching)
            return [];
        return (menuData && menuData.searchResults) ? menuData.searchResults : [];
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

        Kirigami.Separator {
            Layout.fillWidth: true
            opacity: 0.35
        }

        // ---- Home: pinned only (A-Z hallmark: no frequent) ----
        ColumnLayout {
            visible: !root.searching && !root.showAllApps
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
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

            Flow {
                id: pinnedFlow
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                Layout.preferredHeight: Math.ceil(Math.max(1, root.pinnedItems.length)
                    / Math.max(1, Math.floor(Math.max(root.pinnedCellWidth, width) / root.pinnedCellWidth)))
                    * root.pinnedCellHeight
                Layout.maximumHeight: root.pinnedCellHeight * 4
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

            Item { Layout.fillHeight: true }
        }

        // ---- All apps A–Z / search ----
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

            Components.VirtualizedAppList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                items: root.searching ? root.searchItems : root.allApplicationRows
                menuData: root.menuData
                iconSize: Math.max(root.appIconSize, 24)
                showDescription: root.showAppDescriptions
                showGenericNames: root.showGenericNames
                multiLineLabels: root.multiLineLabels
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                onAppActivated: (app) => root.activateItem(app)
                onAppContextMenu: (app, x, y) => {
                    if (app && !app.action) root.appContextMenu(app, x, y);
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: root.searching
                         ? root.searchItems.length === 0
                         : root.azSections.length === 0
                text: root.searching
                      ? root.tr("No matching applications found")
                      : root.tr("No applications")
                opacity: 0.45
                color: root.fg
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            opacity: 0.35
        }

        // ---- Footer ----
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
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
