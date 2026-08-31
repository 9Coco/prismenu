import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/AppDrag.js" as AppDrag
import "../../code/SearchExtras.js" as SearchExtras

GridView {
    id: root

    property var items: []
    property var menuData: null
    property int iconSize: 48
    property int columns: 6
    /** When > 0, column count is floor(width / minCellWidth) so cells shrink/grow with the pane. */
    property int minCellWidth: 0
    property bool showDescription: false
    property bool multiLineLabels: true
    property bool showGenericNames: false
    /** Pinned/favorite views: tiles accept drop-to-reorder / drop-to-pin. */
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
    signal contextMenuRequested(var app, real x, real y)

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
    // GridView otherwise selects row 0 automatically, leaving the first tile
    // blue even while another tile is merely hovered.
    currentIndex: -1
    // Kickoff/Kicker: the dragged cell moves, and mid-list cells make way.
    move: Transition {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            properties: "x,y"
            easing.type: Easing.OutCubic
        }
    }
    moveDisplaced: Transition {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            properties: "x,y"
            easing.type: Easing.OutCubic
        }
    }
    readonly property int resolvedColumns: {
        if (minCellWidth > 0 && width > 0)
            return Math.max(1, Math.floor(width / minCellWidth));
        return Math.max(1, columns);
    }
    cellWidth: Math.max(1, width / Math.max(1, resolvedColumns))
    readonly property int cellIconSize: minCellWidth > 0
        ? Math.max(20, Math.min(iconSize, Math.round(cellWidth * 0.48)))
        : iconSize
    // Icon + up to two label lines. Too-short cells stack delegates and
    // clicks in the "empty" gap hit the overlapping row.
    cellHeight: minCellWidth > 0
        ? (cellIconSize + Kirigami.Units.gridUnit * 3)
        : (iconSize + Kirigami.Units.gridUnit * 2)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    QQC2.ScrollBar.vertical: MenuScrollBar { menuData: root.menuData }
    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
    reuseItems: true
    cacheBuffer: Math.max(height, cellHeight * 2)
    Accessible.name: i18n("Applications")
    Accessible.role: Accessible.List

    // KickoffDropArea: one view-level target so indexAt() can hop the
    // dragged row onto the hovered cell and mid-list tiles make way.
    PinnedDropArea {
        anchors.fill: parent
        targetView: root
        menuData: root.menuData
        reorderEnabled: root.reorderEnabled
    }

    delegate: Item {
        id: del
        required property int index
        readonly property var app: {
            if (!root.reorderModel)
                return root.items[index];
            var id = "";
            try { id = String(model.appId || ""); } catch (e) { id = ""; }
            if (!id && root.reorderModel.appIdAt)
                id = root.reorderModel.appIdAt(index);
            return root.appForId(id);
        }
        width: root.cellWidth
        height: root.cellHeight
        clip: true

        readonly property int tilePad: Kirigami.Units.smallSpacing
        readonly property int labelWidth: Math.min(
            del.width - Kirigami.Units.largeSpacing,
            root.cellIconSize + Kirigami.Units.gridUnit * 2)
        readonly property bool draggable: !!(del.app && !del.app.isSection
            && (AppDrag.canDragOut(del.app) || root.reorderEnabled))
        readonly property bool dropHover: false

        // Highlight hugs the icon + label, matching Application Dashboard.
        Rectangle {
            id: tileBg
            anchors.centerIn: parent
            width: Math.min(del.width - Kirigami.Units.largeSpacing,
                            Math.max(root.cellIconSize, del.labelWidth) + del.tilePad * 2)
            height: Math.min(del.height - Kirigami.Units.largeSpacing,
                             dragGhost.implicitHeight + del.tilePad * 2)
            radius: Kirigami.Units.smallSpacing
            color: {
                if (del.dropHover)
                    return root.selectedBg;
                if (root.activeFocus && root.currentIndex === del.index)
                    return root.selectedBg;
                if (mouse.containsMouse)
                    return root.hoverBg;
                return "transparent";
            }
        }

        // Drag surface: stays put in its slot; the grabbed snapshot is the
        // drag image (same pattern as Plasma's desktop containment). Carries
        // the launcher payload to the desktop / pinned tiles.
        Item {
            id: dragGhost
            anchors.fill: tileBg
            readonly property string dragAppId: del.app ? String(del.app.id || "") : ""
            readonly property int dragIndex: del.index
            readonly property Item dragView: root
            readonly property int implicitHeight: contentCol.implicitHeight
            visible: !dragGhost.Drag.active
            Drag.dragType: Drag.Automatic
            Drag.hotSpot.x: Math.round(dragGhost.width / 2)
            Drag.hotSpot.y: Math.round(dragGhost.height / 2)
            Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
            Drag.mimeData: AppDrag.mimeDataFor(del.app)
            Drag.onDragStarted: AppDrag.resetLiveReorder()
            Drag.onDragFinished: AppDrag.finishDrag(root.menuData)

            Column {
                id: contentCol
                anchors.centerIn: parent
                width: del.labelWidth
                spacing: Kirigami.Units.smallSpacing / 2

                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: SearchExtras.resultIconSource(del.app)
                    fallback: (del.app && del.app.icon) ? del.app.icon : "application-x-executable"
                    width: root.cellIconSize
                    height: root.cellIconSize
                    animated: false
                }

                PlasmaComponents.Label {
                    width: parent.width
                    text: {
                        if (!del.app)
                            return "";
                        if (root.showGenericNames && del.app.genericName)
                            return del.app.genericName;
                        return del.app.name || "";
                    }
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: root.multiLineLabels ? Text.Wrap : Text.NoWrap
                    maximumLineCount: root.multiLineLabels ? 2 : 1
                    readonly property color labelColor: {
                        if (root.activeFocus && root.currentIndex === del.index)
                            return root.selectedFg;
                        if (mouse.containsMouse)
                            return root.hoverFg;
                        return root.fg;
                    }
                    color: labelColor
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.textColor: labelColor
                }
            }
        }

        // Only the tile launches. Empty padding around it does nothing.
        MouseArea {
            id: mouse
            anchors.fill: tileBg
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            property bool dragStarted: false
            property real pressX: 0
            property real pressY: 0

            // Left-button drags only — right-click keeps opening the menu.
            // Start the drag past the platform threshold; the grabbed tile
            // snapshot becomes the drag image (Drag.Automatic).
            function maybeStartDrag(event) {
                if (!del.draggable || mouse.dragStarted || dragGhost.Drag.active)
                    return;
                if (!(event.buttons & Qt.LeftButton))
                    return;
                var dx = event.x - mouse.pressX;
                var dy = event.y - mouse.pressY;
                var threshold = Qt.styleHints.startDragDistance;
                if (dx * dx + dy * dy < threshold * threshold)
                    return;
                mouse.dragStarted = true;
                dragGhost.grabToImage(function (result) {
                    dragGhost.Drag.imageSource = result.url;
                    dragGhost.Drag.active = true;
                });
            }
            onPressed: (event) => {
                if (event.button === Qt.LeftButton) {
                    mouse.dragStarted = false;
                    mouse.pressX = event.x;
                    mouse.pressY = event.y;
                }
            }
            onPositionChanged: (event) => mouse.maybeStartDrag(event)
            onClicked: (event) => {
                if (!del.app || del.app.isSection)
                    return;
                if (mouse.dragStarted) {
                    mouse.dragStarted = false;
                    return;
                }
                root.currentIndex = del.index;
                if (event.button === Qt.RightButton) {
                    root.contextMenuRequested(del.app, event.x, event.y);
                } else {
                    root.appActivated(del.app);
                }
            }
        }

        Accessible.name: del.app ? (del.app.name || "") : ""
        Accessible.role: Accessible.Button
        Accessible.onPressAction: if (del.app) root.appActivated(del.app)
    }

    Keys.onReturnPressed: {
        if (currentIndex >= 0 && root.items && currentIndex < root.items.length)
            appActivated(root.items[currentIndex]);
    }
}
