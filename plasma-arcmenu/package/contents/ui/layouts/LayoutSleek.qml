import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Sleek layout (ArcMenu Sleek).
 *
 * Left: search + Pinned / All Apps toggle + icon grid
 * Right: centered avatar, places + software/settings, single power button
 */
LayoutBase {
    id: root

    // Sleek home view starts on pinned apps (matches reference screenshot)
    property bool showPinned: true

    readonly property int gridColumns: 4
    readonly property int gridIconSize: (menuData && menuData.gridIconOverride) ? menuData.gridIconSize : Math.max(40, root.appIconSize + 12)
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 2
    readonly property int avatarSize: Kirigami.Units.gridUnit * 4


    readonly property var sideItems: root.sidebarShortcuts

    readonly property var gridItems: {
        if (root.searching) {
            return (menuData && menuData.searchResultsFlat) ? menuData.searchResultsFlat : [];
        }
        if (root.showPinned) {
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        return root.allApplications;
    }


    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: 0
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Left: search + pinned / all-apps grid ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
                Layout.fillHeight: false
                onTextChanged: {
                    if (text && text.length)
                        root.showPinned = false;
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                visible: !root.searching

                PlasmaComponents.Label {
                    text: root.showPinned ? root.tr("Pinned") : root.tr("All Applications")
                    font.bold: true
                    color: root.fg
                    Layout.fillWidth: true
                }

                PlasmaComponents.ToolButton {
                    flat: true
                    text: root.showPinned
                          ? root.tr("All Applications") + " >"
                          : root.tr("Pinned") + " >"
                    onClicked: root.showPinned = !root.showPinned
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 10

                Components.LayoutGroupPane {
                    layoutRoot: root
                    anchors.fill: parent
                    items: root.gridItems
                    navId: root.showPinned ? "pinned" : "all-apps"
                    useGrid: !root.searching && root.usesGridView(
                        root.showPinned ? "pinned" : "all-apps")
                    showDescription: root.searching
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.gridItems.length === 0
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : (root.showPinned
                             ? root.tr("Pin applications from the context menu")
                             : root.tr("No applications"))
                    opacity: 0.45
                    color: root.fg
                    width: parent.width * 0.8
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Components.ColumnSplitHandle {
            Layout.fillHeight: true
            Layout.preferredWidth: implicitWidth
            z: 5
            fg: root.fg
            currentWidth: root.sidebarW
            minWidth: root.sidebarMin
            maxWidth: root.sidebarMax
            sidebarOnRight: true
            flipped: root.flip
            onWidthDragged: (w) => root.setSidebarFromDrag(w)
        }

        // ---- Right sidebar: avatar + places + power ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: root.sidebarW
            Layout.minimumWidth: root.elasticColumnMin
            Layout.maximumWidth: root.sidebarMax
            spacing: Kirigami.Units.smallSpacing

            // Centered circular avatar + username
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.avatarSize
                    Layout.preferredHeight: root.avatarSize

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.color: root.fg
                        border.width: 1
                        opacity: 0.55
                    }

                    Item {
                        anchors.centerIn: parent
                        width: root.avatarSize - Kirigami.Units.smallSpacing * 2
                        height: width
                        Components.UserFace {
                            anchors.fill: parent
                            userIcon: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                            userName: (menuData && menuData.userName) ? menuData.userName : ""
                            fallbackColor: root.fg
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            Accessible.name: root.tr("User")
                            onClicked: root.userMenu()
                            PlasmaComponents.ToolTip.text: root.tr("User")
                            PlasmaComponents.ToolTip.visible: containsMouse
                            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                    }
                }

                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                    color: root.fg
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.userMenu()
                    }
                }
            }

            Flickable {
                id: sideFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: sideCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

                Column {
                    id: sideCol
                    width: sideFlick.width
                    spacing: Kirigami.Units.smallSpacing / 2

                    Repeater {
                        model: root.sideItems.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.sideItems[index].icon
                            label: root.sideItems[index].name
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.activateItem(root.sideItems[index])
                        }
                    }
                }
            }

            // Single power button centered at bottom (Sleek signature)
            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
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
    }
}
