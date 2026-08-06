import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

/**
 * Functional module: session / power icon row (logout, lock, restart, shutdown).
 */
RowLayout {
    id: root

    property var enabledOptions: ["logout", "lock", "restart", "shutdown"]

    signal actionRequested(string actionId)

    spacing: Kirigami.Units.smallSpacing
    Layout.alignment: Qt.AlignVCenter

    readonly property var buttonDefs: [
        { id: "logout", icon: "system-log-out", tip: i18n("Log Out") },
        { id: "lock", icon: "system-lock-screen", tip: i18n("Lock Screen") },
        { id: "restart", icon: "system-reboot", tip: i18n("Restart") },
        { id: "shutdown", icon: "system-shutdown", tip: i18n("Shut Down") }
    ]

    function isOn(id) {
        var opts = root.enabledOptions || [];
        if (typeof opts === "string") {
            return ("," + opts + ",").indexOf("," + id + ",") >= 0 || opts.split(",").indexOf(id) >= 0;
        }
        // Always show the four session buttons if options missing the id but list is odd;
        // still honor explicit disable when list is a normal array without the id.
        return opts.indexOf(id) >= 0;
    }

    Repeater {
        model: root.buttonDefs.length
        PlasmaComponents.ToolButton {
            required property int index
            readonly property var def: root.buttonDefs[index]
            visible: root.isOn(def.id)
            flat: true
            icon.name: def.icon
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Accessible.name: def.tip
            onClicked: root.actionRequested(def.id)
            PlasmaComponents.ToolTip.text: def.tip
            PlasmaComponents.ToolTip.visible: hovered
            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
