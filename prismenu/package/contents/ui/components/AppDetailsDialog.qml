import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

QQC2.Dialog {
    id: root

    property var app: null

    modal: true
    title: i18n("Application Details")
    standardButtons: QQC2.Dialog.Close
    width: Math.min(Kirigami.Units.gridUnit * 28, parent ? parent.width * 0.92 : Kirigami.Units.gridUnit * 28)

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon {
                source: root.app ? root.app.icon : "application-x-executable"
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            }
            ColumnLayout {
                PlasmaComponents.Label {
                    text: root.app ? root.app.name : ""
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                }
                PlasmaComponents.Label {
                    text: root.app && root.app.genericName ? root.app.genericName : ""
                    opacity: 0.8
                    visible: text.length > 0
                }
            }
        }

        Kirigami.FormLayout {
            PlasmaComponents.Label {
                Kirigami.FormData.label: i18n("ID:")
                text: root.app ? root.app.id : ""
                wrapMode: Text.WrapAnywhere
            }
            PlasmaComponents.Label {
                Kirigami.FormData.label: i18n("Command:")
                text: root.app ? (root.app.exec || "") : ""
                wrapMode: Text.WrapAnywhere
            }
            PlasmaComponents.Label {
                Kirigami.FormData.label: i18n("Categories:")
                text: root.app && root.app.categories ? root.app.categories.join(", ") : ""
                wrapMode: Text.WordWrap
            }
            PlasmaComponents.Label {
                Kirigami.FormData.label: i18n("Path:")
                text: root.app ? (root.app.entryPath || "") : ""
                wrapMode: Text.WrapAnywhere
            }
        }
    }
}
