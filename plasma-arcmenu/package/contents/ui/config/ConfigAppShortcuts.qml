import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC
import "../../code/CatalogBridge.js" as CatalogBridge
import ".." as Ui

Item {
    id: root

    property var cfg_ApplicationShortcuts: []
    property var localApps: []

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function writeLive(list) {
        cfg_ApplicationShortcuts = list;
        try { plasmoid.configuration.applicationShortcuts = list; } catch (e) {}
    }

    readonly property var ids: SC.normalizeList(cfg_ApplicationShortcuts, SC.DEFAULT_APPS)

    function findApp(id) {
        var apps = root.localApps;
        for (var i = 0; i < apps.length; ++i) {
            if (apps[i].id === id || apps[i].favoriteId === id)
                return apps[i];
        }
        try {
            var md = CatalogBridge.menuData();
            if (md && md.allApps) {
                for (var j = 0; j < md.allApps.length; ++j) {
                    if (md.allApps[j].id === id)
                        return md.allApps[j];
                }
            }
        } catch (e) {}
        return null;
    }

    readonly property var items: {
        var out = [];
        for (var i = 0; i < ids.length; ++i)
            out.push(SC.resolveApplication(ids[i], root.tr, root.findApp));
        return out;
    }

    Ui.AppsBackend {
        onAppsUpdated: (apps) => { root.localApps = apps || []; }
    }

    function move(from, to) { writeLive(SC.moveItem(ids, from, to)); }
    function removeAt(index) {
        var list = ids.slice();
        list.splice(index, 1);
        writeLive(list);
    }
    function addId(id) {
        if (!id || ids.indexOf(id) >= 0) return;
        writeLive(ids.concat([id]));
    }
    function resetDefaults() { writeLive(SC.DEFAULT_APPS.slice()); }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label { text: root.tr("Application Shortcuts"); font.bold: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: listCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: listCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: root.items
                        RowLayout {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Kirigami.Icon { source: "transform-move"; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small; opacity: 0.4 }
                            Kirigami.Icon {
                                source: modelData.icon || "application-x-executable"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                color: modelData.invalid ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                            }
                            QQC2.Label {
                                text: modelData.name
                                color: modelData.invalid ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            QQC2.Button { icon.name: "go-up"; flat: true; enabled: index > 0; onClicked: root.move(index, index - 1) }
                            QQC2.Button { icon.name: "go-down"; flat: true; enabled: index < root.items.length - 1; onClicked: root.move(index, index + 1) }
                            QQC2.Button { icon.name: "list-remove"; flat: true; onClicked: root.removeAt(index) }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: addCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: addCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Add more applications"); Layout.fillWidth: true }
                        QQC2.Button { icon.name: "list-add"; flat: true; onClicked: addAppDialog.open() }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Add custom shortcut"); Layout.fillWidth: true }
                        QQC2.Button {
                            icon.name: "list-add"; flat: true
                            onClicked: { customName.text = ""; customIcon.text = "application-x-executable"; customExec.text = ""; customDialog.open(); }
                        }
                    }
                }
            }

            QQC2.Button { text: root.tr("Reset to defaults"); onClicked: root.resetDefaults() }
            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
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
            QQC2.TextField { id: appFilter; Layout.fillWidth: true; placeholderText: root.tr("Search…") }
            ListView {
                id: appPickList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: {
                    var builtins = ["discover", "settings", "tweaks", "overview"];
                    var q = String(appFilter.text || "").toLowerCase();
                    var out = [];
                    for (var b = 0; b < builtins.length; ++b) {
                        if (root.ids.indexOf(builtins[b]) >= 0) continue;
                        var bi = SC.builtinApp(builtins[b], root.tr);
                        if (q && String(bi.name).toLowerCase().indexOf(q) < 0) continue;
                        out.push({ id: builtins[b], name: bi.name, icon: bi.icon });
                    }
                    var apps = root.localApps || [];
                    for (var i = 0; i < apps.length; ++i) {
                        var a = apps[i];
                        if (!a || !a.id || root.ids.indexOf(a.id) >= 0) continue;
                        if (q && String(a.name || "").toLowerCase().indexOf(q) < 0 && String(a.id).toLowerCase().indexOf(q) < 0)
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
                    onClicked: { root.addId(modelData.id); addAppDialog.close(); }
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
            QQC2.TextField { id: customIcon; Kirigami.FormData.label: root.tr("Icon name"); text: "application-x-executable" }
            QQC2.TextField { id: customExec; Kirigami.FormData.label: root.tr("Command:"); placeholderText: "firefox" }
        }
        onAccepted: {
            var name = String(customName.text || "").trim().replace(/\|/g, "-");
            var icon = String(customIcon.text || "application-x-executable").trim().replace(/\|/g, "-");
            var exec = String(customExec.text || "").trim().replace(/\|/g, " ");
            if (!name || !exec) return;
            root.addId("custom:" + name + "|" + icon + "|" + exec);
        }
    }
}
