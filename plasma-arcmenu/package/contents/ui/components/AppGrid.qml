import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

GridView {
    id: root

    property int iconSize: 48
    property int columns: 6
    property bool showDescription: false
    property bool multiLineLabels: true
    property bool showGenericNames: false
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg

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

        // Highlight hugs the icon+label content instead of the whole cell
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(del.width - Kirigami.Units.smallSpacing,
                            contentCol.implicitWidth + Kirigami.Units.largeSpacing)
            height: Math.min(del.height - Kirigami.Units.smallSpacing,
                             contentCol.implicitHeight + Kirigami.Units.smallSpacing)
            radius: Kirigami.Units.smallSpacing * 1.5
            color: {
                if (root.currentIndex === del.index)
                    return root.selectedBg;
                if (mouse.containsMouse)
                    return root.hoverBg;
                return "transparent";
            }
        }

        ColumnLayout {
            id: contentCol
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing / 2

            Kirigami.Icon {
                source: model.icon || "application-x-executable"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
            }

            PlasmaComponents.Label {
                text: {
                    if (root.showGenericNames && model.genericName)
                        return model.genericName;
                    return model.name || "";
                }
                elide: root.multiLineLabels ? Text.ElideNone : Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Layout.maximumWidth: del.width - Kirigami.Units.largeSpacing
                wrapMode: root.multiLineLabels ? Text.WordWrap : Text.NoWrap
                maximumLineCount: root.multiLineLabels ? 2 : 1
                color: {
                    if (root.currentIndex === del.index)
                        return root.selectedFg;
                    if (mouse.containsMouse)
                        return root.hoverFg;
                    return Kirigami.Theme.textColor;
                }
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
