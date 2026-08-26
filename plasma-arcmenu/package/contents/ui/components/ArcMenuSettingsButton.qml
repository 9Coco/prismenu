import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

/** Opens the applet configuration dialog from any layout chrome. */
PlasmaComponents.ToolButton {
    id: root

    required property var layoutRoot

    implicitWidth: Kirigami.Units.gridUnit * 2
    implicitHeight: Kirigami.Units.gridUnit * 2
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    Layout.fillHeight: false
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.maximumWidth: implicitWidth
    Layout.maximumHeight: implicitHeight
    icon.name: "preferences-system-windows"
    icon.width: Kirigami.Units.iconSizes.smallMedium
    icon.height: Kirigami.Units.iconSizes.smallMedium
    Accessible.name: root.labelText
    Accessible.role: Accessible.Button
    PlasmaComponents.ToolTip.text: root.labelText
    PlasmaComponents.ToolTip.visible: hovered
        && (!layoutRoot || !layoutRoot.menuData || layoutRoot.menuData.showTooltips !== false)
    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay

    readonly property string labelText: layoutRoot
        ? layoutRoot.tr("ArcMenu Settings")
        : "ArcMenu Settings"

    onClicked: {
        if (layoutRoot && layoutRoot.openArcMenuSettings)
            layoutRoot.openArcMenuSettings();
        else if (layoutRoot && layoutRoot.menuData)
            layoutRoot.menuData.requestConfigure();
    }
}
