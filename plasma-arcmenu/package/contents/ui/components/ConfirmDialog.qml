import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

QQC2.Dialog {
    id: root

    property string actionId: ""
    property string actionTitle: ""
    property string actionIcon: "dialog-warning"
    property string actionMessage: ""

    signal confirmed(string actionId)

    modal: true
    standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
    title: actionTitle
    width: Math.min(Kirigami.Units.gridUnit * 22, parent ? parent.width * 0.9 : Kirigami.Units.gridUnit * 22)

    onAccepted: confirmed(actionId)

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: root.actionIcon
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Kirigami.Units.iconSizes.large
        }

        PlasmaComponents.Label {
            text: root.actionMessage
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    function openFor(id) {
        actionId = id;
        switch (id) {
        case "shutdown":
            actionTitle = i18n("Shut Down");
            actionIcon = "system-shutdown";
            actionMessage = i18n("Are you sure you want to shut down the computer?");
            break;
        case "restart":
            actionTitle = i18n("Restart");
            actionIcon = "system-reboot";
            actionMessage = i18n("Are you sure you want to restart the computer?");
            break;
        case "logout":
            actionTitle = i18n("Log Out");
            actionIcon = "system-log-out";
            actionMessage = i18n("Are you sure you want to log out?");
            break;
        default:
            actionTitle = i18n("Confirm");
            actionIcon = "dialog-warning";
            actionMessage = i18n("Do you want to continue?");
        }
        open();
    }
}
