import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

GridView {
    id: root

    property int columns: 6
    property int iconSize: 32
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg

    signal appActivated(var app)
    signal contextMenuRequested(var app, real x, real y)
    signal reorderRequested(int from, int to)

    cellWidth: Math.max(Kirigami.Units.gridUnit * 3, width / Math.max(1, columns))
    cellHeight: iconSize + Kirigami.Units.gridUnit * 1.6
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    Accessible.name: i18n("Pinned applications")
    Accessible.role: Accessible.List

    delegate: Item {
        id: del
        required property var model
        required property int index
        width: root.cellWidth
        height: root.cellHeight

        // Highlight hugs the icon+label content instead of the whole cell
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(del.width - Kirigami.Units.smallSpacing,
                            contentCol.implicitWidth + Kirigami.Units.largeSpacing)
            height: Math.min(del.height - Kirigami.Units.smallSpacing,
                             contentCol.implicitHeight + Kirigami.Units.smallSpacing)
            radius: Kirigami.Units.smallSpacing * 1.5
            color: mouse.containsMouse ? root.hoverBg : "transparent"
        }

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

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            drag.target: drag.enabled ? del : undefined
            property bool dragActive: false

            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    dragActive = false;
                }
            }
            onPositionChanged: {
                if (pressedButtons & Qt.LeftButton) {
                    dragActive = true;
                }
            }
            onReleased: (mouse) => {
                if (mouse.button === Qt.LeftButton && !dragActive) {
                    root.appActivated(model);
                }
            }
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    root.contextMenuRequested(model, mouse.x, mouse.y);
                }
            }
        }

        Accessible.name: model.name || ""
        Accessible.role: Accessible.Button
        Accessible.onPressAction: root.appActivated(model)
    }
}
