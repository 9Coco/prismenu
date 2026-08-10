import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/IdList.js" as IdList
import "../../code/Favorites.js" as Favorites
import "../../code/CatalogBridge.js" as CatalogBridge
import ".." as Ui

/**
 * Pinned Applications editor — reorder, remove, add apps / custom shortcuts.
 */
Item {
    id: root

    property var cfg_PinnedApps: []
    property var localApps: []

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function writeLive(list) {
        cfg_PinnedApps = list;
        try { plasmoid.configuration.PinnedApps = list; } catch (e) {}
    }

    readonly property var pinnedIds: {
        var ids = IdList.normalizeIdList(cfg_PinnedApps || []);
        if (ids.length === 0)
            return IdList.defaultPinnedIds().slice();
        return ids;
    }

    Ui.AppsBackend {
        id: pinBackend
        onAppsUpdated: (apps) => { root.localApps = apps || []; }
    }

    readonly property var catalogApps: {
        if (root.localApps && root.localApps.length)
            return root.localApps;
        try {
            var md = CatalogBridge.menuData();
            if (md && md.allApps)
                return md.allApps;
        } catch (e) {}
        return [];
    }

    function resolvePinnedItem(id) {
        id = String(id || "");
        if (id === "arcmenu-settings") {
            return {
                id: id,
                name: root.tr("ArcMenu Settings"),
                icon: "preferences-system-windows"
            };
        }
        if (id.indexOf("custom:") === 0) {
            var rest = id.substring(7);
            var parts = rest.split("|");
            return {
                id: id,
                name: parts[0] || root.tr("Custom shortcut"),
                icon: parts[1] || "application-x-executable"
            };
        }
        var apps = root.catalogApps;
        for (var i = 0; i < apps.length; ++i) {
            if (apps[i].id === id || apps[i].favoriteId === id)
                return { id: id, name: apps[i].name, icon: apps[i].icon };
        }
        // Fallback from desktop id
        var shortName = id.replace(/\.desktop$/, "").split(".").pop();
        return { id: id, name: shortName || id, icon: "application-x-executable" };
    }

    function movePinned(from, to) {
        var list = pinnedIds.slice();
        writeLive(Favorites.moveItem(list, from, to));
    }

    function removePinned(id) {
        writeLive(Favorites.removeFavorite(pinnedIds.slice(), id));
    }

    function addPinned(id) {
        if (!id)
            return;
        writeLive(Favorites.addFavorite(pinnedIds.slice(), id));
    }

    function resetDefaults() {
        writeLive(IdList.defaultPinnedIds().slice());
    }

    ConfigPage {
        title: root.tr("Pinned Applications")
        tip: root.tr("Reorder and manage pinned apps")

        ConfigGroup {
            title: root.tr("Pinned Applications")
            Repeater {
                model: root.pinnedIds.length
                ColumnLayout {
                    id: pinWrap
                    required property int index
                    readonly property var item: root.resolvePinnedItem(root.pinnedIds[index])
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: pinWrap.item.name
                        iconName: pinWrap.item.icon || "application-x-executable"
                        accent: index % 2 === 0 ? "blue" : "purple"
                        Kirigami.Icon {
                            source: "transform-move"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.4
                        }
                        QQC2.Button {
                            icon.name: "go-up"
                            flat: true
                            enabled: index > 0
                            onClicked: root.movePinned(index, index - 1)
                        }
                        QQC2.Button {
                            icon.name: "go-down"
                            flat: true
                            enabled: index < root.pinnedIds.length - 1
                            onClicked: root.movePinned(index, index + 1)
                        }
                        QQC2.Button {
                            icon.name: "list-remove"
                            flat: true
                            onClicked: root.removePinned(pinWrap.item.id)
                        }
                    }
                    ConfigSep { visible: index < root.pinnedIds.length - 1 }
                }
            }
            ConfigSettingRow {
                visible: root.pinnedIds.length === 0
                title: root.tr("No pinned applications")
                iconName: "dialog-information"
                accent: "yellow"
            }
        }

        ConfigGroup {
            title: root.tr("Add")
            ConfigSettingRow {
                title: root.tr("Add more applications")
                iconName: "list-add"
                accent: "green"
                QQC2.Button {
                    icon.name: "list-add"
                    flat: true
                    onClicked: addAppDialog.open()
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Add custom shortcut")
                iconName: "document-new"
                accent: "teal"
                QQC2.Button {
                    icon.name: "list-add"
                    flat: true
                    onClicked: {
                        customName.text = "";
                        customIcon.text = "application-x-executable";
                        customExec.text = "";
                        customDialog.open();
                    }
                }
            }
        }

        QQC2.Button {
            text: root.tr("Reset to defaults")
            onClicked: root.resetDefaults()
        }
    }

    QQC2.Dialog {
        id: addAppDialog
        title: root.tr("Add more applications")
        modal: true
        standardButtons: QQC2.Dialog.Close
        width: Math.min(parent.width * 0.95, Kirigami.Units.gridUnit * 28)
        height: Math.min(parent.height * 0.8, Kirigami.Units.gridUnit * 24)
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            QQC2.TextField {
                id: appFilter
                Layout.fillWidth: true
                placeholderText: root.tr("Search…")
            }
            ListView {
                id: appPickList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: {
                    var q = String(appFilter.text || "").toLowerCase();
                    var apps = root.catalogApps || [];
                    var out = [];
                    for (var i = 0; i < apps.length; ++i) {
                        var a = apps[i];
                        if (!a || !a.id)
                            continue;
                        if (root.pinnedIds.indexOf(a.id) >= 0)
                            continue;
                        if (q && String(a.name || "").toLowerCase().indexOf(q) < 0
                            && String(a.id).toLowerCase().indexOf(q) < 0)
                            continue;
                        out.push(a);
                    }
                    return out;
                }
                delegate: QQC2.ItemDelegate {
                    required property var modelData
                    width: appPickList.width
                    text: modelData.name
                    icon.name: modelData.icon || "application-x-executable"
                    onClicked: {
                        root.addPinned(modelData.id);
                        addAppDialog.close();
                    }
                }
            }
            QQC2.Label {
                visible: appPickList.count === 0
                text: root.tr("No applications")
                opacity: 0.55
                Layout.alignment: Qt.AlignHCenter
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
            QQC2.TextField {
                id: customName
                Kirigami.FormData.label: root.tr("Name:")
            }
            QQC2.TextField {
                id: customIcon
                Kirigami.FormData.label: root.tr("Icon name")
                text: "application-x-executable"
            }
            QQC2.TextField {
                id: customExec
                Kirigami.FormData.label: root.tr("Command:")
                placeholderText: "firefox"
            }
        }

        onAccepted: {
            var name = String(customName.text || "").trim();
            var icon = String(customIcon.text || "application-x-executable").trim();
            var exec = String(customExec.text || "").trim();
            if (!name || !exec)
                return;
            // Encode: custom:Name|icon|exec  (no pipes in name/icon)
            name = name.replace(/\|/g, "-");
            icon = icon.replace(/\|/g, "-");
            exec = exec.replace(/\|/g, " ");
            root.addPinned("custom:" + name + "|" + icon + "|" + exec);
        }
    }
}
