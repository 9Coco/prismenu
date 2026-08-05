import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var cfg_Options: ["shutdown", "restart", "logout", "lock", "suspend", "hibernate", "settings", "discover", "switchuser"]
    property alias cfg_Confirm: confirmBox.checked
    property alias cfg_SoftwareCenterCmd: softwareCmd.text

    function isOn(id) {
        return (cfg_Options || []).indexOf(id) >= 0;
    }

    function setOpt(id, on) {
        var list = (cfg_Options || []).slice();
        var idx = list.indexOf(id);
        if (on && idx < 0) list.push(id);
        if (!on && idx >= 0) list.splice(idx, 1);
        cfg_Options = list;
    }

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.label: i18n("Visible actions:")
            Layout.fillWidth: true
            implicitHeight: opts.implicitHeight
            ColumnLayout {
                id: opts
                anchors.left: parent.left
                anchors.right: parent.right
                QQC2.CheckBox { text: i18n("Shut Down"); checked: root.isOn("shutdown"); onToggled: root.setOpt("shutdown", checked) }
                QQC2.CheckBox { text: i18n("Restart"); checked: root.isOn("restart"); onToggled: root.setOpt("restart", checked) }
                QQC2.CheckBox { text: i18n("Log Out"); checked: root.isOn("logout"); onToggled: root.setOpt("logout", checked) }
                QQC2.CheckBox { text: i18n("Lock"); checked: root.isOn("lock"); onToggled: root.setOpt("lock", checked) }
                QQC2.CheckBox { text: i18n("Suspend"); checked: root.isOn("suspend"); onToggled: root.setOpt("suspend", checked) }
                QQC2.CheckBox { text: i18n("Hibernate"); checked: root.isOn("hibernate"); onToggled: root.setOpt("hibernate", checked) }
                QQC2.CheckBox { text: i18n("System Settings"); checked: root.isOn("settings"); onToggled: root.setOpt("settings", checked) }
                QQC2.CheckBox { text: i18n("Discover / Software Center"); checked: root.isOn("discover"); onToggled: root.setOpt("discover", checked) }
                QQC2.CheckBox { text: i18n("Switch User"); checked: root.isOn("switchuser"); onToggled: root.setOpt("switchuser", checked) }
            }
        }

        QQC2.CheckBox {
            id: confirmBox
            Kirigami.FormData.label: i18n("Confirmation:")
            text: i18n("Confirm shut down / restart / log out")
        }

        QQC2.TextField {
            id: softwareCmd
            Kirigami.FormData.label: i18n("Software center command:")
            placeholderText: "auto-detect"
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Leave as auto-detect to launch Discover (plasma-discover). On Kubuntu this is the default software center.")
        }
    }
}
