import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

/**
 * Functional module: single icon+label row used by Places / system shortcuts.
 */
Item {
    id: root

    property string iconName: "application-x-executable"
    property string label: ""
    property int iconSize: 22
    property bool selected: false
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg
    property color fg: Kirigami.Theme.textColor

    readonly property bool hot: root.selected || mouse.containsMouse
    readonly property color chipBg: root.selected ? root.selectedBg
        : (mouse.containsMouse ? root.hoverBg : "transparent")
    readonly property color chipFg: root.selected ? root.selectedFg
        : (mouse.containsMouse ? root.hoverFg : root.fg)

    signal activated()
    signal contextMenuRequested(real x, real y)

    height: Math.max(iconSize + Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 1.85)
    Accessible.name: label
    Accessible.role: Accessible.Button
    Accessible.onPressAction: root.activated()

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.smallSpacing
        color: root.chipBg
        opacity: root.hot ? 1 : 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        ResolvedIcon {
            iconName: root.iconName
            tintColor: root.chipFg
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
            color: root.chipFg
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.contextMenuRequested(mouse.x, mouse.y);
            else
                root.activated();
        }
    }
}
