import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/CatalogBridge.js" as CatalogBridge
import "../../code/PresetIcons.js" as PresetIcons
import ".." as Ui

/**
 * ArcMenu Layout Adjustment — avatar, search, flip, shortcuts, category quick links.
 */
Item {
    id: root

    property string cfg_AllAppsButtonAction
    property bool cfg_ShowUserAvatar
    property string cfg_AvatarShape
    property string cfg_SearchbarLocation
    property bool cfg_FlipHorizontal
    property bool cfg_ShowVerticalSeparator
    property bool cfg_ShowExternalDevices
    property bool cfg_ShowBookmarks
    property var cfg_QuickLinksOrder: []
    property var cfg_QuickLinksEnabled: []
    property string cfg_QuickLinkPosition
    property var cfg_CustomQuickLinks: []
    property string cfg_CustomGroupApps: "{}"

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }
    function writeLive(key, value) {
        try {
            plasmoid.configuration[key] = value;
            console.log("ArcMenu writeLive", key, "->", JSON.stringify(value));
        } catch (e) {
            console.log("ArcMenu writeLive FAILED", key, e);
        }
    }
    
    // ---- App catalog for the group management dialogs (same source as ConfigPinned) ----
    property var localApps: []
    Ui.AppsBackend {
        id: grpBackend
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
    
    // ---- Custom quick link groups ----
    readonly property var customLinkDefs: {
        var raw = cfg_CustomQuickLinks || [];
        if (typeof raw === "string")
            raw = raw.length ? raw.split(",") : [];
        var out = [];
        for (var i = 0; i < raw.length; ++i) {
            var parts = String(raw[i] || "").split("|");
            if (!parts[0])
                continue;
            out.push({ id: parts[0], name: parts[1] || parts[0], icon: parts[2] || "folder-favorites" });
        }
        return out;
    }
    
    function customGroupMap() {
        // Read the LIVE config, not the frozen cfg_CustomGroupApps mirror:
        // the menu right-click "Add to <group>" writes live while this page is
        // open, and writing the stale mirror back would silently drop them.
        try {
            var obj = JSON.parse(String(plasmoid.configuration.customGroupApps || "{}"));
            return (obj && typeof obj === "object") ? obj : {};
        } catch (e) {
            return {};
        }
    }
    
    function groupContains(gid, appId) {
        var ids = customGroupMap()[gid];
        return Array.isArray(ids) && ids.indexOf(appId) >= 0;
    }
    
    function writeCustomLinks(list) {
        cfg_CustomQuickLinks = list;
        writeLive("customQuickLinks", list);
    }
    
    function writeCustomGroupApps(map) {
        var s = JSON.stringify(map);
        cfg_CustomGroupApps = s;
        writeLive("customGroupApps", s);
    }
    
    /** Resolve a group icon id to a renderable source (theme name, bundled
     *  preset SVG, or absolute image path). */
    function groupIconSource(g) {
        g = g || "folder-favorites";
        if (PresetIcons.isPreset(g))
            return Qt.resolvedUrl("../../icons/menu-button/" + g + ".svg");
        if (String(g).indexOf("/") === 0)
            return "file://" + g;
        return g;
    }

    function createGroup(name, icon) {
        name = String(name || "").replace(/[|,]/g, " ").trim();
        if (!name)
            return;
        icon = String(icon || "folder-favorites").replace(/[|,]/g, "-").trim() || "folder-favorites";
        var gid = "qgrp-" + Math.random().toString(36).slice(2, 10);
        var list = (cfg_CustomQuickLinks || []).slice();
        if (typeof list === "string")
            list = list.length ? list.split(",") : [];
        list.push(gid + "|" + name + "|" + icon);
        writeCustomLinks(list);
        // New groups start enabled and ordered last
        var enabled = (cfg_QuickLinksEnabled || []).slice();
        if (enabled.indexOf(gid) < 0)
            enabled.push(gid);
        cfg_QuickLinksEnabled = enabled;
        writeLive("quickLinksEnabled", enabled);
        var order = (cfg_QuickLinksOrder || []).slice();
        if (order.indexOf(gid) < 0)
            order.push(gid);
        cfg_QuickLinksOrder = order;
        writeLive("quickLinksOrder", order);
    }
    
    function deleteGroup(gid) {
        var list = ((cfg_CustomQuickLinks || []).slice()).filter(function (s) {
            return String(s).split("|")[0] !== gid;
        });
        writeCustomLinks(list);
        var map = customGroupMap();
        delete map[gid];
        writeCustomGroupApps(map);
        var enabled = (cfg_QuickLinksEnabled || []).slice().filter(function (x) { return x !== gid; });
        cfg_QuickLinksEnabled = enabled;
        writeLive("quickLinksEnabled", enabled);
        var order = (cfg_QuickLinksOrder || []).slice().filter(function (x) { return x !== gid; });
        cfg_QuickLinksOrder = order;
        writeLive("quickLinksOrder", order);
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
        writeCustomGroupApps(map);
    }

    readonly property var defaultQuickOrder: ["favorites", "frequent", "pinned", "recent-files"]

    readonly property var quickLinkDefs: [
        { id: "favorites", name: root.tr("Favorites"), icon: "bookmarks" },
        { id: "frequent", name: root.tr("Frequent Apps"), icon: "view-calendar" },
        // Retired: the sidebar AllAppsButton already navigates to the all-apps view,
        // so a duplicate quick link only confused the menu (removed 2026-08).
        { id: "pinned", name: root.tr("Pinned Applications"), icon: "pin" },
        { id: "recent-files", name: root.tr("Recent Files"), icon: "document-open-recent" }
    ]

    readonly property var orderedQuickLinks: {
        var order = (cfg_QuickLinksOrder && cfg_QuickLinksOrder.length)
            ? cfg_QuickLinksOrder : defaultQuickOrder;
        var all = quickLinkDefs.concat(root.customLinkDefs);
        var byId = {};
        for (var i = 0; i < all.length; ++i)
            byId[all[i].id] = all[i];
        var out = [];
        for (var o = 0; o < order.length; ++o) {
            if (byId[order[o]])
                out.push(byId[order[o]]);
        }
        for (var k = 0; k < all.length; ++k) {
            if (order.indexOf(all[k].id) < 0)
                out.push(all[k]);
        }
        return out;
    }

    function isQuickEnabled(id) {
        return (cfg_QuickLinksEnabled || []).indexOf(id) >= 0;
    }

    function setQuickEnabled(id, on) {
        var list = (cfg_QuickLinksEnabled || []).slice();
        var idx = list.indexOf(id);
        if (on && idx < 0)
            list.push(id);
        if (!on && idx >= 0)
            list.splice(idx, 1);
        cfg_QuickLinksEnabled = list;
        console.log("ArcMenu setQuickEnabled", id, on, "list:", JSON.stringify(list));
        writeLive("quickLinksEnabled", list);
    }

    function moveQuick(from, to) {
        var order = orderedQuickLinks.map(function (q) { return q.id; });
        if (from < 0 || to < 0 || from >= order.length || to >= order.length)
            return;
        var item = order.splice(from, 1)[0];
        order.splice(to, 0, item);
        cfg_QuickLinksOrder = order;
        writeLive("quickLinksOrder", order);
    }

    ConfigPage {
        title: root.tr("ArcMenu layout adjustment")
        tip: root.tr("Settings specific to the current menu layout")

        ConfigGroup {
            title: root.tr("Layout")
            ConfigSettingRow {
                title: root.tr("“All Applications” button action")
                iconName: "view-app-grid-symbolic"
                accent: "blue"
                QQC2.ComboBox {
                    model: [root.tr("Category list"), root.tr("All applications")]
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    Component.onCompleted: currentIndex = cfg_AllAppsButtonAction === "all-apps" ? 1 : 0
                    onActivated: {
                        cfg_AllAppsButtonAction = currentIndex === 1 ? "all-apps" : "category-list";
                        writeLive("allAppsButtonAction", cfg_AllAppsButtonAction);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Show user avatar")
                iconName: "user-identity"
                accent: "purple"
                QQC2.Switch {
                    checked: cfg_ShowUserAvatar
                    onToggled: { cfg_ShowUserAvatar = checked; writeLive("showUserAvatar", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Avatar shape")
                iconName: "draw-circle"
                accent: "teal"
                QQC2.ComboBox {
                    model: [root.tr("Circle"), root.tr("Square"), root.tr("Rounded square")]
                    property var keys: ["circle", "square", "rounded"]
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    Component.onCompleted: {
                        var i = keys.indexOf(cfg_AvatarShape || "circle");
                        currentIndex = i >= 0 ? i : 0;
                    }
                    onActivated: {
                        cfg_AvatarShape = keys[currentIndex];
                        writeLive("avatarShape", cfg_AvatarShape);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Search bar location")
                iconName: "edit-find"
                accent: "orange"
                QQC2.ComboBox {
                    model: [root.tr("Top"), root.tr("Bottom")]
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    Component.onCompleted: currentIndex = cfg_SearchbarLocation === "bottom" ? 1 : 0
                    onActivated: {
                        cfg_SearchbarLocation = currentIndex === 1 ? "bottom" : "top";
                        writeLive("searchbarLocation", cfg_SearchbarLocation);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Flip layout horizontally")
                iconName: "object-flip-horizontal"
                accent: "green"
                QQC2.Switch {
                    checked: cfg_FlipHorizontal
                    onToggled: { cfg_FlipHorizontal = checked; writeLive("flipHorizontal", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Vertical separator")
                iconName: "view-split-left-right"
                accent: "cyan"
                QQC2.Switch {
                    checked: cfg_ShowVerticalSeparator
                    onToggled: { cfg_ShowVerticalSeparator = checked; writeLive("showVerticalSeparator", checked); }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Extra shortcuts")
            ConfigSettingRow {
                title: root.tr("External devices")
                iconName: "drive-removable-media"
                accent: "indigo"
                QQC2.Switch {
                    checked: cfg_ShowExternalDevices
                    onToggled: { cfg_ShowExternalDevices = checked; writeLive("showExternalDevices", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Bookmarks")
                iconName: "bookmarks"
                accent: "pink"
                QQC2.Switch {
                    checked: cfg_ShowBookmarks
                    onToggled: { cfg_ShowBookmarks = checked; writeLive("showBookmarks", checked); }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Category quick links")
            ConfigSettingRow {
                title: root.tr("Quick link position")
                subtitle: root.tr("Display a category on the default menu view.")
                iconName: "go-up"
                accent: "yellow"
                QQC2.ComboBox {
                    model: [root.tr("Top"), root.tr("Bottom")]
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    Component.onCompleted: currentIndex = cfg_QuickLinkPosition === "top" ? 0 : 1
                    onActivated: {
                        cfg_QuickLinkPosition = currentIndex === 0 ? "top" : "bottom";
                        writeLive("quickLinkPosition", cfg_QuickLinkPosition);
                    }
                }
            }
            ConfigSep {}
            Repeater {
                model: root.orderedQuickLinks
                ColumnLayout {
                    id: qwrap
                    required property var modelData
                    required property int index
                    readonly property string linkId: modelData && modelData.id ? String(modelData.id) : ""
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: modelData.name
                        iconName: modelData.icon
                        accent: index % 2 === 0 ? "blue" : "teal"
                        Kirigami.Icon {
                            source: "transform-move"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.45
                        }
                        QQC2.Switch {
                            checked: root.isQuickEnabled(qwrap.linkId)
                            onToggled: root.setQuickEnabled(qwrap.linkId, checked)
                        }
                        QQC2.Button {
                            icon.name: "go-up"
                            flat: true
                            enabled: qwrap.index > 0
                            onClicked: root.moveQuick(qwrap.index, qwrap.index - 1)
                        }
                        QQC2.Button {
                            icon.name: "go-down"
                            flat: true
                            enabled: qwrap.index < root.orderedQuickLinks.length - 1
                            onClicked: root.moveQuick(qwrap.index, qwrap.index + 1)
                        }
                        QQC2.Button {
                            visible: qwrap.linkId.indexOf("qgrp-") === 0
                            icon.name: "document-edit"
                            flat: true
                            onClicked: {
                                manageDialog.groupId = qwrap.linkId;
                                manageFilter.text = "";
                                manageDialog.open();
                            }
                        }
                        QQC2.Button {
                            visible: qwrap.linkId.indexOf("qgrp-") === 0
                            icon.name: "list-remove"
                            flat: true
                            onClicked: {
                                deleteDialog.groupId = qwrap.linkId;
                                deleteDialog.open();
                            }
                        }
                    }
                    ConfigSep { visible: qwrap.index < root.orderedQuickLinks.length - 1 }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("New custom group…")
                subtitle: root.tr("Create your own quick link with a personal app collection")
                iconName: "list-add"
                accent: "green"
                QQC2.Button {
                    icon.name: "list-add"
                    flat: true
                    onClicked: {
                        groupNameField.text = "";
                        newGroupDialog.groupIcon = "folder-favorites";
                        newGroupDialog.open();
                    }
                }
            }
        }
    }
    
    QQC2.Dialog {
        id: newGroupDialog
        property string groupIcon: "folder-favorites"
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
                    implicitWidth: Kirigami.Units.gridUnit * 14
                    Kirigami.FormData.label: root.tr("Group name")
                }
                RowLayout {
                    Kirigami.FormData.label: root.tr("Group icon")
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        source: root.groupIconSource(newGroupDialog.groupIcon)
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

        onAccepted: root.createGroup(groupNameField.text, newGroupDialog.groupIcon)
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
            spacing: Kirigami.Units.smallSpacing
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
                    var apps = root.catalogApps || [];
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
            QQC2.Label {
                visible: manageList.count === 0
                text: root.tr("No applications")
                opacity: 0.55
                Layout.alignment: Qt.AlignHCenter
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
        // Migrate away legacy "all-apps" quick link (now served by AllAppsButton)
        if ((cfg_QuickLinksEnabled || []).indexOf("all-apps") >= 0) {
            var cleaned = (cfg_QuickLinksEnabled || []).filter(function (id) { return id !== "all-apps"; });
            cfg_QuickLinksEnabled = cleaned;
            writeLive("quickLinksEnabled", cleaned);
        }
        if (!cfg_QuickLinksOrder || !cfg_QuickLinksOrder.length)
            cfg_QuickLinksOrder = defaultQuickOrder.slice();
        if (!cfg_AllAppsButtonAction)
            cfg_AllAppsButtonAction = "category-list";
        if (!cfg_AvatarShape)
            cfg_AvatarShape = "circle";
        if (!cfg_SearchbarLocation)
            cfg_SearchbarLocation = "bottom";
        if (!cfg_QuickLinkPosition)
            cfg_QuickLinkPosition = "bottom";
    }
}
