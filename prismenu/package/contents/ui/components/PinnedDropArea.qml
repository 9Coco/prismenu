import QtQuick
import "../../code/AppDrag.js" as AppDrag

/**
 * KickoffDropArea equivalent: one DropArea over a ListView/GridView that
 * live-moves the dragged row onto the cell under the pointer. Mid-list
 * items make way through the view's move / moveDisplaced transitions.
 *
 * Official reference: plasma-desktop applets/kickoff KickoffDropArea.qml
 * (model.move(source.index, targetIndex, 1) while !move.running).
 */
DropArea {
    id: root

    required property Item targetView
    property var menuData: null
    property bool reorderEnabled: true

    enabled: root.reorderEnabled && !!root.targetView

    function targetIndexAt(x, y) {
        var view = root.targetView;
        if (!view || view.count <= 0)
            return -1;
        var pos = root.mapToItem(view.contentItem, x, y);
        var idx = view.indexAt(pos.x, pos.y);
        if (idx >= 0)
            return idx;
        // Empty tail past the last cell → last index (append slot).
        var last = view.itemAtIndex(view.count - 1);
        if (!last)
            return view.count - 1;
        var lastPos = root.mapFromItem(last, 0, 0);
        if (y > lastPos.y + last.height)
            return view.count - 1;
        if (y >= lastPos.y && x > lastPos.x + last.width)
            return view.count - 1;
        return -1;
    }

    onEntered: (event) => {
        if (AppDrag.isPinDrag(event))
            event.accept(Qt.MoveAction);
    }
    onPositionChanged: (event) => {
        if (!AppDrag.isPinDrag(event))
            return;
        event.accept(Qt.MoveAction);
        AppDrag.movePinnedInView(root.targetView, root.menuData, event,
            root.targetIndexAt(event.x, event.y));
    }
    onDropped: (event) => {
        AppDrag.dropPinnedInView(root.targetView, root.menuData, event,
            root.targetIndexAt(event.x, event.y));
    }
}
