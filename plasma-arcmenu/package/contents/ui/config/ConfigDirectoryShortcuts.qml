import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC

Item {
    id: root

    property var cfg_DirectoryShortcuts: []

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function writeLive(list) {
        cfg_DirectoryShortcuts = list;
        try { plasmoid.configuration.DirectoryShortcuts = list; } catch (e) {}
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

    function pathFromUrl(url) {
        var s = String(url || "");
        if (s.indexOf("file://") === 0)
            s = decodeURIComponent(s.substring(7));
        return s;
    }

    function basename(path) {
        var p = String(path || "").replace(/\/+$/, "");
        var i = Math.max(p.lastIndexOf("/"), p.lastIndexOf("\\"));
        return i >= 0 ? p.substring(i + 1) : p;
    }

    function iconForFile(path) {
        var lower = String(path || "").toLowerCase();
        if (/\.(png|jpe?g|gif|webp|svg|bmp|ico)$/.test(lower))
            return "image-x-generic";
        if (/\.(mp3|flac|ogg|wav|m4a|aac)$/.test(lower))
            return "audio-x-generic";
        if (/\.(mp4|mkv|avi|webm|mov)$/.test(lower))
            return "video-x-generic";
        if (/\.pdf$/.test(lower))
            return "application-pdf";
        if (/\.(zip|tar|gz|7z|rar|xz)$/.test(lower))
            return "package-x-generic";
        if (/\.(txt|md|log|csv)$/.test(lower))
            return "text-x-generic";
        return "text-x-generic";
    }

    function hasPath(path) {
        path = String(path || "");
        for (var i = 0; i < items.length; ++i) {
            if (items[i] && String(items[i].path || "") === path)
                return true;
        }
        return false;
    }

    function addCustomPath(path, icon) {
        path = String(path || "").trim();
        if (!path || hasPath(path))
            return;
        var name = basename(path) || path;
        icon = String(icon || "folder").trim() || "folder";
        var encoded = "custom:" + name.replace(/\|/g, "-") + "|"
                + icon.replace(/\|/g, "-") + "|" + path.replace(/\|/g, " ");
        writeLive(ids.concat([encoded]));
    }

    ConfigPage {
        title: root.tr("Frequent Locations")
        tip: root.tr("Folders and files shown in the places sidebar")

        ConfigGroup {
            title: root.tr("Frequent Locations")
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
                title: root.tr("Add custom folder")
                subtitle: root.tr("Choose a folder to pin in the places sidebar")
                iconName: "folder-add"
                accent: "teal"
                QQC2.Button {
                    icon.name: "list-add"; flat: true
                    onClicked: folderPicker.open()
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Add custom file")
                subtitle: root.tr("Choose a file to pin in the places sidebar")
                iconName: "document-new"
                accent: "orange"
                QQC2.Button {
                    icon.name: "list-add"; flat: true
                    onClicked: filePicker.open()
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Add custom shortcut")
                iconName: "document-edit"
                accent: "orange"
                QQC2.Button {
                    icon.name: "list-add"; flat: true
                    onClicked: {
                        customName.text = "";
                        customIcon.text = "folder";
                        customPath.text = "";
                        customDialog.open();
                    }
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
            RowLayout {
                Kirigami.FormData.label: root.tr("Path:")
                QQC2.TextField {
                    id: customPath
                    Layout.fillWidth: true
                    placeholderText: "/home"
                }
                QQC2.Button {
                    text: root.tr("Browse...")
                    onClicked: customBrowse.open()
                }
            }
        }
        onAccepted: {
            var name = String(customName.text || "").trim().replace(/\|/g, "-");
            var icon = String(customIcon.text || "folder").trim().replace(/\|/g, "-");
            var path = String(customPath.text || "").trim().replace(/\|/g, " ");
            if (!path)
                return;
            if (!name)
                name = root.basename(path) || path;
            if (root.hasPath(path))
                return;
            writeLive(ids.concat(["custom:" + name + "|" + icon + "|" + path]));
        }
    }

    Dialogs.FileDialog {
        id: filePicker
        title: root.tr("Add custom file")
        fileMode: Dialogs.FileDialog.OpenFile
        nameFilters: [root.tr("All files (*)")]
        onAccepted: {
            var path = root.pathFromUrl(selectedFile);
            root.addCustomPath(path, root.iconForFile(path));
        }
    }

    Dialogs.FolderDialog {
        id: folderPicker
        title: root.tr("Add custom folder")
        onAccepted: root.addCustomPath(root.pathFromUrl(selectedFolder), "folder")
    }

    Dialogs.FileDialog {
        id: customBrowse
        title: root.tr("Add custom file")
        fileMode: Dialogs.FileDialog.OpenFile
        nameFilters: [root.tr("All files (*)")]
        onAccepted: {
            var path = root.pathFromUrl(selectedFile);
            customPath.text = path;
            if (!String(customName.text || "").trim())
                customName.text = root.basename(path);
            customIcon.text = root.iconForFile(path);
        }
    }
}
