import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

/**
 * Page: search results list.
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

    ListView {
        id: appList
        anchors.fill: parent
        clip: true
        model: appModel
        boundsBehavior: Flickable.StopAtBounds
        Accessible.name: i18n("Search results")

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

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: appModel.count === 0
        text: i18n("No matching applications found")
        opacity: 0.6
        color: root.fg
    }

    Ui.ListModelBridge {
        id: appModel
        source: menuData ? menuData.searchResults : []
    }
}
