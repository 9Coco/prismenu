import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC

/**
 * Functional module: session / power icon row (ordered from Power Options).
 */
RowLayout {
    id: root

    property var enabledOptions: ["logout", "lock", "restart", "shutdown"]
    property var menuData: null
    property int iconSize: 0

    signal actionRequested(string actionId)

    spacing: Kirigami.Units.smallSpacing
    Layout.alignment: Qt.AlignVCenter

    readonly property int resolvedIcon: iconSize > 0 ? iconSize
        : (menuData && menuData.buttonIconSize ? menuData.buttonIconSize
           : Kirigami.Units.iconSizes.smallMedium)

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    readonly property var buttonDefs: {
        var _ = root.uiLang;
        var defs = SC.powerDefs(root.t);
        var order = (menuData && menuData.powerOptionsOrder && menuData.powerOptionsOrder.length)
            ? menuData.powerOptionsOrder
            : SC.DEFAULT_POWER_ORDER;
        var byId = {};
        for (var i = 0; i < defs.length; ++i)
            byId[defs[i].id] = defs[i];
        var out = [];
        for (var o = 0; o < order.length; ++o) {
            var d = byId[order[o]];
            if (!d)
                continue;
            out.push({ id: d.id, icon: d.icon, tip: d.name });
        }
        return out;
    }

    function isOn(id) {
        var opts = root.enabledOptions || [];
        if (typeof opts === "string") {
            return ("," + opts + ",").indexOf("," + id + ",") >= 0 || opts.split(",").indexOf(id) >= 0;
        }
        return opts.indexOf(id) >= 0;
    }

    Repeater {
        model: root.buttonDefs
        PlasmaComponents.ToolButton {
            required property var modelData
            visible: root.isOn(modelData.id)
            icon.name: modelData.icon
            icon.width: root.resolvedIcon
            icon.height: root.resolvedIcon
            Accessible.name: modelData.tip
            onClicked: root.actionRequested(modelData.id)
            PlasmaComponents.ToolTip.text: modelData.tip
            PlasmaComponents.ToolTip.visible: hovered
                && (!root.menuData || root.menuData.showTooltips !== false)
            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
