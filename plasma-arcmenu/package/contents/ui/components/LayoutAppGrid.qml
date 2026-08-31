import QtQuick

/** AppGrid pre-wired to the shared LayoutBase theme and event contract. */
AppGrid {
    id: root

    required property var layoutRoot
    property bool contextMenuForActions: false

    menuData: layoutRoot ? layoutRoot.menuData : null
    iconSize: layoutRoot ? layoutRoot.gridIconSize : 48
    multiLineLabels: layoutRoot ? layoutRoot.multiLineLabels : true
    showGenericNames: layoutRoot ? layoutRoot.showGenericNames : false
    selectedBg: layoutRoot ? layoutRoot.selectedBg : "transparent"
    selectedFg: layoutRoot ? layoutRoot.selectedFg : "white"
    hoverBg: layoutRoot ? layoutRoot.hoverBg : selectedBg
    hoverFg: layoutRoot ? layoutRoot.hoverFg : selectedFg
    fg: layoutRoot ? layoutRoot.fg : "white"

    Connections {
        target: root
        function onAppActivated(app) {
            if (root.layoutRoot)
                root.layoutRoot.activateItem(app);
        }
        function onContextMenuRequested(app, x, y, anchor) {
            if (root.layoutRoot && app && (root.contextMenuForActions || !app.action))
                root.layoutRoot.appContextMenu(app, x, y, anchor);
        }
    }
}
