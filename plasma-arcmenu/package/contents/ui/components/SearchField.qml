import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

/**
 * ArcMenu search entry — PlasmaExtras.SearchField like Kickoff Header.qml.
 * Optional ArcMenu radius / hide-when-empty on top.
 *
 * Note: do not alias Item.focus (FINAL) — forward via forceActiveFocus / Component.onCompleted.
 */
Item {
    id: root

    property alias text: searchField.text
    property alias placeholderText: searchField.placeholderText
    property string placeholder: ""
    property bool searching: searchField.text.length > 0
    property var menuData: null
    property bool forceVisible: false
    /** When true, focus the inner PlasmaExtras.SearchField after create */
    property bool autoFocus: true

    readonly property bool hideWhenEmpty: !!(menuData && menuData.hideSearchBar)
    readonly property bool effectivelyVisible: !hideWhenEmpty || searching || forceVisible || searchField.activeFocus
    readonly property int boxRadius: (menuData && menuData.searchBoxRadiusEnabled)
        ? Math.max(0, menuData.searchBoxRadius)
        : Kirigami.Units.smallSpacing
    readonly property bool useCustomRadius: !!(menuData && menuData.searchBoxRadiusEnabled)
    readonly property int sideInset: Math.max(
        Kirigami.Units.largeSpacing,
        Math.round(boxRadius * 0.65) + Kirigami.Units.smallSpacing
    )
    /** Inner field focus (Item.activeFocus is FINAL — do not override) */
    readonly property bool fieldActiveFocus: searchField.activeFocus

    signal accepted()
    signal textEdited()

    function forceActiveFocus(reason) {
        searchField.forceActiveFocus(reason !== undefined ? reason : Qt.OtherFocusReason);
    }
    function clear() { searchField.clear(); }

    visible: effectivelyVisible
    opacity: effectivelyVisible ? 1 : 0
    Layout.fillWidth: true
    Layout.preferredHeight: effectivelyVisible ? Kirigami.Units.gridUnit * 2.2 : 0
    implicitHeight: Layout.preferredHeight
    implicitWidth: Kirigami.Units.gridUnit * 12

    Component.onCompleted: {
        if (root.placeholder && root.placeholder.length)
            searchField.placeholderText = root.placeholder;
        if (root.autoFocus && root.effectivelyVisible)
            Qt.callLater(function () { searchField.forceActiveFocus(); });
    }
    onPlaceholderChanged: {
        if (root.placeholder && root.placeholder.length)
            searchField.placeholderText = root.placeholder;
    }

    Rectangle {
        anchors.fill: parent
        visible: root.useCustomRadius
        radius: root.boxRadius
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: searchField.activeFocus
            ? Kirigami.Theme.highlightColor
            : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
        opacity: 0.95
        z: 0
    }

    PlasmaExtras.SearchField {
        id: searchField
        anchors.fill: parent
        z: 1
        Binding on leftPadding {
            when: root.useCustomRadius
            value: root.sideInset
        }
        Binding on rightPadding {
            when: root.useCustomRadius
            value: root.sideInset + Kirigami.Units.gridUnit
        }

        onAccepted: root.accepted()
        onTextEdited: root.textEdited()

        Keys.onEscapePressed: (event) => {
            if (text.length > 0) {
                text = "";
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }
        Keys.onDownPressed: (event) => { event.accepted = false; }
    }
}
