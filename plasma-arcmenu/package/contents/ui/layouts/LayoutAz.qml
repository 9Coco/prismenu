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
        return root.homeItems;
    }

    function resetForOpen() { root.showAllApps = false; }

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

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
            onTextChanged: {
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
                    text: root.homeGroupName
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

            Components.LayoutAppGrid {
                id: pinnedGrid
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                Layout.preferredHeight: Math.ceil(Math.max(1, root.pinnedItems.length)
                    / Math.max(1, Math.floor(Math.max(root.pinnedCellWidth, width) / root.pinnedCellWidth)))
                    * root.pinnedCellHeight
                Layout.maximumHeight: root.pinnedCellHeight * 4
                layoutRoot: root
                items: root.pinnedItems
                reorderEnabled: root.isPinnedGroup(root.homeGroupId)
                columns: Math.max(1, Math.floor(width / root.pinnedCellWidth))
                cellWidth: root.pinnedCellWidth
                cellHeight: root.pinnedCellHeight
                iconSize: root.pinnedIconSize
                multiLineLabels: false
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

            Components.LayoutAppList {
                layoutRoot: root
                Layout.fillWidth: true
                Layout.fillHeight: true
                items: root.searching ? root.searchItems : root.allApplicationRows
                iconSize: Math.max(root.appIconSize, 24)
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
