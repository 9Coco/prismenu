import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var cfg_Providers: ["applications"]
    property alias cfg_Placeholder: placeholderField.text
    property alias cfg_ShowDescription: showDesc.checked
    property alias cfg_MaxResults: maxResultsSpin.value

    function providerChecked(id) {
        return (cfg_Providers || []).indexOf(id) >= 0;
    }

    function setProvider(id, on) {
        var list = (cfg_Providers || []).slice();
        var idx = list.indexOf(id);
        if (on && idx < 0) list.push(id);
        if (!on && idx >= 0) list.splice(idx, 1);
        if (list.length === 0) list = ["applications"];
        cfg_Providers = list;
    }

    Kirigami.FormLayout {
        QQC2.TextField {
            id: placeholderField
            Kirigami.FormData.label: i18n("Placeholder text:")
        }

        QQC2.CheckBox {
            id: showDesc
            Kirigami.FormData.label: i18n("Descriptions:")
            text: i18n("Show result descriptions")
        }

        QQC2.SpinBox {
            id: maxResultsSpin
            Kirigami.FormData.label: i18n("Maximum results:")
            from: 5
            to: 100
        }

        Item {
            Kirigami.FormData.label: i18n("Result sources:")
            Kirigami.FormData.isSection: false
            Layout.fillWidth: true
            implicitHeight: providerCol.implicitHeight
            ColumnLayout {
                id: providerCol
                anchors.left: parent.left
                anchors.right: parent.right
                QQC2.CheckBox { text: i18n("Applications"); checked: root.providerChecked("applications"); onToggled: root.setProvider("applications", checked) }
                QQC2.CheckBox { text: i18n("Files"); checked: root.providerChecked("files"); onToggled: root.setProvider("files", checked) }
                QQC2.CheckBox { text: i18n("Bookmarks"); checked: root.providerChecked("bookmarks"); onToggled: root.setProvider("bookmarks", checked) }
                QQC2.CheckBox { text: i18n("Settings"); checked: root.providerChecked("settings"); onToggled: root.setProvider("settings", checked) }
                QQC2.CheckBox { text: i18n("Other Plasma Search runners"); checked: root.providerChecked("other"); onToggled: root.setProvider("other", checked) }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Application results are always prioritized. When Plasma Search is unavailable, Arc Menu falls back to local application matching.")
        }
    }
}
