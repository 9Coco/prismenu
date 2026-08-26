import QtQuick
import QtQuick.Controls as QQC2
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
    readonly property color selectedBg: themeStyle.activeBg || themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color selectedFg: themeStyle.activeFg || themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    readonly property color hoverBg: themeStyle.hoverBg || root.selectedBg
    readonly property color hoverFg: themeStyle.hoverFg || root.selectedFg
    readonly property int appIconSize: menuData ? menuData.appIconSize : 24

    ListView {
        id: appList
        anchors.fill: parent
        clip: true
        model: appModel
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
        QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
        Accessible.name: i18n("Search results")

        delegate: Components.AppListItem {
            width: appList.width
            app: model
            menuData: root.menuData
            iconSize: root.appIconSize
            showDescription: menuData ? menuData.showSearchDescription : true
            selected: !(model && model.isSection) && appList.currentIndex === index
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            fg: root.fg
            onActivated: {
                if (model && model.isSection)
                    return;
                root.appActivated(model);
            }
            onContextMenuRequested: (x, y) => {
                if (model && model.isSection)
                    return;
                root.appContextMenu(model, x, y);
            }
        }
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: appModel.count === 0
        text: {
            if (!menuData)
                return i18n("No matching applications found");
            try {
                return menuData.tr ? menuData.tr("No matching applications found")
                    : i18n("No matching applications found");
            } catch (e) {
                return i18n("No matching applications found");
            }
        }
        opacity: 0.6
        color: root.fg
    }

    Ui.ListModelBridge {
        id: appModel
        source: menuData ? menuData.searchResults : []
    }
}
