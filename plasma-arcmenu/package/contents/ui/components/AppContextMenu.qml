import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Window
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
    /** Native Kicker actionList for the selected application. */
    property var systemActions: []

    signal launchRequested(var app)
    signal newWindowRequested(var app)
    signal toggleFavoriteRequested(var app)
    signal addToDesktopRequested(var app)
    signal addToPanelRequested(var app)
    signal editRequested(var app)
    signal detailsRequested(var app)
    signal uninstallRequested(var app)
    signal runInTerminalRequested(var app)
    signal systemActionRequested(var app, string actionId, var actionArgument)
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

    readonly property bool hasSystemActions: root.isDesktopApp
        && root.systemActions && root.systemActions.length > 0

    // QQC2 nested menus are unstable on the Plasma/Qt version this applet
    // targets. Flatten native sub-actions while preserving the exact Kicker
    // action id and argument; separators/titles do not trigger anything.
    readonly property var flatSystemActions: {
        var out = [];
        var list = root.systemActions || [];
        for (var i = 0; i < list.length; ++i) {
            var a = list[i];
            if (!a || a.type === "separator" || a.type === "title")
                continue;
            if (a.subActions && a.subActions.length) {
                for (var j = 0; j < a.subActions.length; ++j) {
                    var sub = a.subActions[j];
                    if (!sub || sub.type === "separator" || sub.type === "title")
                        continue;
                    out.push({
                        text: (a.text ? String(a.text) + " — " : "") + String(sub.text || ""),
                        icon: sub.icon || a.icon || "application-x-executable",
                        enabled: sub.enabled !== false,
                        actionId: sub.actionId,
                        actionArgument: sub.actionArgument
                    });
                }
            } else if (a.actionId) {
                out.push(a);
            }
        }
        return out;
    }
    
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
    /** Extra "Add to …" rows are only for custom groups (pin/unpin is above). */
    readonly property bool hasAddTargets: root.canPinToMenu && root.customGroupCount > 0

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    /**
     * Item the menu must stay inside (set by main.qml to the popup content).
     * The menu's parent must be the same item so x/y are directly comparable.
     */
    property Item boundsItem: null

    /**
     * Keep the menu inside its bounds (applet popup window / screen).
     * Cursor-anchored popup() ignores edges, so items right-clicked near
     * the bottom/right border got clipped — shift the menu back in view.
     */
    function repositionWithinBounds() {
        try {
            if (!root.opened || !root.width || !root.height)
                return;
            var minX = 0, minY = 0, maxX, maxY;
            if (root.boundsItem) {
                maxX = root.boundsItem.width - root.width;
                maxY = root.boundsItem.height - root.height;
            } else {
                // Fallback: screen available area (panel excluded)
                var gp = root.mapToGlobal(0, 0);
                minX = Screen.desktopAvailableX - gp.x + root.x;
                minY = Screen.desktopAvailableY - gp.y + root.y;
                maxX = minX + Screen.desktopAvailableWidth - root.width;
                maxY = minY + Screen.desktopAvailableHeight - root.height;
            }
            var m = Kirigami.Units.smallSpacing;
            var nx = Math.min(root.x, maxX - m);
            nx = Math.max(nx, minX + m);
            if (maxX - m < minX + m)
                nx = minX + m; // taller/wider than the bounds → pin to origin
            var ny = Math.min(root.y, maxY - m);
            ny = Math.max(ny, minY + m);
            if (maxY - m < minY + m)
                ny = minY + m;
            if (nx !== root.x)
                root.x = nx;
            if (ny !== root.y)
                root.y = ny;
        } catch (e) {}
    }

    onOpened: Qt.callLater(root.repositionWithinBounds)
    // Group items are appended while open → height changes after opening
    onHeightChanged: if (root.opened) root.repositionWithinBounds()
    onWidthChanged: if (root.opened) root.repositionWithinBounds()

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
        visible: root.isDesktopApp && !root.hasSystemActions
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
        visible: root.canDesktopActions && !root.hasSystemActions
        text: root.t("Create Desktop Shortcut")
        icon.name: "user-desktop"
        onTriggered: root.addToDesktopRequested(root.app)
    }

    QQC2.MenuSeparator {
        visible: root.canDesktopActions && !root.hasSystemActions
    }

    QQC2.MenuItem {
        visible: root.canDesktopActions && !root.hasSystemActions
        text: root.t("Pin to Taskbar")
        icon.name: "pin"
        onTriggered: root.addToPanelRequested(root.app)
    }

    QQC2.MenuItem {
        visible: root.canPinToMenu && !root.isFavorite
        text: root.isDesktopApp ? root.t("Pin to Favorites") : root.t("Pin to ArcMenu")
        icon.name: "bookmark-new"
        onTriggered: root.toggleFavoriteRequested(root.app)
    }

    QQC2.MenuItem {
        visible: root.canPinToMenu && root.isFavorite && !root.isArcMenuSettings
        text: root.isDesktopApp ? root.t("Remove from Favorites") : root.t("Unpin from ArcMenu")
        icon.name: "unpin"
        onTriggered: root.toggleFavoriteRequested(root.app)
    }
    
    QQC2.MenuSeparator {
        visible: root.isDesktopApp && !root.hasSystemActions
            && (root.canEditDesktop || root.canUninstall)
    }

    QQC2.MenuItem {
        visible: root.isDesktopApp && !root.hasSystemActions && root.canEditDesktop
        text: root.t("Edit Application…")
        icon.name: "document-edit"
        onTriggered: root.editRequested(root.app)
    }
    QQC2.MenuItem {
        visible: root.isDesktopApp && !root.hasSystemActions
        text: root.t("Show Details")
        icon.name: "dialog-information"
        onTriggered: root.detailsRequested(root.app)
    }
    QQC2.MenuItem {
        visible: root.isDesktopApp && !root.hasSystemActions && root.canUninstall
        text: root.t("Uninstall…")
        icon.name: "edit-delete"
        onTriggered: root.uninstallRequested(root.app)
    }

    // Every action here (desktop shortcut, panel/task-manager pinning,
    // desktop-entry actions, menu editor and Discover management) comes from
    // the same Kicker actionList consumed by KDE's official Kickoff.
    Instantiator {
        active: root.visible && root.hasSystemActions
        model: active ? root.flatSystemActions : []
        delegate: QQC2.MenuItem {
            required property var modelData
            text: String(modelData.text || "")
            icon.name: typeof modelData.icon === "string" ? modelData.icon : ""
            enabled: modelData.enabled !== false
            onTriggered: root.systemActionRequested(
                root.app, String(modelData.actionId || ""), modelData.actionArgument)
        }
        onObjectAdded: (index, object) => {
            root.addItem(object);
            root.repositionWithinBounds();
        }
        onObjectRemoved: (index, object) => root.removeItem(object)
    }

    // "Add to…" — quick add the app to favorites or a custom quick link group.
    // Kept at the END of the menu so group items can be appended with addItem():
    // this Qt build's QQuickMenu has no indexOf(), and a nested QQC2.Menu whose
    // `visible` is binding-driven crashes plasmashell (2026-08). Items are built
    // only while this menu is open (inserting into a closed menu also crashed).
    QQC2.MenuSeparator {
        visible: root.hasAddTargets
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
        onObjectAdded: (index, object) => {
            root.addItem(object);
            // Height changed while open → re-check the bounds
            root.repositionWithinBounds();
        }
        onObjectRemoved: (index, object) => root.removeItem(object)
    }
}
