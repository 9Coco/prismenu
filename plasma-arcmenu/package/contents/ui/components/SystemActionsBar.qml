import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

RowLayout {
    id: root

    property var enabledOptions: ["shutdown", "restart", "logout", "lock", "suspend", "settings", "discover", "switchuser"]
    property bool confirmDestructive: true
    property string softwareCenterCmd: "auto-detect"
    property bool showUser: true
    property string userName: ""
    property string userIcon: "user-identity"

    signal actionRequested(string actionId)
    signal userMenuRequested()

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    function isEnabled(id) {
        return (enabledOptions || []).indexOf(id) >= 0;
    }

    Item {
        Layout.fillWidth: true
        visible: showUser
        height: Kirigami.Units.gridUnit * 1.8

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            // Kickoff-style avatar (no parent clip — layer effect)
            UserFace {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                userIcon: root.userIcon
                userName: root.userName
                showRing: true
                shape: "circle"
            }

            PlasmaComponents.Label {
                text: root.userName || i18n("User")
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.userMenuRequested()
            Accessible.name: i18n("User account")
            Accessible.role: Accessible.Button
        }
    }

    PlasmaComponents.ToolButton {
        visible: isEnabled("settings")
        icon.name: "configure"
        Accessible.name: i18n("System Settings")
        onClicked: root.actionRequested("settings")
        PlasmaComponents.ToolTip.text: i18n("System Settings")
        PlasmaComponents.ToolTip.visible: hovered
        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    PlasmaComponents.ToolButton {
        visible: isEnabled("discover")
        icon.name: "plasmadiscover"
        Accessible.name: i18n("Software Center")
        onClicked: root.actionRequested("discover")
        PlasmaComponents.ToolTip.text: i18n("Discover")
        PlasmaComponents.ToolTip.visible: hovered
        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    PlasmaComponents.ToolButton {
        visible: isEnabled("lock")
        icon.name: "system-lock-screen"
        Accessible.name: i18n("Lock")
        onClicked: root.actionRequested("lock")
        PlasmaComponents.ToolTip.text: i18n("Lock Screen")
        PlasmaComponents.ToolTip.visible: hovered
        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    PlasmaComponents.ToolButton {
        id: powerButton
        visible: isEnabled("shutdown") || isEnabled("restart") || isEnabled("logout") || isEnabled("suspend") || isEnabled("hibernate")
        icon.name: "system-shutdown"
        Accessible.name: i18n("Power")
        onClicked: powerMenu.open()
        PlasmaComponents.ToolTip.text: i18n("Power")
        PlasmaComponents.ToolTip.visible: hovered
        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay

        QQC2.Menu {
            id: powerMenu
            QQC2.MenuItem {
                visible: root.isEnabled("logout")
                text: i18n("Log Out")
                icon.name: "system-log-out"
                onTriggered: root.actionRequested("logout")
            }
            QQC2.MenuItem {
                visible: root.isEnabled("suspend")
                text: i18n("Suspend")
                icon.name: "system-suspend"
                onTriggered: root.actionRequested("suspend")
            }
            QQC2.MenuItem {
                visible: root.isEnabled("hibernate")
                text: i18n("Hibernate")
                icon.name: "system-suspend-hibernate"
                onTriggered: root.actionRequested("hibernate")
            }
            QQC2.MenuSeparator {}
            QQC2.MenuItem {
                visible: root.isEnabled("restart")
                text: i18n("Restart")
                icon.name: "system-reboot"
                onTriggered: root.actionRequested("restart")
            }
            QQC2.MenuItem {
                visible: root.isEnabled("shutdown")
                text: i18n("Shut Down")
                icon.name: "system-shutdown"
                onTriggered: root.actionRequested("shutdown")
            }
            QQC2.MenuItem {
                visible: root.isEnabled("switchuser")
                text: i18n("Switch User")
                icon.name: "system-switch-user"
                onTriggered: root.actionRequested("switchuser")
            }
        }
    }
}
