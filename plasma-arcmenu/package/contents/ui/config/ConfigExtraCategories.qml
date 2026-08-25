import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC
import "../../code/SidebarModel.js" as SidebarModel
import "../../code/CatalogBridge.js" as CatalogBridge

Item {
    id: root

    property var cfg_ExtraCategoriesOrder: []
    property var cfg_ExtraCategoriesEnabled: []
    property bool cfg_ExtraCategoriesUserSet: false
    property var cfg_SidebarOrder: []
    property var cfg_SidebarHidden: []
    property var cfg_CustomQuickLinks: []

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function writeLive(key, value) {
        try {
            var payload = (value && value.slice) ? value.slice() : value;
            plasmoid.configuration[key] = payload;
            try { plasmoid.configuration.writeConfig(); } catch (e2) {}
            console.log("ArcMenu ExtraCategories writeLive", key, JSON.stringify(payload));
        } catch (e) {
            console.warn("ArcMenu ExtraCategories writeLive failed", key, e);
        }
    }

    function userSet() {
        if (cfg_ExtraCategoriesUserSet === true || cfg_ExtraCategoriesUserSet === 1)
            return true;
        try { return !!plasmoid.configuration.ExtraCategoriesUserSet; } catch (e) { return false; }
    }

    function enabledIds() {
        return SC.effectiveExtraEnabled(cfg_ExtraCategoriesEnabled, userSet());
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

    function persistEnabledFromModel() {
        var list = [];
        for (var i = 0; i < listModel.count; ++i) {
            if (listModel.get(i).catOn)
                list.push(listModel.get(i).catId);
        }
        cfg_ExtraCategoriesUserSet = true;
        cfg_ExtraCategoriesEnabled = list.slice();
        writeLive("ExtraCategoriesUserSet", true);
        writeLive("ExtraCategoriesEnabled", list.slice());
    }

    function persistOrderFromModel() {
        var order = [];
        for (var i = 0; i < listModel.count; ++i)
            order.push(listModel.get(i).catId);
        cfg_ExtraCategoriesUserSet = true;
        cfg_ExtraCategoriesOrder = order.slice();
        writeLive("ExtraCategoriesUserSet", true);
        writeLive("ExtraCategoriesOrder", order.slice());
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
        cfg_ExtraCategoriesUserSet = true;
        writeLive("ExtraCategoriesOrder", cfg_ExtraCategoriesOrder.slice());
        writeLive("ExtraCategoriesEnabled", cfg_ExtraCategoriesEnabled.slice());
        writeLive("ExtraCategoriesUserSet", true);
        rebuildModel();
    }

    function sidebarCategories() {
        try {
            var md = CatalogBridge.menuData();
            return md && md.categories ? md.categories : [];
        } catch (e) {
            return [];
        }
    }

    function sidebarGroups() {
        var raw = cfg_CustomQuickLinks || [];
        if (typeof raw === "string")
            raw = raw.length ? raw.split(",") : [];
        var out = [];
        for (var i = 0; i < raw.length; ++i) {
            var parts = String(raw[i] || "").split("|");
            if (parts[0])
                out.push({ id: parts[0], name: parts[1] || parts[0],
                    icon: parts[2] || "folder-favorites" });
        }
        return out;
    }

    function rebuildSidebarModel() {
        var categories = sidebarCategories();
        var groups = sidebarGroups();
        var defs = SidebarModel.definitions(categories, groups, root.tr);
        var order = SidebarModel.fullOrder(categories, groups, cfg_SidebarOrder, root.tr);
        var hidden = SidebarModel.normalizeList(cfg_SidebarHidden);
        var byId = {};
        for (var d = 0; d < defs.length; ++d)
            byId[defs[d].id] = defs[d];
        sidebarListModel.clear();
        for (var i = 0; i < order.length; ++i) {
            var item = byId[order[i]];
            if (!item)
                continue;
            sidebarListModel.append({
                itemId: item.id,
                itemName: item.name,
                itemIcon: item.icon || "applications-other",
                itemOn: hidden.indexOf(item.id) < 0
            });
        }
    }

    function persistSidebarOrder() {
        var order = [];
        for (var i = 0; i < sidebarListModel.count; ++i)
            order.push(sidebarListModel.get(i).itemId);
        cfg_SidebarOrder = order.slice();
        writeLive("SidebarOrder", order.slice());
    }

    function persistSidebarHidden() {
        var hidden = [];
        for (var i = 0; i < sidebarListModel.count; ++i) {
            if (!sidebarListModel.get(i).itemOn)
                hidden.push(sidebarListModel.get(i).itemId);
        }
        cfg_SidebarHidden = hidden.slice();
        writeLive("SidebarHidden", hidden.slice());
    }

    function setSidebarItemOn(index, on) {
        if (index < 0 || index >= sidebarListModel.count)
            return;
        sidebarListModel.setProperty(index, "itemOn", !!on);
        persistSidebarHidden();
    }

    function moveSidebarItem(from, to) {
        if (from < 0 || to < 0 || from >= sidebarListModel.count
                || to >= sidebarListModel.count || from === to)
            return;
        sidebarListModel.move(from, to, 1);
        persistSidebarOrder();
    }

    function resetSidebarDefaults() {
        cfg_SidebarOrder = [];
        cfg_SidebarHidden = [];
        writeLive("SidebarOrder", []);
        writeLive("SidebarHidden", []);
        rebuildSidebarModel();
    }

    ListModel { id: listModel }
    ListModel { id: sidebarListModel }

    ConfigPage {
        title: root.tr("Sidebar Items")
        tip: root.tr("Configure the shared application sidebar and legacy extra categories.")

        ConfigGroup {
            title: root.tr("Application Sidebar")
            Repeater {
                model: sidebarListModel
                ColumnLayout {
                    id: sidebarRow
                    required property int index
                    required property string itemId
                    required property string itemName
                    required property string itemIcon
                    required property bool itemOn
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: sidebarRow.itemName
                        iconName: sidebarRow.itemIcon
                        accent: index % 2 === 0 ? "blue" : "teal"
                        Kirigami.Icon {
                            source: "transform-move"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.4
                        }
                        QQC2.Switch {
                            checked: sidebarRow.itemOn
                            onToggled: root.setSidebarItemOn(sidebarRow.index, checked)
                        }
                        QQC2.Button {
                            icon.name: "go-up"
                            flat: true
                            enabled: sidebarRow.index > 0
                            onClicked: root.moveSidebarItem(sidebarRow.index, sidebarRow.index - 1)
                        }
                        QQC2.Button {
                            icon.name: "go-down"
                            flat: true
                            enabled: sidebarRow.index < sidebarListModel.count - 1
                            onClicked: root.moveSidebarItem(sidebarRow.index, sidebarRow.index + 1)
                        }
                    }
                    ConfigSep { visible: sidebarRow.index < sidebarListModel.count - 1 }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Add custom item in ArcMenu layout adjustment")
                subtitle: root.tr("Custom application groups appear here automatically.")
                iconName: "list-add"
                accent: "green"
            }
        }

        QQC2.Button { text: root.tr("Reset sidebar"); onClicked: root.resetSidebarDefaults() }

        ConfigGroup {
            title: root.tr("Extra Categories")
            Repeater {
                model: listModel
                ColumnLayout {
                    id: row
                    required property int index
                    required property string catId
                    required property string catName
                    required property string catIcon
                    required property bool catOn
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: row.catName
                        iconName: row.catIcon
                        accent: index % 2 === 0 ? "blue" : "indigo"
                        Kirigami.Icon {
                            source: "transform-move"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.4
                        }
                        QQC2.Switch {
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
                    ConfigSep { visible: row.index < listModel.count - 1 }
                }
            }
        }

        QQC2.Button { text: root.tr("Reset to defaults"); onClicked: root.resetDefaults() }
    }

    Component.onCompleted: {
        if (!cfg_ExtraCategoriesOrder || !cfg_ExtraCategoriesOrder.length)
            cfg_ExtraCategoriesOrder = SC.DEFAULT_EXTRA_ORDER.slice();
        // Before the user has customized: show & keep defaults (do not treat [] as all-off)
        if (!userSet()) {
            cfg_ExtraCategoriesEnabled = SC.DEFAULT_EXTRA_ON.slice();
            // Align stored config with what the menu already shows, without marking user-set
            writeLive("ExtraCategoriesEnabled", SC.DEFAULT_EXTRA_ON.slice());
            writeLive("ExtraCategoriesOrder",
                SC.normalizeList(cfg_ExtraCategoriesOrder, SC.DEFAULT_EXTRA_ORDER));
        } else if (cfg_ExtraCategoriesEnabled === undefined || cfg_ExtraCategoriesEnabled === null) {
            cfg_ExtraCategoriesEnabled = SC.DEFAULT_EXTRA_ON.slice();
        }
        rebuildModel();
        rebuildSidebarModel();
    }

    onCfg_ExtraCategoriesOrderChanged: {
        if (listModel.count === 0)
            rebuildModel();
    }
    onCfg_ExtraCategoriesEnabledChanged: {
        if (listModel.count === 0)
            rebuildModel();
        else {
            var enabled = enabledIds();
            for (var i = 0; i < listModel.count; ++i) {
                var on = enabled.indexOf(listModel.get(i).catId) >= 0;
                if (listModel.get(i).catOn !== on)
                    listModel.setProperty(i, "catOn", on);
            }
        }
    }
    onCfg_ExtraCategoriesUserSetChanged: rebuildModel()
    onCfg_SidebarOrderChanged: {
        if (sidebarListModel.count === 0)
            rebuildSidebarModel();
    }
    onCfg_SidebarHiddenChanged: {
        if (sidebarListModel.count === 0)
            rebuildSidebarModel();
    }
    onCfg_CustomQuickLinksChanged: rebuildSidebarModel()
}
