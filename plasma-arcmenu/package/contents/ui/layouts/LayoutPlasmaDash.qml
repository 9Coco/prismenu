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
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        Components.PinnedAppsGrid {
            visible: !root.searching && pinnedModel.count > 0
            Layout.fillWidth: true
            // Fit the actual rows (capped at 2) instead of a fixed strip
            Layout.preferredHeight: visible ? Math.min(contentHeight, cellHeight * 2) : 0
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

        Components.AppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: appModel
            iconSize: Math.max(48, root.appIconSize + 24)
            columns: Math.max(4, Math.floor(width / (Kirigami.Units.gridUnit * 6)))
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            multiLineLabels: root.multiLineLabels
            showGenericNames: root.showGenericNames
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            onAppActivated: (app) => root.activateItem(app)
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
            if (menuData.isSearching) return menuData.searchResultsFlat;
            return menuData.categoryApps;
        }
    }
}
