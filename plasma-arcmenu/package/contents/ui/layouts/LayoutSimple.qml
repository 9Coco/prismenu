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
            id: search
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
            Component.onCompleted: forceActiveFocus()
        }

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: appModel
            boundsBehavior: Flickable.StopAtBounds
            delegate: Components.AppListItem {
                width: appList.width
                app: model
                iconSize: Math.max(28, root.appIconSize)
                showDescription: menuData ? menuData.showSearchDescription : true
                selected: appList.currentIndex === index
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                onActivated: root.activateItem(model)
                onContextMenuRequested: (x, y) => root.appContextMenu(model, x, y)
            }

            PlasmaComponents.Label {
                anchors.centerIn: parent
                visible: appModel.count === 0
                text: root.searching ? root.tr("No matching applications found") : root.tr("Type to search applications")
                opacity: 0.6
            }
        }
    }

    Ui.ListModelBridge {
        id: appModel
        source: {
            if (!menuData) return [];
            if (menuData.isSearching) return menuData.searchResults;
            // Simple layout shows all apps when not searching
            return menuData.categoryApps;
        }
    }
}
