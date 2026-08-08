import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

/**
 * Page: pinned / home favorites list.
 */
Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    readonly property color fg: themeStyle.fg || Kirigami.Theme.textColor
    readonly property color selectedBg: themeStyle.activeBg || themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color selectedFg: themeStyle.activeFg || themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    readonly property color hoverBg: themeStyle.hoverBg || root.selectedBg
    readonly property color hoverFg: themeStyle.hoverFg || root.selectedFg
    readonly property int iconSize: menuData ? Math.max(menuData.appIconSize, 28) : 28

    ListView {
        id: pinnedList
        anchors.fill: parent
        clip: true
        model: pinnedModel
        spacing: Kirigami.Units.smallSpacing / 2
        boundsBehavior: Flickable.StopAtBounds
        Accessible.name: i18n("Pinned applications")

        delegate: Components.AppListItem {
            width: pinnedList.width
            app: model
            menuData: root.menuData
            iconSize: root.iconSize
            showDescription: false
            selected: pinnedList.currentIndex === index
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            fg: root.fg
            onActivated: root.appActivated(model)
            onContextMenuRequested: (x, y) => root.appContextMenu(model, x, y)
        }
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: pinnedModel.count === 0
        text: i18n("Pin applications from the context menu")
        opacity: 0.45
        color: root.fg
        width: parent.width * 0.8
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    Ui.ListModelBridge {
        id: pinnedModel
        source: menuData ? menuData.pinnedApps : []
    }
}
