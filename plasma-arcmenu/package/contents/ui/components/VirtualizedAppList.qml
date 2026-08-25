import QtQuick
import org.kde.kirigami as Kirigami

/**
 * Shared virtualized application list for every layout.
 *
 * Callers provide a plain JS array through `items`; the ListView uses an
 * integer model so it does not need to copy the array into a ListModel. Only
 * viewport-near AppListItem delegates are created, reused, and kept warm.
 */
ListView {
    id: root

    property var items: []
    property var menuData: null
    property int iconSize: 24
    property bool showDescription: false
    property bool showGenericNames: false
    property bool multiLineLabels: false
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg
    property color fg: Kirigami.Theme.textColor

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    model: items ? items.length : 0
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: -1
    keyNavigationWraps: true
    reuseItems: true
    cacheBuffer: Math.max(height, Kirigami.Units.gridUnit * 12)
    spacing: Kirigami.Units.smallSpacing / 2
    Accessible.role: Accessible.List
    Accessible.name: qsTr("Applications")

    function warmViewport() {
        if (count > 0)
            forceLayout();
    }

    onCountChanged: {
        if (count > 0)
            Qt.callLater(root.warmViewport);
    }
    Component.onCompleted: {
        if (count > 0)
            Qt.callLater(root.warmViewport);
    }

    delegate: AppListItem {
        required property int index
        readonly property var itemData: root.items[index]

        width: ListView.view.width
        app: itemData
        menuData: root.menuData
        iconSize: root.iconSize
        showDescription: root.showDescription
        showGenericNames: root.showGenericNames
        multiLineLabels: root.multiLineLabels
        selected: !isSection && root.currentIndex === index
        selectedBg: root.selectedBg
        selectedFg: root.selectedFg
        hoverBg: root.hoverBg
        hoverFg: root.hoverFg
        fg: root.fg

        onActivated: {
            if (itemData && !itemData.isSection)
                root.appActivated(itemData);
        }
        onContextMenuRequested: (x, y) => {
            if (itemData && !itemData.isSection)
                root.appContextMenu(itemData, x, y);
        }
    }
}
