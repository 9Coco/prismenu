import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale

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
        var byId = {};
        for (var i = 0; i < quickLinkDefs.length; ++i)
            byId[quickLinkDefs[i].id] = quickLinkDefs[i];
        var out = [];
        for (var o = 0; o < order.length; ++o) {
            if (byId[order[o]])
                out.push(byId[order[o]]);
        }
        for (var k = 0; k < quickLinkDefs.length; ++k) {
            if (order.indexOf(quickLinkDefs[k].id) < 0)
                out.push(quickLinkDefs[k]);
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
                    }
                    ConfigSep { visible: qwrap.index < root.orderedQuickLinks.length - 1 }
                }
            }
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
