import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

GridView {
    id: root

    property var items: []
    property int iconSize: 48
    property int columns: 6
    property bool showDescription: false
    property bool multiLineLabels: true
    property bool showGenericNames: false
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg
    property color fg: Kirigami.Theme.textColor

    signal appActivated(var app)
    signal contextMenuRequested(var app, real x, real y)

    model: items ? items.length : 0
    cellWidth: Math.max(Kirigami.Units.gridUnit * 4, width / Math.max(1, columns))
    cellHeight: iconSize + Kirigami.Units.gridUnit * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    reuseItems: true
    cacheBuffer: Math.max(height, cellHeight * 2)
    Accessible.name: i18n("Applications")
    Accessible.role: Accessible.List

    delegate: Item {
        id: del
        required property int index
        readonly property var app: root.items[index]
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
                source: del.app ? (del.app.icon || "application-x-executable") : "application-x-executable"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
            }

            PlasmaComponents.Label {
                text: {
                    if (!del.app)
                        return "";
                    if (root.showGenericNames && del.app.genericName)
                        return del.app.genericName;
                    return del.app.name || "";
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
                    return root.fg;
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
                    root.contextMenuRequested(del.app, mouse.x, mouse.y);
                } else {
                    root.appActivated(del.app);
                }
            }
        }

        Accessible.name: del.app ? (del.app.name || "") : ""
        Accessible.role: Accessible.Button
        Accessible.onPressAction: if (del.app) root.appActivated(del.app)
    }

    Keys.onReturnPressed: {
        if (currentIndex >= 0 && root.items && currentIndex < root.items.length)
            appActivated(root.items[currentIndex]);
    }
}
