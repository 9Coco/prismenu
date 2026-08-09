import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Elementary layout (ArcMenu Elementary / elementary OS Slingshot style).
 *
 * Search on top, 6-column scrollable app icon grid below.
 */
LayoutBase {
    id: root

    readonly property int gridColumns: 6
    readonly property int gridIconSize: (menuData && menuData.gridIconOverride) ? menuData.gridIconSize : Math.max(48, root.appIconSize + 20)
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 2.2

    readonly property var gridItems: {
        if (root.searching) {
            return (menuData && menuData.searchResultsFlat) ? menuData.searchResultsFlat : [];
        }
        if (menuData && menuData.allApps && menuData.allApps.length)
            return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
        return [];
    }


    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Components.SearchField {
            Layout.fillWidth: true
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: gridFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: Math.max(height, gridFlow.height)
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: gridFlow
                    width: gridFlick.width
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: root.gridItems.length
                        Item {
                            required property int index
                            readonly property var app: root.gridItems[index]
                            readonly property int cellW: Math.floor(
                                (gridFlow.width - gridFlow.spacing * (root.gridColumns - 1))
                                / root.gridColumns)

                            width: Math.max(Kirigami.Units.gridUnit * 5, cellW)
                            height: root.gridCellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Kirigami.Units.smallSpacing
                                color: cellMouse.containsMouse ? root.selectedBg : "transparent"
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
                                    color: cellMouse.containsMouse ? root.selectedFg : root.fg
                                }
                            }

                            MouseArea {
                                id: cellMouse
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
