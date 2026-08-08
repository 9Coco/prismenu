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

        Components.SearchField {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        PlasmaComponents.Label {
            visible: !root.searching && pinnedModel.count > 0
            text: root.tr("Frequent")
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
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            onAppActivated: (app) => root.activateItem(app)
            onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
        }

        PlasmaComponents.Label {
            text: root.searching ? root.tr("Results") : root.tr("Applications")
            font.bold: true
            color: root.fg
        }

        Components.AppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: appModel
            iconSize: Math.max(48, root.appIconSize + 24)
            columns: 7
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            onAppActivated: (app) => root.activateItem(app)
            onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
        }
    }

    Ui.ListModelBridge { id: pinnedModel; source: menuData ? menuData.pinnedApps : [] }
    Ui.ListModelBridge { id: appModel; source: root.appsModel() }
}
