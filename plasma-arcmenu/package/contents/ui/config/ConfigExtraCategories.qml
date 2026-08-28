import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC
import "../../code/SidebarModel.js" as SidebarModel
import "../../code/CatalogBridge.js" as CatalogBridge
import "../../code/AppsModel.js" as AppsModel
import ".." as Ui
import "../components" as Components

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
    property string cfg_GroupViewOptions: "{}"
    property string cfg_HomeGroupId: "pinned"
    property var cfg_PinnedApps: []
    property var cfg_Order: []
    property var cfg_Hidden: []
    property string cfg_CustomNames: "{}"
    property string cfg_CustomIcons: "{}"
    property bool cfg_ShowEmpty: true
    property bool cfg_Enabled: true
    property int cfg_MaxItems: 5
    property var cfg_RecentApps: []
    property var localApps: []
    property bool groupCreationPending: false
    property bool groupModelsDirty: false

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    readonly property var homeGroupChoices: {
        var _preferenceCount = listModel.count;
        var _typeCount = typeListModel.count;
        var out = [];
        var seen = {};
        function appendChoice(id, name, icon) {
            id = String(id || "");
            if (!id || seen[id])
                return;
            seen[id] = true;
            out.push({ groupId: id, text: name || id, iconName: icon || "applications-other" });
        }
        // Keep the safe default available even while the live models initialize.
        appendChoice("pinned", root.tr("Pinned Applications"), "favorite");
        appendChoice("all-apps", root.tr("All Applications"), "view-app-grid-symbolic");
        appendChoice("frequent", root.tr("Frequent"), "view-history");
        appendChoice("recent-files", root.tr("Recent Files"), "document-open-recent");
        for (var p = 0; p < listModel.count; ++p) {
            var pref = listModel.get(p);
            appendChoice(pref.catId, pref.catName, pref.catIcon);
        }
        for (var t = 0; t < typeListModel.count; ++t) {
            var type = typeListModel.get(t);
            appendChoice(type.catId, type.catName, type.catIcon);
        }
        return out;
    }

    function homeGroupIndex() {
        var wanted = String(cfg_HomeGroupId || "pinned");
        for (var i = 0; i < homeGroupChoices.length; ++i) {
            if (homeGroupChoices[i].groupId === wanted)
                return i;
        }
        return 0;
    }

    function setHomeGroup(index) {
        if (index < 0 || index >= homeGroupChoices.length)
            return;
        cfg_HomeGroupId = homeGroupChoices[index].groupId;
        writeLive("HomeGroupId", cfg_HomeGroupId);
    }

    function writeLive(key, value) {
        try {
            var payload = (value && value.slice) ? value.slice() : value;
            plasmoid.configuration[key] = payload;
            console.log("ArcMenu ExtraCategories writeLive", key, JSON.stringify(payload));
        } catch (e) {
            console.warn("ArcMenu ExtraCategories writeLive failed", key, e);
        }
    }

    Timer {
        id: groupModelsTimer
        interval: 30
        repeat: false
        onTriggered: {
            root.groupModelsDirty = false;
            root.rebuildModel();
            root.rebuildTypeModel();
            root.rebuildSidebarModel();
        }
    }

    function scheduleGroupModelsRebuild() {
        root.groupModelsDirty = true;
        groupModelsTimer.restart();
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
        if (root.localApps && root.localApps.length)
            return root.localApps;
        try {
            var md = CatalogBridge.menuData();
            return md && md.allApps ? md.allApps : [];
        } catch (e) {
            return [];
        }
    }

    function visibleCatalog() {
        return AppsModel.filterVisibleApps(root.catalogApps() || []);
    }

    function resolveCatalogApp(appId) {
        var apps = root.catalogApps() || [];
        for (var i = 0; i < apps.length; ++i) {
            if (apps[i] && (apps[i].id === appId || apps[i].favoriteId === appId))
                return apps[i];
        }
        return { id: appId, name: appId, icon: "application-x-executable" };
    }

    function extraAssignedIds(gid) {
        var ids = customGroupMap()[gid];
        return Array.isArray(ids) ? ids.slice() : [];
    }

    function groupContains(gid, appId) {
        return root.extraAssignedIds(gid).indexOf(appId) >= 0;
    }

    function columnApps(gid) {
        if (!gid)
            return [];
        var seen = {};
        var out = [];
        var i;
        var extras = root.extraAssignedIds(gid);
        if (String(gid).indexOf("tgrp-") === 0 || String(gid).indexOf("qgrp-") === 0) {
            for (i = 0; i < extras.length; ++i) {
                if (!extras[i] || seen[extras[i]])
                    continue;
                seen[extras[i]] = true;
                var app = root.resolveCatalogApp(extras[i]);
                out.push({
                    id: extras[i],
                    name: app.name || extras[i],
                    icon: app.icon || "application-x-executable",
                    extra: true
                });
            }
            return out;
        }
        var base = AppsModel.appsInCategory(root.catalogApps() || [], gid);
        for (i = 0; i < base.length; ++i) {
            if (!base[i] || !base[i].id || seen[base[i].id])
                continue;
            seen[base[i].id] = true;
            out.push({
                id: base[i].id,
                name: base[i].name,
                icon: base[i].icon || "application-x-executable",
                extra: extras.indexOf(base[i].id) >= 0
            });
        }
        for (i = 0; i < extras.length; ++i) {
            if (!extras[i] || seen[extras[i]])
                continue;
            seen[extras[i]] = true;
            var extraApp = root.resolveCatalogApp(extras[i]);
            out.push({
                id: extras[i],
                name: extraApp.name || extras[i],
                icon: extraApp.icon || "application-x-executable",
                extra: true
            });
        }
        return out;
    }

    function filteredPickerApps(query) {
        var q = String(query || "").toLowerCase();
        var apps = root.visibleCatalog();
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

    function groupViewMode(id) {
        return SC.groupViewMode(cfg_GroupViewOptions, id);
    }

    function setGroupViewMode(id, view) {
        var s = SC.setGroupView(cfg_GroupViewOptions, id, view);
        cfg_GroupViewOptions = s;
        writeLive("GroupViewOptions", s);
    }

    function groupIconSize(id) {
        return SC.groupIconSize(cfg_GroupViewOptions, id);
    }

    function setGroupIconSize(id, size) {
        var s = SC.setGroupIconSize(cfg_GroupViewOptions, id, size);
        cfg_GroupViewOptions = s;
        writeLive("GroupViewOptions", s);
    }

    function openColumnSettings(id, name, isType) {
        columnDialog.groupId = id;
        columnDialog.groupName = name || id;
        columnDialog.isType = !!isType;
        columnDialog.appsExpanded = false;
        columnDialog.refreshApps();
        columnDialog.open();
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
        var normalizedName = name.toLocaleLowerCase();
        for (var existing = 0; existing < list.length; ++existing) {
            var existingParts = String(list[existing] || "").split("|");
            if (String(existingParts[1] || "").trim().toLocaleLowerCase() === normalizedName) {
                console.warn("ArcMenu duplicate custom group ignored:", name);
                return false;
            }
        }
        list.push(gid + "|" + name + "|" + icon);
        if (isType)
            cfg_CustomTypeGroups = list;
        else
            cfg_CustomQuickLinks = list;
        writeLive(key, list);
        if (!isType)
            root.enableExtraId(gid);
        if (isType)
            persistTypeOrder();
        scheduleGroupModelsRebuild();
        return true;
    }

    function deleteGroup(gid) {
        if (String(cfg_HomeGroupId || "pinned") === String(gid)) {
            cfg_HomeGroupId = "pinned";
            writeLive("HomeGroupId", "pinned");
        }
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
        var views = SC.parseGroupViewOptions(cfg_GroupViewOptions);
        if (views[gid]) {
            delete views[gid];
            var vs = JSON.stringify(views);
            cfg_GroupViewOptions = vs;
            writeLive("GroupViewOptions", vs);
        }
        var order = SC.normalizeList(cfg_ExtraCategoriesOrder, SC.DEFAULT_EXTRA_ORDER)
            .filter(function (id) { return id !== gid; });
        var enabled = enabledIds().filter(function (id) { return id !== gid; });
        cfg_ExtraCategoriesOrder = order.slice();
        cfg_ExtraCategoriesEnabled = enabled.slice();
        writeLive("ExtraCategoriesOrder", order.slice());
        writeLive("ExtraCategoriesEnabled", enabled.slice());
        var quickOrder = SC.normalizeList(plasmoid.configuration.QuickLinksOrder, [])
            .filter(function (id) { return id !== gid; });
        var quickEnabled = SC.normalizeList(plasmoid.configuration.QuickLinksEnabled, [])
            .filter(function (id) { return id !== gid; });
        writeLive("QuickLinksOrder", quickOrder);
        writeLive("QuickLinksEnabled", quickEnabled);
        var sidebarId = "group:" + gid;
        var sidebarOrder = SC.normalizeList(cfg_SidebarOrder, [])
            .filter(function (id) { return id !== gid && id !== sidebarId; });
        var sidebarHidden = SC.normalizeList(cfg_SidebarHidden, [])
            .filter(function (id) { return id !== gid && id !== sidebarId; });
        cfg_SidebarOrder = sidebarOrder.slice();
        cfg_SidebarHidden = sidebarHidden.slice();
        writeLive("SidebarOrder", sidebarOrder.slice());
        writeLive("SidebarHidden", sidebarHidden.slice());
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
        if (columnDialog.visible)
            columnDialog.refreshApps();
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

    Ui.AppsBackend {
        id: typeBackend
        onAppsUpdated: (apps) => {
            root.localApps = apps || [];
            root.rebuildTypeModel();
            if (columnDialog.visible)
                columnDialog.refreshApps();
        }
    }

    function systemCategories() {
        var src = [];
        if (typeBackend.categories && typeBackend.categories.length)
            src = typeBackend.categories;
        else {
            try {
                var md = CatalogBridge.menuData();
                if (md && md.rawCategories && md.rawCategories.length)
                    src = md.rawCategories;
                else if (md && md.categories && md.categories.length)
                    src = md.categories;
            } catch (e) {}
        }
        var live = [];
        for (var i = 0; i < src.length; ++i) {
            if (src[i] && src[i].id && src[i].id !== "all")
                live.push(src[i]);
        }
        return live;
    }

    function customNamesMap() {
        return AppsModel.parseJsonMap(cfg_CustomNames);
    }

    function customIconsMap() {
        return AppsModel.parseJsonMap(cfg_CustomIcons);
    }

    function displayTypeName(cat) {
        var names = customNamesMap();
        if (cat.id && names[cat.id])
            return names[cat.id];
        return cat.name || cat.id;
    }

    function isTypeHidden(id) {
        return (cfg_Hidden || []).indexOf(id) >= 0;
    }

    function rebuildTypeModel() {
        typeListModel.clear();
        var cats = root.systemCategories();
        var groups = root.typeGroups();
        var byId = {};
        var i;
        for (i = 0; i < cats.length; ++i) {
            if (cats[i] && cats[i].id)
                byId[cats[i].id] = {
                    catId: cats[i].id,
                    catName: root.displayTypeName(cats[i]),
                    catIcon: customIconsMap()[cats[i].id] || cats[i].icon || "applications-other",
                    rowKind: "system",
                    catOn: !root.isTypeHidden(cats[i].id)
                };
        }
        for (i = 0; i < groups.length; ++i) {
            byId[groups[i].id] = {
                catId: groups[i].id,
                catName: groups[i].name,
                catIcon: groups[i].icon || "folder-favorites",
                rowKind: "custom",
                catOn: !root.isTypeHidden(groups[i].id)
            };
        }
        var order = (cfg_Order && cfg_Order.length)
            ? cfg_Order.slice()
            : cats.map(function (c) { return c.id; });
        var seen = {};
        for (i = 0; i < order.length; ++i) {
            var id = order[i];
            if (!byId[id] || seen[id])
                continue;
            seen[id] = true;
            typeListModel.append(byId[id]);
        }
        for (i = 0; i < cats.length; ++i) {
            if (cats[i] && cats[i].id && !seen[cats[i].id]) {
                seen[cats[i].id] = true;
                typeListModel.append(byId[cats[i].id]);
            }
        }
        for (i = 0; i < groups.length; ++i) {
            if (!seen[groups[i].id])
                typeListModel.append(byId[groups[i].id]);
        }
    }

    function persistTypeOrder() {
        var order = [];
        for (var i = 0; i < typeListModel.count; ++i)
            order.push(typeListModel.get(i).catId);
        cfg_Order = order.slice();
        writeLive("Order", order.slice());
    }

    function moveTypeRow(from, to) {
        if (from < 0 || to < 0 || from >= typeListModel.count
                || to >= typeListModel.count || from === to)
            return;
        typeListModel.move(from, to, 1);
        persistTypeOrder();
    }

    function setTypeHidden(id, hide) {
        var list = (cfg_Hidden || []).slice();
        var idx = list.indexOf(id);
        if (hide && idx < 0)
            list.push(id);
        if (!hide && idx >= 0)
            list.splice(idx, 1);
        cfg_Hidden = list;
        writeLive("Hidden", list);
        rebuildTypeModel();
    }

    ConfigPage {
        title: root.tr("Menu Groups")
        tip: root.tr("Preference groups appear above the split; type groups appear below it.")

        ConfigGroup {
            title: root.tr("Home Page")
            ConfigSettingRow {
                title: root.tr("Home page content")
                subtitle: root.tr("Choose the group shown in each layout's home application area.")
                iconName: root.homeGroupChoices[root.homeGroupIndex()]
                    ? root.homeGroupChoices[root.homeGroupIndex()].iconName : "favorite"
                accent: "blue"
                QQC2.ComboBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                    textRole: "text"
                    model: root.homeGroupChoices
                    currentIndex: root.homeGroupIndex()
                    onActivated: (index) => root.setHomeGroup(index)
                }
            }
        }

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
                            icon.name: "settings-configure"
                            flat: true
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: root.tr("Column settings")
                            Accessible.name: root.tr("Column settings")
                            onClicked: root.openColumnSettings(row.catId, row.catName, false)
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
            ConfigSettingRow {
                title: root.tr("Show empty categories")
                iconName: "view-list-details"
                accent: "blue"
                QQC2.Switch {
                    checked: root.cfg_ShowEmpty
                    onToggled: {
                        root.cfg_ShowEmpty = checked;
                        root.writeLive("ShowEmpty", checked);
                    }
                }
            }
            ConfigSep {}
            Repeater {
                model: typeListModel
                ColumnLayout {
                    id: typeRow
                    required property int index
                    required property string catId
                    required property string catName
                    required property string catIcon
                    required property string rowKind
                    required property bool catOn
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: typeRow.catName
                        iconName: typeRow.catIcon
                        accent: index % 2 === 0 ? "teal" : "purple"
                        QQC2.Switch {
                            checked: typeRow.catOn
                            onToggled: root.setTypeHidden(typeRow.catId, !checked)
                        }
                        QQC2.Button {
                            icon.name: "go-up"
                            flat: true
                            enabled: typeRow.index > 0
                            onClicked: root.moveTypeRow(typeRow.index, typeRow.index - 1)
                        }
                        QQC2.Button {
                            icon.name: "go-down"
                            flat: true
                            enabled: typeRow.index < typeListModel.count - 1
                            onClicked: root.moveTypeRow(typeRow.index, typeRow.index + 1)
                        }
                        QQC2.Button {
                            icon.name: "settings-configure"
                            flat: true
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: root.tr("Column settings")
                            Accessible.name: root.tr("Column settings")
                            onClicked: root.openColumnSettings(typeRow.catId, typeRow.catName, true)
                        }
                        QQC2.Button {
                            visible: typeRow.rowKind === "custom"
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
                subtitle: root.tr("Shown below the split with system application types")
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
        property bool submitLocked: false
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
                    Components.ResolvedIcon {
                        iconName: newGroupDialog.groupIcon
                        tintColor: Kirigami.Theme.textColor
                        preferSymbolic: false
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
        onOpened: submitLocked = false
        onAccepted: {
            if (submitLocked || root.groupCreationPending)
                return;
            submitLocked = true;
            root.groupCreationPending = true;
            var pendingName = groupNameField.text;
            var pendingIcon = groupIcon;
            var pendingType = isType;
            // Let the dialog close and paint before configuration/model work.
            Qt.callLater(function () {
                root.createGroup(pendingName, pendingIcon, pendingType);
                root.groupCreationPending = false;
            });
        }
    }

    QQC2.Dialog {
        id: columnDialog
        property string groupId: ""
        property string groupName: ""
        property bool isType: false
        property bool appsExpanded: false
        property var appsList: []
        readonly property bool isFrequent: groupId === "frequent"
        title: root.tr("Column settings")
        modal: true
        dim: true
        standardButtons: QQC2.Dialog.Close
        width: Math.min((parent ? parent.width : Kirigami.Units.gridUnit * 28) * 0.95, Kirigami.Units.gridUnit * 28)
        padding: Kirigami.Units.largeSpacing
        anchors.centerIn: parent
        clip: true
        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            radius: Kirigami.Units.cornerRadius
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.18)
        }
        function refreshApps() {
            appsList = root.columnApps(groupId);
        }
        onAboutToShow: {
            var view = root.groupViewMode(columnDialog.groupId);
            viewCombo.currentIndex = view === "grid" ? 0 : 1;
            iconSizeSpin.value = root.groupIconSize(columnDialog.groupId);
            refreshApps();
        }
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            QQC2.Label {
                Layout.fillWidth: true
                text: columnDialog.groupName
                wrapMode: Text.WordWrap
                font.weight: Font.Medium
            }
            Kirigami.FormLayout {
                Layout.fillWidth: true
                QQC2.ComboBox {
                    id: viewCombo
                    Kirigami.FormData.label: root.tr("Icon display")
                    model: [root.tr("Icon grid"), root.tr("List")]
                    onActivated: root.setGroupViewMode(columnDialog.groupId, currentIndex === 0 ? "grid" : "list")
                }
                RowLayout {
                    visible: viewCombo.currentIndex === 0
                    Kirigami.FormData.label: root.tr("Icon size")
                    QQC2.Slider {
                        id: iconSizeSlider
                        Layout.fillWidth: true
                        from: 24
                        to: 80
                        stepSize: 4
                        value: iconSizeSpin.value
                        onMoved: {
                            var n = Math.round(value);
                            if (iconSizeSpin.value !== n)
                                iconSizeSpin.value = n;
                            root.setGroupIconSize(columnDialog.groupId, n);
                        }
                    }
                    QQC2.SpinBox {
                        id: iconSizeSpin
                        from: 24
                        to: 80
                        stepSize: 4
                        value: 48
                        onValueModified: {
                            iconSizeSlider.value = value;
                            root.setGroupIconSize(columnDialog.groupId, value);
                        }
                    }
                }
                QQC2.Label {
                    visible: viewCombo.currentIndex === 0
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.55
                    text: root.tr("Smaller icons show more applications")
                }
            }
            ColumnLayout {
                visible: columnDialog.isType
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing / 2
                QQC2.ToolButton {
                    Layout.fillWidth: true
                    icon.name: columnDialog.appsExpanded ? "go-down" : "go-next"
                    text: root.tr("Applications in this column")
                          + " (" + columnDialog.appsList.length + ")"
                    display: QQC2.AbstractButton.TextBesideIcon
                    onClicked: {
                        columnDialog.appsExpanded = !columnDialog.appsExpanded;
                        if (columnDialog.appsExpanded)
                            columnDialog.refreshApps();
                    }
                }
                QQC2.Label {
                    visible: columnDialog.appsExpanded && columnDialog.appsList.length === 0
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    text: root.localApps.length
                          ? root.tr("No applications in this column")
                          : root.tr("Loading applications…")
                    opacity: 0.55
                    wrapMode: Text.WordWrap
                }
                Rectangle {
                    visible: columnDialog.appsExpanded && columnDialog.appsList.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(
                        columnDialog.appsList.length * (Kirigami.Units.gridUnit * 2.2),
                        Kirigami.Units.gridUnit * 14)
                    color: Kirigami.Theme.alternateBackgroundColor
                    radius: Kirigami.Units.cornerRadius
                    border.width: 1
                    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                    clip: true
                    ListView {
                        id: columnAppsList
                        anchors.fill: parent
                        anchors.margins: 1
                        anchors.rightMargin: Kirigami.Units.gridUnit * 0.85
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 0
                        model: columnDialog.appsExpanded ? columnDialog.appsList : []
                        delegate: RowLayout {
                            id: appRow
                            required property var modelData
                            width: ListView.view ? ListView.view.width : columnAppsList.width
                            height: Kirigami.Units.gridUnit * 2.2
                            spacing: Kirigami.Units.smallSpacing
                            Kirigami.Icon {
                                source: (appRow.modelData && appRow.modelData.icon)
                                        ? appRow.modelData.icon : "application-x-executable"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: appRow.modelData
                                      ? (appRow.modelData.name || appRow.modelData.id) : ""
                            }
                            QQC2.Button {
                                visible: !!(appRow.modelData && appRow.modelData.extra)
                                icon.name: "list-remove"
                                flat: true
                                onClicked: {
                                    if (appRow.modelData)
                                        root.toggleGroupApp(columnDialog.groupId, appRow.modelData.id, false);
                                }
                            }
                        }
                        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                            parent: columnAppsList.parent
                            anchors.top: columnAppsList.top
                            anchors.bottom: columnAppsList.bottom
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            policy: QQC2.ScrollBar.AlwaysOn
                            implicitWidth: Kirigami.Units.gridUnit * 0.7
                        }
                        QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                            policy: QQC2.ScrollBar.AlwaysOff
                        }
                    }
                }
                ConfigSettingRow {
                    title: root.tr("Add applications")
                    subtitle: root.tr("Choose which applications appear in this column")
                    iconName: "list-add"
                    accent: "green"
                    QQC2.Button {
                        text: root.tr("Add applications")
                        icon.name: "list-add"
                        onClicked: {
                            manageDialog.groupId = columnDialog.groupId;
                            manageFilter.text = "";
                            manageDialog.open();
                        }
                    }
                }
            }
            ColumnLayout {
                visible: columnDialog.isFrequent
                Layout.fillWidth: true
                spacing: 0
                ConfigSep {}
                ConfigSettingRow {
                    title: root.tr("Enable recent applications section")
                    iconName: "view-history"
                    accent: "indigo"
                    QQC2.Switch {
                        checked: root.cfg_Enabled
                        onToggled: {
                            root.cfg_Enabled = checked;
                            root.writeLive("Enabled", checked);
                        }
                    }
                }
                ConfigSep {}
                ConfigSettingRow {
                    title: root.tr("Maximum recent items:")
                    iconName: "view-list-details"
                    accent: "cyan"
                    opacity: root.cfg_Enabled ? 1 : 0.45
                    QQC2.SpinBox {
                        from: 1
                        to: 20
                        value: root.cfg_MaxItems
                        enabled: root.cfg_Enabled
                        onValueModified: {
                            root.cfg_MaxItems = value;
                            root.writeLive("MaxItems", value);
                        }
                    }
                }
                ConfigSep {}
                ConfigSettingRow {
                    title: root.tr("Clear recent applications")
                    iconName: "edit-clear-history"
                    accent: "red"
                    QQC2.Button {
                        text: root.tr("Clear recent applications")
                        icon.name: "edit-clear-history"
                        onClicked: {
                            cfg_RecentApps = [];
                            root.writeLive("RecentApps", []);
                        }
                    }
                }
            }
        }
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
        title: root.tr("Add applications")
        modal: true
        dim: true
        standardButtons: QQC2.Dialog.Close
        width: Math.min((parent ? parent.width : Kirigami.Units.gridUnit * 28) * 0.92, Kirigami.Units.gridUnit * 28)
        padding: Kirigami.Units.largeSpacing
        anchors.centerIn: parent
        clip: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            radius: Kirigami.Units.cornerRadius
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.18)
        }
        contentItem: Rectangle {
            color: Kirigami.Theme.backgroundColor
            implicitWidth: Kirigami.Units.gridUnit * 26
            implicitHeight: Kirigami.Units.gridUnit * 22
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                QQC2.TextField {
                    id: manageFilter
                    Layout.fillWidth: true
                    placeholderText: root.tr("Search…")
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 18
                    Layout.minimumHeight: Kirigami.Units.gridUnit * 12
                    color: Kirigami.Theme.alternateBackgroundColor
                    radius: Kirigami.Units.cornerRadius
                    border.width: 1
                    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                    clip: true
                    ListView {
                        id: manageList
                        anchors.fill: parent
                        anchors.margins: 1
                        anchors.rightMargin: Kirigami.Units.gridUnit * 0.85
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: {
                            var _apps = root.localApps;
                            return root.filteredPickerApps(manageFilter.text);
                        }
                        delegate: QQC2.CheckDelegate {
                            required property var modelData
                            width: manageList.width
                            text: modelData.name
                            icon.name: modelData.icon || "application-x-executable"
                            checked: root.groupContains(manageDialog.groupId, modelData.id)
                            onToggled: root.toggleGroupApp(manageDialog.groupId, modelData.id, checked)
                        }
                        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                            parent: manageList.parent
                            anchors.top: manageList.top
                            anchors.bottom: manageList.bottom
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            policy: QQC2.ScrollBar.AlwaysOn
                            implicitWidth: Kirigami.Units.gridUnit * 0.7
                        }
                        QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                            policy: QQC2.ScrollBar.AlwaysOff
                        }
                    }
                    QQC2.Label {
                        anchors.centerIn: parent
                        visible: manageList.count === 0
                        opacity: 0.55
                        text: root.localApps.length
                              ? root.tr("No applications")
                              : root.tr("Loading applications…")
                    }
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
        if (root.groupCreationPending) { root.scheduleGroupModelsRebuild(); return; }
        if (listModel.count === 0)
            rebuildModel();
    }
    onCfg_ExtraCategoriesEnabledChanged: {
        if (root.groupCreationPending) { root.scheduleGroupModelsRebuild(); return; }
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
    onCfg_ExtraCategoriesUserSetChanged: {
        if (root.groupCreationPending) root.scheduleGroupModelsRebuild();
        else rebuildModel();
    }
    onCfg_SidebarOrderChanged: {
        if (sidebarListModel.count === 0)
            rebuildSidebarModel();
    }
    onCfg_SidebarHiddenChanged: {
        if (sidebarListModel.count === 0)
            rebuildSidebarModel();
    }
    onCfg_CustomQuickLinksChanged: {
        root.scheduleGroupModelsRebuild();
    }
    onCfg_CustomTypeGroupsChanged: root.scheduleGroupModelsRebuild()
    onCfg_OrderChanged: {
        if (typeListModel.count === 0)
            rebuildTypeModel();
    }
    onCfg_HiddenChanged: {
        if (typeListModel.count === 0)
            rebuildTypeModel();
    }
}
