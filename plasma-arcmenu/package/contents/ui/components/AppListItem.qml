import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
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
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg
    property color fg: Kirigami.Theme.textColor

    readonly property bool isSection: !!(app && app.isSection)
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
        color: root.chipBg
        opacity: root.hot ? 1 : 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        visible: !root.isSection

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

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !root.isSection
        hoverEnabled: !root.isSection
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
