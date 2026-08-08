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
    function writeLive(key, value) { try { plasmoid.configuration[key] = value; } catch (e) {} }

    readonly property var ordered: {
        var order = SC.normalizeList(cfg_ExtraCategoriesOrder, SC.DEFAULT_EXTRA_ORDER);
        var defs = SC.extraCategoryDefs(root.tr);
        var byId = {};
        for (var i = 0; i < defs.length; ++i)
            byId[defs[i].id] = defs[i];
        var out = [];
        for (var o = 0; o < order.length; ++o) {
            if (byId[order[o]])
                out.push(byId[order[o]]);
        }
        for (var k = 0; k < defs.length; ++k) {
            if (order.indexOf(defs[k].id) < 0)
                out.push(defs[k]);
        }
        return out;
    }

    function enabledIds() {
        // null/undefined → defaults; [] stays []
        if (cfg_ExtraCategoriesEnabled === undefined || cfg_ExtraCategoriesEnabled === null)
            return SC.DEFAULT_EXTRA_ON.slice();
        return SC.normalizeList(cfg_ExtraCategoriesEnabled, SC.DEFAULT_EXTRA_ON);
    }

    function isOn(id) {
        return enabledIds().indexOf(id) >= 0;
    }

    function setOn(id, on) {
        if (!id)
            return;
        var list = enabledIds().slice();
        var idx = list.indexOf(id);
        if (on && idx < 0)
            list.push(id);
        if (!on && idx >= 0)
            list.splice(idx, 1);
        // New array so Plasma cfg StringList + bindings refresh
        cfg_ExtraCategoriesEnabled = list.slice();
        writeLive("extraCategoriesEnabled", list.slice());
    }

    function move(from, to) {
        var order = ordered.map(function (q) { return q.id; });
        order = SC.moveItem(order, from, to);
        cfg_ExtraCategoriesOrder = order.slice();
        writeLive("extraCategoriesOrder", order.slice());
    }

    function resetDefaults() {
        cfg_ExtraCategoriesOrder = SC.DEFAULT_EXTRA_ORDER.slice();
        cfg_ExtraCategoriesEnabled = SC.DEFAULT_EXTRA_ON.slice();
        writeLive("extraCategoriesOrder", cfg_ExtraCategoriesOrder);
        writeLive("extraCategoriesEnabled", cfg_ExtraCategoriesEnabled);
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

            QQC2.Label { text: root.tr("Extra Categories"); font.bold: true }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.65
                text: root.tr("“All Applications” is already available from the apps page header.")
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
                        model: root.ordered

                        delegate: RowLayout {
                            id: row
                            required property var modelData
                            required property int index
                            // Capture id once — nested Switch must not rely on loose modelData lookup
                            readonly property string catId: modelData && modelData.id ? String(modelData.id) : ""
                            readonly property string catName: modelData && modelData.name ? String(modelData.name) : ""
                            readonly property string catIcon: modelData && modelData.icon ? String(modelData.icon) : "applications-other"

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
                                // Bind via row.catId so toggles never affect the wrong row
                                checked: root.isOn(row.catId)
                                onToggled: root.setOn(row.catId, checked)
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
                                enabled: row.index < root.ordered.length - 1
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
    }
}
