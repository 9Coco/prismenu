import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/**
 * SearchField pre-wired to LayoutBase, with a compact ArcMenu Settings
 * button. Root is an Item (not a Layout) so ColumnLayout does not treat
 * this row as fillHeight — nested layouts default fillHeight to true and
 * would stretch the menu.
 */
Item {
    id: root

    required property var layoutRoot
    property bool showSettingsButton: true
    property alias text: field.text
    property alias placeholder: field.placeholder
    property alias autoFocus: field.autoFocus
    property alias searching: field.searching
    property alias menuData: field.menuData

    readonly property int rowHeight: Kirigami.Units.gridUnit * 2.2
    readonly property bool showRow: field.effectivelyVisible || root.showSettingsButton

    implicitWidth: Kirigami.Units.gridUnit * 12
    implicitHeight: root.showRow ? root.rowHeight : 0
    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: 0

    function forceActiveFocus(reason) {
        field.forceActiveFocus(reason);
    }
    function clear() {
        field.clear();
    }

    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        SearchField {
            id: field
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: root.rowHeight
            menuData: layoutRoot ? layoutRoot.menuData : null
            placeholder: menuData ? menuData.searchPlaceholder
                : (layoutRoot ? layoutRoot.tr("Search…") : "")
            text: menuData ? menuData.searchQuery : ""
        }

        Connections {
            target: field
            function onTextChanged() {
                if (field.menuData)
                    field.menuData.setSearch(field.text);
            }
        }

        ArcMenuSettingsButton {
            visible: root.showSettingsButton
            layoutRoot: root.layoutRoot
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
