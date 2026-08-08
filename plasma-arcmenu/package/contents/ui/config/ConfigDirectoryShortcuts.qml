import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC

Item {
    id: root

    property var cfg_DirectoryShortcuts: []

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function writeLive(list) {
        cfg_DirectoryShortcuts = list;
        try { plasmoid.configuration.directoryShortcuts = list; } catch (e) {}
    }

    readonly property var ids: SC.normalizeList(cfg_DirectoryShortcuts, SC.DEFAULT_DIRS)

    readonly property var items: {
        var out = [];
        for (var i = 0; i < ids.length; ++i)
            out.push(SC.resolveDirectory(ids[i], root.tr));
        return out;
    }

    function move(from, to) { writeLive(SC.moveItem(ids, from, to)); }
    function removeAt(index) {
        var list = ids.slice();
        list.splice(index, 1);
        writeLive(list);
    }
    function addDefaultDir(key) {
        if (ids.indexOf(key) >= 0)
            return;
        writeLive(ids.concat([key]));
    }
    function resetDefaults() { writeLive(SC.DEFAULT_DIRS.slice()); }

    ConfigPage {
        title: root.tr("Directory Shortcuts")
        tip: root.tr("Folders shown in the places sidebar")

        ConfigGroup {
            title: root.tr("Directory Shortcuts")
            Repeater {
                model: root.items
                ColumnLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: modelData.invalid ? (root.tr("Invalid shortcut") + " - " + modelData.id) : modelData.name
                        iconName: modelData.icon || "folder"
                        accent: modelData.invalid ? "red" : (index % 2 === 0 ? "blue" : "teal")
                        Kirigami.Icon {
                            source: "transform-move"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.4
                        }
                        QQC2.Button { icon.name: "go-up"; flat: true; enabled: index > 0; onClicked: root.move(index, index - 1) }
                        QQC2.Button { icon.name: "go-down"; flat: true; enabled: index < root.items.length - 1; onClicked: root.move(index, index + 1) }
                        QQC2.Button { icon.name: "list-remove"; flat: true; onClicked: root.removeAt(index) }
                    }
                    ConfigSep { visible: index < root.items.length - 1 }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Add")
            ConfigSettingRow {
                title: root.tr("Add default user directory")
                iconName: "folder-add"
                accent: "green"
                QQC2.Button { icon.name: "list-add"; flat: true; onClicked: defaultDirDialog.open() }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Add custom shortcut")
                iconName: "document-new"
                accent: "orange"
                QQC2.Button {
                    icon.name: "list-add"; flat: true
                    onClicked: { customName.text = ""; customIcon.text = "folder"; customPath.text = ""; customDialog.open(); }
                }
            }
        }

        QQC2.Button { text: root.tr("Reset to defaults"); onClicked: root.resetDefaults() }
    }

    QQC2.Dialog {
        id: defaultDirDialog
        title: root.tr("Add default user directory")
        modal: true
        standardButtons: QQC2.Dialog.Close
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, Kirigami.Units.gridUnit * 22)

        ColumnLayout {
            anchors.fill: parent
            Repeater {
                model: SC.DEFAULT_DIRS
                QQC2.ItemDelegate {
                    required property var modelData
                    Layout.fillWidth: true
                    enabled: root.ids.indexOf(modelData) < 0
                    text: SC.resolveDirectory(modelData, root.tr).name
                    icon.name: SC.resolveDirectory(modelData, root.tr).icon
                    onClicked: { root.addDefaultDir(modelData); defaultDirDialog.close(); }
                }
            }
        }
    }

    QQC2.Dialog {
        id: customDialog
        title: root.tr("Add custom shortcut")
        modal: true
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        anchors.centerIn: parent
        Kirigami.FormLayout {
            QQC2.TextField { id: customName; Kirigami.FormData.label: root.tr("Name:") }
            QQC2.TextField { id: customIcon; Kirigami.FormData.label: root.tr("Icon name"); text: "folder" }
            QQC2.TextField { id: customPath; Kirigami.FormData.label: root.tr("Path:"); placeholderText: "/home" }
        }
        onAccepted: {
            var name = String(customName.text || "").trim().replace(/\|/g, "-");
            var icon = String(customIcon.text || "folder").trim().replace(/\|/g, "-");
            var path = String(customPath.text || "").trim().replace(/\|/g, " ");
            if (!name || !path) return;
            writeLive(ids.concat(["custom:" + name + "|" + icon + "|" + path]));
        }
    }
}
