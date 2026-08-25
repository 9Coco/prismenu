import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

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
        return root.allApplications;
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

            Components.AppGrid {
                anchors.fill: parent
                items: root.gridItems
                columns: root.gridColumns
                iconSize: root.gridIconSize
                cellWidth: Math.max(Kirigami.Units.gridUnit * 5, width / Math.max(1, columns))
                cellHeight: root.gridCellHeight
                multiLineLabels: true
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                onAppActivated: (app) => root.activateItem(app)
                onContextMenuRequested: (app, x, y) => {
                    if (app && !app.action) root.appContextMenu(app, x, y);
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
