import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../../code/Locale.js" as Locale

/**
 * Mirror of components/PlacesSidebar.qml for the arcmenu/ folder tree.
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
        return [
            { id: "shortcut-software", name: root.t("Software"), icon: "plasmadiscover", action: "discover" },
            { id: "shortcut-settings", name: root.t("Settings"), icon: "preferences-system", action: "settings" },
            { id: "shortcut-tweaks", name: root.t("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel" }
        ];
    }

    ShortcutRow {
        Layout.fillWidth: true
        iconName: menuData ? menuData.userIcon : "user-identity"
        label: (menuData && menuData.userName) ? menuData.userName : root.t("User")
        iconSize: Math.max(root.iconSize, Kirigami.Units.iconSizes.medium)
        selectedBg: root.selectedBg
        selectedFg: root.selectedFg
        hoverBg: root.hoverBg
        hoverFg: root.hoverFg
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
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
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
            hoverBg: root.hoverBg
            hoverFg: root.hoverFg
            fg: root.fg
            onActivated: root.itemActivated(modelData)
        }
    }

    Item { Layout.fillHeight: true }
}
