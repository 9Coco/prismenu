import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/** GNOME-style overview: windows first, workspaces at the edge, Dash below. */
LayoutBase {
    id: root

    readonly property var windows: menuData && menuData.openWindowResults
        ? menuData.openWindowResults : []
    readonly property var dashItems: {
        var pinned = menuData && menuData.pinnedApps ? menuData.pinnedApps : [];
        return (pinned.length ? pinned : root.defaultPinned).slice(0, 9);
    }

    Component.onCompleted: {
        if (menuData && menuData.appsBackend && menuData.appsBackend.refreshOpenWindows)
            menuData.appsBackend.refreshOpenWindows();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.preferredWidth: Math.min(720, root.width * 0.65)
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
        }

        Components.LayoutAppList {
            visible: root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutRoot: root
            items: menuData ? menuData.searchResults : []
            showDescription: true
            inlineDescription: true
        }

        RowLayout {
            visible: !root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            GridView {
                id: windowsGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.windows.length
                cellWidth: Math.max(190, width / 3)
                cellHeight: Math.max(125, height / 2)
                delegate: Rectangle {
                    required property int index
                    readonly property var windowItem: root.windows[index]
                    width: windowsGrid.cellWidth - Kirigami.Units.largeSpacing
                    height: windowsGrid.cellHeight - Kirigami.Units.largeSpacing
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, hover.hovered ? 0.16 : 0.08)
                    border.width: 1
                    border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.24)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                            source: windowItem.icon || "window"
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: windowItem.name || ""
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            color: root.fg
                        }
                    }
                    HoverHandler { id: hover }
                    TapHandler { onTapped: root.activateItem(windowItem) }
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.windows.length === 0
                    text: root.tr("No open windows")
                    color: root.fg
                    opacity: 0.55
                }
            }

            ColumnLayout {
                Layout.preferredWidth: Math.max(92, root.width * 0.12)
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Kirigami.Units.cornerRadius
                        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, index === 0 ? 0.16 : 0.07)
                        border.width: index === 0 ? 2 : 1
                        border.color: index === 0 ? root.activeBg : root.borderColor
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: String(index + 1)
                            color: root.fg
                            opacity: 0.7
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(root.width * 0.78, root.dashItems.length * 70 + 54)
            Layout.preferredHeight: Kirigami.Units.gridUnit * 4.5
            visible: !root.searching
            radius: height / 2
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)
            Components.LayoutAppGrid {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                layoutRoot: root
                items: root.dashItems
                columns: Math.max(1, root.dashItems.length)
                iconSize: Math.max(40, root.gridIconSize)
            }
        }
    }
}
