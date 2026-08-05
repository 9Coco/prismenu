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
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.SearchField {
            Layout.fillWidth: true
            placeholder: menuData ? menuData.searchPlaceholder : i18n("Search applications…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        // Horizontal categories
        ListView {
            id: catBar
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
            orientation: ListView.Horizontal
            clip: true
            model: categoryModel
            spacing: Kirigami.Units.smallSpacing
            delegate: PlasmaComponents.ToolButton {
                required property var model
                text: model.name
                icon.name: model.icon
                checkable: true
                checked: menuData && menuData.currentCategoryId === model.id
                onClicked: if (menuData) menuData.selectCategory(model.id)
                Accessible.name: model.name
            }
        }

        Components.AppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: appModel
            iconSize: Math.max(40, root.appIconSize + 16)
            columns: 6
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            onAppActivated: (app) => root.appActivated(app)
            onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
        }
    }

    Ui.ListModelBridge { id: categoryModel; source: menuData ? menuData.categories : [] }
    Ui.ListModelBridge { id: appModel; source: root.appsModel() }
}
