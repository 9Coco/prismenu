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

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function writeLive(key, value) {
        try { plasmoid.configuration[key] = value; } catch (e) {}
    }

    readonly property var defaultQuickOrder: ["favorites", "frequent", "all-apps", "pinned", "recent-files"]

    readonly property var quickLinkDefs: [
        { id: "favorites", name: root.tr("Favorites"), icon: "bookmarks" },
        { id: "frequent", name: root.tr("Frequent Apps"), icon: "view-calendar" },
        { id: "all-apps", name: root.tr("All Applications"), icon: "view-app-grid-symbolic" },
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

    component ToggleRow: RowLayout {
        id: trow
        property string label: ""
        property bool checked: false
        signal toggled(bool on)
        Layout.fillWidth: true
        QQC2.Label { text: trow.label; Layout.fillWidth: true }
        QQC2.Switch {
            checked: trow.checked
            onToggled: trow.toggled(checked)
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: root.tr("ArcMenu layout adjustment")
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: mainCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            text: root.tr("“All Applications” button action")
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                        QQC2.ComboBox {
                            model: [root.tr("Category list"), root.tr("All applications")]
                            Component.onCompleted: currentIndex = cfg_AllAppsButtonAction === "all-apps" ? 1 : 0
                            onActivated: {
                                cfg_AllAppsButtonAction = currentIndex === 1 ? "all-apps" : "category-list";
                                writeLive("allAppsButtonAction", cfg_AllAppsButtonAction);
                            }
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    ToggleRow {
                        label: root.tr("Show user avatar")
                        checked: cfg_ShowUserAvatar
                        onToggled: (on) => { cfg_ShowUserAvatar = on; writeLive("showUserAvatar", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Avatar shape"); Layout.fillWidth: true }
                        QQC2.ComboBox {
                            model: [root.tr("Circle"), root.tr("Square"), root.tr("Rounded square")]
                            property var keys: ["circle", "square", "rounded"]
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
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Search bar location"); Layout.fillWidth: true }
                        QQC2.ComboBox {
                            model: [root.tr("Top"), root.tr("Bottom")]
                            Component.onCompleted: currentIndex = cfg_SearchbarLocation === "bottom" ? 1 : 0
                            onActivated: {
                                cfg_SearchbarLocation = currentIndex === 1 ? "bottom" : "top";
                                writeLive("searchbarLocation", cfg_SearchbarLocation);
                            }
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    ToggleRow {
                        label: root.tr("Flip layout horizontally")
                        checked: cfg_FlipHorizontal
                        onToggled: (on) => { cfg_FlipHorizontal = on; writeLive("flipHorizontal", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    ToggleRow {
                        label: root.tr("Vertical separator")
                        checked: cfg_ShowVerticalSeparator
                        onToggled: (on) => { cfg_ShowVerticalSeparator = on; writeLive("showVerticalSeparator", on); }
                    }
                }
            }

            QQC2.Label {
                text: root.tr("Extra shortcuts")
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: extraCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: extraCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    ToggleRow {
                        label: root.tr("External devices")
                        checked: cfg_ShowExternalDevices
                        onToggled: (on) => { cfg_ShowExternalDevices = on; writeLive("showExternalDevices", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Bookmarks")
                        checked: cfg_ShowBookmarks
                        onToggled: (on) => { cfg_ShowBookmarks = on; writeLive("showBookmarks", on); }
                    }
                }
            }

            QQC2.Label {
                text: root.tr("Category quick links")
                font.bold: true
            }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.65
                text: root.tr("Display a category on the default menu view.")
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: quickCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: quickCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: root.orderedQuickLinks
                        RowLayout {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "transform-move"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                opacity: 0.45
                            }
                            Kirigami.Icon {
                                source: modelData.icon
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            }
                            QQC2.Label {
                                text: modelData.name
                                Layout.fillWidth: true
                            }
                            QQC2.Switch {
                                checked: root.isQuickEnabled(modelData.id)
                                onToggled: root.setQuickEnabled(modelData.id, checked)
                            }
                            QQC2.Button {
                                icon.name: "go-up"
                                flat: true
                                enabled: index > 0
                                onClicked: root.moveQuick(index, index - 1)
                            }
                            QQC2.Button {
                                icon.name: "go-down"
                                flat: true
                                enabled: index < root.orderedQuickLinks.length - 1
                                onClicked: root.moveQuick(index, index + 1)
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    text: root.tr("Quick link position")
                    Layout.fillWidth: true
                }
                QQC2.ComboBox {
                    model: [root.tr("Top"), root.tr("Bottom")]
                    Component.onCompleted: currentIndex = cfg_QuickLinkPosition === "top" ? 0 : 1
                    onActivated: {
                        cfg_QuickLinkPosition = currentIndex === 0 ? "top" : "bottom";
                        writeLive("quickLinkPosition", cfg_QuickLinkPosition);
                    }
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
        }
    }

    Component.onCompleted: {
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
