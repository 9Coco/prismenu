import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

/**
 * Draggable vertical scrollbar for menu Flickables (Kickoff-style).
 * Honors Fine-tuning → Show scrollbars / Overlay scrollbars.
 */
QQC2.ScrollBar {
    id: root

    property var menuData: null

    readonly property bool barEnabled: !menuData || menuData.showScrollbars !== false
    readonly property bool overlay: !menuData || menuData.overlayScrollbars !== false
    readonly property bool overflowing: root.size > 0 && root.size < 1

    policy: root.barEnabled ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff
    interactive: true
    padding: 1
    implicitWidth: Kirigami.Units.gridUnit * 0.55
    minimumSize: 0.12
    z: 10

    // Inset mode: keep the thumb in its own strip so category/places rows
    // stay clickable and the bar sits in the column gap instead of covering
    // labels. Overlay mode leaves Flickable margins alone.
    Binding {
        target: root.parent
        property: "rightMargin"
        when: !!(root.parent && root.parent.rightMargin !== undefined)
        value: (!root.overlay && root.barEnabled && root.overflowing)
               ? root.implicitWidth : 0
    }

    contentItem: Rectangle {
        implicitWidth: Kirigami.Units.smallSpacing
        implicitHeight: Kirigami.Units.gridUnit
        radius: width / 2
        color: Kirigami.Theme.textColor
        opacity: root.pressed ? 0.7
            : (root.hovered || root.active ? 0.55 : 0.4)
        visible: root.overflowing && root.barEnabled
    }

    background: Item {
        implicitWidth: Kirigami.Units.gridUnit * 0.55
        visible: root.overflowing && root.barEnabled
    }
}
