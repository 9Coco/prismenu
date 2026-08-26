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
    property var cfg_CustomTypeGroups: []
    property string cfg_CustomGroupApps: "{}"

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
        var i;
        for (i = 0; i < defs.length; ++i)
            byId[defs[i].id] = defs[i];
        var groups = root.sidebarGroups();
        for (i = 0; i < groups.length; ++i)
            byId[groups[i].id] = groups[i];
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
            seen[defs[k].id] = true;
            listModel.append({
                catId: defs[k].id,
                catName: defs[k].name,
                catIcon: defs[k].icon || "applications-other",
                catOn: enabled.indexOf(defs[k].id) >= 0
            });
        }
        for (i = 0; i < groups.length; ++i) {
            if (seen[groups[i].id])
                continue;
            listModel.append({
                catId: groups[i].id,
                catName: groups[i].name,
                catIcon: groups[i].icon || "folder-favorites",
                catOn: enabled.indexOf(groups[i].id) >= 0 || !userSet()
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

    function parseGroups(raw) {
        if (typeof raw === "string")
            raw = raw.length ? raw.split(",") : [];
        var out = [];
        for (var i = 0; i < (raw || []).length; ++i) {
            var parts = String(raw[i] || "").split("|");
            if (parts[0])
                out.push({ id: parts[0], name: parts[1] || parts[0],
                    icon: parts[2] || "folder-favorites" });
        }
        return out;
    }

    function sidebarGroups() {
        return parseGroups(cfg_CustomQuickLinks);
    }

    function typeGroups() {
        return parseGroups(cfg_CustomTypeGroups);
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

    function customGroupMap() {
        try {
            var obj = JSON.parse(String(cfg_CustomGroupApps || "{}"));
            return (obj && typeof obj === "object") ? obj : {};
        } catch (e) {
            return {};
        }
    }

    function catalogApps() {
        try {
            var md = CatalogBridge.menuData();
            return md && md.allApps ? md.allApps : [];
        } catch (e) {
            return [];
        }
    }

    function groupContains(gid, appId) {
        var ids = customGroupMap()[gid];
        return Array.isArray(ids) && ids.indexOf(appId) >= 0;
    }

    function enableExtraId(gid) {
        var order = SC.normalizeList(cfg_ExtraCategoriesOrder, SC.DEFAULT_EXTRA_ORDER);
        if (order.indexOf(gid) < 0)
            order.push(gid);
        var enabled = enabledIds().slice();
        if (enabled.indexOf(gid) < 0)
            enabled.push(gid);
        cfg_ExtraCategoriesUserSet = true;
        cfg_ExtraCategoriesOrder = order.slice();
        cfg_ExtraCategoriesEnabled = enabled.slice();
        writeLive("ExtraCategoriesUserSet", true);
        writeLive("ExtraCategoriesOrder", order.slice());
        writeLive("ExtraCategoriesEnabled", enabled.slice());
    }

    function createGroup(name, icon, isType) {
        name = String(name || "").replace(/[|,]/g, " ").trim();
        if (!name)
            return;
        icon = String(icon || "folder-favorites").replace(/[|,]/g, "-").trim() || "folder-favorites";
        var prefix = isType ? "tgrp-" : "qgrp-";
        var gid = prefix + Math.random().toString(36).slice(2, 10);
        var key = isType ? "CustomTypeGroups" : "CustomQuickLinks";
        var list = ((isType ? cfg_CustomTypeGroups : cfg_CustomQuickLinks) || []).slice();
        if (typeof list === "string")
            list = list.length ? list.split(",") : [];
        list.push(gid + "|" + name + "|" + icon);
        if (isType)
            cfg_CustomTypeGroups = list;
        else
            cfg_CustomQuickLinks = list;
        writeLive(key, list);
        if (!isType)
            root.enableExtraId(gid);
        rebuildModel();
        rebuildTypeModel();
        rebuildSidebarModel();
    }

    function deleteGroup(gid) {
        var pref = ((cfg_CustomQuickLinks || []).slice()).filter(function (s) {
            return String(s).split("|")[0] !== gid;
        });
        var types = ((cfg_CustomTypeGroups || []).slice()).filter(function (s) {
            return String(s).split("|")[0] !== gid;
        });
        cfg_CustomQuickLinks = pref;
        cfg_CustomTypeGroups = types;
        writeLive("CustomQuickLinks", pref);
        writeLive("CustomTypeGroups", types);
        var map = customGroupMap();
        delete map[gid];
        var s = JSON.stringify(map);
        cfg_CustomGroupApps = s;
        writeLive("CustomGroupApps", s);
        var order = SC.normalizeList(cfg_ExtraCategoriesOrder, SC.DEFAULT_EXTRA_ORDER)
            .filter(function (id) { return id !== gid; });
        var enabled = enabledIds().filter(function (id) { return id !== gid; });
        cfg_ExtraCategoriesOrder = order.slice();
        cfg_ExtraCategoriesEnabled = enabled.slice();
        writeLive("ExtraCategoriesOrder", order.slice());
        writeLive("ExtraCategoriesEnabled", enabled.slice());
        rebuildModel();
        rebuildTypeModel();
        rebuildSidebarModel();
    }

    function toggleGroupApp(gid, appId, on) {
        if (!gid || !appId)
            return;
        var map = customGroupMap();
        var ids = Array.isArray(map[gid]) ? map[gid].slice() : [];
        var idx = ids.indexOf(appId);
        if (on && idx < 0)
            ids.push(appId);
        if (!on && idx >= 0)
            ids.splice(idx, 1);
        map[gid] = ids;
        var s = JSON.stringify(map);
        cfg_CustomGroupApps = s;
        writeLive("CustomGroupApps", s);
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
    ListModel { id: typeListModel }

    function rebuildTypeModel() {
        typeListModel.clear();
        var groups = root.typeGroups();
        for (var i = 0; i < groups.length; ++i) {
            typeListModel.append({
                catId: groups[i].id,
                catName: groups[i].name,
                catIcon: groups[i].icon || "folder-favorites"
            });
        }
    }

    ConfigPage {
        title: root.tr("Menu Groups")
        tip: root.tr("Preference groups appear above the split; type groups appear below it.")

        ConfigGroup {
            title: root.tr("Preference Groups")
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
                        QQC2.Button {
                            visible: String(row.catId).indexOf("qgrp-") === 0
                            icon.name: "document-edit"
                            flat: true
                            onClicked: {
                                manageDialog.groupId = row.catId;
                                manageFilter.text = "";
                                manageDialog.open();
                            }
                        }
                        QQC2.Button {
                            visible: String(row.catId).indexOf("qgrp-") === 0
                            icon.name: "list-remove"
                            flat: true
                            onClicked: {
                                deleteDialog.groupId = row.catId;
                                deleteDialog.open();
                            }
                        }
                    }
                    ConfigSep { visible: row.index < listModel.count - 1 }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("New custom group…")
                subtitle: root.tr("Shown above the split, with pinned and all-apps")
                iconName: "list-add"
                accent: "green"
                QQC2.Button {
                    icon.name: "list-add"
                    flat: true
                    onClicked: {
                        groupNameField.text = "";
                        newGroupDialog.groupIcon = "folder-favorites";
                        newGroupDialog.isType = false;
                        newGroupDialog.open();
                    }
                }
            }
        }

        QQC2.Button { text: root.tr("Reset preference groups"); onClicked: root.resetDefaults() }

        ConfigGroup {
            title: root.tr("Type Groups")
            Repeater {
                model: typeListModel
                ColumnLayout {
                    id: typeRow
                    required property int index
                    required property string catId
                    required property string catName
                    required property string catIcon
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: typeRow.catName
                        iconName: typeRow.catIcon
                        accent: index % 2 === 0 ? "teal" : "purple"
                        QQC2.Button {
                            icon.name: "document-edit"
                            flat: true
                            onClicked: {
                                manageDialog.groupId = typeRow.catId;
                                manageFilter.text = "";
                                manageDialog.open();
                            }
                        }
                        QQC2.Button {
                            icon.name: "list-remove"
                            flat: true
                            onClicked: {
                                deleteDialog.groupId = typeRow.catId;
                                deleteDialog.open();
                            }
                        }
                    }
                    ConfigSep { visible: typeRow.index < typeListModel.count - 1 }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("New custom group…")
                subtitle: root.tr("Shown below the split, with Office, Games, and other types")
                iconName: "list-add"
                accent: "teal"
                QQC2.Button {
                    icon.name: "list-add"
                    flat: true
                    onClicked: {
                        groupNameField.text = "";
                        newGroupDialog.groupIcon = "folder-favorites";
                        newGroupDialog.isType = true;
                        newGroupDialog.open();
                    }
                }
            }
        }
    }

    QQC2.Dialog {
        id: newGroupDialog
        property string groupIcon: "folder-favorites"
        property bool isType: false
        title: root.tr("New custom group…")
        modal: true
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        width: Kirigami.Units.gridUnit * 24
        padding: Kirigami.Units.largeSpacing
        anchors.centerIn: parent
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.FormLayout {
                Layout.fillWidth: true
                QQC2.TextField {
                    id: groupNameField
                    Layout.fillWidth: true
                    Kirigami.FormData.label: root.tr("Group name")
                }
                RowLayout {
                    Kirigami.FormData.label: root.tr("Group icon")
                    Kirigami.Icon {
                        source: newGroupDialog.groupIcon
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }
                    QQC2.Button {
                        text: root.tr("Browse...")
                        onClicked: iconChooser.openFor(newGroupDialog.groupIcon || "folder-favorites")
                    }
                }
            }
        }
        onAccepted: root.createGroup(groupNameField.text, newGroupDialog.groupIcon, newGroupDialog.isType)
    }

    QQC2.Dialog {
        id: deleteDialog
        property string groupId: ""
        title: root.tr("Delete group…")
        modal: true
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        width: Kirigami.Units.gridUnit * 22
        padding: Kirigami.Units.largeSpacing
        anchors.centerIn: parent
        contentItem: QQC2.Label {
            text: root.tr("Are you sure you want to delete this group?")
            wrapMode: Text.WordWrap
        }
        onAccepted: root.deleteGroup(deleteDialog.groupId)
    }

    QQC2.Dialog {
        id: manageDialog
        property string groupId: ""
        title: root.tr("Manage applications…")
        modal: true
        standardButtons: QQC2.Dialog.Close
        width: Math.min((parent ? parent.width : Kirigami.Units.gridUnit * 28) * 0.95, Kirigami.Units.gridUnit * 28)
        height: Math.min((parent ? parent.height : Kirigami.Units.gridUnit * 24) * 0.8, Kirigami.Units.gridUnit * 24)
        padding: Kirigami.Units.largeSpacing
        anchors.centerIn: parent
        contentItem: ColumnLayout {
            QQC2.TextField {
                id: manageFilter
                Layout.fillWidth: true
                placeholderText: root.tr("Search…")
            }
            ListView {
                id: manageList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: {
                    var q = String(manageFilter.text || "").toLowerCase();
                    var apps = root.catalogApps() || [];
                    var out = [];
                    for (var i = 0; i < apps.length; ++i) {
                        var a = apps[i];
                        if (!a || !a.id)
                            continue;
                        if (q && String(a.name || "").toLowerCase().indexOf(q) < 0
                            && String(a.id).toLowerCase().indexOf(q) < 0)
                            continue;
                        out.push(a);
                    }
                    return out;
                }
                delegate: QQC2.CheckDelegate {
                    required property var modelData
                    width: manageList.width
                    text: modelData.name
                    icon.name: modelData.icon || "application-x-executable"
                    checked: root.groupContains(manageDialog.groupId, modelData.id)
                    onToggled: root.toggleGroupApp(manageDialog.groupId, modelData.id, checked)
                }
            }
        }
    }

    IconChooserDialog {
        id: iconChooser
        uiLang: root.uiLang
        onIconChosen: (iconId, kind, filePath) => {
            newGroupDialog.groupIcon = kind === "file" ? filePath : iconId;
        }
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
        rebuildTypeModel();
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
    onCfg_CustomQuickLinksChanged: {
        rebuildSidebarModel();
        rebuildModel();
    }
    onCfg_CustomTypeGroupsChanged: rebuildTypeModel()
}
