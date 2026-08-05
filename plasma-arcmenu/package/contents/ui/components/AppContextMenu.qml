import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.Menu {
    id: root

    property var app: null
    property bool isFavorite: false
    property bool canUninstall: false
    property bool canEditDesktop: true

    signal launchRequested(var app)
    signal toggleFavoriteRequested(var app)
    signal addToDesktopRequested(var app)
    signal addToPanelRequested(var app)
    signal editRequested(var app)
    signal detailsRequested(var app)
    signal uninstallRequested(var app)
    signal runInTerminalRequested(var app)

    QQC2.MenuItem {
        text: i18n("Launch")
        icon.name: "media-playback-start"
        onTriggered: root.launchRequested(root.app)
    }
    QQC2.MenuItem {
        text: root.isFavorite ? i18n("Remove from Favorites") : i18n("Add to Favorites")
        icon.name: root.isFavorite ? "bookmark-remove" : "bookmark-new"
        onTriggered: root.toggleFavoriteRequested(root.app)
    }
    QQC2.MenuSeparator {}
    QQC2.MenuItem {
        text: i18n("Add to Desktop")
        icon.name: "user-desktop"
        onTriggered: root.addToDesktopRequested(root.app)
    }
    QQC2.MenuItem {
        text: i18n("Add to Panel")
        icon.name: "plasma"
        onTriggered: root.addToPanelRequested(root.app)
    }
    QQC2.MenuSeparator {}
    QQC2.MenuItem {
        visible: root.canEditDesktop
        text: i18n("Edit Application…")
        icon.name: "document-edit"
        onTriggered: root.editRequested(root.app)
    }
    QQC2.MenuItem {
        text: i18n("Show Details")
        icon.name: "dialog-information"
        onTriggered: root.detailsRequested(root.app)
    }
    QQC2.MenuItem {
        text: i18n("Run in Terminal")
        icon.name: "utilities-terminal"
        onTriggered: root.runInTerminalRequested(root.app)
    }
    QQC2.MenuItem {
        visible: root.canUninstall
        text: i18n("Uninstall…")
        icon.name: "edit-delete"
        onTriggered: root.uninstallRequested(root.app)
    }
}
