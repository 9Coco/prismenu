import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

/**
 * Edge / corner drag handles to resize the menu popup.
 * Writes menuWidth / menuHeight through the catalog (MenuData).
 */
Item {
    id: root

    property var menuData: null
    property int minWidth: 400
    property int maxWidth: 900
    property int minHeight: 400
    property int maxHeight: 800
    property int handleThickness: 6
    /** When false (e.g. Raven fill height), only horizontal edges are shown */
    property bool resizeHeight: true

    readonly property int loc: {
        try { return plasmoid.location; } catch (e) { return PlasmaCore.Types.BottomEdge; }
    }
    // Prefer growing away from the panel
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

    function applySize(w, h) {
        if (!root.menuData)
            return;
        if (w !== undefined && root.menuData.setMenuWidth)
            root.menuData.setMenuWidth(root.clampW(w));
        if (h !== undefined && root.menuData.setMenuHeight)
            root.menuData.setMenuHeight(root.clampH(h));
    }

    component EdgeHandle: MouseArea {
        id: edge
        property string edgeRole: "e" // n,s,e,w,se,sw,ne,nw
        property real pressGlobalX: 0
        property real pressGlobalY: 0
        property int pressW: 0
        property int pressH: 0

        z: 50
        hoverEnabled: true
        preventStealing: true
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
            pressW = root.menuData ? root.menuData.menuWidth : 620;
            pressH = root.menuData ? root.menuData.menuHeight : 540;
        }
        onPositionChanged: (mouse) => {
            if (!pressed || !root.menuData)
                return;
            var g = mapToGlobal(mouse.x, mouse.y);
            var dx = g.x - pressGlobalX;
            var dy = g.y - pressGlobalY;
            var w = pressW;
            var h = pressH;
            var role = edge.edgeRole;
            var changeW = false;
            var changeH = false;
            // Match whole tokens so "ne" is east+north, not confused with lone letters
            if (role === "e" || role === "ne" || role === "se") {
                w = pressW + dx;
                changeW = true;
            } else if (role === "w" || role === "nw" || role === "sw") {
                w = pressW - dx;
                changeW = true;
            }
            if (role === "s" || role === "se" || role === "sw") {
                h = pressH + dy;
                changeH = true;
            } else if (role === "n" || role === "ne" || role === "nw") {
                h = pressH - dy;
                changeH = true;
            }
            root.applySize(changeW ? w : undefined, changeH ? h : undefined);
        }
    }

    // Edges
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

    // Corners
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

    // Subtle affordance on the primary grow corner (bottom panel → top-right)
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
