import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/AppsModel.js" as AppsModel
import "../../code/Locale.js" as Locale
import "../components" as Components

Item {
    id: root

    property var cfg_Order: []
    property var cfg_Hidden: []
    property string cfg_CustomNames
    property string cfg_CustomIcons
    property alias cfg_ShowEmpty: showEmpty.checked
    property var cfg_PinnedApps: []
    property alias cfg_PinnedCols: pinnedColsSpin.value
    property alias cfg_SyncWithPlasma: syncPlasma.checked
    property alias cfg_Enabled: recentEnabled.checked
    property alias cfg_MaxItems: recentMaxSpin.value
    property var cfg_RecentApps: []

    property var categories: AppsModel.defaultCategories()
    property var customNamesMap: AppsModel.parseJsonMap(cfg_CustomNames)
    property var customIconsMap: AppsModel.parseJsonMap(cfg_CustomIcons)

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
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
    }

    function displayName(cat) {
        if (customNamesMap[cat.id])
            return customNamesMap[cat.id];
        return Locale.tr(cat.name, uiLang);
    }

    QQC2.ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: scroll.availableWidth
            spacing: Kirigami.Units.largeSpacing

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.CheckBox {
                    id: showEmpty
                    Kirigami.FormData.label: root.tr("Categories")
                    text: root.tr("Show empty categories")
                }
            }

            // Category editor — Column of rows (ListView+RowLayout was collapsing to 0 height)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.orderedCategories

                    delegate: RowLayout {
                        id: catRow
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(Kirigami.Units.gridUnit * 2,
                                                         nameField.implicitHeight + Kirigami.Units.smallSpacing)
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.CheckBox {
                            checked: !root.isHidden(modelData.id)
                            onToggled: root.toggleHidden(modelData.id, !checked)
                            QQC2.ToolTip.text: root.tr("Show category")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        Components.ResolvedIcon {
                            iconName: root.customIconsMap[modelData.id] || modelData.icon
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }

                        QQC2.TextField {
                            id: nameField
                            Layout.fillWidth: true
                            Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                            text: root.displayName(modelData)
                            onEditingFinished: {
                                var map = Object.assign({}, root.customNamesMap);
                                map[modelData.id] = text;
                                root.customNamesMap = map;
                                cfg_CustomNames = AppsModel.stringifyJsonMap(map);
                            }
                        }

                        QQC2.TextField {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 7
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
                            }
                        }

                        QQC2.Button {
                            icon.name: "go-up"
                            enabled: index > 0
                            onClicked: root.moveCategory(index, index - 1)
                            Accessible.name: root.tr("Move up")
                        }

                        QQC2.Button {
                            icon.name: "go-down"
                            enabled: index < root.orderedCategories.length - 1
                            onClicked: root.moveCategory(index, index + 1)
                            Accessible.name: root.tr("Move down")
                        }
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.SpinBox {
                    id: pinnedColsSpin
                    from: 4
                    to: 8
                    Kirigami.FormData.label: root.tr("Pinned columns:")
                }

                QQC2.CheckBox {
                    id: syncPlasma
                    Kirigami.FormData.label: root.tr("Favorites")
                    text: root.tr("Sync favorites with Plasma global favorites")
                }

                QQC2.Label {
                    text: root.trf("Pinned apps: %1", (cfg_PinnedApps || []).length)
                    opacity: 0.8
                }

                QQC2.CheckBox {
                    id: recentEnabled
                    Kirigami.FormData.label: root.tr("Recent applications")
                    text: root.tr("Enable recent applications section")
                }

                QQC2.SpinBox {
                    id: recentMaxSpin
                    from: 1
                    to: 20
                    enabled: recentEnabled.checked
                    Kirigami.FormData.label: root.tr("Maximum recent items:")
                }

                QQC2.Button {
                    text: root.tr("Clear recent applications")
                    icon.name: "edit-clear-history"
                    onClicked: cfg_RecentApps = []
                }
            }
        }
    }
}
