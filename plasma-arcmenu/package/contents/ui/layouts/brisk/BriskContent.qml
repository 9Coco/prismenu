import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../components" as Components

/**
 * Brisk right content pane: pinned apps, category apps, or search results.
 */
Item {
    id: root

    property var menuData: null
    property string selectedId: "pinned"
    property bool searching: false
    property int iconSize: 28
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color fg: Kirigami.Theme.textColor

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    readonly property var items: {
        if (!menuData) {
            return [];
        }
        if (searching) {
            return menuData.searchResults || [];
        }
        if (selectedId === "pinned") {
            return menuData.pinnedApps || [];
        }
        if (selectedId === "all") {
            return menuData.categoryApps || [];
        }
        // Category id
        return menuData.categoryApps || [];
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Accessible.name: i18n("Applications")

        Column {
            id: col
            width: flick.width
            spacing: Kirigami.Units.smallSpacing / 2

            Repeater {
                model: root.items.length
                Components.AppListItem {
                    required property int index
                    width: col.width
                    app: root.items[index]
                    iconSize: root.iconSize
                    showDescription: root.searching && menuData ? menuData.showSearchDescription : false
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    fg: root.fg
                    onActivated: root.appActivated(root.items[index])
                    onContextMenuRequested: (x, y) => {
                        var a = root.items[index];
                        if (a && !a.action) {
                            root.appContextMenu(a, x, y);
                        }
                    }
                }
            }
        }
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: root.items.length === 0
        text: {
            if (root.searching) {
                return i18n("No matching applications found");
            }
            if (root.selectedId === "pinned") {
                return i18n("Pin applications from the context menu");
            }
            return i18n("No applications");
        }
        opacity: 0.45
        color: root.fg
        width: parent.width * 0.8
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
