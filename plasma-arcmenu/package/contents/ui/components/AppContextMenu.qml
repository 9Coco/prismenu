import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import "../../code/Locale.js" as Locale
import "../../code/PresetIcons.js" as PresetIcons

/**
 * Kickoff ActionMenu: PlasmaExtras.Menu filled with Kicker's native
 * actionList (new window, add/remove favorites, desktop, task manager,
 * edit, uninstall). ArcMenu-only extras (custom groups, local pins) sit
 * after that native block.
 */
Item {
    id: root
    width: 0
    height: 0
    visible: false

    property var app: null
    property bool isFavorite: false
    property var menuData: null
    property var systemActions: []
    property Item boundsItem: null

    signal launchRequested(var app)
    signal toggleFavoriteRequested(var app)
    signal detailsRequested(var app)
    signal systemActionRequested(var app, string actionId, var actionArgument)
    signal toggleCustomGroupRequested(var app, string groupId)

    readonly property bool opened: nativeMenu.status === PlasmaExtras.Menu.Open
    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"
    readonly property string appId: app ? String(app.id || "") : ""
    readonly property bool isPlace: !!(app && app.place)
    readonly property bool isArcMenuSettings: appId === "arcmenu-settings"
        || (app && app.action === "configure")
    readonly property bool isExtraShortcut: {
        if (!app || isPlace || isArcMenuSettings)
            return false;
        return appId.indexOf("shortcut-") === 0
            || (app.action && app.action !== "configure");
    }
    readonly property bool isDesktopApp: !!(app && !isPlace && !isArcMenuSettings
        && !isExtraShortcut && (app.exec || app.entryPath || app.kickerUrl)
        && appId.indexOf("shortcut-") !== 0)
    readonly property bool canPinLocally: isExtraShortcut || isArcMenuSettings
    readonly property bool hasSystemActions: systemActions && systemActions.length > 0
    readonly property string contextGroupAppId: {
        if (!app)
            return "";
        if (menuData && menuData.customGroupAppId) {
            var id = menuData.customGroupAppId(app);
            if (id)
                return id;
        }
        return appId;
    }
    readonly property var customGroups: (menuData && menuData.customQuickLinkDefs)
        ? menuData.customQuickLinkDefs : []

    function t(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    function customGroupIcon(iconId) {
        var value = String(iconId || "folder-favorites");
        if (PresetIcons.isPreset(value))
            return Qt.resolvedUrl("../../icons/menu-button/" + value + ".svg");
        if (value.indexOf("/") === 0)
            return "file://" + value;
        return value;
    }

    function separator() {
        return { type: "separator", separator: true };
    }

    /** Native Kickoff actions first; ArcMenu-only rows follow. */
    readonly property var menuEntries: {
        var out = [];
        if (!root.app || root.isPlace)
            return out;

        if (root.isArcMenuSettings) {
            if (root.isFavorite)
                out.push({ type: "local-favorite", text: root.t("Unpin from ArcMenu"), icon: "unpin" });
            return out;
        }

        if (root.hasSystemActions) {
            for (var i = 0; i < root.systemActions.length; ++i)
                out.push(root.systemActions[i]);
        } else if (root.canPinLocally) {
            out.push({
                type: "local-favorite",
                text: root.isFavorite ? root.t("Unpin from ArcMenu") : root.t("Pin to ArcMenu"),
                icon: root.isFavorite ? "unpin" : "bookmark-new"
            });
        }

        if (root.customGroups.length && (root.isDesktopApp || root.hasSystemActions)) {
            if (out.length && !out[out.length - 1].separator)
                out.push(root.separator());
            for (var g = 0; g < root.customGroups.length; ++g) {
                var group = root.customGroups[g];
                out.push({
                    type: "custom-group",
                    groupId: group.id,
                    text: root.t("Add to") + " \"" + group.name + "\"",
                    icon: root.customGroupIcon(group.icon),
                    checkable: true,
                    checked: root.menuData
                        ? root.menuData.isAppInCustomGroup(group.id, root.contextGroupAppId)
                        : false
                });
            }
        }
        return out;
    }

    function isNativeEntry(entry) {
        return !!(entry && entry.actionId !== undefined && !entry.type);
    }

    function activateEntry(entry) {
        if (!entry || entry.separator || entry.type === "title")
            return;
        if (root.isNativeEntry(entry)) {
            root.systemActionRequested(root.app, String(entry.actionId || ""), entry.actionArgument);
            return;
        }
        switch (String(entry.type || "")) {
        case "launch": root.launchRequested(root.app); break;
        case "local-favorite": root.toggleFavoriteRequested(root.app); break;
        case "details": root.detailsRequested(root.app); break;
        case "custom-group":
            root.toggleCustomGroupRequested(root.app, String(entry.groupId || ""));
            break;
        }
    }

    function clearSelection() {
        root.app = null;
        root.systemActions = [];
        root.isFavorite = false;
    }

    function dismissAndClear() {
        if (root.opened)
            nativeMenu.close();
        else
            root.clearSelection();
    }

    function popup(x, y, anchor) {
        if (!root.app)
            return;
        // Kickoff ActionMenu: visualParent is the clicked delegate, and
        // (x, y) is the mouse position inside that item. Using the whole
        // popup as the parent with tile-local coordinates puts the menu
        // at the launcher's top-left instead of under the cursor.
        nativeMenu.visualParent = anchor || root.boundsItem;
        nativeMenu.open(Math.round(x || 0), Math.round(y || 0));
    }

    Component {
        id: subMenuComponent
        PlasmaExtras.Menu {
            visualParent: parent ? parent.action : null
        }
    }

    Component {
        id: menuItemComponent
        PlasmaExtras.MenuItem {
            id: item
            required property var modelData
            readonly property PlasmaExtras.Menu subMenu: modelData.subActions
                ? subMenuComponent.createObject(item)
                : null
            text: String(modelData.text || "")
            icon: modelData.icon || null
            enabled: modelData.type !== "title" && modelData.enabled !== false
            separator: modelData.type === "separator" || modelData.separator === true
            section: modelData.type === "title" || modelData.section === true
            checkable: modelData.checkable === true
            checked: modelData.checked === true

            readonly property Instantiator childActions: Instantiator {
                active: item.subMenu !== null
                model: item.modelData.subActions || []
                delegate: menuItemComponent
                onObjectAdded: (index, object) => item.subMenu.addMenuItem(object)
                onObjectRemoved: (index, object) => item.subMenu.removeMenuItem(object)
            }

            onClicked: root.activateEntry(modelData)
        }
    }

    PlasmaExtras.Menu {
        id: nativeMenu
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
        onStatusChanged: {
            if (status === PlasmaExtras.Menu.Closed)
                root.clearSelection();
        }
    }

    Instantiator {
        model: root.app ? root.menuEntries : []
        delegate: menuItemComponent
        onObjectAdded: (index, object) => nativeMenu.addMenuItem(object)
        onObjectRemoved: (index, object) => nativeMenu.removeMenuItem(object)
    }
}
