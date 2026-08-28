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
    property bool menuPinnedOpen: false
    hideOnWindowDeactivate: !menuPinnedOpen
    property string lastLayoutId: plasmoid.configuration.MenuLayoutId || "arcmenu"

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
            // Match Plasma Kickoff: every open starts from pinned/home,
            // regardless of whether the popup was opened by click, shortcut,
            // or after losing focus.
            menuData.resetView();
            root.applyKUserMeta();
            // os-release already probed at startup; face/name from KUser above
            if (plasmoid.configuration.SearchRecentFiles
                || menuData.isExtraCategoryEnabled("recent-files"))
                backend.refreshRecentFiles();
            backend.refreshOpenWindows();
            if (!menuData.bookmarkResults || !menuData.bookmarkResults.length)
                backend.refreshBookmarks();
        }
    }

    Connections {
        target: menuData
        function onSearchQueryChanged() {
            if (!menuData.isSearching)
                return;
            if (plasmoid.configuration.SearchRecentFiles && (!menuData.recentFileResults || !menuData.recentFileResults.length))
                backend.refreshRecentFiles();
            if (!menuData.openWindowResults || !menuData.openWindowResults.length)
                backend.refreshOpenWindows();
            if (!menuData.bookmarkResults || !menuData.bookmarkResults.length)
                backend.refreshBookmarks();
        }
        function onRecentFilesRequestChanged() {
            backend.refreshRecentFiles();
        }
        function onBookmarksRequestChanged() {
            backend.refreshBookmarks();
        }
        function onDevicesRequestChanged() {
            backend.refreshDevices();
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
        function onDevicesUpdated() {
            menuData.devicesEpoch++;
        }
    }

    /**
     * fullRepresentation / compactRepresentation often cannot see sibling ids.
     * Always pass catalog through this alias: root.catalog
     */
    property alias catalog: menuData

    readonly property var currentLayoutInfo: LayoutRegistry.getLayout(
        plasmoid.configuration.MenuLayoutId || "arcmenu")
    readonly property bool layoutFillsAvailableHeight: false
    readonly property int availableLayoutHeight: menuData.menuHeight
    readonly property int effectiveMenuHeight: menuData.menuHeight

    MenuData {
        id: menuData
        plasmoidConfig: plasmoid.configuration
        currentLayoutId: plasmoid.configuration.MenuLayoutId || "arcmenu"
        // Width ceiling follows the screen (drag handles cap at the same fit)
        maxMenuWidth: Math.max(900, Screen.width - 80)
        maxMenuHeight: Math.max(800, Screen.desktopAvailableHeight
            ? (Screen.desktopAvailableHeight - 80) : (Screen.height - 80))
        layoutSizesRaw: plasmoid.configuration.LayoutSizes
        // Direct bindings — required for live Extra Categories / Search Options toggles
        extraCategoriesEnabledRaw: plasmoid.configuration.ExtraCategoriesEnabled
        extraCategoriesOrderRaw: plasmoid.configuration.ExtraCategoriesOrder
        extraCategoriesUserSetRaw: !!plasmoid.configuration.ExtraCategoriesUserSet
        quickLinksEnabledRaw: plasmoid.configuration.QuickLinksEnabled
        quickLinksOrderRaw: plasmoid.configuration.QuickLinksOrder
        quickLinkPositionRaw: plasmoid.configuration.QuickLinkPosition
        customQuickLinksRaw: plasmoid.configuration.CustomQuickLinks
        customTypeGroupsRaw: plasmoid.configuration.CustomTypeGroups
        customGroupAppsRaw: plasmoid.configuration.CustomGroupApps
        groupViewOptionsRaw: plasmoid.configuration.GroupViewOptions
        sidebarOrderRaw: plasmoid.configuration.SidebarOrder
        sidebarHiddenRaw: plasmoid.configuration.SidebarHidden
        showDescriptionRaw: plasmoid.configuration.ShowDescription
        hideSearchBarRaw: plasmoid.configuration.HideSearchBar
        highlightSearchTermsRaw: plasmoid.configuration.HighlightSearchTerms
        searchBoxRadiusEnabledRaw: plasmoid.configuration.SearchBoxRadiusEnabled
        searchBoxRadiusRaw: plasmoid.configuration.SearchBoxRadius
        searchWindowsRaw: plasmoid.configuration.SearchWindows
        searchRecentFilesRaw: plasmoid.configuration.SearchRecentFiles
        maxResultsRaw: plasmoid.configuration.MaxResults
        Component.onCompleted: {
            CatalogBridge.setMenuData(menuData);
            menuData.dropInMenuSettingsPin();
            console.log("ArcMenu catalog registered on bridge");
        }
    }

    Connections {
        target: plasmoid.configuration
        ignoreUnknownSignals: true
        function onValueChanged(key, value) {
            if (key === "ExtraCategoriesEnabled" || key === "ExtraCategoriesOrder"
                || key === "ExtraCategoriesUserSet" || key === "SidebarOrder"
                || key === "SidebarHidden" || key === "CustomQuickLinks"
                || key === "CustomTypeGroups"
                || key === "CustomGroupApps" || key === "GroupViewOptions"
                || key === "DirectoryShortcuts" || key === "PlaceSectionOrder"
                || key === "SystemPlaceOrder" || key === "HiddenSystemPlaces"
                || key === "DolphinPlaceOrder" || key === "HiddenDolphinPlaces"
                || key === "HiddenCustomPlaces"
                || key === "ApplicationShortcuts" || key === "Order"
                || key === "Hidden" || key === "ShowEmpty" || key === "CustomNames"
                || key === "CustomIcons" || key === "Enabled" || key === "MaxItems"
                || key === "RecentApps" || key === "PinnedApps") {
                menuData.bumpStructure();
                console.log("ArcMenu extras changed:", key, value);
            }
            if (key === "ShowDescription" || key === "HideSearchBar" || key === "HighlightSearchTerms"
                || key === "SearchBoxRadiusEnabled" || key === "SearchBoxRadius"
                || key === "SearchWindows" || key === "SearchRecentFiles" || key === "MaxResults") {
                menuData.bumpSearchConfig();
                if (key === "SearchWindows" || key === "SearchRecentFiles") {
                    if (plasmoid.configuration.SearchRecentFiles)
                        backend.refreshRecentFiles();
                    if (plasmoid.configuration.SearchWindows)
                        backend.refreshOpenWindows();
                }
            }
        }
        function onExtraCategoriesEnabledChanged() { menuData.bumpStructure(); }
        function onExtraCategoriesOrderChanged() { menuData.bumpStructure(); }
        function onExtraCategoriesUserSetChanged() { menuData.bumpStructure(); }
        function onSidebarOrderChanged() { menuData.bumpStructure(); }
        function onSidebarHiddenChanged() { menuData.bumpStructure(); }
        function onCustomQuickLinksChanged() { menuData.bumpStructure(); }
        function onCustomTypeGroupsChanged() { menuData.bumpStructure(); }
        function onOrderChanged() { menuData.bumpStructure(); }
        function onHiddenChanged() { menuData.bumpStructure(); }
        function onShowEmptyChanged() { menuData.bumpStructure(); }
        function onCustomGroupAppsChanged() { menuData.bumpStructure(); }
        function onGroupViewOptionsChanged() { menuData.bumpStructure(); }
        function onEnabledChanged() { menuData.bumpStructure(); }
        function onMaxItemsChanged() { menuData.bumpStructure(); }
        function onRecentAppsChanged() { menuData.bumpStructure(); }
        function onPinnedAppsChanged() { menuData.bumpStructure(); }
        function onDirectoryShortcutsChanged() { menuData.bumpStructure(); }
        function onPlaceSectionOrderChanged() { menuData.bumpStructure(); }
        function onSystemPlaceOrderChanged() { menuData.bumpStructure(); }
        function onHiddenSystemPlacesChanged() { menuData.bumpStructure(); }
        function onDolphinPlaceOrderChanged() { menuData.bumpStructure(); }
        function onHiddenDolphinPlacesChanged() { menuData.bumpStructure(); }
        function onHiddenCustomPlacesChanged() { menuData.bumpStructure(); }
        function onApplicationShortcutsChanged() { menuData.bumpStructure(); }
        function onShowDescriptionChanged() { menuData.bumpSearchConfig(); }
        function onHideSearchBarChanged() { menuData.bumpSearchConfig(); }
        function onHighlightSearchTermsChanged() { menuData.bumpSearchConfig(); }
        function onSearchBoxRadiusEnabledChanged() { menuData.bumpSearchConfig(); }
        function onSearchBoxRadiusChanged() { menuData.bumpSearchConfig(); }
        function onSearchWindowsChanged() {
            menuData.bumpSearchConfig();
            if (plasmoid.configuration.SearchWindows)
                backend.refreshOpenWindows();
        }
        function onSearchRecentFilesChanged() {
            menuData.bumpSearchConfig();
            if (plasmoid.configuration.SearchRecentFiles)
                backend.refreshRecentFiles();
        }
        function onMaxResultsChanged() { menuData.bumpSearchConfig(); }
    }

    AppsBackend {
        id: backend
        menuData: menuData
        appletInterface: root
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
        themeMode: plasmoid.configuration.ThemeMode,
        overrideMenuTheme: !!plasmoid.configuration.OverrideMenuTheme
            || plasmoid.configuration.ThemeMode === "custom",
        menuThemeName: plasmoid.configuration.MenuThemeName || "",
        bgColor: plasmoid.configuration.BgColor,
        fgColor: plasmoid.configuration.FgColor,
        borderColor: plasmoid.configuration.BorderColor,
        borderWidth: plasmoid.configuration.BorderWidth,
        cornerRadius: plasmoid.configuration.CornerRadius,
        font: plasmoid.configuration.Font,
        fontSize: plasmoid.configuration.FontSize,
        separatorColor: plasmoid.configuration.SeparatorColor,
        hoverBg: plasmoid.configuration.HoverBg,
        hoverFg: plasmoid.configuration.HoverFg,
        activeBg: plasmoid.configuration.ActiveBg,
        activeFg: plasmoid.configuration.ActiveFg,
        selectedBg: plasmoid.configuration.SelectedBg,
        selectedFg: plasmoid.configuration.SelectedFg,
        categoryIconSize: plasmoid.configuration.CategoryIconSize,
        appIconSize: plasmoid.configuration.AppIconSize,
        followColorScheme: plasmoid.configuration.FollowColorScheme
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
                activateExisting: !!plasmoid.configuration.ActivateExistingWindow && !ctrl
            });
        }
        menuData.recordLaunch(app);
        if (ctrl && plasmoid.configuration.KeepOpenOnCtrlClick)
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
        var confMode = plasmoid.configuration.Confirm ? "force" : "skip";
        if (sessionIds.indexOf(actionId) >= 0) {
            // Close first: the system leave dialog (and polkit) sit behind this
            // popup, so keeping the menu open looks like the button did nothing.
            closeMenu();
            Qt.callLater(function () {
                backend.runPower(actionId, plasmoid.configuration.SoftwareCenterCmd, confMode);
            });
            return;
        }
        backend.runPower(actionId, plasmoid.configuration.SoftwareCenterCmd, confMode);
        if (actionId === "settings" || actionId === "discover" || actionId === "accountsettings") {
            closeMenu();
        }
    }

    // Compact: panel button
    compactRepresentation: MouseArea {
        id: compact
        readonly property bool isVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical
        readonly property int panelIconSize: {
            var n = parseInt(plasmoid.configuration.PanelButtonIconSize, 10);
            return (!n || isNaN(n)) ? 20 : Math.max(12, Math.min(64, n));
        }
        readonly property int panelPadding: {
            var n = parseInt(plasmoid.configuration.PanelButtonPadding, 10);
            // -1 = theme default (no extra padding)
            if (isNaN(n) || n < 0)
                return 0;
            return Math.min(25, n);
        }
        readonly property int positionOffset: {
            var n = parseInt(plasmoid.configuration.PanelButtonPositionOffset, 10);
            if (isNaN(n) || n < 0)
                return 0;
            return Math.min(10, n);
        }
        readonly property string buttonAppearance: {
            var a = plasmoid.configuration.MenuButtonAppearance || "";
            if (a)
                return a;
            // Migrate older configs that only had buttonLabelVisible
            return plasmoid.configuration.ButtonLabelVisible ? "icon-text" : "icon";
        }
        readonly property bool showButtonIcon: buttonAppearance === "icon"
            || buttonAppearance === "icon-text"
            || buttonAppearance === "text-icon"
        readonly property bool showButtonText: buttonAppearance === "text"
            || buttonAppearance === "icon-text"
            || buttonAppearance === "text-icon"
        readonly property bool buttonHidden: buttonAppearance === "hidden"
        readonly property string leftAction: plasmoid.configuration.LeftClickAction || "arcmenu"
        readonly property string rightAction: plasmoid.configuration.RightClickAction || "context"
        readonly property string middleAction: plasmoid.configuration.MiddleClickAction || "arcmenu"

        readonly property bool styleFgOn: !!plasmoid.configuration.ButtonStyleFgEnabled
        readonly property bool styleBgOn: !!plasmoid.configuration.ButtonStyleBgEnabled
        readonly property bool styleHoverBgOn: !!plasmoid.configuration.ButtonStyleHoverBgEnabled
        readonly property bool styleHoverFgOn: !!plasmoid.configuration.ButtonStyleHoverFgEnabled
        readonly property bool styleActiveBgOn: !!plasmoid.configuration.ButtonStyleActiveBgEnabled
        readonly property bool styleActiveFgOn: !!plasmoid.configuration.ButtonStyleActiveFgEnabled
        readonly property bool styleRadiusOn: !!plasmoid.configuration.ButtonStyleRadiusEnabled
        readonly property bool styleBorderWOn: !!plasmoid.configuration.ButtonStyleBorderWidthEnabled
        readonly property bool styleBorderCOn: !!plasmoid.configuration.ButtonStyleBorderColorEnabled

        readonly property color styleFg: {
            try { return styleFgOn && plasmoid.configuration.ButtonStyleFg
                ? plasmoid.configuration.ButtonStyleFg : Kirigami.Theme.textColor; } catch (e) { return Kirigami.Theme.textColor; }
        }
        readonly property color styleHoverFg: {
            try { return styleHoverFgOn && plasmoid.configuration.ButtonStyleHoverFg
                ? plasmoid.configuration.ButtonStyleHoverFg : styleFg; } catch (e) { return styleFg; }
        }
        readonly property color styleActiveFg: {
            try { return styleActiveFgOn && plasmoid.configuration.ButtonStyleActiveFg
                ? plasmoid.configuration.ButtonStyleActiveFg : styleFg; } catch (e) { return styleFg; }
        }

        implicitWidth: {
            if (compact.buttonHidden)
                return 1;
            var pad = styleBorderWOn ? Math.max(0, plasmoid.configuration.ButtonStyleBorderWidth) * 2 : 0;
            var base = isVertical ? compactContent.implicitHeight : compactContent.implicitWidth;
            var offset = isVertical ? 0 : compact.positionOffset * Kirigami.Units.smallSpacing;
            return base + Kirigami.Units.smallSpacing * 2 + pad + compact.panelPadding * 2 + offset;
        }
        implicitHeight: {
            if (compact.buttonHidden)
                return 1;
            var pad = styleBorderWOn ? Math.max(0, plasmoid.configuration.ButtonStyleBorderWidth) * 2 : 0;
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
            ? (plasmoid.configuration.ButtonLabelText || i18n("Arc Menu"))
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
                            plasmoid.configuration.ContextMenuItems,
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
                ? Math.max(0, plasmoid.configuration.ButtonStyleRadius)
                : Kirigami.Units.smallSpacing
            border.width: compact.styleBorderWOn
                ? Math.max(0, plasmoid.configuration.ButtonStyleBorderWidth)
                : 0
            border.color: {
                if (compact.styleBorderCOn && plasmoid.configuration.ButtonStyleBorderColor)
                    return plasmoid.configuration.ButtonStyleBorderColor;
                return "transparent";
            }
            color: {
                if (root.expanded && compact.styleActiveBgOn && plasmoid.configuration.ButtonStyleActiveBg)
                    return plasmoid.configuration.ButtonStyleActiveBg;
                if (compact.containsMouse && compact.styleHoverBgOn && plasmoid.configuration.ButtonStyleHoverBg)
                    return plasmoid.configuration.ButtonStyleHoverBg;
                if (compact.styleBgOn && plasmoid.configuration.ButtonStyleBg)
                    return plasmoid.configuration.ButtonStyleBg;
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
                text: plasmoid.configuration.ButtonLabelText || ""
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
        /**
         * Popup size is pinned with min == max == preferred: libplasma's
         * AppletPopup ignores Layout.preferredWidth/Height changes once a
         * popup size was remembered (popupWidth/popupHeight in the applet
         * config), but it always applies min/max size changes to the window.
         * Growing works through updateMinSize(); for shrinking the drag
         * handles additionally resize the window directly (syncWindowSize in
         * MenuResizeHandles), because AppletPopup's updateMinSize() can
         * re-issue a stale grow request on Wayland that reverts the shrink.
         */
        readonly property int targetPopupWidth:
            (resizeHandles.liveWidth > 0 ? resizeHandles.liveWidth : root.catalog.menuWidth)
            + hostSideWidth
        readonly property int targetPopupHeight:
            resizeHandles.liveHeight > 0 ? resizeHandles.liveHeight : root.effectiveMenuHeight
        Layout.minimumWidth: targetPopupWidth
        Layout.maximumWidth: targetPopupWidth
        Layout.preferredWidth: targetPopupWidth
        Layout.minimumHeight: targetPopupHeight
        Layout.maximumHeight: targetPopupHeight
        Layout.preferredHeight: targetPopupHeight

        focus: true

        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded)
                    host.resetForOpen();
                else
                    contextMenu.dismissAndClear();
            }
        }

        // Popup animation
        opacity: 1
        transformOrigin: Item.Bottom
        scale: 1

        Behavior on opacity {
            enabled: plasmoid.configuration.PopupAnimation !== "none"
            NumberAnimation { duration: Kirigami.Units.longDuration }
        }
        Behavior on scale {
            enabled: plasmoid.configuration.PopupAnimation === "expand"
            NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        }

        // Visual Appearance → Override menu rise / position (best-effort within Plasma popup)
        readonly property int risePx: {
            if (!plasmoid.configuration.OverrideMenuRise)
                return 0;
            var d = parseInt(plasmoid.configuration.MenuRiseDistance, 10);
            return (!d || isNaN(d)) ? 6 : Math.max(0, Math.min(64, d));
        }
        readonly property string posMode: plasmoid.configuration.OverrideMenuPosition || "off"
        readonly property int posShiftY: {
            if (posMode === "top-centered" || posMode === "center")
                return -Math.round(fullRep.height * 0.08);
            if (posMode === "bottom-centered")
                return Math.round(fullRep.height * 0.02);
            return 0;
        }

        Component.onCompleted: {
            root.catalog.resetView();
            host.resetForOpen();
            var targetY = -fullRep.risePx + fullRep.posShiftY;
            if (plasmoid.configuration.PopupAnimation === "fade") {
                opacity = 0;
                opacity = 1;
                fullRep.y = targetY;
            } else if (plasmoid.configuration.PopupAnimation === "expand") {
                scale = 0.92;
                scale = 1;
                fullRep.y = targetY;
            } else if (plasmoid.configuration.PopupAnimation === "slide") {
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
                // Read actionList lazily for only the selected stable Kicker
                // row; this is the same native list Kickoff presents.
                contextMenu.systemActions = backend.systemActions(app);
                contextMenu.isFavorite = root.catalog.isFavorite(app);
                contextMenu.canUninstall = !(app && (app.action || app.place
                    || String(app.id || "").indexOf("shortcut-") === 0));
                contextMenu.popup();
            }
            onPowerAction: (id) => root.handlePower(id)
            onKeepOpenRequested: (pinned) => root.menuPinnedOpen = pinned
            // ArcMenu "User" → System Settings → Users (not switch-user dialog)
            onUserMenu: root.handlePower("accountsettings")
        }

        // Drag edges/corners to resize popup (persists MenuWidth / MenuHeight)
        Components.MenuResizeHandles {
            id: resizeHandles
            anchors.fill: parent
            z: 40
            menuData: root.catalog
            sideWidth: fullRep.hostSideWidth
            maxHeight: (root.currentLayoutInfo && root.currentLayoutInfo.maxHeight)
                ? root.currentLayoutInfo.maxHeight : 800
            resizeHeight: !root.currentLayoutInfo
                || root.currentLayoutInfo.resizableHeight !== false
        }

        Components.AppContextMenu {
            id: contextMenu
            // Anchor coordinates to the popup content so the menu can clamp
            // itself inside the window (no clipping at the bottom/right edge)
            parent: fullRep
            boundsItem: fullRep
            menuData: root.catalog
            onLaunchRequested: (app) => root.launchApp(app)
            onNewWindowRequested: (app) => {
                backend.openNewWindow(app);
                root.closeMenu();
            }
            onToggleFavoriteRequested: (app) => root.catalog.toggleFavorite(app)
            onToggleCustomGroupRequested: (app, groupId) => {
                var appId = root.catalog.customGroupAppId(app);
                if (!appId)
                    return;
                var wasIn = root.catalog.isAppInCustomGroup(groupId, appId);
                console.log("ArcMenu toggleCustomGroup", groupId, "app:", appId, "wasIn:", wasIn);
                if (wasIn)
                    root.catalog.removeFromCustomGroup(groupId, appId);
                else
                    root.catalog.addToCustomGroup(groupId, appId);
            }
            onAddToDesktopRequested: (app) => {
                backend.addDesktopShortcut(app);
                root.closeMenu();
            }
            onAddToPanelRequested: (app) => {
                backend.pinToTaskManager(app);
                // Match Kickoff: addToTaskManager returns false specifically
                // to keep the launcher open after pinning (KDE BUG 390585).
            }
            onEditRequested: (app) => backend.editDesktop(app)
            onDetailsRequested: (app) => {
                detailsDialog.app = app;
                detailsDialog.open();
            }
            onUninstallRequested: (app) => backend.uninstall(app)
            onRunInTerminalRequested: (app) => backend.runInTerminal(app)
            onSystemActionRequested: (app, actionId, actionArgument) => {
                backend.triggerSystemAction(app, actionId, actionArgument);
                // Match Kickoff's behavior: task-manager pinning deliberately
                // keeps the launcher open, other native actions close it.
                if (actionId !== "addToTaskManager")
                    root.closeMenu();
            }
        }

        Components.ConfirmDialog {
            id: confirmDialog
            anchors.centerIn: parent
            menuData: root.catalog
            onConfirmed: (actionId) => {
                // User already confirmed in ArcMenu dialog → skip system prompt
                backend.runPower(actionId, plasmoid.configuration.SoftwareCenterCmd, "skip");
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
            console.log("ArcMenu: layout ->", plasmoid.configuration.MenuLayoutId);
            var nextId = plasmoid.configuration.MenuLayoutId || "arcmenu";
            menuData.currentLayoutId = nextId;
            if (lastLayoutId !== nextId)
                menuData.applyLayoutSize(nextId);
            if (root.expanded && lastLayoutId !== plasmoid.configuration.MenuLayoutId) {
                root.expanded = false;
                Qt.callLater(() => {
                    menuData.resetView();
                    root.expanded = true;
                });
            }
            lastLayoutId = plasmoid.configuration.MenuLayoutId || "arcmenu";
            // A keep-open request belongs to the layout instance being left.
            // Reset it generically so future layouts can reuse the same signal.
            root.menuPinnedOpen = false;
        }
    }

    // Panel-button right-click is swallowed by compactRepresentation; edit mode needs Remove.
    Plasmoid.contextualActions: []

    Component.onCompleted: {
        // GNOME used to duplicate Budgie. Keep existing installations valid
        // after removing it from the registry and package.
        if (plasmoid.configuration.MenuLayoutId === "gnome")
            plasmoid.configuration.MenuLayoutId = "budgie";

        // Keep Configure / Remove / Alternatives available in panel edit mode.
        var restore = ["remove", "alternatives", "configure"];
        for (var i = 0; i < restore.length; ++i) {
            try {
                var a = plasmoid.internalAction(restore[i]);
                if (a) {
                    a.visible = true;
                    a.enabled = true;
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
