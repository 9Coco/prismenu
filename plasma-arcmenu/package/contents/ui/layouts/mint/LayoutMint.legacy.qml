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
                Layout.preferredWidth: parent.width * 0.30
                Layout.fillHeight: true
                model: categoryModel
                iconSize: root.categoryIconSize
                currentCategoryId: menuData ? menuData.currentCategoryId : "all"
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onCategorySelected: (id) => { if (menuData) menuData.selectCategory(id); }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                Components.PinnedAppsGrid {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.appIconSize + Kirigami.Units.gridUnit * 1.8
                    columns: menuData ? menuData.pinnedCols : 6
                    iconSize: Math.max(24, root.appIconSize)
                    model: pinnedModel
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    onAppActivated: (app) => root.appActivated(app)
                    onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
                }

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: appModel
                    delegate: Components.AppListItem {
                        menuData: menuData
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
        }

        Loader {
            Layout.fillWidth: true
            active: !root.searchOnTop
            sourceComponent: searchComp
        }

        Components.SystemActionsBar {
            Layout.fillWidth: true
            enabledOptions: menuData ? menuData.powerOptions : []
            userName: menuData ? menuData.userName : ""
            userIcon: menuData ? menuData.userIcon : "user-identity"
            onActionRequested: (id) => root.powerAction(id)
            onUserMenuRequested: root.userMenu()
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

    Ui.ListModelBridge { id: pinnedModel; source: menuData ? menuData.pinnedApps : [] }
    Ui.ListModelBridge { id: categoryModel; source: menuData ? menuData.categories : [] }
    Ui.ListModelBridge { id: appModel; source: root.appsModel() }
}
