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
import org.kde.kcmutils as KCM
import "../code/Distro.js" as Distro
import "../code/LayoutRegistry.js" as LayoutRegistry
import "../code/Theme.js" as ThemeHelper
import "../code/Favorites.js" as Favorites
import "../code/CatalogBridge.js" as CatalogBridge
import "../code/Locale.js" as Locale
import "../code/ShortcutsConfig.js" as ShortcutsConfig
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
        // Match Kickoff Header.qml: Avatar { source: kuser.faceIconUrl; name: kuser.fullName }
        var name = kuser.fullName || kuser.loginName || "";
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
    }

    onExpandedChanged: function (expanded) {
        if (expanded) {
            root.applyKUserMeta();
            // os-release already probed at startup; face/name from KUser above
            if (plasmoid.configuration.searchRecentFiles
                || menuData.isExtraCategoryEnabled("recent-files"))
                backend.refreshRecentFiles();
            if (plasmoid.configuration.searchWindows)
                backend.refreshOpenWindows();
        }
    }

    Connections {
        target: menuData
        function onSearchQueryChanged() {
            if (!menuData.isSearching)
                return;
            if (plasmoid.configuration.searchRecentFiles && (!menuData.recentFileResults || !menuData.recentFileResults.length))
                backend.refreshRecentFiles();
            if (plasmoid.configuration.searchWindows && (!menuData.openWindowResults || !menuData.openWindowResults.length))
                backend.refreshOpenWindows();
        }
        function onRecentFilesRequestChanged() {
            backend.refreshRecentFiles();
        }
        function onBookmarksRequestChanged() {
            backend.refreshBookmarks();
        }
    }

    Connections {
        target: backend
        function onRecentFilesUpdated() {
            menuData.recentFilesEpoch++;
        }
        function onBookmarksUpdated() {
            menuData.bookmarksEpoch++;
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
        // Direct bindings — required for live Extra Categories / Search Options toggles
        extraCategoriesEnabledRaw: plasmoid.configuration.extraCategoriesEnabled
        extraCategoriesOrderRaw: plasmoid.configuration.extraCategoriesOrder
        extraCategoriesUserSetRaw: !!plasmoid.configuration.extraCategoriesUserSet
        showDescriptionRaw: plasmoid.configuration.showDescription
        hideSearchBarRaw: plasmoid.configuration.hideSearchBar
        highlightSearchTermsRaw: plasmoid.configuration.highlightSearchTerms
        searchBoxRadiusEnabledRaw: plasmoid.configuration.searchBoxRadiusEnabled
        searchBoxRadiusRaw: plasmoid.configuration.searchBoxRadius
        searchWindowsRaw: plasmoid.configuration.searchWindows
        searchRecentFilesRaw: plasmoid.configuration.searchRecentFiles
        maxResultsRaw: plasmoid.configuration.maxResults
        Component.onCompleted: {
            CatalogBridge.setMenuData(menuData);
            menuData.ensureArcMenuSettingsPinned();
            console.log("ArcMenu catalog registered on bridge");
        }
    }

    Connections {
        target: plasmoid.configuration
        ignoreUnknownSignals: true
        function onValueChanged(key, value) {
            if (key === "extraCategoriesEnabled" || key === "extraCategoriesOrder"
                || key === "extraCategoriesUserSet") {
                menuData.bumpStructure();
                console.log("ArcMenu extras changed:", key, value);
            }
            if (key === "showDescription" || key === "hideSearchBar" || key === "highlightSearchTerms"
                || key === "searchBoxRadiusEnabled" || key === "searchBoxRadius"
                || key === "searchWindows" || key === "searchRecentFiles" || key === "maxResults") {
                menuData.bumpSearchConfig();
                if (key === "searchWindows" || key === "searchRecentFiles") {
                    if (plasmoid.configuration.searchRecentFiles)
                        backend.refreshRecentFiles();
                    if (plasmoid.configuration.searchWindows)
                        backend.refreshOpenWindows();
                }
            }
        }
        function onExtraCategoriesEnabledChanged() { menuData.bumpStructure(); }
        function onExtraCategoriesOrderChanged() { menuData.bumpStructure(); }
        function onExtraCategoriesUserSetChanged() { menuData.bumpStructure(); }
        function onShowDescriptionChanged() { menuData.bumpSearchConfig(); }
        function onHideSearchBarChanged() { menuData.bumpSearchConfig(); }
        function onHighlightSearchTermsChanged() { menuData.bumpSearchConfig(); }
        function onSearchBoxRadiusEnabledChanged() { menuData.bumpSearchConfig(); }
        function onSearchBoxRadiusChanged() { menuData.bumpSearchConfig(); }
        function onSearchWindowsChanged() {
            menuData.bumpSearchConfig();
            if (plasmoid.configuration.searchWindows)
                backend.refreshOpenWindows();
        }
        function onSearchRecentFilesChanged() {
            menuData.bumpSearchConfig();
            if (plasmoid.configuration.searchRecentFiles)
                backend.refreshRecentFiles();
        }
        function onMaxResultsChanged() { menuData.bumpSearchConfig(); }
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
            // Name/face: KUser only (Kickoff). Meta script supplies os-release.
            if (osId)
                menuData.osReleaseId = osId;
            if (osPretty)
                menuData.osPrettyName = osPretty;
        }
        Component.onCompleted: {
            menuData.appsBackend = backend;
            root.applyKUserMeta();
            refreshUserMeta();
        }
        onScanFailed: (message) => {
            console.warn("ArcMenu: Kicker catalog failed:", message);
        }
    }

    readonly property var themeStyle: ThemeHelper.buildStyle({
        themeMode: plasmoid.configuration.themeMode,
        overrideMenuTheme: !!plasmoid.configuration.overrideMenuTheme
            || plasmoid.configuration.themeMode === "custom",
        menuThemeName: plasmoid.configuration.menuThemeName || "",
        bgColor: plasmoid.configuration.bgColor,
        fgColor: plasmoid.configuration.fgColor,
        borderColor: plasmoid.configuration.borderColor,
        borderWidth: plasmoid.configuration.borderWidth,
        cornerRadius: plasmoid.configuration.cornerRadius,
        font: plasmoid.configuration.font,
        fontSize: plasmoid.configuration.fontSize,
        separatorColor: plasmoid.configuration.separatorColor,
        hoverBg: plasmoid.configuration.hoverBg,
        hoverFg: plasmoid.configuration.hoverFg,
        activeBg: plasmoid.configuration.activeBg,
        activeFg: plasmoid.configuration.activeFg,
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
        if (!app || app.isSection) return;
        var mods = 0;
        try { mods = Qt.keyboardModifiers; } catch (e) {}
        var ctrl = (mods & Qt.ControlModifier) !== 0;
        if (ctrl && backend.openNewWindow) {
            backend.openNewWindow(app);
        } else {
            backend.launch(app, {
                activateExisting: !!plasmoid.configuration.activateExistingWindow && !ctrl
            });
        }
        menuData.recordLaunch(app);
        if (ctrl && plasmoid.configuration.keepOpenOnCtrlClick)
            return;
        closeMenu();
    }

    function handlePower(actionId) {
        // Kickoff: Users KCM via KCMLauncher
        if (actionId === "accountsettings") {
            try {
                KCM.KCMLauncher.openSystemSettings("kcm_users");
                closeMenu();
                return;
            } catch (e) {
                console.warn("ArcMenu KCMLauncher failed, fallback", e);
            }
        }
        // SessionManagement shows the system leave prompt (Kickoff Leave).
        // ArcMenu "confirm" → ForcePrompt; off → SkipPrompt.
        var sessionIds = ["shutdown", "restart", "logout", "lock", "suspend", "hibernate", "switchuser", "hybridsleep"];
        var confMode = plasmoid.configuration.confirm ? "force" : "skip";
        if (sessionIds.indexOf(actionId) >= 0) {
            // Still allow ArcMenu dialog as an extra gate when ForcePrompt unsupported
            if (plasmoid.configuration.confirm && ["shutdown", "restart", "logout"].indexOf(actionId) >= 0) {
                confirmDialog.openFor(actionId);
                return;
            }
            backend.runPower(actionId, plasmoid.configuration.softwareCenterCmd, confMode);
            return;
        }
        backend.runPower(actionId, plasmoid.configuration.softwareCenterCmd, confMode);
        if (actionId === "settings" || actionId === "discover" || actionId === "accountsettings") {
            closeMenu();
        }
    }

    // Compact: panel button
    compactRepresentation: MouseArea {
        id: compact
        readonly property bool isVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical
        readonly property int panelIconSize: {
            var n = parseInt(plasmoid.configuration.panelButtonIconSize, 10);
            return (!n || isNaN(n)) ? 20 : Math.max(12, Math.min(64, n));
        }
        readonly property int panelPadding: {
            var n = parseInt(plasmoid.configuration.panelButtonPadding, 10);
            // -1 = theme default (no extra padding)
            if (isNaN(n) || n < 0)
                return 0;
            return Math.min(25, n);
        }
        readonly property int positionOffset: {
            var n = parseInt(plasmoid.configuration.panelButtonPositionOffset, 10);
            if (isNaN(n) || n < 0)
                return 0;
            return Math.min(10, n);
        }
        readonly property string buttonAppearance: {
            var a = plasmoid.configuration.menuButtonAppearance || "";
            if (a)
                return a;
            // Migrate older configs that only had buttonLabelVisible
            return plasmoid.configuration.buttonLabelVisible ? "icon-text" : "icon";
        }
        readonly property bool showButtonIcon: buttonAppearance === "icon"
            || buttonAppearance === "icon-text"
            || buttonAppearance === "text-icon"
        readonly property bool showButtonText: buttonAppearance === "text"
            || buttonAppearance === "icon-text"
            || buttonAppearance === "text-icon"
        readonly property bool buttonHidden: buttonAppearance === "hidden"
        readonly property string leftAction: plasmoid.configuration.leftClickAction || "arcmenu"
        readonly property string rightAction: plasmoid.configuration.rightClickAction || "context"
        readonly property string middleAction: plasmoid.configuration.middleClickAction || "arcmenu"

        readonly property bool styleFgOn: !!plasmoid.configuration.buttonStyleFgEnabled
        readonly property bool styleBgOn: !!plasmoid.configuration.buttonStyleBgEnabled
        readonly property bool styleHoverBgOn: !!plasmoid.configuration.buttonStyleHoverBgEnabled
        readonly property bool styleHoverFgOn: !!plasmoid.configuration.buttonStyleHoverFgEnabled
        readonly property bool styleActiveBgOn: !!plasmoid.configuration.buttonStyleActiveBgEnabled
        readonly property bool styleActiveFgOn: !!plasmoid.configuration.buttonStyleActiveFgEnabled
        readonly property bool styleRadiusOn: !!plasmoid.configuration.buttonStyleRadiusEnabled
        readonly property bool styleBorderWOn: !!plasmoid.configuration.buttonStyleBorderWidthEnabled
        readonly property bool styleBorderCOn: !!plasmoid.configuration.buttonStyleBorderColorEnabled

        readonly property color styleFg: {
            try { return styleFgOn && plasmoid.configuration.buttonStyleFg
                ? plasmoid.configuration.buttonStyleFg : Kirigami.Theme.textColor; } catch (e) { return Kirigami.Theme.textColor; }
        }
        readonly property color styleHoverFg: {
            try { return styleHoverFgOn && plasmoid.configuration.buttonStyleHoverFg
                ? plasmoid.configuration.buttonStyleHoverFg : styleFg; } catch (e) { return styleFg; }
        }
        readonly property color styleActiveFg: {
            try { return styleActiveFgOn && plasmoid.configuration.buttonStyleActiveFg
                ? plasmoid.configuration.buttonStyleActiveFg : styleFg; } catch (e) { return styleFg; }
        }

        implicitWidth: {
            if (compact.buttonHidden)
                return 1;
            var pad = styleBorderWOn ? Math.max(0, plasmoid.configuration.buttonStyleBorderWidth) * 2 : 0;
            var base = isVertical ? compactContent.implicitHeight : compactContent.implicitWidth;
            var offset = isVertical ? 0 : compact.positionOffset * Kirigami.Units.smallSpacing;
            return base + Kirigami.Units.smallSpacing * 2 + pad + compact.panelPadding * 2 + offset;
        }
        implicitHeight: {
            if (compact.buttonHidden)
                return 1;
            var pad = styleBorderWOn ? Math.max(0, plasmoid.configuration.buttonStyleBorderWidth) * 2 : 0;
            var base = isVertical ? compactContent.implicitWidth : compactContent.implicitHeight;
            var offset = isVertical ? compact.positionOffset * Kirigami.Units.smallSpacing : 0;
            return base + Kirigami.Units.smallSpacing * 2 + pad + compact.panelPadding * 2 + offset;
        }
        opacity: compact.buttonHidden ? 0 : 1
        enabled: !compact.buttonHidden
        hoverEnabled: true
        // Swallow right-click so Plasma's applet menu (Configure / Remove / …) does not appear
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        Accessible.name: compact.showButtonText
            ? (plasmoid.configuration.buttonLabelText || i18n("Arc Menu"))
            : i18n("Arc Menu")
        Accessible.role: Accessible.Button
        Accessible.onPressAction: root.toggleMenu()

        function runClickAction(action, mouse) {
            if (action === "nothing")
                return;
            if (action === "context") {
                buttonContextMenu.popup(compact, mouse ? mouse.x : 0, mouse ? mouse.y : compact.height);
                return;
            }
            if (action === "configure") {
                try { plasmoid.internalAction("configure").trigger(); } catch (e) {}
                return;
            }
            if (action === "overview" || action === "show-desktop") {
                root.handlePower(action);
                return;
            }
            // default: arcmenu
            root.toggleMenu();
        }

        property bool wasExpanded: false
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = true;
                return;
            }
            wasExpanded = root.expanded;
        }
        onClicked: (mouse) => {
            mouse.accepted = true;
            if (mouse.button === Qt.RightButton) {
                compact.runClickAction(compact.rightAction, mouse);
                return;
            }
            if (mouse.button === Qt.MiddleButton) {
                compact.runClickAction(compact.middleAction, mouse);
                return;
            }
            if (mouse.button === Qt.LeftButton) {
                compact.runClickAction(compact.leftAction, mouse);
            }
        }

        QQC2.Menu {
            id: buttonContextMenu

            function tr(msgid) {
                return Locale.tr(msgid, menuData && menuData.uiLang ? menuData.uiLang : "zh_CN");
            }

            function activateItem(itemId) {
                if (itemId === "configure" || itemId === "panel-settings") {
                    try { plasmoid.internalAction("configure").trigger(); } catch (e) {}
                    return;
                }
                if (itemId === "power") {
                    root.handlePower("logout");
                    return;
                }
                if (itemId === "overview" || itemId === "show-desktop") {
                    root.handlePower(itemId);
                    return;
                }
                if (String(itemId).indexOf("desktop:") === 0) {
                    var did = String(itemId).substring(8);
                    var apps = menuData.allApps || [];
                    for (var a = 0; a < apps.length; ++a) {
                        if (apps[a].id === did) {
                            root.launchApp(apps[a]);
                            return;
                        }
                    }
                }
            }

            Instantiator {
                model: {
                    try {
                        return ShortcutsConfig.normalizeList(
                            plasmoid.configuration.contextMenuItems,
                            ShortcutsConfig.DEFAULT_CTX);
                    } catch (e) {
                        return ShortcutsConfig.DEFAULT_CTX.slice();
                    }
                }
                delegate: QQC2.MenuItem {
                    required property var modelData
                    readonly property string itemId: String(modelData || "")
                    readonly property bool isSep: itemId === "separator"
                    text: {
                        if (isSep)
                            return "────────";
                        var defs = ShortcutsConfig.contextMenuDefs(buttonContextMenu.tr);
                        for (var i = 0; i < defs.length; ++i) {
                            if (defs[i].id === itemId)
                                return defs[i].name;
                        }
                        if (itemId.indexOf("desktop:") === 0) {
                            var did = itemId.substring(8);
                            var apps = menuData.allApps || [];
                            for (var a = 0; a < apps.length; ++a) {
                                if (apps[a].id === did)
                                    return apps[a].name;
                            }
                            return buttonContextMenu.tr("Invalid shortcut") + " - " + did;
                        }
                        return itemId;
                    }
                    icon.name: {
                        if (isSep)
                            return "";
                        var defs = ShortcutsConfig.contextMenuDefs(buttonContextMenu.tr);
                        for (var i = 0; i < defs.length; ++i) {
                            if (defs[i].id === itemId)
                                return defs[i].icon;
                        }
                        return "application-x-executable";
                    }
                    enabled: !isSep
                    onTriggered: {
                        if (!isSep)
                            buttonContextMenu.activateItem(itemId);
                    }
                }
                onObjectAdded: (index, object) => buttonContextMenu.insertItem(index, object)
                onObjectRemoved: (index, object) => buttonContextMenu.removeItem(object)
            }
        }

        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: i18n("Arc Menu")
            subText: i18n("Click to open application menu")
        }

        Rectangle {
            id: buttonChrome
            anchors.fill: parent
            z: 0
            radius: compact.styleRadiusOn
                ? Math.max(0, plasmoid.configuration.buttonStyleRadius)
                : Kirigami.Units.smallSpacing
            border.width: compact.styleBorderWOn
                ? Math.max(0, plasmoid.configuration.buttonStyleBorderWidth)
                : 0
            border.color: {
                if (compact.styleBorderCOn && plasmoid.configuration.buttonStyleBorderColor)
                    return plasmoid.configuration.buttonStyleBorderColor;
                return "transparent";
            }
            color: {
                if (root.expanded && compact.styleActiveBgOn && plasmoid.configuration.buttonStyleActiveBg)
                    return plasmoid.configuration.buttonStyleActiveBg;
                if (compact.containsMouse && compact.styleHoverBgOn && plasmoid.configuration.buttonStyleHoverBg)
                    return plasmoid.configuration.buttonStyleHoverBg;
                if (compact.styleBgOn && plasmoid.configuration.buttonStyleBg)
                    return plasmoid.configuration.buttonStyleBg;
                if (root.expanded)
                    return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25);
                if (compact.containsMouse)
                    return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12);
                return "transparent";
            }
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
        }

        RowLayout {
            id: compactContent
            anchors.centerIn: parent
            z: 1
            spacing: Kirigami.Units.smallSpacing
            visible: !compact.buttonHidden
            // text-icon: show label before icon via mirrored layout
            layoutDirection: compact.buttonAppearance === "text-icon" ? Qt.RightToLeft : Qt.LeftToRight

            Kirigami.Icon {
                id: buttonIcon
                visible: compact.showButtonIcon
                source: menuData.buttonIcon || "start-here-kde"
                isMask: menuData.buttonIconIsMask
                Layout.preferredWidth: compact.panelIconSize
                Layout.preferredHeight: compact.panelIconSize
                LayoutMirroring.enabled: false
                color: menuData.buttonIconIsMask
                    ? (root.expanded ? compact.styleActiveFg
                        : (compact.containsMouse ? compact.styleHoverFg : compact.styleFg))
                    : undefined
            }

            PlasmaComponents.Label {
                visible: compact.showButtonText
                text: plasmoid.configuration.buttonLabelText || ""
                Layout.alignment: Qt.AlignVCenter
                LayoutMirroring.enabled: false
                color: root.expanded ? compact.styleActiveFg
                    : (compact.containsMouse ? compact.styleHoverFg : compact.styleFg)
            }
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
        Layout.maximumWidth: 900 + hostSideWidth
        Layout.maximumHeight: root.isRavenLayout ? 1400 : 800

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

        // Visual Appearance → Override menu rise / position (best-effort within Plasma popup)
        readonly property int risePx: {
            if (!plasmoid.configuration.overrideMenuRise)
                return 0;
            var d = parseInt(plasmoid.configuration.menuRiseDistance, 10);
            return (!d || isNaN(d)) ? 6 : Math.max(0, Math.min(64, d));
        }
        readonly property string posMode: plasmoid.configuration.overrideMenuPosition || "off"
        readonly property int posShiftY: {
            if (posMode === "top-centered" || posMode === "center")
                return -Math.round(fullRep.height * 0.08);
            if (posMode === "bottom-centered")
                return Math.round(fullRep.height * 0.02);
            return 0;
        }

        Component.onCompleted: {
            var targetY = -fullRep.risePx + fullRep.posShiftY;
            if (plasmoid.configuration.popupAnimation === "fade") {
                opacity = 0;
                opacity = 1;
                fullRep.y = targetY;
            } else if (plasmoid.configuration.popupAnimation === "expand") {
                scale = 0.92;
                scale = 1;
                fullRep.y = targetY;
            } else if (plasmoid.configuration.popupAnimation === "slide") {
                fullRep.y = 12 + targetY;
                slideAnim.to = targetY;
                slideAnim.start();
            } else {
                fullRep.y = targetY;
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

        // Drag edges/corners to resize popup (persists MenuWidth / MenuHeight)
        Components.MenuResizeHandles {
            anchors.fill: parent
            z: 40
            menuData: root.catalog
            maxHeight: root.isRavenLayout ? 1400 : 800
            // Raven fills the screen vertically — width only
            resizeHeight: !root.isRavenLayout
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
                // User already confirmed in ArcMenu dialog → skip system prompt
                backend.runPower(actionId, plasmoid.configuration.softwareCenterCmd, "skip");
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
