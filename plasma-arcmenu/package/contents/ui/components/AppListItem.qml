import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root

    property var app: null
    property int iconSize: 24
    property bool showDescription: true
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

    height: Math.max(iconSize + Kirigami.Units.smallSpacing * 2,
                     showDescription && app && app.genericName ? Kirigami.Units.gridUnit * 2.2 : Kirigami.Units.gridUnit * 1.8)
    Accessible.name: app ? app.name : ""
    Accessible.role: Accessible.ListItem
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

        Kirigami.Icon {
            source: root.app ? root.app.icon : "application-x-executable"
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                text: root.app ? root.app.name : ""
                elide: Text.ElideRight
                Layout.fillWidth: true
                color: root.chipFg
                font.weight: Font.Medium
            }

            PlasmaComponents.Label {
                visible: root.showDescription && root.app && root.app.genericName
                text: root.app && root.app.genericName ? root.app.genericName : ""
                elide: Text.ElideRight
                Layout.fillWidth: true
                opacity: 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: root.chipFg
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.contextMenuRequested(mouse.x, mouse.y);
            } else {
                root.activated();
            }
        }
    }
}
