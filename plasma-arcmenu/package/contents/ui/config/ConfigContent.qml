import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/AppsModel.js" as AppsModel
import "../../code/Locale.js" as Locale

Item {
    id: root

    property var cfg_Order: []
    property var cfg_Hidden: []
    property string cfg_CustomNames
    property string cfg_CustomIcons
    property alias cfg_ShowEmpty: showEmpty.checked
    property var cfg_PinnedApps: []
    property alias cfg_PinnedCols: pinnedColsSpin.value
    // Compatibility key: favorites are now always synchronized with Plasma.
    property bool cfg_SyncWithPlasma: true
    property alias cfg_Enabled: recentEnabled.checked
    property alias cfg_MaxItems: recentMaxSpin.value
    property var cfg_RecentApps: []

    property var categories: AppsModel.defaultCategories()
    property var customNamesMap: AppsModel.parseJsonMap(cfg_CustomNames)
    property var customIconsMap: AppsModel.parseJsonMap(cfg_CustomIcons)

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    readonly property var orderedCategories: {
        var order = (cfg_Order && cfg_Order.length)
            ? cfg_Order
            : categories.map(function (c) { return c.id; });
        var byId = {};
        for (var i = 0; i < categories.length; ++i)
            byId[categories[i].id] = categories[i];
        var out = [];
        for (var o = 0; o < order.length; ++o) {
            if (byId[order[o]])
                out.push(byId[order[o]]);
        }
        for (var k = 0; k < categories.length; ++k) {
            if (order.indexOf(categories[k].id) < 0)
                out.push(categories[k]);
        }
        return out;
    }

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function trf(msgid, arg1) {
        return Locale.trf(msgid, uiLang, arg1);
    }

    // Live apply: every cfg_* write must also land in plasmoid.configuration,
    // otherwise Plasma's cfg-vs-config diff flags the page as "unsaved".
    function writeLive(key, value) { try { plasmoid.configuration[key] = value; } catch (e) {} }

    function isHidden(id) {
        return (cfg_Hidden || []).indexOf(id) >= 0;
    }

    function toggleHidden(id, hide) {
        var list = (cfg_Hidden || []).slice();
        var idx = list.indexOf(id);
        if (hide && idx < 0)
            list.push(id);
        if (!hide && idx >= 0)
            list.splice(idx, 1);
        cfg_Hidden = list;
        writeLive("Hidden", list);
    }

    function moveCategory(from, to) {
        var order = (cfg_Order && cfg_Order.length)
            ? cfg_Order.slice()
            : categories.map(function (c) { return c.id; });
        if (from < 0 || to < 0 || from >= order.length || to >= order.length)
            return;
        var item = order.splice(from, 1)[0];
        order.splice(to, 0, item);
        cfg_Order = order;
        writeLive("Order", order);
    }

    function displayName(cat) {
        if (customNamesMap[cat.id])
            return customNamesMap[cat.id];
        return Locale.tr(cat.name, uiLang);
    }

    ConfigPage {
        title: root.tr("Categories")
        tip: root.tr("Category order, visibility, and recent apps")

        ConfigGroup {
            title: root.tr("Categories")
            ConfigSettingRow {
                title: root.tr("Show empty categories")
                iconName: "view-list-details"
                accent: "blue"
                QQC2.Switch {
                    id: showEmpty
                    onToggled: root.writeLive("ShowEmpty", checked)
                }
            }
            ConfigSep {}
            Repeater {
                model: root.orderedCategories
                ColumnLayout {
                    id: catWrap
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: root.displayName(modelData)
                        iconName: root.customIconsMap[modelData.id] || modelData.icon
                        accent: index % 2 === 0 ? "purple" : "teal"
                        QQC2.CheckBox {
                            checked: !root.isHidden(modelData.id)
                            onToggled: root.toggleHidden(modelData.id, !checked)
                            QQC2.ToolTip.text: root.tr("Show category")
                            QQC2.ToolTip.visible: hovered
                        }
                        QQC2.TextField {
                            id: nameField
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                            text: root.displayName(modelData)
                            onEditingFinished: {
                                var map = Object.assign({}, root.customNamesMap);
                                map[modelData.id] = text;
                                root.customNamesMap = map;
                                cfg_CustomNames = AppsModel.stringifyJsonMap(map);
                                root.writeLive("CustomNames", cfg_CustomNames);
                            }
                        }
                        QQC2.TextField {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            placeholderText: root.tr("Icon name")
                            text: root.customIconsMap[modelData.id] || ""
                            onEditingFinished: {
                                var map = Object.assign({}, root.customIconsMap);
                                if (text)
                                    map[modelData.id] = text;
                                else
                                    delete map[modelData.id];
                                root.customIconsMap = map;
                                cfg_CustomIcons = AppsModel.stringifyJsonMap(map);
                                root.writeLive("CustomIcons", cfg_CustomIcons);
                            }
                        }
                        QQC2.Button {
                            icon.name: "go-up"
                            flat: true
                            enabled: index > 0
                            onClicked: root.moveCategory(index, index - 1)
                        }
                        QQC2.Button {
                            icon.name: "go-down"
                            flat: true
                            enabled: index < root.orderedCategories.length - 1
                            onClicked: root.moveCategory(index, index + 1)
                        }
                    }
                    ConfigSep { visible: index < root.orderedCategories.length - 1 }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Pinned Applications")
            ConfigSettingRow {
                title: root.tr("Pinned columns:")
                subtitle: root.tr("Sync favorites with Plasma global favorites")
                iconName: "view-grid"
                accent: "orange"
                QQC2.SpinBox {
                    id: pinnedColsSpin
                    from: 4
                    to: 8
                    onValueModified: root.writeLive("PinnedCols", value)
                }
            }
        }

        ConfigGroup {
            title: root.tr("Recent applications")
            ConfigSettingRow {
                title: root.tr("Enable recent applications section")
                iconName: "view-history"
                accent: "indigo"
                QQC2.Switch {
                    id: recentEnabled
                    onToggled: root.writeLive("Enabled", checked)
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Maximum recent items:")
                iconName: "view-list-details"
                accent: "cyan"
                opacity: recentEnabled.checked ? 1 : 0.45
                QQC2.SpinBox {
                    id: recentMaxSpin
                    from: 1
                    to: 20
                    enabled: recentEnabled.checked
                    onValueModified: root.writeLive("MaxItems", value)
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
