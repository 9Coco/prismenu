import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/SearchExtras.js" as SearchExtras

GridView {
    id: root

    property var items: []
    property var menuData: null
    property int iconSize: 48
    property int columns: 6
    /** When > 0, column count is floor(width / minCellWidth) so cells shrink/grow with the pane. */
    property int minCellWidth: 0
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
    // GridView otherwise selects row 0 automatically, leaving the first tile
    // blue even while another tile is merely hovered.
    currentIndex: -1
    readonly property int resolvedColumns: {
        if (minCellWidth > 0 && width > 0)
            return Math.max(1, Math.floor(width / minCellWidth));
        return Math.max(1, columns);
    }
    cellWidth: Math.max(1, width / Math.max(1, resolvedColumns))
    readonly property int cellIconSize: minCellWidth > 0
        ? Math.max(20, Math.min(iconSize, Math.round(cellWidth * 0.48)))
        : iconSize
    // Icon + up to two label lines. Too-short cells stack delegates and
    // clicks in the "empty" gap hit the overlapping row.
    cellHeight: minCellWidth > 0
        ? (cellIconSize + Kirigami.Units.gridUnit * 3)
        : (iconSize + Kirigami.Units.gridUnit * 2)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    QQC2.ScrollBar.vertical: MenuScrollBar { menuData: root.menuData }
    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
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
        clip: true

        readonly property int tilePad: Kirigami.Units.smallSpacing
        readonly property int labelWidth: Math.min(
            del.width - Kirigami.Units.largeSpacing,
            root.cellIconSize + Kirigami.Units.gridUnit * 2)

        // Highlight hugs the icon + label, matching Application Dashboard.
        Rectangle {
            id: tileBg
            anchors.centerIn: parent
            width: Math.min(del.width - Kirigami.Units.largeSpacing,
                            Math.max(root.cellIconSize, del.labelWidth) + del.tilePad * 2)
            height: Math.min(del.height - Kirigami.Units.largeSpacing,
                             contentCol.implicitHeight + del.tilePad * 2)
            radius: Kirigami.Units.smallSpacing
            color: {
                if (root.activeFocus && root.currentIndex === del.index)
                    return root.selectedBg;
                if (mouse.containsMouse)
                    return root.hoverBg;
                return "transparent";
            }
        }

        Column {
            id: contentCol
            anchors.centerIn: parent
            width: del.labelWidth
            spacing: Kirigami.Units.smallSpacing / 2

            Kirigami.Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                source: SearchExtras.resultIconSource(del.app)
                fallback: (del.app && del.app.icon) ? del.app.icon : "application-x-executable"
                width: root.cellIconSize
                height: root.cellIconSize
                animated: false
            }

            PlasmaComponents.Label {
                width: parent.width
                text: {
                    if (!del.app)
                        return "";
                    if (root.showGenericNames && del.app.genericName)
                        return del.app.genericName;
                    return del.app.name || "";
                }
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                wrapMode: root.multiLineLabels ? Text.Wrap : Text.NoWrap
                maximumLineCount: root.multiLineLabels ? 2 : 1
                readonly property color labelColor: {
                    if (root.activeFocus && root.currentIndex === del.index)
                        return root.selectedFg;
                    if (mouse.containsMouse)
                        return root.hoverFg;
                    return root.fg;
                }
                color: labelColor
                Kirigami.Theme.inherit: false
                Kirigami.Theme.textColor: labelColor
            }
        }

        // Only the tile launches. Empty padding around it does nothing.
        MouseArea {
            id: mouse
            anchors.fill: tileBg
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (!del.app || del.app.isSection)
                    return;
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
