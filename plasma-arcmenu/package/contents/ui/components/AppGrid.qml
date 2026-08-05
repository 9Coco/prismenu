import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

GridView {
    id: root

    property int iconSize: 48
    property int columns: 6
    property bool showDescription: false
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor

    signal appActivated(var app)
    signal contextMenuRequested(var app, real x, real y)

    cellWidth: Math.max(Kirigami.Units.gridUnit * 4, width / Math.max(1, columns))
    cellHeight: iconSize + Kirigami.Units.gridUnit * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    Accessible.name: i18n("Applications")
    Accessible.role: Accessible.List

    delegate: Item {
        id: del
        required property var model
        required property int index
        width: root.cellWidth
        height: root.cellHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing / 2
            radius: Kirigami.Units.smallSpacing
            color: mouse.containsMouse || root.currentIndex === del.index ? root.selectedBg : "transparent"
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing / 2

            Kirigami.Icon {
                source: model.icon || "application-x-executable"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
            }

            PlasmaComponents.Label {
                text: model.name || ""
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                color: mouse.containsMouse || root.currentIndex === del.index ? root.selectedFg : Kirigami.Theme.textColor
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                root.currentIndex = del.index;
                if (mouse.button === Qt.RightButton) {
                    root.contextMenuRequested(model, mouse.x, mouse.y);
                } else {
                    root.appActivated(model);
                }
            }
        }

        Accessible.name: model.name || ""
        Accessible.role: Accessible.Button
        Accessible.onPressAction: root.appActivated(model)
    }

    Keys.onReturnPressed: {
        if (currentIndex >= 0 && model) {
            var app = model.get ? model.get(currentIndex) : null;
            if (app) {
                appActivated(app);
            }
        }
    }
}
