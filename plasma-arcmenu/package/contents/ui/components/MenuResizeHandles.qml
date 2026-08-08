import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

/**
 * Edge / corner drag handles to resize the menu popup.
 *
 * While dragging, only liveWidth / liveHeight change (one cheap property
 * write per mouse move — no config writes, no direct window manipulation).
 * The host (main.qml) binds the popup's Layout.minimumWidth/maximumWidth
 * (and height) to these values; libplasma's AppletPopup always applies
 * min/max size changes to the window, in BOTH directions, even when it
 * ignores Layout.preferredWidth (which happens as soon as a popup size has
 * been remembered in the applet config). This is what makes shrinking work.
 *
 * The final size is persisted once, through the catalog (MenuData), when
 * the drag ends.
 */
Item {
    id: root

    property var menuData: null
    /** Extra popup width outside menuWidth (layout side panel). */
    property int sideWidth: 0
    property int minWidth: 400
    property int maxWidth: 900
    property int minHeight: 400
    property int maxHeight: 800
    property int handleThickness: 6
    property bool resizeHeight: true

    /** Live drag size (content, excluding sideWidth); -1 while idle. */
    property int liveWidth: -1
    property int liveHeight: -1
    readonly property bool dragging: liveWidth > 0 || liveHeight > 0

    readonly property int loc: {
        try { return plasmoid.location; } catch (e) { return PlasmaCore.Types.BottomEdge; }
    }
    readonly property bool showTop: resizeHeight && (
        loc === PlasmaCore.Types.BottomEdge
        || loc === PlasmaCore.Types.Floating
        || loc === PlasmaCore.Types.Desktop)
    readonly property bool showBottom: resizeHeight && (
        loc === PlasmaCore.Types.TopEdge
        || loc === PlasmaCore.Types.Floating
        || loc === PlasmaCore.Types.Desktop)
    readonly property bool showLeft: loc === PlasmaCore.Types.RightEdge
        || loc === PlasmaCore.Types.Floating
        || loc === PlasmaCore.Types.Desktop
    readonly property bool showRight: loc === PlasmaCore.Types.LeftEdge
        || loc === PlasmaCore.Types.Floating
        || loc === PlasmaCore.Types.Desktop
        || loc === PlasmaCore.Types.BottomEdge
        || loc === PlasmaCore.Types.TopEdge

    function clampW(w) {
        return Math.max(root.minWidth, Math.min(root.maxWidth, Math.round(w)));
    }
    function clampH(h) {
        return Math.max(root.minHeight, Math.min(root.maxHeight, Math.round(h)));
    }

    /** Persist the dragged size once, then leave live-drag mode. */
    function commitDrag() {
        if (root.menuData) {
            if (root.liveWidth > 0 && root.menuData.setMenuWidth)
                root.menuData.setMenuWidth(root.liveWidth);
            if (root.liveHeight > 0 && root.menuData.setMenuHeight)
                root.menuData.setMenuHeight(root.liveHeight);
        }
        root.liveWidth = -1;
        root.liveHeight = -1;
    }

    component EdgeHandle: MouseArea {
        id: edge
        property string edgeRole: "e"
        property real pressGlobalX: 0
        property real pressGlobalY: 0
        property int pressW: 0
        property int pressH: 0

        z: 50
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton
        cursorShape: {
            switch (edgeRole) {
            case "e":
            case "w": return Qt.SizeHorCursor;
            case "n":
            case "s": return Qt.SizeVerCursor;
            case "ne":
            case "sw": return Qt.SizeBDiagCursor;
            default: return Qt.SizeFDiagCursor;
            }
        }

        onPressed: (mouse) => {
            var g = mapToGlobal(mouse.x, mouse.y);
            pressGlobalX = g.x;
            pressGlobalY = g.y;
            // Seed from what is actually on screen, not from the config —
            // the two can disagree (e.g. stale remembered popup size), which
            // used to make the first drag appear to do nothing.
            pressW = root.clampW(root.width - root.sideWidth);
            pressH = root.clampH(root.height);
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return;
            var g = mapToGlobal(mouse.x, mouse.y);
            var dx = g.x - pressGlobalX;
            var dy = g.y - pressGlobalY;
            var role = edge.edgeRole;
            if (role === "e" || role === "ne" || role === "se")
                root.liveWidth = root.clampW(pressW + dx);
            else if (role === "w" || role === "nw" || role === "sw")
                root.liveWidth = root.clampW(pressW - dx);
            if (role === "s" || role === "se" || role === "sw")
                root.liveHeight = root.clampH(pressH + dy);
            else if (role === "n" || role === "ne" || role === "nw")
                root.liveHeight = root.clampH(pressH - dy);
        }
        onReleased: root.commitDrag()
        onCanceled: root.commitDrag()
    }

    EdgeHandle {
        visible: root.showTop
        edgeRole: "n"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.handleThickness
        anchors.leftMargin: root.handleThickness
        anchors.rightMargin: root.handleThickness
    }
    EdgeHandle {
        visible: root.showBottom
        edgeRole: "s"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.handleThickness
        anchors.leftMargin: root.handleThickness
        anchors.rightMargin: root.handleThickness
    }
    EdgeHandle {
        visible: root.showLeft
        edgeRole: "w"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.handleThickness
        anchors.topMargin: root.handleThickness
        anchors.bottomMargin: root.handleThickness
    }
    EdgeHandle {
        visible: root.showRight
        edgeRole: "e"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.handleThickness
        anchors.topMargin: root.handleThickness
        anchors.bottomMargin: root.handleThickness
    }
    EdgeHandle {
        visible: root.showTop && root.showRight
        edgeRole: "ne"
        anchors.top: parent.top
        anchors.right: parent.right
        width: root.handleThickness * 2
        height: root.handleThickness * 2
    }
    EdgeHandle {
        visible: root.showTop && root.showLeft
        edgeRole: "nw"
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.handleThickness * 2
        height: root.handleThickness * 2
    }
    EdgeHandle {
        visible: root.showBottom && root.showRight
        edgeRole: "se"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.handleThickness * 2
        height: root.handleThickness * 2
    }
    EdgeHandle {
        visible: root.showBottom && root.showLeft
        edgeRole: "sw"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.handleThickness * 2
        height: root.handleThickness * 2
    }

    Rectangle {
        z: 49
        width: Kirigami.Units.smallSpacing * 2
        height: width
        radius: 1
        opacity: 0.35
        color: Kirigami.Theme.textColor
        visible: root.showTop && root.showRight
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 2
    }
}
