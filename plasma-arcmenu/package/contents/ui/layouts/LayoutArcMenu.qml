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

        // Top: pinned + search
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

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

            Components.SearchField {
                Layout.preferredWidth: parent.width * 0.42
                Layout.minimumWidth: Kirigami.Units.gridUnit * 10
                placeholder: menuData ? menuData.searchPlaceholder : i18n("Search applications…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
            }
        }

        // Middle: categories + apps
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Components.CategoryList {
                Layout.preferredWidth: parent.width * 0.32
                Layout.fillHeight: true
                model: categoryModel
                iconSize: root.categoryIconSize
                currentCategoryId: menuData ? menuData.currentCategoryId : "all"
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onCategorySelected: (id) => { if (menuData) menuData.selectCategory(id); }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: appList
                    anchors.fill: parent
                    clip: true
                    model: appModel
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationWraps: true
                    Accessible.name: i18n("Applications")

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

                    Keys.onReturnPressed: {
                        if (currentIndex >= 0) {
                            root.appActivated(appModel.get(currentIndex));
                        }
                    }
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: appModel.count === 0
                    text: root.searching ? i18n("No matching applications found") : i18n("No applications")
                    opacity: 0.6
                }
            }
        }

        Components.SystemActionsBar {
            Layout.fillWidth: true
            enabledOptions: menuData ? menuData.powerOptions : []
            confirmDestructive: menuData ? menuData.powerConfirm : true
            softwareCenterCmd: menuData ? menuData.softwareCenterCmd : "auto-detect"
            userName: menuData ? menuData.userName : ""
            userIcon: menuData ? menuData.userIcon : "user-identity"
            onActionRequested: (id) => root.powerAction(id)
            onUserMenuRequested: root.userMenu()
        }
    }

    Ui.ListModelBridge { id: pinnedModel; source: menuData ? menuData.pinnedApps : [] }
    Ui.ListModelBridge { id: categoryModel; source: menuData ? menuData.categories : [] }
    Ui.ListModelBridge { id: appModel; source: root.appsModel() }
}
