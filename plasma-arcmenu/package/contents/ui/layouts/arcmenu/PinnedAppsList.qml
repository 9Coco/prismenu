import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

/**
 * Page-display piece: pinned / favorite applications list (home page).
 * Uses Repeater (not ListModelBridge) so JS arrays always show.
 */
Item {
    id: root

    property var menuData: null
    property var apps: []
    property int iconSize: 28
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color fg: Kirigami.Theme.textColor

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    readonly property var items: {
        if (apps && apps.length) {
            return apps;
        }
        if (menuData && menuData.pinnedApps && menuData.pinnedApps.length) {
            return menuData.pinnedApps;
        }
        // Hard fallback matching official ArcMenu defaults
        return [
            {
                id: "org.kde.dolphin.desktop",
                name: i18n("Files"),
                icon: "system-file-manager",
                exec: "dolphin",
                noDisplay: false
            },
            {
                id: "arcmenu-settings",
                name: i18n("ArcMenu Settings"),
                icon: "preferences-system-windows",
                exec: "",
                action: "configure",
                noDisplay: false
            }
        ];
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Accessible.name: i18n("Pinned applications")

        Column {
            id: column
            width: flick.width
            spacing: Kirigami.Units.smallSpacing / 2

            Repeater {
                model: root.items.length
                AppListItem {
                    required property int index
                    width: column.width
                    app: root.items[index]
                    iconSize: root.iconSize
                    showDescription: false
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
        text: i18n("Pin applications from the context menu")
        opacity: 0.45
        color: root.fg
        width: parent.width * 0.8
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
