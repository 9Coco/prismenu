import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import "../code/Distro.js" as Distro
import "../code/LayoutRegistry.js" as LayoutRegistry
import "../code/Theme.js" as ThemeHelper
import "../code/Favorites.js" as Favorites
import "../code/CatalogBridge.js" as CatalogBridge
import "components" as Components

PlasmoidItem {
    id: root

    Plasmoid.constraintHints: Plasmoid.CanFillArea
    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Arc Menu")
    toolTipSubText: i18n("Application menu with switchable layouts")
    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 12

    property bool menuOpen: false
    property string lastLayoutId: plasmoid.configuration.menuLayoutId || "arcmenu"

    // Plasma Kickoff uses the same API for avatar + display name
    KCoreAddons.KUser {
        id: kuser
    }

    function applyKUserMeta() {
        var name = kuser.loginName || kuser.fullName || "";
        if (name)
            menuData.userName = name;
        var face = "";
        try {
            face = String(kuser.faceIconUrl || "");
        } catch (e) {}
        if (face.length > 8)
            menuData.userIcon = face;
        if (kuser.os)
            menuData.osPrettyName = kuser.os;
        console.log("ArcMenu KUser:", name, face);
    }

    onExpandedChanged: {
        if (expanded) {
            root.applyKUserMeta();
            backend.refreshUserMeta();
        }
    }

    /**
     * fullRepresentation / compactRepresentation often cannot see sibling ids.
     * Always pass catalog through this alias: root.catalog
     */
    property alias catalog: menuData

    readonly property bool isRavenLayout: (plasmoid.configuration.menuLayoutId || "") === "raven"
    // Raven: fill vertical desktop space (panel-reserved area excluded when available)
    readonly property int ravenFillHeight: {
        var h = Screen.desktopAvailableHeight;
        if (!h || h < 400)
            h = Screen.height;
        return LayoutRegistry.clampSize(h, 400, 1400, 900);
    }
    readonly property int effectiveMenuHeight: root.isRavenLayout ? root.ravenFillHeight : menuData.menuHeight

    MenuData {
        id: menuData
        plasmoidConfig: plasmoid.configuration
        currentLayoutId: plasmoid.configuration.menuLayoutId || "arcmenu"
        Component.onCompleted: {
            CatalogBridge.setMenuData(menuData);
            menuData.ensureArcMenuSettingsPinned();
            console.log("ArcMenu catalog registered on bridge");
        }
    }

    AppsBackend {
        id: backend
        menuData: menuData
        onAppsUpdated: (apps) => {
            menuData.allApps = apps;
            menuData.catalogEpoch += 1;
            CatalogBridge.setMenuData(menuData);
            console.log("ArcMenu: allApps updated →", apps ? apps.length : 0,
                        "epoch", menuData.catalogEpoch);
        }
        onMetaUpdated: (userName, userIcon, osId, osPretty) => {
            if (userName)
                menuData.userName = userName;
            // Prefer resolved face file; don't wipe KUser face with bare fallback icon
            if (userIcon && userIcon !== "user-identity")
                menuData.userIcon = userIcon;
            if (osId)
                menuData.osReleaseId = osId;
            if (osPretty)
                menuData.osPrettyName = osPretty;
        }
        Component.onCompleted: {
            root.applyKUserMeta();
            refreshUserMeta();
        }
        onScanFailed: (message) => {
            console.warn("ArcMenu: Kicker catalog failed:", message);
        }
    }

    readonly property var themeStyle: ThemeHelper.buildStyle({
        themeMode: plasmoid.configuration.themeMode,
        bgColor: plasmoid.configuration.bgColor,
        fgColor: plasmoid.configuration.fgColor,
        borderColor: plasmoid.configuration.borderColor,
        borderWidth: plasmoid.configuration.borderWidth,
        cornerRadius: plasmoid.configuration.cornerRadius,
        font: plasmoid.configuration.font,
        fontSize: plasmoid.configuration.fontSize,
        selectedBg: plasmoid.configuration.selectedBg,
        selectedFg: plasmoid.configuration.selectedFg,
        categoryIconSize: plasmoid.configuration.categoryIconSize,
        appIconSize: plasmoid.configuration.appIconSize,
        followColorScheme: plasmoid.configuration.followColorScheme
    }, {
        background: Kirigami.Theme.backgroundColor,
        foreground: Kirigami.Theme.textColor,
        border: Kirigami.Theme.disabledTextColor,
        radius: Kirigami.Units.cornerRadius,
        fontFamily: Kirigami.Theme.defaultFont.family,
        fontSize: Kirigami.Theme.defaultFont.pointSize,
        highlight: Kirigami.Theme.highlightColor,
        highlightedText: Kirigami.Theme.highlightedTextColor
    })

    function toggleMenu() {
        if (root.expanded) {
            root.expanded = false;
        } else {
            menuData.resetView();
            root.expanded = true;
        }
    }

    function closeMenu() {
        root.expanded = false;
    }

    function launchApp(app) {
        if (!app) return;
        backend.launch(app);
        menuData.recordLaunch(app);
        closeMenu();
    }

    function handlePower(actionId) {
        var destructive = ["shutdown", "restart", "logout"];
        if (plasmoid.configuration.confirm && destructive.indexOf(actionId) >= 0) {
            confirmDialog.openFor(actionId);
            return;
        }
        backend.runPower(actionId, plasmoid.configuration.softwareCenterCmd);
        if (actionId === "settings" || actionId === "discover" || actionId === "accountsettings" || actionId === "overview") {
            closeMenu();
        }
    }

    // Compact: panel button
    compactRepresentation: MouseArea {
        id: compact
        readonly property bool isVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical
        implicitWidth: isVertical ? compactContent.implicitHeight : compactContent.implicitWidth
        implicitHeight: isVertical ? compactContent.implicitWidth : compactContent.implicitHeight
        hoverEnabled: true
        // Swallow right-click so Plasma's applet menu (Configure / Remove / …) does not appear
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        Accessible.name: plasmoid.configuration.buttonLabelVisible
            ? plasmoid.configuration.buttonLabelText
            : i18n("Arc Menu")
        Accessible.role: Accessible.Button
        Accessible.onPressAction: root.toggleMenu()

        property bool wasExpanded: false
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = true;
                return;
            }
            wasExpanded = root.expanded;
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = true;
                return;
            }
            if (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                root.toggleMenu();
            }
        }

        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: i18n("Arc Menu")
            subText: i18n("Click to open application menu")
        }

        RowLayout {
            id: compactContent
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                id: buttonIcon
                source: menuData.buttonIcon || "start-here-kde"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                opacity: {
                    try {
                        if (Distro.isLikelyImagePath(plasmoid.configuration.customButtonIcon)
                            && plasmoid.configuration.buttonIcon === "custom"
                            && String(source).indexOf("start-here") === 0)
                            return 0.9;
                    } catch (e) {}
                    return 1;
                }
            }

            PlasmaComponents.Label {
                visible: !!plasmoid.configuration.buttonLabelVisible
                text: plasmoid.configuration.buttonLabelText || ""
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.smallSpacing
            color: Kirigami.Theme.highlightColor
            opacity: root.expanded ? 0.25 : (compact.containsMouse ? 0.12 : 0)
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }
    }

    // Full: menu popup
    fullRepresentation: Item {
        id: fullRep
        readonly property int hostSideWidth: host.sidePanelWidth || 0
        Layout.minimumWidth: root.catalog.menuWidth + hostSideWidth
        Layout.minimumHeight: root.effectiveMenuHeight
        Layout.preferredWidth: root.catalog.menuWidth + hostSideWidth
        Layout.preferredHeight: root.effectiveMenuHeight

        focus: true

        // Popup animation
        opacity: 1
        transformOrigin: Item.Bottom
        scale: 1

        Behavior on opacity {
            enabled: plasmoid.configuration.popupAnimation !== "none"
            NumberAnimation { duration: Kirigami.Units.longDuration }
        }
        Behavior on scale {
            enabled: plasmoid.configuration.popupAnimation === "expand"
            NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        }

        Component.onCompleted: {
            if (plasmoid.configuration.popupAnimation === "fade") {
                opacity = 0;
                opacity = 1;
            } else if (plasmoid.configuration.popupAnimation === "expand") {
                scale = 0.92;
                scale = 1;
            } else if (plasmoid.configuration.popupAnimation === "slide") {
                fullRep.y = 12;
                slideAnim.start();
            }
            Qt.callLater(() => fullRep.forceActiveFocus());
        }

        NumberAnimation {
            id: slideAnim
            target: fullRep
            property: "y"
            to: 0
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }

        // Swallow right-clicks on empty chrome so Plasma's
        // "Configure / Edit mode" applet menu never appears.
        // Only RightButton — left clicks and child context menus still work.
        MouseArea {
            anchors.fill: parent
            z: 0
            acceptedButtons: Qt.RightButton
            onPressed: (mouse) => { mouse.accepted = true; }
            onClicked: (mouse) => { mouse.accepted = true; }
        }

        LayoutHost {
            id: host
            anchors.fill: parent
            z: 1
            // MUST use root.catalog — bare `menuData` id is often invisible here
            menuData: root.catalog
            themeStyle: root.themeStyle
            onAppActivated: (app) => root.launchApp(app)
            onAppContextMenu: (app, x, y) => {
                contextMenu.app = app;
                contextMenu.isFavorite = root.catalog.isFavorite(app);
                contextMenu.canUninstall = !(app && (app.action || app.place
                    || String(app.id || "").indexOf("shortcut-") === 0));
                contextMenu.popup();
            }
            onPowerAction: (id) => root.handlePower(id)
            // ArcMenu "User" → System Settings → Users (not switch-user dialog)
            onUserMenu: root.handlePower("accountsettings")
        }

        Components.AppContextMenu {
            id: contextMenu
            menuData: root.catalog
            onLaunchRequested: (app) => root.launchApp(app)
            onNewWindowRequested: (app) => {
                backend.openNewWindow(app);
                root.closeMenu();
            }
            onToggleFavoriteRequested: (app) => root.catalog.toggleFavorite(app)
            onAddToDesktopRequested: (app) => {
                backend.addDesktopShortcut(app);
                root.closeMenu();
            }
            onAddToPanelRequested: (app) => {
                backend.pinToTaskManager(app);
                root.closeMenu();
            }
            onEditRequested: (app) => backend.editDesktop(app)
            onDetailsRequested: (app) => {
                detailsDialog.app = app;
                detailsDialog.open();
            }
            onUninstallRequested: (app) => backend.uninstall(app)
            onRunInTerminalRequested: (app) => backend.runInTerminal(app)
        }

        Components.ConfirmDialog {
            id: confirmDialog
            anchors.centerIn: parent
            menuData: root.catalog
            onConfirmed: (actionId) => {
                backend.runPower(actionId, plasmoid.configuration.softwareCenterCmd);
            }
        }

        Components.AppDetailsDialog {
            id: detailsDialog
            anchors.centerIn: parent
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                if (menuData.searchQuery.length > 0) {
                    menuData.setSearch("");
                } else {
                    root.closeMenu();
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
                // Ctrl+F focus search — layouts bind search fields; reset query focus via empty set
                event.accepted = true;
            } else if (event.text && event.text.length === 1 && /[a-zA-Z0-9]/.test(event.text)) {
                menuData.setSearch(menuData.searchQuery + event.text);
                event.accepted = true;
            }
        }
    }

    // Global Meta hotkey coordination via plasmoid global shortcut activation
    Plasmoid.onActivated: root.toggleMenu()

    // Layout change: LayoutHost follows menuLayoutId; reopen if menu is open
    Connections {
        target: plasmoid.configuration
        function onMenuLayoutIdChanged() {
            console.log("ArcMenu: layout ->", plasmoid.configuration.menuLayoutId);
            menuData.currentLayoutId = plasmoid.configuration.menuLayoutId || "arcmenu";
            if (root.expanded && lastLayoutId !== plasmoid.configuration.menuLayoutId) {
                root.expanded = false;
                Qt.callLater(() => {
                    menuData.resetView();
                    root.expanded = true;
                });
            }
            lastLayoutId = plasmoid.configuration.menuLayoutId || "arcmenu";
        }
    }

    // No custom contextual actions — panel right-click is swallowed by compact MouseArea
    Plasmoid.contextualActions: []

    Component.onCompleted: {
        // Hide from any residual Plasma applet menu; configure stays triggerable
        var hide = ["configure", "remove", "alternatives"];
        for (var i = 0; i < hide.length; ++i) {
            try {
                var a = plasmoid.internalAction(hide[i]);
                if (a) {
                    a.visible = false;
                    if (hide[i] !== "configure")
                        a.enabled = false;
                }
            } catch (e) {}
        }
    }

    Connections {
        target: menuData
        function onRequestConfigure() {
            root.closeMenu();
            Qt.callLater(() => {
                try {
                    var a = plasmoid.internalAction("configure");
                    if (a) {
                        a.enabled = true;
                        a.trigger();
                    }
                } catch (e) {}
            });
        }
    }
}
