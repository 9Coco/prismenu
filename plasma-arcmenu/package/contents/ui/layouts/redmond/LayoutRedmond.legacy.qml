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

        // User header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon {
                    source: menuData ? menuData.userIcon : "user-identity"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }
                PlasmaComponents.Label {
                    text: menuData ? menuData.userName : i18n("User")
                    font.bold: true
                    Layout.fillWidth: true
                    color: root.fg
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.userMenu()
                Accessible.name: i18n("User menu")
                Accessible.role: Accessible.Button
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Components.CategoryList {
                Layout.preferredWidth: parent.width * 0.34
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
                    columns: menuData ? Math.min(menuData.pinnedCols, 5) : 5
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
                        showDescription: false
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

        // Bottom: search + power
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Components.SearchField {
                Layout.fillWidth: true
                placeholder: menuData ? menuData.searchPlaceholder : i18n("Search applications…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
            }

            PlasmaComponents.ToolButton {
                icon.name: "system-lock-screen"
                Accessible.name: i18n("Lock")
                onClicked: root.powerAction("lock")
            }
            PlasmaComponents.ToolButton {
                icon.name: "system-shutdown"
                Accessible.name: i18n("Power")
                onClicked: root.powerAction("shutdown")
            }
        }
    }

    Ui.ListModelBridge { id: pinnedModel; source: menuData ? menuData.pinnedApps : [] }
    Ui.ListModelBridge { id: categoryModel; source: menuData ? menuData.categories : [] }
    Ui.ListModelBridge { id: appModel; source: root.appsModel() }
}
