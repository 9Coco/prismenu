import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/Locale.js" as Locale

/**
 * Functional module: session / power icon row (logout, lock, restart, shutdown).
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
        return [
            { id: "logout", icon: "system-log-out", tip: root.t("Log Out") },
            { id: "lock", icon: "system-lock-screen", tip: root.t("Lock Screen") },
            { id: "restart", icon: "system-reboot", tip: root.t("Restart") },
            { id: "shutdown", icon: "system-shutdown", tip: root.t("Shut Down") }
        ];
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
            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
