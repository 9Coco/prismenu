import QtQuick
import ".." as Ui

/** VirtualizedAppList pre-wired to the shared LayoutBase contract. */
VirtualizedAppList {
    id: root

    required property var layoutRoot
    property bool contextMenuForActions: false

    menuData: layoutRoot ? layoutRoot.menuData : null
    iconSize: layoutRoot ? layoutRoot.appIconSize : 24
    showDescription: layoutRoot ? layoutRoot.showAppDescriptions : false
    showGenericNames: layoutRoot ? layoutRoot.showGenericNames : false
    multiLineLabels: layoutRoot ? layoutRoot.multiLineLabels : false
    selectedBg: layoutRoot ? layoutRoot.selectedBg : "transparent"
    selectedFg: layoutRoot ? layoutRoot.selectedFg : "white"
    hoverBg: layoutRoot ? layoutRoot.hoverBg : selectedBg
    hoverFg: layoutRoot ? layoutRoot.hoverFg : selectedFg
    fg: layoutRoot ? layoutRoot.fg : "white"
    reorderModel: root.reorderEnabled ? internalReorderModel : null

    Ui.ListModelBridge {
        id: internalReorderModel
        wrapApp: true
        source: root.items
    }

    Connections {
        target: root
        function onAppActivated(app) {
            if (root.layoutRoot)
                root.layoutRoot.activateItem(app);
        }
        function onAppContextMenu(app, x, y, anchor) {
            if (root.layoutRoot && app && (root.contextMenuForActions || !app.action))
                root.layoutRoot.appContextMenu(app, x, y, anchor);
        }
    }
}
