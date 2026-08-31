import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Insider layout (ArcMenu Insider / Win10 Fluent style).
 *
 * Left column: hamburger (top) + files/settings/power (bottom)
 * Main column: centered avatar, search, 5-column app grid
 */
LayoutBase {
    id: root

    readonly property int gridColumns: 5
    readonly property int gridIconSize: (menuData && menuData.gridIconOverride) ? menuData.gridIconSize : Math.max(40, root.appIconSize + 12)
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 2
    readonly property int railWidth: Kirigami.Units.gridUnit * 2.8

    readonly property var gridItems: {
        if (root.searching) {
            return (menuData && menuData.searchResultsFlat) ? menuData.searchResultsFlat : [];
        }
        return root.homeItems;
    }


    function openFiles() {
        root.appActivated({
            id: "org.kde.dolphin.desktop",
            name: root.tr("Files"),
            icon: "system-file-manager",
            exec: "dolphin"
        });
    }

    function openMenu() {
        root.openArcMenuSettings();
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Dedicated left rail ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: root.railWidth
            Layout.maximumWidth: root.railWidth
            Layout.fillWidth: false
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "application-menu"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("ArcMenu Settings")
                onClicked: root.openMenu()
                PlasmaComponents.ToolTip.text: root.tr("ArcMenu Settings")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "system-file-manager"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Files")
                onClicked: root.openFiles()
                PlasmaComponents.ToolTip.text: root.tr("Files")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "preferences-system"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Settings")
                onClicked: root.powerAction("settings")
                PlasmaComponents.ToolTip.text: root.tr("Settings")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "system-shutdown"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Shut Down")
                onClicked: root.powerAction("shutdown")
                PlasmaComponents.ToolTip.text: root.tr("Shut Down")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        // ---- Main column: avatar + search + grid (search only as wide as this column) ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.5
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
                    Layout.alignment: Qt.AlignHCenter
                    text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    color: root.fg
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.userMenu()
                    }
                }
            }

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Components.LayoutAppGrid {
                    layoutRoot: root
                    anchors.fill: parent
                    items: root.gridItems
                    reorderEnabled: !root.searching && root.isPinnedGroup(root.homeGroupId)
                    columns: root.gridColumns
                    iconSize: root.gridIconSize
                    cellWidth: Math.max(Kirigami.Units.gridUnit * 4, width / Math.max(1, columns))
                    cellHeight: root.gridCellHeight
                    multiLineLabels: true
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    hoverBg: root.hoverBg
                    hoverFg: root.hoverFg
                    fg: root.fg
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.gridItems.length === 0
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : root.tr("No applications")
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
