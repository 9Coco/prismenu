import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/AppDrag.js" as AppDrag
import "../../code/SearchExtras.js" as SearchExtras

Item {
    id: root

    property var app: null
    /** Optional — enables search-term highlight from MenuData when searching */
    property var menuData: null
    property int iconSize: 24
    property bool showDescription: true
    /** Kickoff-style single-line row with the description/path at the right. */
    property bool inlineDescription: false
    property bool showGenericNames: false
    property bool multiLineLabels: false
    /** When set with highlightTerms, primary label uses RichText bold matches (ArcMenu) */
    property string highlightQuery: ""
    property bool highlightTerms: false
    property bool selected: false
    /** Drop target for drag-to-reorder / drop-to-pin (pinned views only). */
    property bool reorderEnabled: false
    /** ListView/GridView row, used as Kickoff's source.index during a drag. */
    property int modelIndex: -1
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg
    property color fg: Kirigami.Theme.textColor

    readonly property bool isSection: !!(app && app.isSection)
    /** Real .desktop rows can be dragged out to the desktop/panel (Kickoff
     * parity: KIO shows Copy / Link / Move on drop). */
    readonly property bool dragOutEnabled: !root.isSection && AppDrag.canDragOut(root.app)
    readonly property bool dragEnabled: !root.isSection
        && (root.dragOutEnabled || root.reorderEnabled)
    readonly property bool _doHighlight: {
        if (root.isSection)
            return false;
        if (root.highlightTerms && root.highlightQuery.length)
            return true;
        return !!(menuData && menuData.highlightSearchTerms && menuData.isSearching
                  && menuData.searchQuery && String(menuData.searchQuery).length);
    }
    readonly property string _highlightQ: root.highlightQuery.length
        ? root.highlightQuery
        : ((menuData && menuData.searchQuery) ? String(menuData.searchQuery) : "")

    readonly property bool hot: !root.isSection && (root.selected || mouse.containsMouse)
    readonly property color chipBg: root.selected ? root.selectedBg
        : (mouse.containsMouse ? root.hoverBg : "transparent")
    readonly property color chipFg: root.selected ? root.selectedFg
        : (mouse.containsMouse ? root.hoverFg : root.fg)
    readonly property bool dropHover: false

    readonly property string primaryText: {
        if (!app)
            return "";
        if (root.showGenericNames && app.genericName)
            return app.genericName;
        return app.name || "";
    }
    readonly property string secondaryText: {
        if (!app || root.isSection || !root.showDescription)
            return "";
        if (root.showGenericNames)
            return app.name || "";
        return app.genericName || "";
    }

    signal activated()
    signal contextMenuRequested(real x, real y)

    height: root.isSection
        ? Kirigami.Units.gridUnit * 1.35
        : Math.max(iconSize + Kirigami.Units.smallSpacing * 2,
                   secondaryText && !inlineDescription
                       ? Kirigami.Units.gridUnit * 2.2 : Kirigami.Units.gridUnit * 1.8)
    Accessible.name: primaryText
    Accessible.role: root.isSection ? Accessible.Heading : Accessible.ListItem
    Accessible.onPressAction: {
        if (!root.isSection)
            root.activated();
    }

    // ---- Section header (Applications / Files / Windows) ----
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        visible: root.isSection
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: root.primaryText
            elide: Text.ElideRight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.weight: Font.DemiBold
            color: root.fg
        }

        Kirigami.Separator { Layout.fillWidth: true }
    }

    // ---- Normal result row ----
    Rectangle {
        anchors.fill: parent
        visible: !root.isSection
        radius: Kirigami.Units.smallSpacing
        color: root.dropHover ? root.selectedBg : root.chipBg
        opacity: (root.hot || root.dropHover) ? 1 : 0
    }

    // Drag surface: when a drag session starts the row content is grabbed
    // to an image (Drag.imageSource) that follows the pointer, leaving the
    // row as a "hole" — same feel as Kickoff. Dropping the image on the
    // desktop/panel runs the KIO paste dialog via the launcher MIME.
    Item {
        id: dragGhost
        anchors.fill: parent
        readonly property string dragAppId: root.app ? String(root.app.id || "") : ""
        readonly property int dragIndex: root.modelIndex
        readonly property Item dragView: root.ListView.view
        visible: !root.isSection && !dragGhost.Drag.active
        Drag.dragType: Drag.Automatic
        Drag.hotSpot.x: Math.round(dragGhost.width / 2)
        Drag.hotSpot.y: Math.round(dragGhost.height / 2)
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
        Drag.mimeData: AppDrag.mimeDataFor(root.app)
        Drag.onDragStarted: AppDrag.resetLiveReorder()
        Drag.onDragFinished: AppDrag.finishDrag(root.menuData)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: SearchExtras.resultIconSource(root.app)
                fallback: (root.app && root.app.icon) ? root.app.icon : "application-x-executable"
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
                animated: false
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    text: root._doHighlight
                        ? SearchExtras.highlightMarkup(root.primaryText, root._highlightQ)
                        : root.primaryText
                    textFormat: root._doHighlight ? Text.RichText : Text.PlainText
                    elide: root.multiLineLabels ? Text.ElideNone : Text.ElideRight
                    wrapMode: root.multiLineLabels ? Text.WordWrap : Text.NoWrap
                    maximumLineCount: root.multiLineLabels ? 2 : 1
                    Layout.fillWidth: true
                    color: root.chipFg
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.textColor: root.chipFg
                    font.weight: Font.Medium
                }

                PlasmaComponents.Label {
                    visible: !root.inlineDescription && root.secondaryText.length > 0
                    text: root._doHighlight
                        ? SearchExtras.highlightMarkup(root.secondaryText, root._highlightQ)
                        : root.secondaryText
                    textFormat: root._doHighlight ? Text.RichText : Text.PlainText
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    opacity: 0.7
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: root.chipFg
                }
            }

            PlasmaComponents.Label {
                visible: root.inlineDescription && root.secondaryText.length > 0
                text: root.secondaryText
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Math.min(implicitWidth, Math.max(120, root.width * 0.42))
                Layout.maximumWidth: root.width * 0.5
                opacity: 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: root.chipFg
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !root.isSection
        hoverEnabled: !root.isSection
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property bool dragStarted: false
        property real pressX: 0
        property real pressY: 0

        /** Left-drag past the system threshold → native drag session. */
        function maybeStartDrag(event) {
            if (!root.dragEnabled || mouse.dragStarted || dragGhost.Drag.active)
                return;
            if (!(event.buttons & Qt.LeftButton))
                return;
            var dx = event.x - mouse.pressX;
            var dy = event.y - mouse.pressY;
            var threshold = Qt.styleHints.startDragDistance;
            if (dx * dx + dy * dy < threshold * threshold)
                return;
            mouse.dragStarted = true;
            dragGhost.grabToImage(function (result) {
                dragGhost.Drag.imageSource = result.url;
                dragGhost.Drag.active = true;
            });
        }

        onPressed: (event) => {
            if (event.button === Qt.LeftButton) {
                mouse.dragStarted = false;
                mouse.pressX = event.x;
                mouse.pressY = event.y;
            }
        }
        onPositionChanged: (event) => mouse.maybeStartDrag(event)
        onClicked: (event) => {
            if (mouse.dragStarted) {
                mouse.dragStarted = false;
                return;
            }
            if (event.button === Qt.RightButton) {
                root.contextMenuRequested(event.x, event.y);
            } else {
                root.activated();
            }
        }
    }
}
