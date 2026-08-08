import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/**
 * Scrollable config page shell — title + tip banner + content (图3 style).
 */
Flickable {
    id: root

    property string title: ""
    property string tip: ""
    default property alias content: body.data

    contentWidth: width
    contentHeight: outer.implicitHeight + Kirigami.Units.largeSpacing * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    anchors.fill: parent

    ColumnLayout {
        id: outer
        x: Kirigami.Units.largeSpacing
        width: Math.max(0, root.width - Kirigami.Units.largeSpacing * 2)
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            visible: root.title.length > 0
            text: root.title
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.35
            font.weight: Font.DemiBold
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
        }

        Rectangle {
            visible: root.tip.length > 0
            Layout.fillWidth: true
            implicitHeight: tipRow.implicitHeight + Kirigami.Units.largeSpacing
            radius: Kirigami.Units.smallSpacing
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                           Kirigami.Theme.highlightColor.b, 0.14)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                                  Kirigami.Theme.highlightColor.b, 0.28)

            RowLayout {
                id: tipRow
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Icon {
                    source: "help-hint"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    color: Kirigami.Theme.highlightColor
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: root.tip
                    opacity: 0.9
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
        }

        Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
    }
}
