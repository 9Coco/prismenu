import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC

Item {
    id: root

    property var cfg_ExtraCategoriesOrder: []
    property var cfg_ExtraCategoriesEnabled: []

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function writeLive(key, value) {
        try {
            plasmoid.configuration[key] = value;
        } catch (e) {}
    }

    function rebuildModel() {
        var order = SC.normalizeList(cfg_ExtraCategoriesOrder, SC.DEFAULT_EXTRA_ORDER);
        var defs = SC.extraCategoryDefs(root.tr);
        var byId = {};
        for (var i = 0; i < defs.length; ++i)
            byId[defs[i].id] = defs[i];
        var enabled = enabledIds();
        listModel.clear();
        var seen = {};
        for (var o = 0; o < order.length; ++o) {
            var id = order[o];
            if (!byId[id] || seen[id])
                continue;
            seen[id] = true;
            listModel.append({
                catId: id,
                catName: byId[id].name,
                catIcon: byId[id].icon || "applications-other",
                catOn: enabled.indexOf(id) >= 0
            });
        }
        for (var k = 0; k < defs.length; ++k) {
            if (seen[defs[k].id])
                continue;
            listModel.append({
                catId: defs[k].id,
                catName: defs[k].name,
                catIcon: defs[k].icon || "applications-other",
                catOn: enabled.indexOf(defs[k].id) >= 0
            });
        }
    }

    function enabledIds() {
        if (cfg_ExtraCategoriesEnabled === undefined || cfg_ExtraCategoriesEnabled === null)
            return SC.DEFAULT_EXTRA_ON.slice();
        return SC.normalizeList(cfg_ExtraCategoriesEnabled, SC.DEFAULT_EXTRA_ON);
    }

    function persistEnabledFromModel() {
        var list = [];
        for (var i = 0; i < listModel.count; ++i) {
            if (listModel.get(i).catOn)
                list.push(listModel.get(i).catId);
        }
        cfg_ExtraCategoriesEnabled = list.slice();
        writeLive("extraCategoriesEnabled", list.slice());
    }

    function persistOrderFromModel() {
        var order = [];
        for (var i = 0; i < listModel.count; ++i)
            order.push(listModel.get(i).catId);
        cfg_ExtraCategoriesOrder = order.slice();
        writeLive("extraCategoriesOrder", order.slice());
    }

    function setRowOn(index, on) {
        if (index < 0 || index >= listModel.count)
            return;
        listModel.setProperty(index, "catOn", !!on);
        persistEnabledFromModel();
    }

    function move(from, to) {
        if (from < 0 || to < 0 || from >= listModel.count || to >= listModel.count || from === to)
            return;
        listModel.move(from, to, 1);
        persistOrderFromModel();
    }

    function resetDefaults() {
        cfg_ExtraCategoriesOrder = SC.DEFAULT_EXTRA_ORDER.slice();
        cfg_ExtraCategoriesEnabled = SC.DEFAULT_EXTRA_ON.slice();
        writeLive("extraCategoriesOrder", cfg_ExtraCategoriesOrder.slice());
        writeLive("extraCategoriesEnabled", cfg_ExtraCategoriesEnabled.slice());
        rebuildModel();
    }

    ListModel { id: listModel }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label { text: root.tr("Extra Categories"); font.bold: true }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.65
                text: root.tr("Toggle which fixed categories appear above the normal category list.")
            }

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
                        model: listModel

                        delegate: RowLayout {
                            id: row
                            required property int index
                            required property string catId
                            required property string catName
                            required property string catIcon
                            required property bool catOn

                            Layout.fillWidth: true

                            Kirigami.Icon {
                                source: "transform-move"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                opacity: 0.4
                            }
                            Kirigami.Icon {
                                source: row.catIcon
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            }
                            QQC2.Label {
                                text: row.catName
                                Layout.fillWidth: true
                            }
                            QQC2.Switch {
                                // Drive from ListModel role — not a shared JS array lookup
                                checked: row.catOn
                                onToggled: root.setRowOn(row.index, checked)
                            }
                            QQC2.Button {
                                icon.name: "go-up"
                                flat: true
                                enabled: row.index > 0
                                onClicked: root.move(row.index, row.index - 1)
                            }
                            QQC2.Button {
                                icon.name: "go-down"
                                flat: true
                                enabled: row.index < listModel.count - 1
                                onClicked: root.move(row.index, row.index + 1)
                            }
                        }
                    }
                }
            }

            QQC2.Button { text: root.tr("Reset to defaults"); onClicked: root.resetDefaults() }
            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
        }
    }

    Component.onCompleted: {
        if (!cfg_ExtraCategoriesOrder || !cfg_ExtraCategoriesOrder.length)
            cfg_ExtraCategoriesOrder = SC.DEFAULT_EXTRA_ORDER.slice();
        if (cfg_ExtraCategoriesEnabled === undefined || cfg_ExtraCategoriesEnabled === null)
            cfg_ExtraCategoriesEnabled = SC.DEFAULT_EXTRA_ON.slice();
        rebuildModel();
    }

    onCfg_ExtraCategoriesOrderChanged: {
        // Rebuild when parent ConfigMenu syncs values into this page
        if (listModel.count === 0)
            rebuildModel();
    }
    onCfg_ExtraCategoriesEnabledChanged: {
        if (listModel.count === 0)
            rebuildModel();
        else {
            // Keep ListModel switches in sync if cfg was updated externally
            var enabled = enabledIds();
            for (var i = 0; i < listModel.count; ++i) {
                var on = enabled.indexOf(listModel.get(i).catId) >= 0;
                if (listModel.get(i).catOn !== on)
                    listModel.setProperty(i, "catOn", on);
            }
        }
    }
}
