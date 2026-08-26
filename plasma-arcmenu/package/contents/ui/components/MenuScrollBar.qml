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

    policy: root.barEnabled ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff
    interactive: true
    padding: 1
    implicitWidth: Kirigami.Units.gridUnit * 0.55
    minimumSize: 0.12
    z: 10

    contentItem: Rectangle {
        implicitWidth: Kirigami.Units.smallSpacing
        implicitHeight: Kirigami.Units.gridUnit
        radius: width / 2
        color: Kirigami.Theme.textColor
        opacity: root.pressed ? 0.55
            : (root.hovered || root.active ? 0.42 : 0.28)
        visible: root.size > 0 && root.size < 1 && root.barEnabled
    }

    background: Item {
        implicitWidth: Kirigami.Units.gridUnit * 0.55
        visible: root.size > 0 && root.size < 1 && root.barEnabled
    }
}
