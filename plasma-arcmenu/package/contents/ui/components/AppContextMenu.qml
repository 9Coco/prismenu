import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../../code/Locale.js" as Locale

/**
 * ArcMenu-style context menu for apps, pinned items, and sidebar shortcuts.
 */
QQC2.Menu {
    id: root

    property var app: null
    property bool isFavorite: false
    property bool canUninstall: false
    property bool canEditDesktop: true
    property var menuData: null

    signal launchRequested(var app)
    signal newWindowRequested(var app)
    signal toggleFavoriteRequested(var app)
    signal addToDesktopRequested(var app)
    signal addToPanelRequested(var app)
    signal editRequested(var app)
    signal detailsRequested(var app)
    signal uninstallRequested(var app)
    signal runInTerminalRequested(var app)
    signal toggleCustomGroupRequested(var app, string groupId)

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"

    readonly property string appId: app ? String(app.id || "") : ""

    readonly property bool isPlace: !!(app && app.place)

    readonly property bool isArcMenuSettings: appId === "arcmenu-settings"
        || (app && app.action === "configure")

    /** Software / Settings / Tweaks / Overview in the right rail */
    readonly property bool isExtraShortcut: {
        if (!app || isPlace || isArcMenuSettings)
            return false;
        if (appId.indexOf("shortcut-") === 0)
            return true;
        if (app.action && app.action !== "configure")
            return true;
        return false;
    }

    readonly property bool isDesktopApp: !!(app && !isPlace && !isArcMenuSettings && !isExtraShortcut
        && (app.exec || app.entryPath || app.kickerUrl)
        && appId.indexOf("shortcut-") !== 0)

    /** Pin target exists for apps + extra shortcuts (not places) */
    readonly property bool canPinToMenu: isDesktopApp || isExtraShortcut || isArcMenuSettings

    readonly property bool canDesktopActions: isDesktopApp
        || (isExtraShortcut && (app.action === "discover" || app.action === "settings"
            || appId === "shortcut-software" || appId === "shortcut-settings"))
    
    /** Pin id used for group-membership checks (matches MenuData.resolvePinId) */
    readonly property string contextPinId: {
        if (!root.app)
            return "";
        if (root.menuData && root.menuData.resolvePinId) {
            var pid = root.menuData.resolvePinId(root.app);
            if (pid)
                return pid;
        }
        return root.appId;
    }

    readonly property int customGroupCount: (root.menuData && root.menuData.customQuickLinkDefs)
        ? root.menuData.customQuickLinkDefs.length : 0
    /** "Add to" section only makes sense when there is at least one target */
    readonly property bool hasAddTargets: root.canPinToMenu
        && (!root.isFavorite || root.customGroupCount > 0)

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    // ArcMenu Settings (pinned): unpin only
    QQC2.MenuItem {
        visible: root.isArcMenuSettings && root.isFavorite
        text: root.t("Unpin from ArcMenu")
        icon.name: "unpin"
        onTriggered: root.toggleFavoriteRequested(root.app)
    }

    // Places: no context actions (open only)
    // ---- Desktop apps + pinable shortcuts ----
    QQC2.MenuItem {
        visible: root.isDesktopApp || root.isExtraShortcut
        text: root.t("Launch")
        icon.name: "media-playback-start"
        onTriggered: root.launchRequested(root.app)
    }

    QQC2.MenuItem {
        visible: root.isDesktopApp
        text: root.t("New Window")
        icon.name: "window-new"
        onTriggered: root.newWindowRequested(root.app)
    }

    QQC2.MenuItem {
        visible: root.isDesktopApp && !!(root.app && (root.app.exec || root.app.entryPath || root.app.kickerUrl))
        text: root.t("Run in Terminal")
        icon.name: "utilities-terminal"
        onTriggered: root.runInTerminalRequested(root.app)
    }

    QQC2.MenuSeparator {
        visible: root.isDesktopApp
    }

    QQC2.MenuItem {
        visible: root.canDesktopActions
        text: root.t("Create Desktop Shortcut")
        icon.name: "user-desktop"
        onTriggered: root.addToDesktopRequested(root.app)
    }

    QQC2.MenuSeparator {
        visible: root.canDesktopActions
    }

    QQC2.MenuItem {
        visible: root.canDesktopActions
        text: root.t("Pin to Taskbar")
        icon.name: "pin"
        onTriggered: root.addToPanelRequested(root.app)
    }

    QQC2.MenuItem {
        visible: root.canPinToMenu && !root.isFavorite
        text: root.t("Pin to ArcMenu")
        icon.name: "bookmark-new"
        onTriggered: root.toggleFavoriteRequested(root.app)
    }

    QQC2.MenuItem {
        visible: root.canPinToMenu && root.isFavorite && !root.isArcMenuSettings
        text: root.t("Unpin from ArcMenu")
        icon.name: "unpin"
        onTriggered: root.toggleFavoriteRequested(root.app)
    }
    
    QQC2.MenuSeparator {
        visible: root.isDesktopApp && (root.canEditDesktop || root.canUninstall)
    }

    QQC2.MenuItem {
        visible: root.isDesktopApp && root.canEditDesktop
        text: root.t("Edit Application…")
        icon.name: "document-edit"
        onTriggered: root.editRequested(root.app)
    }
    QQC2.MenuItem {
        visible: root.isDesktopApp
        text: root.t("Show Details")
        icon.name: "dialog-information"
        onTriggered: root.detailsRequested(root.app)
    }
    QQC2.MenuItem {
        visible: root.isDesktopApp && root.canUninstall
        text: root.t("Uninstall…")
        icon.name: "edit-delete"
        onTriggered: root.uninstallRequested(root.app)
    }

    // "Add to…" — quick add the app to favorites or a custom quick link group.
    // Kept at the END of the menu so group items can be appended with addItem():
    // this Qt build's QQuickMenu has no indexOf(), and a nested QQC2.Menu whose
    // `visible` is binding-driven crashes plasmashell (2026-08). Items are built
    // only while this menu is open (inserting into a closed menu also crashed).
    QQC2.MenuSeparator {
        visible: root.hasAddTargets
    }
    QQC2.MenuItem {
        visible: root.hasAddTargets && !root.isFavorite
        text: root.t("Add to Favorites")
        icon.name: "emblem-favorite"
        onTriggered: root.toggleFavoriteRequested(root.app)
    }
    Instantiator {
        active: root.visible && root.customGroupCount > 0
        model: active && root.menuData && root.menuData.customQuickLinkDefs
            ? root.menuData.customQuickLinkDefs : []
        delegate: QQC2.MenuItem {
            required property var modelData
            text: root.t("Add to") + " \"" + modelData.name + "\""
            icon.name: modelData.icon || "folder-favorites"
            checkable: true
            checked: root.menuData
                ? root.menuData.isAppInCustomGroup(modelData.id, root.contextPinId)
                : false
            onTriggered: root.toggleCustomGroupRequested(root.app, modelData.id)
        }
        onObjectAdded: (index, object) => root.addItem(object)
        onObjectRemoved: (index, object) => root.removeItem(object)
    }
}
