import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/Locale.js" as Locale

/**
 * Functional chrome: right sidebar with user, places, and system shortcuts.
 */
ColumnLayout {
    id: root

    property var menuData: null
    property int iconSize: 22
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg
    property color separatorColor: Kirigami.Theme.disabledTextColor
    property color fg: Kirigami.Theme.textColor
    property bool preferSymbolic: true
    property bool showTooltips: true

    signal userClicked()
    signal itemActivated(var item)
    signal itemContextMenu(var item, real x, real y)

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"
    readonly property bool showAvatar: !menuData || menuData.showUserAvatar !== false
    readonly property string avatarShape: (menuData && menuData.avatarShape) ? menuData.avatarShape : "circle"

    spacing: Kirigami.Units.smallSpacing / 2

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    readonly property var placeItems: {
        var _ = root.uiLang;
        if (menuData && menuData.places && menuData.places.length)
            return menuData.places;
        return [
            { id: "place-home", name: root.t("Home"), icon: "user-home", place: "HOME" },
            { id: "place-docs", name: root.t("Documents"), icon: "folder-documents", place: "DOCUMENTS" },
            { id: "place-dl", name: root.t("Downloads"), icon: "folder-download", place: "DOWNLOAD" },
            { id: "place-music", name: root.t("Music"), icon: "folder-music", place: "MUSIC" },
            { id: "place-pics", name: root.t("Pictures"), icon: "folder-pictures", place: "PICTURES" },
            { id: "place-videos", name: root.t("Videos"), icon: "folder-videos", place: "VIDEOS" }
        ];
    }

    readonly property var shortcutItems: {
        var _ = root.uiLang;
        if (menuData && menuData.systemShortcuts && menuData.systemShortcuts.length)
            return menuData.systemShortcuts;
        return [
            { id: "shortcut-software", name: root.t("Software"), icon: "plasmadiscover", action: "discover" },
            { id: "shortcut-settings", name: root.t("Settings"), icon: "preferences-system", action: "settings" },
            { id: "shortcut-tweaks", name: root.t("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel" }
        ];
    }

    Item {
        id: userRow
        Layout.fillWidth: true
        height: Math.max(avatarBox.height + Kirigami.Units.smallSpacing * 2,
                         Kirigami.Units.gridUnit * 2.1)
        Accessible.name: userLabel.text
        Accessible.role: Accessible.Button
        Accessible.onPressAction: root.userClicked()

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.smallSpacing
            color: userMouse.containsMouse ? root.hoverBg : "transparent"
            opacity: userMouse.containsMouse ? 1 : 0
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Item {
                id: avatarBox
                readonly property int avSize: Math.max(root.iconSize, Kirigami.Units.iconSizes.medium)
                Layout.preferredWidth: root.showAvatar ? avSize : 0
                Layout.preferredHeight: avSize
                width: root.showAvatar ? avSize : 0
                height: avSize
                visible: root.showAvatar
                clip: true

                UserFace {
                    anchors.fill: parent
                    userIcon: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                    userName: (menuData && menuData.userName) ? menuData.userName : ""
                    fallbackColor: userMouse.containsMouse ? root.hoverFg : root.fg
                    shape: root.avatarShape
                    showRing: true
                }
            }

            PlasmaComponents.Label {
                id: userLabel
                Layout.fillWidth: true
                text: (menuData && menuData.userName) ? menuData.userName : root.t("User")
                elide: Text.ElideRight
                color: userMouse.containsMouse ? root.hoverFg : root.fg
            }
        }

        MouseArea {
            id: userMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.userClicked()
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing / 2
        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
        color: root.separatorColor
        opacity: 1
    }

    Repeater {
        model: root.placeItems
        ShortcutRow {
            required property var modelData
            Layout.fillWidth: true
            iconName: modelData.icon
            label: modelData.name
            iconSize: root.iconSize
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            fg: root.fg
            preferSymbolic: root.preferSymbolic
            showTooltips: root.showTooltips
            onActivated: root.itemActivated(modelData)
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing / 2
        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
        color: root.separatorColor
        opacity: 1
    }

    Repeater {
        model: root.shortcutItems
        ShortcutRow {
            required property var modelData
            Layout.fillWidth: true
            iconName: modelData.icon
            label: modelData.name
            iconSize: root.iconSize
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            fg: root.fg
            preferSymbolic: root.preferSymbolic
            showTooltips: root.showTooltips
            onActivated: root.itemActivated(modelData)
            onContextMenuRequested: (x, y) => root.itemContextMenu(modelData, x, y)
        }
    }

    Item { Layout.fillHeight: true }
}
