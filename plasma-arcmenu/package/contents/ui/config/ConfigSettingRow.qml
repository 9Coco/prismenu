import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/**
 * Settings row: optional accent icon badge + title/subtitle + trailing control.
 */
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property string accent: "blue"
    default property alias trailing: trail.data

    Layout.fillWidth: true
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 3.0,
                             lay.implicitHeight + Kirigami.Units.largeSpacing)

    readonly property color badgeColor: {
        switch (String(root.accent || "blue")) {
        case "purple": return "#8B5CF6";
        case "green": return "#22C55E";
        case "orange": return "#F59E0B";
        case "pink": return "#EC4899";
        case "teal": return "#14B8A6";
        case "red": return "#EF4444";
        case "cyan": return "#06B6D4";
        case "indigo": return "#6366F1";
        case "yellow": return "#EAB308";
        default: return Kirigami.Theme.highlightColor;
        }
    }

    RowLayout {
        id: lay
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Rectangle {
            visible: root.iconName.length > 0
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.0
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.0
            Layout.alignment: Qt.AlignVCenter
            radius: Kirigami.Units.smallSpacing
            color: Qt.rgba(root.badgeColor.r, root.badgeColor.g, root.badgeColor.b, 0.22)

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                source: root.iconName
                color: root.badgeColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 7
            Layout.alignment: Qt.AlignVCenter
            spacing: 3
            QQC2.Label {
                text: root.title
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                font.weight: Font.Medium
            }
            QQC2.Label {
                visible: root.subtitle.length > 0
                text: root.subtitle
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.55
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        RowLayout {
            id: trail
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: Kirigami.Units.smallSpacing
        }
    }
}
