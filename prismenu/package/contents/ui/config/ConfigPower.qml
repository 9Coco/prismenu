import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC

/**
 * Power Options — reorderable toggles + display style.
 */
Item {
    id: root

    property var cfg_Options: []
    property var cfg_PowerOptionsOrder: []
    property alias cfg_Confirm: confirmSwitch.checked
    property alias cfg_SoftwareCenterCmd: softwareCmd.text
    property string cfg_PowerDisplayStyle

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }
    function writeLive(key, value) { try { plasmoid.configuration[key] = value; } catch (e) {} }

    readonly property var ordered: {
        var order = SC.normalizeList(cfg_PowerOptionsOrder, SC.DEFAULT_POWER_ORDER);
        var defs = SC.powerDefs(root.tr);
        var byId = {};
        for (var i = 0; i < defs.length; ++i) byId[defs[i].id] = defs[i];
        var out = [];
        for (var o = 0; o < order.length; ++o) {
            if (byId[order[o]]) out.push(byId[order[o]]);
        }
        for (var k = 0; k < defs.length; ++k) {
            if (order.indexOf(defs[k].id) < 0) out.push(defs[k]);
        }
        return out;
    }

    function isOn(id) {
        return SC.normalizeList(cfg_Options, ["logout", "lock", "restart", "shutdown"]).indexOf(id) >= 0;
    }

    function setOn(id, on) {
        var list = SC.normalizeList(cfg_Options, ["logout", "lock", "restart", "shutdown"]);
        var idx = list.indexOf(id);
        if (on && idx < 0) list.push(id);
        if (!on && idx >= 0) list.splice(idx, 1);
        var order = ordered.map(function (d) { return d.id; });
        var sorted = [];
        for (var i = 0; i < order.length; ++i) {
            if (list.indexOf(order[i]) >= 0) sorted.push(order[i]);
        }
        cfg_Options = sorted;
        writeLive("Options", sorted);
    }

    function move(from, to) {
        var order = ordered.map(function (d) { return d.id; });
        order = SC.moveItem(order, from, to);
        cfg_PowerOptionsOrder = order;
        writeLive("PowerOptionsOrder", order);
        var enabled = SC.normalizeList(cfg_Options, []);
        var sorted = [];
        for (var i = 0; i < order.length; ++i) {
            if (enabled.indexOf(order[i]) >= 0) sorted.push(order[i]);
        }
        cfg_Options = sorted;
        writeLive("Options", sorted);
    }

    ConfigPage {
        title: root.tr("Power Options")
        tip: root.tr("If unavailable on your system, the action will be hidden from Prismenu.")

        ConfigGroup {
            title: root.tr("Power Options")
            Repeater {
                model: root.ordered
                ColumnLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 0
                    ConfigSettingRow {
                        title: modelData.name
                        iconName: modelData.icon
                        accent: index % 2 === 0 ? "blue" : "purple"
                        Kirigami.Icon {
                            source: "transform-move"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.4
                        }
                        QQC2.Switch {
                            checked: root.isOn(modelData.id)
                            onToggled: root.setOn(modelData.id, checked)
                        }
                        QQC2.Button {
                            icon.name: "go-up"
                            flat: true
                            enabled: index > 0
                            onClicked: root.move(index, index - 1)
                        }
                        QQC2.Button {
                            icon.name: "go-down"
                            flat: true
                            enabled: index < root.ordered.length - 1
                            onClicked: root.move(index, index + 1)
                        }
                    }
                    ConfigSep { visible: index < root.ordered.length - 1 }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Display Style")
            ConfigSettingRow {
                title: root.tr("Override Display Style")
                iconName: "view-list-icons"
                accent: "teal"
                QQC2.ComboBox {
                    model: [root.tr("Off"), root.tr("Buttons"), root.tr("List")]
                    property var keys: ["off", "buttons", "list"]
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    Component.onCompleted: {
                        var i = keys.indexOf(cfg_PowerDisplayStyle || "off");
                        currentIndex = i >= 0 ? i : 0;
                    }
                    onActivated: {
                        cfg_PowerDisplayStyle = keys[currentIndex];
                        writeLive("PowerDisplayStyle", cfg_PowerDisplayStyle);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Confirm shut down / restart / log out")
                iconName: "dialog-warning"
                accent: "orange"
                QQC2.Switch {
                    id: confirmSwitch
                    onToggled: root.writeLive("Confirm", checked)
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Software center command:")
                subtitle: "auto-detect"
                iconName: "applications-other"
                accent: "green"
                QQC2.TextField {
                    id: softwareCmd
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                    placeholderText: "auto-detect"
                    onEditingFinished: root.writeLive("SoftwareCenterCmd", text)
                }
            }
        }
    }

    Component.onCompleted: {
        if (!cfg_PowerOptionsOrder || !cfg_PowerOptionsOrder.length)
            cfg_PowerOptionsOrder = SC.DEFAULT_POWER_ORDER.slice();
        if (!cfg_Options || !cfg_Options.length)
            cfg_Options = ["logout", "lock", "restart", "shutdown"];
        if (!cfg_PowerDisplayStyle)
            cfg_PowerDisplayStyle = "off";
    }
}
