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
    property alias cfg_Confirm: confirmBox.checked
    property alias cfg_SoftwareCenterCmd: softwareCmd.text
    property string cfg_PowerDisplayStyle

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
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
        // Keep Options in PowerOptionsOrder sequence
        var order = ordered.map(function (d) { return d.id; });
        var sorted = [];
        for (var i = 0; i < order.length; ++i) {
            if (list.indexOf(order[i]) >= 0) sorted.push(order[i]);
        }
        cfg_Options = sorted;
        writeLive("options", sorted);
    }

    function move(from, to) {
        var order = ordered.map(function (d) { return d.id; });
        order = SC.moveItem(order, from, to);
        cfg_PowerOptionsOrder = order;
        writeLive("powerOptionsOrder", order);
        // Re-sort enabled options
        var enabled = SC.normalizeList(cfg_Options, []);
        var sorted = [];
        for (var i = 0; i < order.length; ++i) {
            if (enabled.indexOf(order[i]) >= 0) sorted.push(order[i]);
        }
        cfg_Options = sorted;
        writeLive("options", sorted);
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

            QQC2.Label { text: root.tr("Power Options"); font.bold: true }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.65
                text: root.tr("If unavailable on your system, the action will be hidden from ArcMenu.")
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
                        RowLayout {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Kirigami.Icon { source: "transform-move"; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small; opacity: 0.4 }
                            Kirigami.Icon { source: modelData.icon; Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium }
                            QQC2.Label { text: modelData.name; Layout.fillWidth: true }
                            QQC2.Switch {
                                checked: root.isOn(modelData.id)
                                onToggled: root.setOn(modelData.id, checked)
                            }
                            QQC2.Button { icon.name: "go-up"; flat: true; enabled: index > 0; onClicked: root.move(index, index - 1) }
                            QQC2.Button { icon.name: "go-down"; flat: true; enabled: index < root.ordered.length - 1; onClicked: root.move(index, index + 1) }
                        }
                    }
                }
            }

            QQC2.Label { text: root.tr("Display Style"); font.bold: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: styleCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: styleCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Override Display Style"); Layout.fillWidth: true }
                        QQC2.ComboBox {
                            model: [root.tr("Off"), root.tr("Buttons"), root.tr("List")]
                            property var keys: ["off", "buttons", "list"]
                            Component.onCompleted: {
                                var i = keys.indexOf(cfg_PowerDisplayStyle || "off");
                                currentIndex = i >= 0 ? i : 0;
                            }
                            onActivated: {
                                cfg_PowerDisplayStyle = keys[currentIndex];
                                writeLive("powerDisplayStyle", cfg_PowerDisplayStyle);
                            }
                        }
                    }
                }
            }

            Kirigami.FormLayout {
                Layout.fillWidth: true
                QQC2.CheckBox {
                    id: confirmBox
                    Kirigami.FormData.label: root.tr("Confirmation:")
                    text: root.tr("Confirm shut down / restart / log out")
                }
                QQC2.TextField {
                    id: softwareCmd
                    Kirigami.FormData.label: root.tr("Software center command:")
                    placeholderText: "auto-detect"
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
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
