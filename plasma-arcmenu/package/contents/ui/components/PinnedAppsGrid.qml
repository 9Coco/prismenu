import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/AppDrag.js" as AppDrag

GridView {
    id: root

    property int columns: 6
    property int iconSize: 32
    /** Catalog access for drop-to-reorder / drop-to-pin on the cells. */
    property var menuData: null
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg

    signal appActivated(var app)
    signal contextMenuRequested(var app, real x, real y, var anchor)
    signal reorderRequested(int from, int to)

    cellWidth: Math.max(Kirigami.Units.gridUnit * 3, width / Math.max(1, columns))
    cellHeight: iconSize + Kirigami.Units.gridUnit * 1.6
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
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
    QQC2.ScrollBar.vertical: MenuScrollBar {}
    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
    Accessible.name: i18n("Pinned applications")
    Accessible.role: Accessible.List

    PinnedDropArea {
        anchors.fill: parent
        targetView: root
        menuData: root.menuData
        reorderEnabled: true
    }

    delegate: Item {
        id: del
        required property var model
        required property int index
        width: root.cellWidth
        height: root.cellHeight
        readonly property bool dropHover: false

        // Highlight hugs the icon+label content instead of the whole cell
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(del.width - Kirigami.Units.smallSpacing,
                            contentCol.implicitWidth + Kirigami.Units.largeSpacing)
            height: Math.min(del.height - Kirigami.Units.smallSpacing,
                             contentCol.implicitHeight + Kirigami.Units.smallSpacing)
            radius: Kirigami.Units.smallSpacing * 1.5
            color: {
                if (del.dropHover)
                    return root.hoverBg;
                return mouse.containsMouse ? root.hoverBg : "transparent";
            }
        }

        // Drag surface: stays put in its cell; the grabbed snapshot is the
        // drag image (same pattern as Plasma's desktop containment). Carries
        // the launcher payload (drop on desktop/panel → KIO paste dialog).
        Item {
            id: dragGhost
            anchors.centerIn: parent
            readonly property string dragAppId: String(model.id || model.appId || "")
            readonly property int dragIndex: del.index
            readonly property Item dragView: root
            width: contentCol.implicitWidth + Kirigami.Units.largeSpacing
            height: contentCol.implicitHeight + Kirigami.Units.smallSpacing
            visible: !dragGhost.Drag.active
            Drag.dragType: Drag.Automatic
            Drag.hotSpot.x: Math.round(dragGhost.width / 2)
            Drag.hotSpot.y: Math.round(dragGhost.height / 2)
            Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
            Drag.mimeData: AppDrag.mimeDataFor(model)
            Drag.onDragStarted: AppDrag.resetLiveReorder()
            Drag.onDragFinished: AppDrag.finishDrag(root.menuData)

            ColumnLayout {
                id: contentCol
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing / 2

                ResolvedIcon {
                    iconName: model.icon || "application-x-executable"
                    // Real app icons must stay unmasked; bundled/preset names
                    // (if any) still resolve to their SVGs
                    preferSymbolic: false
                    tintColor: mouse.containsMouse ? root.hoverFg : Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.iconSize
                    Layout.preferredHeight: root.iconSize
                }

                PlasmaComponents.Label {
                    text: model.name || ""
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    Layout.maximumWidth: del.width - Kirigami.Units.smallSpacing * 2
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: mouse.containsMouse ? root.hoverFg : Kirigami.Theme.textColor
                }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property bool dragStarted: false
            property real pressX: 0
            property real pressY: 0

            // Left-button drags only — right-click keeps opening the menu.
            // Start the drag past the platform threshold; the grabbed cell
            // snapshot becomes the drag image (Drag.Automatic).
            function maybeStartDrag(event) {
                if (mouse.dragStarted || dragGhost.Drag.active)
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
            onReleased: (event) => {
                if (event.button === Qt.LeftButton && !mouse.dragStarted)
                    root.appActivated(model);
            }
            onClicked: (event) => {
                if (mouse.dragStarted) {
                    mouse.dragStarted = false;
                    return;
                }
                if (event.button === Qt.RightButton)
                    root.contextMenuRequested(model, event.x, event.y, mouse);
            }
        }

        Accessible.name: model.name || ""
        Accessible.role: Accessible.Button
        Accessible.onPressAction: root.appActivated(model)
    }
}
