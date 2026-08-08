import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root

    property var app: null
    property int iconSize: 24
    property bool showDescription: true
    property bool showGenericNames: false
    property bool multiLineLabels: false
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

    readonly property string primaryText: {
        if (!app)
            return "";
        if (root.showGenericNames && app.genericName)
            return app.genericName;
        return app.name || "";
    }
    readonly property string secondaryText: {
        if (!app || !root.showDescription)
            return "";
        if (root.showGenericNames)
            return app.name || "";
        return app.genericName || "";
    }

    signal activated()
    signal contextMenuRequested(real x, real y)

    height: Math.max(iconSize + Kirigami.Units.smallSpacing * 2,
                     secondaryText ? Kirigami.Units.gridUnit * 2.2 : Kirigami.Units.gridUnit * 1.8)
    Accessible.name: primaryText
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
                text: root.primaryText
                elide: root.multiLineLabels ? Text.ElideNone : Text.ElideRight
                wrapMode: root.multiLineLabels ? Text.WordWrap : Text.NoWrap
                maximumLineCount: root.multiLineLabels ? 2 : 1
                Layout.fillWidth: true
                color: root.chipFg
                font.weight: Font.Medium
            }

            PlasmaComponents.Label {
                visible: root.secondaryText.length > 0
                text: root.secondaryText
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
