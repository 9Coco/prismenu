import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/Locale.js" as Locale

QQC2.Dialog {
    id: root

    property string actionId: ""
    property string actionTitle: ""
    property string actionIcon: "dialog-warning"
    property string actionMessage: ""
    property var menuData: null

    signal confirmed(string actionId)

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

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
            actionTitle = root.t("Shut Down");
            actionIcon = "system-shutdown";
            actionMessage = root.t("Are you sure you want to shut down the computer?");
            break;
        case "restart":
            actionTitle = root.t("Restart");
            actionIcon = "system-reboot";
            actionMessage = root.t("Are you sure you want to restart the computer?");
            break;
        case "logout":
            actionTitle = root.t("Log Out");
            actionIcon = "system-log-out";
            actionMessage = root.t("Are you sure you want to log out?");
            break;
        default:
            actionTitle = root.t("Confirm");
            actionIcon = "dialog-warning";
            actionMessage = root.t("Do you want to continue?");
        }
        open();
    }
}
