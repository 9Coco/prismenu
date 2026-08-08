import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC
import ".." as Ui

Item {
    id: root

    property var cfg_ContextMenuItems: []
    property var localApps: []

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function writeLive(list) {
        cfg_ContextMenuItems = list;
        try { plasmoid.configuration.contextMenuItems = list; } catch (e) {}
    }

    readonly property var ids: SC.normalizeList(cfg_ContextMenuItems, SC.DEFAULT_CTX)

    function resolveItem(id) {
        id = String(id || "");
        var defs = SC.contextMenuDefs(root.tr);
        for (var i = 0; i < defs.length; ++i) {
            if (defs[i].id === id)
                return defs[i];
        }
        if (id.indexOf("custom:") === 0) {
            var rest = id.substring(7).split("|");
            return { id: id, name: rest[0] || root.tr("Custom shortcut"), icon: rest[1] || "application-x-executable" };
        }
        if (id.indexOf("desktop:") === 0) {
            var did = id.substring(8);
            for (var a = 0; a < localApps.length; ++a) {
                if (localApps[a].id === did)
                    return { id: id, name: localApps[a].name, icon: localApps[a].icon || "application-x-executable" };
            }
            return { id: id, name: root.tr("Invalid shortcut") + " - " + did, icon: "dialog-warning", invalid: true };
        }
        return { id: id, name: root.tr("Invalid shortcut") + " - " + id, icon: "dialog-warning", invalid: true };
    }

    readonly property var items: {
        var out = [];
        for (var i = 0; i < ids.length; ++i)
            out.push(resolveItem(ids[i]));
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
        if (!id) return;
        writeLive(ids.concat([id]));
    }
    function resetDefaults() { writeLive(SC.DEFAULT_CTX.slice()); }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label { text: root.tr("Modify ArcMenu Context Menu"); font.bold: true }

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
                                source: modelData.icon
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

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Add more applications"); Layout.fillWidth: true }
                        QQC2.Button { icon.name: "list-add"; flat: true; onClicked: addDialog.open() }
                    }
                }
            }

            QQC2.Button { text: root.tr("Reset to defaults"); onClicked: root.resetDefaults() }
            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
        }
    }

    QQC2.Dialog {
        id: addDialog
        title: root.tr("Add more applications")
        modal: true
        standardButtons: QQC2.Dialog.Close
        width: Math.min(parent.width * 0.95, Kirigami.Units.gridUnit * 26)
        height: Math.min(parent.height * 0.75, Kirigami.Units.gridUnit * 22)
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: {
                    var builtins = SC.contextMenuDefs(root.tr);
                    var out = [];
                    for (var i = 0; i < builtins.length; ++i) {
                        if (builtins[i].id === "separator" || root.ids.indexOf(builtins[i].id) < 0)
                            out.push({ id: builtins[i].id, name: builtins[i].name, icon: builtins[i].icon });
                    }
                    for (var a = 0; a < root.localApps.length; ++a) {
                        var app = root.localApps[a];
                        var cid = "desktop:" + app.id;
                        if (root.ids.indexOf(cid) >= 0) continue;
                        out.push({ id: cid, name: app.name, icon: app.icon || "application-x-executable" });
                    }
                    return out;
                }
                delegate: QQC2.ItemDelegate {
                    required property var modelData
                    width: parent.width
                    text: modelData.name
                    icon.name: modelData.icon
                    onClicked: { root.addId(modelData.id); addDialog.close(); }
                }
            }
        }
    }
}
