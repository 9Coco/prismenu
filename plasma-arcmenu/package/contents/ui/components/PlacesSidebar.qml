import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

/**
 * Functional chrome: right sidebar with user, places, and system shortcuts.
 * Lists are defined here (not via MenuData) so they always render.
 */
ColumnLayout {
    id: root

    property var menuData: null
    property int iconSize: 22
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color fg: Kirigami.Theme.textColor

    signal userClicked()
    signal itemActivated(var item)

    spacing: Kirigami.Units.smallSpacing / 2

    // Built locally — avoids QtObject/i18n array binding failures in MenuData
    readonly property var placeItems: [
        { id: "place-home", name: i18n("Home"), icon: "user-home", exec: "xdg-open $HOME" },
        { id: "place-docs", name: i18n("Documents"), icon: "folder-documents", exec: "xdg-open xdg:Documents" },
        { id: "place-dl", name: i18n("Downloads"), icon: "folder-download", exec: "xdg-open xdg:Download" },
        { id: "place-music", name: i18n("Music"), icon: "folder-music", exec: "xdg-open xdg:Music" },
        { id: "place-pics", name: i18n("Pictures"), icon: "folder-pictures", exec: "xdg-open xdg:Pictures" },
        { id: "place-videos", name: i18n("Videos"), icon: "folder-videos", exec: "xdg-open xdg:Videos" }
    ]

    readonly property var shortcutItems: [
        { id: "shortcut-software", name: i18n("Software"), icon: "plasmadiscover", action: "discover" },
        { id: "shortcut-settings", name: i18n("Settings"), icon: "preferences-system", action: "settings" },
        { id: "shortcut-tweaks", name: i18n("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel" },
        { id: "shortcut-overview", name: i18n("Activities Overview"), icon: "overview", action: "overview" }
    ]

    ShortcutRow {
        Layout.fillWidth: true
        iconName: menuData ? menuData.userIcon : "user-identity"
        label: (menuData && menuData.userName) ? menuData.userName : i18n("User")
        iconSize: Math.max(root.iconSize, Kirigami.Units.iconSizes.medium)
        selectedBg: root.selectedBg
        selectedFg: root.selectedFg
        fg: root.fg
        onActivated: root.userClicked()
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing / 2
        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
        opacity: 0.4
    }

    Repeater {
        model: root.placeItems.length
        ShortcutRow {
            required property int index
            Layout.fillWidth: true
            iconName: root.placeItems[index].icon
            label: root.placeItems[index].name
            iconSize: root.iconSize
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            fg: root.fg
            onActivated: root.itemActivated(root.placeItems[index])
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing / 2
        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
        opacity: 0.4
    }

    Repeater {
        model: root.shortcutItems.length
        ShortcutRow {
            required property int index
            Layout.fillWidth: true
            iconName: root.shortcutItems[index].icon
            label: root.shortcutItems[index].name
            iconSize: root.iconSize
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            fg: root.fg
            onActivated: root.itemActivated(root.shortcutItems[index])
        }
    }

    Item { Layout.fillHeight: true }
}
