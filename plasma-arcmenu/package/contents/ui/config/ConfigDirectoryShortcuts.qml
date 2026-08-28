import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC
import ".." as Ui

Item {
    id: root

    property var cfg_DirectoryShortcuts: []
    property var cfg_PlaceSectionOrder: []
    property var cfg_SystemPlaceOrder: []
    property var cfg_HiddenSystemPlaces: []
    property var cfg_DolphinPlaceOrder: []
    property var cfg_HiddenDolphinPlaces: []
    property var cfg_HiddenCustomPlaces: []
    property var localApps: []

    // Use the same native places backend as the menu so this page never
    // presents the legacy DirectoryShortcuts defaults as a separate truth.
    QtObject {
        id: placesData
        property string searchQuery: ""
        property var runnerResults: []
        property var plasmaRecentApps: []
        property var plasmaFavoriteIds: []
        property var plasmaPlaces: []
        function tr(msgid) { return root.tr(msgid); }
    }

    Ui.PlasmaNative {
        id: placesBackend
        menuData: placesData
        appletInterface: plasmoid
    }

    Ui.AppsBackend {
        onAppsUpdated: (apps) => { root.localApps = apps || []; }
    }

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function writeLive(list) {
        cfg_DirectoryShortcuts = list;
        try { plasmoid.configuration.DirectoryShortcuts = list; } catch (e) {}
    }

    function writeOption(key, value) {
        root["cfg_" + key] = value;
        try { plasmoid.configuration[key] = value; } catch (e) {}
    }

    readonly property var sectionOrder: {
        var raw = SC.normalizeList(cfg_PlaceSectionOrder, ["system", "dolphin", "custom"]);
        var out = [];
        raw.concat(["system", "dolphin", "custom"]).forEach(function (id) {
            if (["system", "dolphin", "custom"].indexOf(id) >= 0 && out.indexOf(id) < 0) out.push(id);
        });
        return out;
    }

    function itemKey(item) { return String(item ? (item.customPlaceKey || item.kickerUrl || item.entryPath || item.id || "") : ""); }
    function optionList(key) { return SC.normalizeList(root["cfg_" + key], []); }
    function ordered(items, key) {
        var out = (items || []).slice(), order = optionList(key), rank = {};
        for (var i = 0; i < order.length; ++i) rank[order[i]] = i;
        out.sort(function (a, b) {
            var ar = rank[root.itemKey(a)] !== undefined ? rank[root.itemKey(a)] : 100000;
            var br = rank[root.itemKey(b)] !== undefined ? rank[root.itemKey(b)] : 100000;
            return ar - br;
        });
        return out;
    }
    function sectionItems(id) {
        if (id === "system") return ordered(systemItems, "SystemPlaceOrder");
        if (id === "dolphin") return ordered(dolphinCustomItems, "DolphinPlaceOrder");
        return arcCustomItems;
    }
    function sectionTitle(id) {
        if (id === "system") return root.tr("System Locations");
        if (id === "dolphin") return root.tr("File Manager Locations");
        return root.tr("User Custom Locations");
    }
    function orderKey(id) { return id === "system" ? "SystemPlaceOrder" : (id === "dolphin" ? "DolphinPlaceOrder" : "DirectoryShortcuts"); }
    function hiddenKey(id) { return id === "system" ? "HiddenSystemPlaces" : (id === "dolphin" ? "HiddenDolphinPlaces" : "HiddenCustomPlaces"); }
    function isShown(id, item) { return optionList(hiddenKey(id)).indexOf(itemKey(item)) < 0; }
    function toggleShown(id, item) {
        var key = hiddenKey(id), list = optionList(key), value = itemKey(item), pos = list.indexOf(value);
        if (pos >= 0) list.splice(pos, 1); else list.push(value);
        writeOption(key, list);
    }
    function moveSection(from, to) { writeOption("PlaceSectionOrder", SC.moveItem(sectionOrder, from, to)); }
    function moveSectionItem(id, from, to) {
        var items = sectionItems(id), keys = items.map(function (x) { return root.itemKey(x); });
        var moved = SC.moveItem(keys, from, to);
        if (id === "custom") writeLive(moved); else writeOption(orderKey(id), moved);
    }

    readonly property var ids: SC.normalizeList(cfg_DirectoryShortcuts, SC.DEFAULT_DIRS)

    readonly property var arcCustomIds: {
        var out = [];
        for (var i = 0; i < ids.length; ++i) {
            if (String(ids[i] || "").indexOf("custom:") === 0
                    || String(ids[i] || "").indexOf("app:") === 0)
                out.push(ids[i]);
        }
        return out;
    }

    readonly property var arcCustomItems: {
        var out = [];
        for (var i = 0; i < arcCustomIds.length; ++i) {
            var shortcutId = String(arcCustomIds[i]);
            var item = null;
            if (shortcutId.indexOf("app:") === 0) {
                var appId = shortcutId.substring(4);
                for (var a = 0; a < root.localApps.length; ++a) {
                    if (root.localApps[a].id === appId || root.localApps[a].favoriteId === appId) {
                        item = Object.assign({}, root.localApps[a]);
                        item.id = shortcutId;
                        item.customPlaceKey = shortcutId;
                        break;
                    }
                }
            } else {
                item = SC.resolveDirectory(shortcutId, root.tr);
            }
            if (!item)
                item = { id: shortcutId, name: shortcutId, icon: "dialog-warning", invalid: true, customPlaceKey: shortcutId };
            item.sourceKind = "arcmenu";
            item.arcIndex = i;
            out.push(item);
        }
        return out;
    }

    readonly property var systemItems: {
        var source = placesData.plasmaPlaces || [];
        var out = [];
        for (var i = 0; i < source.length; ++i) {
            if (source[i] && source[i].isSystemPlace === true)
                out.push(source[i]);
        }
        if (out.length)
            return out;
        return SC.resolveDirectories(SC.DEFAULT_DIRS, root.tr);
    }

    readonly property var dolphinCustomItems: {
        var source = placesData.plasmaPlaces || [];
        var out = [];
        for (var i = 0; i < source.length; ++i) {
            if (source[i] && source[i].isSystemPlace !== true) {
                var copy = Object.assign({}, source[i]);
                copy.sourceKind = "dolphin";
                out.push(copy);
            }
        }
        return out;
    }

    readonly property var userItems: {
        var out = dolphinCustomItems.slice();
        var seen = {};
        for (var i = 0; i < out.length; ++i) {
            var nativeKey = String(out[i].kickerUrl || out[i].path || out[i].id || "");
            if (nativeKey.length)
                seen[nativeKey] = true;
        }
        for (var j = 0; j < arcCustomItems.length; ++j) {
            var custom = arcCustomItems[j];
            var customKey = String(custom.kickerUrl || custom.path || custom.id || "");
            if (!customKey.length || !seen[customKey])
                out.push(custom);
        }
        return out;
    }

    function move(from, to) { writeLive(SC.moveItem(arcCustomIds, from, to)); }
    function removeAt(index) {
        var list = arcCustomIds.slice();
        list.splice(index, 1);
        writeLive(list);
    }

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
        for (var i = 0; i < userItems.length; ++i) {
            if (userItems[i] && String(userItems[i].path || "") === path)
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
        writeLive(arcCustomIds.concat([encoded]));
    }

    ConfigPage {
        title: root.tr("Frequent Locations")
        tip: root.tr("Folders and files shown in the places sidebar")

        ConfigGroup {
            title: root.tr("Location Section Order")
            Repeater {
                model: root.sectionOrder
                ColumnLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: root.sectionTitle(modelData)
                        iconName: "transform-move"
                        accent: "blue"
                        QQC2.Button { icon.name: "go-up"; flat: true; enabled: index > 0; onClicked: root.moveSection(index, index - 1) }
                        QQC2.Button { icon.name: "go-down"; flat: true; enabled: index < root.sectionOrder.length - 1; onClicked: root.moveSection(index, index + 1) }
                    }
                    ConfigSep { visible: index < root.sectionOrder.length - 1 }
                }
            }
        }

        Repeater {
            model: root.sectionOrder
            ConfigGroup {
                id: sectionGroup
                required property var modelData
                readonly property string sectionId: String(modelData)
                readonly property var rows: root.sectionItems(sectionId)
                title: root.sectionTitle(sectionId)
                ConfigSettingRow {
                    visible: sectionGroup.rows.length === 0
                    title: root.tr("No locations in this section")
                    iconName: "dialog-information"
                    accent: "yellow"
                }
                Repeater {
                    model: sectionGroup.rows
                    ColumnLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 0
                        ConfigSettingRow {
                            title: modelData.invalid ? (root.tr("Invalid shortcut") + " - " + modelData.id) : modelData.name
                            subtitle: sectionGroup.sectionId === "system" ? root.tr("Provided by KDE Places")
                                : (sectionGroup.sectionId === "dolphin" ? root.tr("Managed in Dolphin Places") : root.tr("Managed by ArcMenu"))
                            iconName: modelData.icon || "folder"
                            accent: sectionGroup.sectionId === "system" ? "blue"
                                : (sectionGroup.sectionId === "dolphin" ? "purple" : "green")
                            QQC2.Button {
                                icon.name: root.isShown(sectionGroup.sectionId, modelData) ? "view-visible" : "view-hidden"
                                flat: true
                                onClicked: root.toggleShown(sectionGroup.sectionId, modelData)
                            }
                            QQC2.Button { icon.name: "go-up"; flat: true; enabled: index > 0; onClicked: root.moveSectionItem(sectionGroup.sectionId, index, index - 1) }
                            QQC2.Button { icon.name: "go-down"; flat: true; enabled: index < sectionGroup.rows.length - 1; onClicked: root.moveSectionItem(sectionGroup.sectionId, index, index + 1) }
                            QQC2.Button {
                                visible: sectionGroup.sectionId === "custom"
                                icon.name: "list-remove"
                                flat: true
                                onClicked: root.removeAt(Number(modelData.arcIndex))
                            }
                        }
                        ConfigSep { visible: index < sectionGroup.rows.length - 1 }
                    }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Add")
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
                title: root.tr("Add custom application")
                subtitle: root.tr("Choose an installed application")
                iconName: "application-x-executable"
                accent: "green"
                QQC2.Button { icon.name: "list-add"; flat: true; onClicked: appDialog.open() }
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

    }

    QQC2.Dialog {
        id: appDialog
        title: root.tr("Add custom application")
        modal: true
        standardButtons: QQC2.Dialog.Close
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.92, Kirigami.Units.gridUnit * 26)
        height: Math.min(parent.height * 0.78, Kirigami.Units.gridUnit * 24)
        ListView {
            anchors.fill: parent
            clip: true
            model: root.localApps
            delegate: QQC2.ItemDelegate {
                required property var modelData
                width: ListView.view.width
                text: modelData.name
                icon.name: modelData.icon || "application-x-executable"
                enabled: root.arcCustomIds.indexOf("app:" + modelData.id) < 0
                onClicked: {
                    root.writeLive(root.arcCustomIds.concat(["app:" + modelData.id]));
                    appDialog.close();
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
            writeLive(arcCustomIds.concat(["custom:" + name + "|" + icon + "|" + path]));
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
