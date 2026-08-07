import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../../code/Locale.js" as Locale

QQC2.Menu {
    id: root

    property var app: null
    property bool isFavorite: false
    property bool canUninstall: false
    property bool canEditDesktop: true
    property var menuData: null

    signal launchRequested(var app)
    signal toggleFavoriteRequested(var app)
    signal addToDesktopRequested(var app)
    signal addToPanelRequested(var app)
    signal editRequested(var app)
    signal detailsRequested(var app)
    signal uninstallRequested(var app)
    signal runInTerminalRequested(var app)

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    QQC2.MenuItem {
        text: root.t("Launch")
        icon.name: "media-playback-start"
        onTriggered: root.launchRequested(root.app)
    }
    QQC2.MenuItem {
        text: root.isFavorite ? root.t("Remove from Favorites") : root.t("Add to Favorites")
        icon.name: root.isFavorite ? "bookmark-remove" : "bookmark-new"
        onTriggered: root.toggleFavoriteRequested(root.app)
    }
    QQC2.MenuSeparator {}
    QQC2.MenuItem {
        text: root.t("Add to Desktop")
        icon.name: "user-desktop"
        onTriggered: root.addToDesktopRequested(root.app)
    }
    QQC2.MenuItem {
        text: root.t("Add to Panel")
        icon.name: "plasma"
        onTriggered: root.addToPanelRequested(root.app)
    }
    QQC2.MenuSeparator {}
    QQC2.MenuItem {
        visible: root.canEditDesktop
        text: root.t("Edit Application…")
        icon.name: "document-edit"
        onTriggered: root.editRequested(root.app)
    }
    QQC2.MenuItem {
        text: root.t("Show Details")
        icon.name: "dialog-information"
        onTriggered: root.detailsRequested(root.app)
    }
    QQC2.MenuItem {
        text: root.t("Run in Terminal")
        icon.name: "utilities-terminal"
        onTriggered: root.runInTerminalRequested(root.app)
    }
    QQC2.MenuItem {
        visible: root.canUninstall
        text: root.t("Uninstall…")
        icon.name: "edit-delete"
        onTriggered: root.uninstallRequested(root.app)
    }
}
