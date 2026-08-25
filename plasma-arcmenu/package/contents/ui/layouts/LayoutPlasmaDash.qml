import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

LayoutBase {
    id: root

    readonly property var gridItems: root.appsModel()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
        }

        Components.PinnedAppsGrid {
            visible: !root.searching && pinnedModel.count > 0
            Layout.fillWidth: true
            // Fit the actual rows (capped at 2) without feeding GridView's
            // height-dependent contentHeight back into the parent layout.
            Layout.preferredHeight: visible
                ? cellHeight * Math.min(2, Math.ceil(count / Math.max(1, columns)))
                : 0
            columns: menuData ? menuData.pinnedCols : 6
            iconSize: Math.max(48, root.appIconSize + 24)
            model: pinnedModel
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            onAppActivated: (app) => root.activateItem(app)
            onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
        }

        Kirigami.Separator {
            visible: !root.searching && pinnedModel.count > 0
            Layout.fillWidth: true
            opacity: 0.4
        }

        Components.LayoutAppGrid {
            layoutRoot: root
            Layout.fillWidth: true
            Layout.fillHeight: true
            items: root.gridItems
            iconSize: Math.max(48, root.appIconSize + 24)
            columns: Math.max(4, Math.floor(width / (Kirigami.Units.gridUnit * 6)))
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            multiLineLabels: root.multiLineLabels
            showGenericNames: root.showGenericNames
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            fg: root.fg
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            visible: root.gridItems.length === 0
            text: root.tr("No matching applications found")
            opacity: 0.6
        }
    }

    Ui.ListModelBridge { id: pinnedModel; source: menuData ? menuData.pinnedApps : [] }
}
