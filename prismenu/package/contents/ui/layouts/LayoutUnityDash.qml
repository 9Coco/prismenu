import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

LayoutBase {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
        }

        PlasmaComponents.Label {
            visible: !root.searching && pinnedModel.count > 0
            text: root.homeGroupName
            font.bold: true
            color: root.fg
        }

        Components.PinnedAppsGrid {
            visible: !root.searching && pinnedModel.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.appIconSize + Kirigami.Units.gridUnit * 2.2
            columns: menuData ? menuData.pinnedCols : 6
            iconSize: Math.max(36, root.appIconSize + 12)
            model: pinnedModel
            menuData: root.menuData
            reorderEnabled: root.canReorderGroup(root.homeGroupId)
            reorderGroupId: root.homeGroupId
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            onAppActivated: (app) => root.activateItem(app)
            onContextMenuRequested: (app, x, y, anchor) => root.appContextMenu(app, x, y, anchor)
        }

        PlasmaComponents.Label {
            text: root.searching ? root.tr("Results") : root.tr("Applications")
            font.bold: true
            color: root.fg
        }

        Components.LayoutAppGrid {
            layoutRoot: root
            Layout.fillWidth: true
            Layout.fillHeight: true
            items: root.appsModel()
            iconSize: Math.max(48, root.appIconSize + 24)
            columns: 7
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            multiLineLabels: root.multiLineLabels
            showGenericNames: root.showGenericNames
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            fg: root.fg
        }
    }

    Ui.ListModelBridge { id: pinnedModel; source: root.homeItems }
}
