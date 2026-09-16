import QtQuick
import QtQuick.Controls as QQC2
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
    property bool showSystemShortcuts: true

    signal userClicked()
    signal itemActivated(var item)
    signal itemContextMenu(var item, real x, real y, var anchor)

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"
    readonly property bool showAvatar: !menuData || menuData.showUserAvatar !== false
    readonly property string avatarShape: (menuData && menuData.avatarShape) ? menuData.avatarShape : "circle"

    spacing: Kirigami.Units.smallSpacing / 2

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    readonly property var systemPlaceItems: {
        var _ = root.uiLang;
        if (menuData && menuData.systemPlaces && menuData.systemPlaces.length)
            return menuData.systemPlaces;
        return [
            { id: "place-home", name: root.t("Home"), icon: "user-home", place: "HOME" },
            { id: "place-docs", name: root.t("Documents"), icon: "folder-documents", place: "DOCUMENTS" },
            { id: "place-dl", name: root.t("Downloads"), icon: "folder-download", place: "DOWNLOAD" },
            { id: "place-music", name: root.t("Music"), icon: "folder-music", place: "MUSIC" },
            { id: "place-pics", name: root.t("Pictures"), icon: "folder-pictures", place: "PICTURES" },
            { id: "place-videos", name: root.t("Videos"), icon: "folder-videos", place: "VIDEOS" }
        ];
    }


    readonly property var placeSections: (menuData && menuData.placeSections)
        ? menuData.placeSections : [
            { id: "system", items: systemPlaceItems },
            { id: "dolphin", items: [] },
            { id: "custom", items: [] }
        ]

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
                // Do NOT clip here — Kirigami Addons Avatar uses layer + ShadowedTexture
                // for the circle; a clipped ancestor paints a black disc (Kickoff avoids this).

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

    // Scrollable middle: places + shortcuts must never push the fixed chrome
    // (avatar row above, session buttons below) out of the column. When the
    // menu is resized shorter than the full list, this region scrolls
    // instead of overflowing (fixed rows used to overlap and break the
    // layout once the drag went below the list's natural height).
    Flickable {
        id: listFlick
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: listCol.height
        QQC2.ScrollBar.vertical: MenuScrollBar { menuData: root.menuData }
        QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

        Column {
            id: listCol
            width: listFlick.width
            spacing: root.spacing

            Repeater {
                model: root.placeSections
                Column {
                    required property var modelData
                    required property int index
                    width: listCol.width
                    spacing: root.spacing

                    Repeater {
                        model: modelData.items || []
                        ShortcutRow {
                            required property var modelData
                            width: listCol.width
                            iconName: modelData.icon
                            iconItem: modelData
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

                    // Exactly two permanent boundaries separate the three blocks,
                    // even when one of the blocks has no visible rows.
                    Kirigami.Separator {
                        visible: index < root.placeSections.length - 1
                        width: listCol.width
                        color: root.separatorColor
                        opacity: 1
                    }
                }
            }

            Kirigami.Separator {
                visible: root.showSystemShortcuts && root.shortcutItems.length > 0
                width: listCol.width
                Layout.topMargin: Kirigami.Units.smallSpacing / 2
                Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
                color: root.separatorColor
                opacity: 1
            }

            Repeater {
                model: root.showSystemShortcuts ? root.shortcutItems : []
                ShortcutRow {
                    required property var modelData
                    width: listCol.width
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
                    onContextMenuRequested: (x, y, anchor) => root.itemContextMenu(modelData, x, y, anchor)
                }
            }
        }
    }
}
