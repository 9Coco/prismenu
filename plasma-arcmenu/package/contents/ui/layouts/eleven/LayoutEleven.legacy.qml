import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

LayoutBase {
    id: root

    property bool showAllApps: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.SearchField {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            placeholder: menuData ? menuData.searchPlaceholder : i18n("Search applications…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        // Pinned grid (Windows 11 style)
        Components.PinnedAppsGrid {
            visible: !root.searching && !root.showAllApps
            Layout.fillWidth: true
            Layout.preferredHeight: (root.appIconSize + Kirigami.Units.gridUnit * 1.8) * 2 + Kirigami.Units.smallSpacing
            columns: menuData ? menuData.pinnedCols : 6
            iconSize: Math.max(32, root.appIconSize + 8)
            model: pinnedModel
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            onAppActivated: (app) => root.appActivated(app)
            onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
        }

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: root.showAllApps || root.searching ? i18n("All apps") : i18n("Pinned")
                font.bold: true
                color: root.fg
                Layout.fillWidth: true
            }
            PlasmaComponents.ToolButton {
                visible: !root.searching
                text: root.showAllApps ? i18n("Back") : i18n("All apps")
                icon.name: root.showAllApps ? "go-previous" : "view-list-details"
                onClicked: root.showAllApps = !root.showAllApps
            }
        }

        // All apps / categories view
        ColumnLayout {
            visible: root.showAllApps || root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: !root.searching
                Repeater {
                    model: categoryModel
                    PlasmaComponents.ToolButton {
                        required property var model
                        text: model.name
                        checkable: true
                        checked: menuData && menuData.currentCategoryId === model.id
                        onClicked: if (menuData) menuData.selectCategory(model.id)
                        Accessible.name: model.name
                    }
                }
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

        Item {
            visible: !root.showAllApps && !root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Recent apps under pinned
            ColumnLayout {
                anchors.fill: parent
                visible: menuData && menuData.recentEnabled && recentModel.count > 0
                PlasmaComponents.Label {
                    text: i18n("Recommended")
                    font.bold: true
                    color: root.fg
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: recentModel
                    delegate: Components.AppListItem {
                        menuData: menuData
                        width: parent.width
                        app: model
                        iconSize: root.appIconSize
                        showDescription: false
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.appActivated(model)
                        onContextMenuRequested: (x, y) => root.appContextMenu(model, x, y)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: menuData ? menuData.userIcon : "user-identity"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            PlasmaComponents.Label {
                text: menuData ? menuData.userName : i18n("User")
                Layout.fillWidth: true
                color: root.fg
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.userMenu()
                }
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
    Ui.ListModelBridge { id: recentModel; source: menuData ? menuData.recentApps : [] }
}
