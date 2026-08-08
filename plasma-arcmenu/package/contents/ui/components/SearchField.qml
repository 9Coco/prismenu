import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.TextField {
    id: root

    property string placeholder: i18n("Search applications…")
    property bool searching: text.length > 0
    property var menuData: null
    /** When hideSearchBar is on, collapse until focused/typing */
    property bool forceVisible: false

    readonly property bool hideWhenEmpty: !!(menuData && menuData.hideSearchBar)
    readonly property bool effectivelyVisible: !hideWhenEmpty || searching || forceVisible || activeFocus
    readonly property int boxRadius: (menuData && menuData.searchBoxRadiusEnabled)
        ? Math.max(0, menuData.searchBoxRadius)
        : Kirigami.Units.smallSpacing

    visible: effectivelyVisible
    opacity: effectivelyVisible ? 1 : 0
    Layout.preferredHeight: effectivelyVisible ? Kirigami.Units.gridUnit * 2.2 : 0

    placeholderText: placeholder
    clearButtonShown: true
    Accessible.name: i18n("Search")
    Accessible.role: Accessible.EditableText
    focus: true

    // Capsule / large radius clips glyphs without extra horizontal inset
    readonly property int sideInset: Math.max(
        Kirigami.Units.largeSpacing,
        Math.round(boxRadius * 0.65) + Kirigami.Units.smallSpacing
    )
    leftPadding: sideInset
    rightPadding: sideInset + (clearButtonShown ? Kirigami.Units.gridUnit : 0)
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

    // ArcMenu search-entry-border-radius
    background: Rectangle {
        implicitHeight: Kirigami.Units.gridUnit * 2.2
        radius: root.boxRadius
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: root.activeFocus
            ? Kirigami.Theme.highlightColor
            : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
        opacity: 0.95
    }

    Keys.onEscapePressed: (event) => {
        if (text.length > 0) {
            text = "";
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    Keys.onDownPressed: (event) => {
        event.accepted = false;
    }
}
