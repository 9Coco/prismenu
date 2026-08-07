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
        spacing: Kirigami.Units.smallSpacing

        Components.SearchField {
            Layout.fillWidth: true
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search applications…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        Components.PinnedAppsGrid {
            visible: !root.searching && pinnedModel.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.appIconSize + Kirigami.Units.gridUnit * 2
            columns: menuData ? menuData.pinnedCols : 6
            iconSize: Math.max(32, root.appIconSize + 8)
            model: pinnedModel
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            onAppActivated: (app) => root.appActivated(app)
            onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
        }

        Components.AppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: appModel
            iconSize: Math.max(48, root.appIconSize + 24)
            columns: 7
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            onAppActivated: (app) => root.appActivated(app)
            onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            visible: appModel.count === 0
            text: root.tr("No matching applications found")
            opacity: 0.6
        }
    }

    Ui.ListModelBridge { id: pinnedModel; source: menuData ? menuData.pinnedApps : [] }
    Ui.ListModelBridge {
        id: appModel
        source: {
            if (!menuData) return [];
            if (menuData.isSearching) return menuData.searchResults;
            return menuData.categoryApps;
        }
    }
}
