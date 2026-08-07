import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/Locale.js" as Locale

/**
 * Functional module: "All Applications" / Back navigation control.
 */
Item {
    id: root

    property bool showBack: false
    property int iconSize: 24
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color fg: Kirigami.Theme.textColor
    property bool highlighted: false
    property var menuData: null

    signal clicked()

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"
    readonly property string labelText: Locale.tr(showBack ? "Back" : "All Applications", uiLang)

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
    Accessible.name: root.labelText
    Accessible.role: Accessible.Button
    Accessible.onPressAction: root.clicked()

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.smallSpacing
        color: root.highlighted || mouse.containsMouse ? root.selectedBg : "transparent"
        opacity: root.highlighted || mouse.containsMouse ? 1 : 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: root.showBack ? "go-previous" : "view-app-grid-symbolic"
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: root.labelText
            elide: Text.ElideRight
            font.weight: Font.Medium
            color: root.highlighted || mouse.containsMouse ? root.selectedFg : root.fg
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
