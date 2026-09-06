import QtQuick
import org.kde.kirigami as Kirigami

/**
 * Vertical drag handle between two columns.
 * Persist width via onWidthDragged(newWidth).
 *
 * sidebarOnRight (default true, LTR ArcMenu): drag left → grow sidebar.
 * sidebarOnRight false (categories on left): drag right → grow sidebar.
 * When parent uses RightToLeft flip, pass flipped=true to invert drag math.
 */
Item {
    id: root

    property color fg: Kirigami.Theme.textColor
    /** Current sidebar/column width being edited */
    property int currentWidth: 220
    property int minWidth: 160
    property int maxWidth: 360
    /**
     * true  = resizable column is on the visual right (LTR ArcMenu places)
     * false = resizable column is on the visual left (Brisk categories)
     */
    property bool sidebarOnRight: true
    /** Match RowLayout.layoutDirection === Qt.RightToLeft */
    property bool flipped: false

    signal widthDragged(int newWidth)

    // Used inside RowLayout
    implicitWidth: Kirigami.Units.smallSpacing * 2
    implicitHeight: parent ? parent.height : Kirigami.Units.gridUnit * 4

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: Math.min(parent.height * 0.35, Kirigami.Units.gridUnit * 4)
        radius: 1
        color: root.fg
        opacity: splitMouse.containsMouse || splitMouse.pressed ? 0.55 : 0.22
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    }

    MouseArea {
        id: splitMouse
        anchors.fill: parent
        anchors.leftMargin: -2
        anchors.rightMargin: -2
        hoverEnabled: true
        cursorShape: Qt.SplitHCursor
        preventStealing: true
        property real pressGlobalX: 0
        property int pressWidth: 220

        onPressed: (mouse) => {
            var g = mapToGlobal(mouse.x, mouse.y);
            pressGlobalX = g.x;
            pressWidth = root.currentWidth;
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return;
            var g = mapToGlobal(mouse.x, mouse.y);
            var dx = g.x - pressGlobalX;
            // Effective: growing the sidebar when dragging the handle toward the main content
            var growPositive = root.sidebarOnRight ? -dx : dx;
            if (root.flipped)
                growPositive = -growPositive;
            var next = pressWidth + growPositive;
            next = Math.max(root.minWidth, Math.min(root.maxWidth, Math.round(next)));
            root.widthDragged(next);
        }
    }
}
