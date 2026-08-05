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

        Loader {
            Layout.fillWidth: true
            active: root.searchOnTop
            sourceComponent: searchComp
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Components.CategoryList {
                id: cats
                Layout.preferredWidth: (menuData && menuData.categoriesCollapsed) ? Kirigami.Units.gridUnit * 2.5 : parent.width * 0.32
                Layout.fillHeight: true
                collapsible: true
                collapsed: menuData ? menuData.categoriesCollapsed : false
                model: categoryModel
                iconSize: root.categoryIconSize
                currentCategoryId: menuData ? menuData.currentCategoryId : "all"
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onCategorySelected: (id) => { if (menuData) menuData.selectCategory(id); }
                onToggleCollapsed: if (menuData) menuData.categoriesCollapsed = !menuData.categoriesCollapsed
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: appModel
                delegate: Components.AppListItem {
                    width: appList.width
                    app: model
                    iconSize: root.appIconSize
                    showDescription: menuData ? menuData.showSearchDescription : true
                    selected: appList.currentIndex === index
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    fg: root.fg
                    onActivated: root.appActivated(model)
                    onContextMenuRequested: (x, y) => root.appContextMenu(model, x, y)
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            active: !root.searchOnTop
            sourceComponent: searchComp
        }

        Components.SystemActionsBar {
            Layout.fillWidth: true
            showUser: false
            enabledOptions: menuData ? menuData.powerOptions : []
            onActionRequested: (id) => root.powerAction(id)
        }
    }

    Component {
        id: searchComp
        Components.SearchField {
            Layout.fillWidth: true
            placeholder: menuData ? menuData.searchPlaceholder : i18n("Search applications…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }
    }

    Ui.ListModelBridge { id: categoryModel; source: menuData ? menuData.categories : [] }
    Ui.ListModelBridge { id: appModel; source: root.appsModel() }
}
