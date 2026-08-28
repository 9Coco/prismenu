import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

LayoutBase {
    id: root

    property string cascadeCategoryId: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
        }

        Components.PinnedAppsGrid {
            visible: !root.searching && pinnedModel.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.appIconSize + Kirigami.Units.gridUnit * 1.6
            columns: menuData ? Math.min(menuData.pinnedCols, 4) : 4
            iconSize: Math.max(24, root.appIconSize)
            model: pinnedModel
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            onAppActivated: (app) => root.activateItem(app)
            onContextMenuRequested: (app, x, y) => root.appContextMenu(app, x, y)
        }

        ListView {
            id: searchList
            visible: root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: appModel
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
            QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
            delegate: Components.AppListItem {
                menuData: menuData
                width: searchList.width
                app: model
                iconSize: root.appIconSize
                showDescription: menuData ? menuData.showSearchDescription : true
                selected: searchList.currentIndex === index
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                onActivated: root.activateItem(model)
                onContextMenuRequested: (x, y) => root.appContextMenu(model, x, y)
            }
        }

        ListView {
            id: cascadeList
            visible: !root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: categoryModel
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
            QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

            delegate: Item {
                id: del
                required property var model
                required property int index
                width: cascadeList.width
                height: Kirigami.Units.gridUnit * 1.8

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Kirigami.Units.smallSpacing
                    color: mouse.containsMouse ? root.selectedBg : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Components.ResolvedIcon {
                        iconName: model.icon || "application-x-executable"
                        preferSymbolic: true
                        tintColor: mouse.containsMouse ? root.selectedFg : root.fg
                        Layout.preferredWidth: root.appIconSize
                        Layout.preferredHeight: root.appIconSize
                    }
                    PlasmaComponents.Label {
                        text: model.name || ""
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: mouse.containsMouse ? root.selectedFg : root.fg
                    }
                    Kirigami.Icon {
                        source: "go-next"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        opacity: 0.6
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        root.cascadeCategoryId = model.id;
                        if (menuData) menuData.selectCategory(model.id);
                        cascadePopup.open();
                    }
                }
            }
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

    QQC2.Popup {
        id: cascadePopup
        x: root.width - Kirigami.Units.smallSpacing
        y: Kirigami.Units.gridUnit * 4
        width: Kirigami.Units.gridUnit * 16
        height: Math.min(root.height * 0.8, Kirigami.Units.gridUnit * 20)
        modal: false
        focus: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

        background: Rectangle {
            color: root.bg
            border.color: root.borderColor
            border.width: root.borderWidth
            radius: root.radius
        }

        contentItem: ListView {
            id: cascadeApps
            clip: true
            model: cascadeAppModel
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
            QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
            delegate: Components.AppListItem {
                menuData: menuData
                width: cascadeApps.width
                app: model
                iconSize: root.appIconSize
                showDescription: root.showAppDescriptions
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                onActivated: {
                    root.activateItem(model);
                    cascadePopup.close();
                }
                onContextMenuRequested: (x, y) => root.appContextMenu(model, x, y)
            }
        }
    }

    Ui.ListModelBridge { id: pinnedModel; source: root.homeItems }
    Ui.ListModelBridge { id: categoryModel; source: menuData ? menuData.categories : [] }
    Ui.ListModelBridge { id: appModel; source: menuData ? menuData.searchResults : [] }
    Ui.ListModelBridge { id: cascadeAppModel; source: menuData ? menuData.categoryApps : [] }
}
