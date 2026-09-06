import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/**
 * Section title + rounded card for settings rows.
 */
ColumnLayout {
    id: root

    property string title: ""
    default property alias content: rows.data

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    QQC2.Label {
        visible: root.title.length > 0
        text: root.title
        font.weight: Font.DemiBold
        opacity: 0.9
        Layout.topMargin: Kirigami.Units.smallSpacing / 2
        Layout.leftMargin: Kirigami.Units.smallSpacing / 2
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: rows.implicitHeight + Kirigami.Units.smallSpacing
        radius: Kirigami.Units.largeSpacing
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g,
                       Kirigami.Theme.backgroundColor.b, 0.55)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b, 0.08)

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                           Kirigami.Theme.textColor.b, 0.04)
        }

        ColumnLayout {
            id: rows
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
        }
    }
}
