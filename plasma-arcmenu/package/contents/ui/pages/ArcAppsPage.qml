import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

/**
 * Page: category sidebar + application list.
 */
Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    readonly property color fg: themeStyle.fg || Kirigami.Theme.textColor
    readonly property color selectedBg: themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color selectedFg: themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    readonly property int appIconSize: menuData ? menuData.appIconSize : 24
    readonly property int categoryIconSize: menuData ? menuData.categoryIconSize : 24

    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Components.CategoryList {
            Layout.preferredWidth: parent.width * 0.36
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
                Accessible.name: i18n("Applications")

                delegate: Components.AppListItem {
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

            PlasmaComponents.Label {
                anchors.centerIn: parent
                visible: appModel.count === 0
                text: i18n("No applications")
                opacity: 0.6
                color: root.fg
            }
        }
    }

    Ui.ListModelBridge {
        id: categoryModel
        source: menuData ? menuData.categories : []
    }
    Ui.ListModelBridge {
        id: appModel
        source: menuData ? menuData.categoryApps : []
    }
}
