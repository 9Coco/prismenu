import QtQuick
import QtQuick.Controls as QQC2
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
    property bool inlineDescription: false
    property bool showGenericNames: false
    property bool multiLineLabels: false
    /** Pinned/favorite views: rows accept drop-to-reorder / drop-to-pin. */
    property bool reorderEnabled: false
    /** Optional ListModel (role `app`) backing reorderable pinned views.
     *  When set, row moves animate because the bridge emits rowsMoved. */
    property var reorderModel: null
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg
    property color fg: Kirigami.Theme.textColor

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y, var anchor)

    function appForId(id) {
        var wanted = String(id || "");
        var source = root.items || [];
        for (var i = 0; i < source.length; ++i) {
            if (source[i] && String(source[i].id || "") === wanted)
                return source[i];
        }
        return null;
    }

    model: root.reorderModel ? root.reorderModel : (items ? items.length : 0)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: -1
    // Kickoff/Kicker: the dragged row moves, and mid-list rows make way.
    move: Transition {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            properties: "y"
            easing.type: Easing.OutCubic
        }
    }
    moveDisplaced: Transition {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            properties: "y"
            easing.type: Easing.OutCubic
        }
    }
    QQC2.ScrollBar.vertical: MenuScrollBar { menuData: root.menuData }
    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
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
    onItemsChanged: {
        // Providers update asynchronously. Do not inherit contentY from the
        // previous category/result snapshot or its first groups disappear
        // above the viewport despite still being present in the model.
        // Reorderable pinned views keep their scroll offset: a live
        // Kickoff-style move only reshuffles the same rows.
        currentIndex = -1;
        if (root.reorderEnabled)
            return;
        Qt.callLater(function () {
            if (root.count > 0)
                root.positionViewAtBeginning();
        });
    }
    Component.onCompleted: {
        if (count > 0)
            Qt.callLater(root.warmViewport);
    }

    PinnedDropArea {
        anchors.fill: parent
        targetView: root
        menuData: root.menuData
        reorderEnabled: root.reorderEnabled
    }

    delegate: AppListItem {
        required property int index
        readonly property var entryData: {
            if (!root.reorderModel)
                return root.items[index];
            var id = "";
            try { id = String(model.appId || ""); } catch (e) { id = ""; }
            if (!id && root.reorderModel.appIdAt)
                id = root.reorderModel.appIdAt(index);
            return root.appForId(id);
        }

        width: ListView.view.width
        app: entryData
        modelIndex: index
        menuData: root.menuData
        iconSize: root.iconSize
        showDescription: root.showDescription
        inlineDescription: root.inlineDescription
        showGenericNames: root.showGenericNames
        multiLineLabels: root.multiLineLabels
        reorderEnabled: root.reorderEnabled
        selected: !isSection && root.currentIndex === index
        selectedBg: root.selectedBg
        selectedFg: root.selectedFg
        hoverBg: root.hoverBg
        hoverFg: root.hoverFg
        fg: root.fg

        onActivated: {
            if (entryData && !entryData.isSection)
                root.appActivated(entryData);
        }
        onContextMenuRequested: (x, y, anchor) => {
            if (entryData && !entryData.isSection)
                root.appContextMenu(entryData, x, y, anchor);
        }
    }
}
