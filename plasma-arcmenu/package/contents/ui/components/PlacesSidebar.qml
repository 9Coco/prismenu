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
    property color fg: Kirigami.Theme.textColor

    signal userClicked()
    signal itemActivated(var item)

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"

    spacing: Kirigami.Units.smallSpacing / 2

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    readonly property var placeItems: {
        var _ = root.uiLang;
        return [
            { id: "place-home", name: root.t("Home"), icon: "user-home", exec: "xdg-open $HOME" },
            { id: "place-docs", name: root.t("Documents"), icon: "folder-documents", exec: "xdg-open xdg:Documents" },
            { id: "place-dl", name: root.t("Downloads"), icon: "folder-download", exec: "xdg-open xdg:Download" },
            { id: "place-music", name: root.t("Music"), icon: "folder-music", exec: "xdg-open xdg:Music" },
            { id: "place-pics", name: root.t("Pictures"), icon: "folder-pictures", exec: "xdg-open xdg:Pictures" },
            { id: "place-videos", name: root.t("Videos"), icon: "folder-videos", exec: "xdg-open xdg:Videos" }
        ];
    }

    readonly property var shortcutItems: {
        var _ = root.uiLang;
        return [
            { id: "shortcut-software", name: root.t("Software"), icon: "plasmadiscover", action: "discover" },
            { id: "shortcut-settings", name: root.t("Settings"), icon: "preferences-system", action: "settings" },
            { id: "shortcut-tweaks", name: root.t("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel" },
            { id: "shortcut-overview", name: root.t("Activities Overview"), icon: "overview", action: "overview" }
        ];
    }

    ShortcutRow {
        Layout.fillWidth: true
        iconName: menuData ? menuData.userIcon : "user-identity"
        label: (menuData && menuData.userName) ? menuData.userName : root.t("User")
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
        model: root.placeItems
        ShortcutRow {
            required property var modelData
            Layout.fillWidth: true
            iconName: modelData.icon
            label: modelData.name
            iconSize: root.iconSize
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            fg: root.fg
            onActivated: root.itemActivated(modelData)
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing / 2
        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
        opacity: 0.4
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
            fg: root.fg
            onActivated: root.itemActivated(modelData)
        }
    }

    Item { Layout.fillHeight: true }
}
