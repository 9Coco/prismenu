import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/ShortcutsConfig.js" as SC

/**
 * Menu settings hub — mirrors GNOME ArcMenu’s nested “Menu” page:
 * section groups → secondary pages (not a flat Plasma sidebar list).
 *
 * Plasma Apply only reads cfg_* on this root item, so we declare the union of
 * subpage keys -- but after the page is created these mirrors MUST NOT change:
 * Plasma 6 re-evaluates "dirty" on every root cfg_*Changed signal (and older
 * Plasma treats any cfg_* change as dirty outright), which kept popping the
 * "Apply Settings" prompt even though everything is applied live.
 *
 * Architecture: subpages write through to plasmoid.configuration on every
 * edit; subpage instances are initialized from the live config (push props);
 * saveConfig() re-pulls the live config into the root mirrors right before
 * Plasma writes them back, making that write-back a no-op.
 */
Item {
    id: root

    // —— cfg_* mirror (union of Menu subpages; Plasma injects values on load) ——
    property string cfg_MenuLayoutId
    property bool cfg_FlipHorizontal
    property string cfg_SearchbarLocation
    property bool cfg_SearchbarLocationUserSet: false
    property int cfg_MenuWidth
    property int cfg_MenuHeight
    property int cfg_SidebarWidth
    property int cfg_CategoryColumnWidth
    property int cfg_LeftPanelWidth
    property int cfg_RightPanelWidth
    property int cfg_WidthOffset

    property string cfg_ThemeMode
    property bool cfg_OverrideMenuTheme
    property string cfg_MenuThemeName
    property string cfg_CustomThemes
    property string cfg_BgColor
    property string cfg_FgColor
    property string cfg_BorderColor
    property int cfg_BorderWidth
    property int cfg_CornerRadius
    property string cfg_Font
    property int cfg_FontSize
    property string cfg_SeparatorColor
    property string cfg_HoverBg
    property string cfg_HoverFg
    property string cfg_ActiveBg
    property string cfg_ActiveFg
    property string cfg_SelectedBg
    property string cfg_SelectedFg
    property int cfg_CategoryIconSize
    property int cfg_AppIconSize
    property bool cfg_FollowColorScheme

    property string cfg_OverrideMenuPosition
    property bool cfg_OverrideMenuRise
    property int cfg_MenuRiseDistance
    property int cfg_IconSizeGrid
    property int cfg_IconSizeApps
    property int cfg_IconSizeShortcuts
    property int cfg_IconSizeCategories
    property int cfg_IconSizeButtons
    property int cfg_IconSizeOther

    property bool cfg_ShowCategorySubmenus
    property bool cfg_ShowAppDescriptions
    property bool cfg_ShowGenericNames
    property bool cfg_ShowHiddenRecentFiles
    property bool cfg_MultiLineLabels
    property bool cfg_ShowTooltips
    property bool cfg_GroupAppsAlphabeticallyList
    property bool cfg_GroupAppsAlphabeticallyGrid
    property bool cfg_ActivateExistingWindow
    property bool cfg_KeepOpenOnCtrlClick
    property bool cfg_ScrollviewFadeEffects
    property bool cfg_ShowScrollbars
    property bool cfg_OverlayScrollbars
    property string cfg_CategoryIconType
    property string cfg_ShortcutIconType

    property string cfg_AllAppsButtonAction
    property bool cfg_ShowUserAvatar
    property string cfg_AvatarShape
    property bool cfg_ShowVerticalSeparator
    property bool cfg_ShowExternalDevices
    property bool cfg_ShowBookmarks
    property var cfg_QuickLinksOrder: []
    property var cfg_QuickLinksEnabled: []
    property string cfg_QuickLinkPosition

    property var cfg_PinnedApps: []
    property var cfg_DirectoryShortcuts: []
    property var cfg_PlaceSectionOrder: []
    property var cfg_SystemPlaceOrder: []
    property var cfg_HiddenSystemPlaces: []
    property var cfg_DolphinPlaceOrder: []
    property var cfg_HiddenDolphinPlaces: []
    property var cfg_HiddenCustomPlaces: []
    property var cfg_ApplicationShortcuts: []
    property var cfg_ExtraCategoriesOrder
    property var cfg_ExtraCategoriesEnabled
    property bool cfg_ExtraCategoriesUserSet: false
    property var cfg_SidebarOrder: []
    property var cfg_SidebarHidden: []
    property var cfg_ContextMenuItems: []
    property var cfg_CustomQuickLinks: []
    property var cfg_CustomTypeGroups: []
    property string cfg_CustomGroupApps: "{}"
    property string cfg_GroupViewOptions: "{}"
    property string cfg_LayoutSizes: "{}"

    property var cfg_Providers: ["applications", "places", "files"]
    property string cfg_Placeholder
    property bool cfg_ShowDescription
    property int cfg_MaxResults
    property bool cfg_HideSearchBar
    property bool cfg_HighlightSearchTerms
    property bool cfg_SearchBoxRadiusEnabled
    property int cfg_SearchBoxRadius
    property bool cfg_SearchWindows
    property bool cfg_SearchRecentFiles

    property var cfg_Options: []
    property var cfg_PowerOptionsOrder: []
    property bool cfg_Confirm
    property string cfg_SoftwareCenterCmd
    property string cfg_PowerDisplayStyle

    property var cfg_Order: []
    property var cfg_Hidden: []
    property string cfg_CustomNames
    property string cfg_CustomIcons
    property bool cfg_ShowEmpty
    property int cfg_PinnedCols
    property bool cfg_SyncWithPlasma
    property bool cfg_Enabled
    property int cfg_MaxItems
    property var cfg_RecentApps: []

    // ---- camelCase compatibility aliases ---------------------------------
    // Plasma hosts inject and read cfg_<key> using the lowercase-first names
    // from KConfigPropertyMap. Without these, injection silently fails and
    // a save-time read-back can wipe live-edited values back to defaults.
    property alias cfg_menuLayoutId: root.cfg_MenuLayoutId
    property alias cfg_flipHorizontal: root.cfg_FlipHorizontal
    property alias cfg_searchbarLocation: root.cfg_SearchbarLocation
    property alias cfg_searchbarLocationUserSet: root.cfg_SearchbarLocationUserSet
    property alias cfg_menuWidth: root.cfg_MenuWidth
    property alias cfg_menuHeight: root.cfg_MenuHeight
    property alias cfg_sidebarWidth: root.cfg_SidebarWidth
    property alias cfg_categoryColumnWidth: root.cfg_CategoryColumnWidth
    property alias cfg_leftPanelWidth: root.cfg_LeftPanelWidth
    property alias cfg_rightPanelWidth: root.cfg_RightPanelWidth
    property alias cfg_widthOffset: root.cfg_WidthOffset
    property alias cfg_layoutSizes: root.cfg_LayoutSizes
    property alias cfg_themeMode: root.cfg_ThemeMode
    property alias cfg_overrideMenuTheme: root.cfg_OverrideMenuTheme
    property alias cfg_menuThemeName: root.cfg_MenuThemeName
    property alias cfg_customThemes: root.cfg_CustomThemes
    property alias cfg_bgColor: root.cfg_BgColor
    property alias cfg_fgColor: root.cfg_FgColor
    property alias cfg_borderColor: root.cfg_BorderColor
    property alias cfg_borderWidth: root.cfg_BorderWidth
    property alias cfg_cornerRadius: root.cfg_CornerRadius
    property alias cfg_font: root.cfg_Font
    property alias cfg_fontSize: root.cfg_FontSize
    property alias cfg_separatorColor: root.cfg_SeparatorColor
    property alias cfg_hoverBg: root.cfg_HoverBg
    property alias cfg_hoverFg: root.cfg_HoverFg
    property alias cfg_activeBg: root.cfg_ActiveBg
    property alias cfg_activeFg: root.cfg_ActiveFg
    property alias cfg_selectedBg: root.cfg_SelectedBg
    property alias cfg_selectedFg: root.cfg_SelectedFg
    property alias cfg_categoryIconSize: root.cfg_CategoryIconSize
    property alias cfg_appIconSize: root.cfg_AppIconSize
    property alias cfg_followColorScheme: root.cfg_FollowColorScheme
    property alias cfg_overrideMenuPosition: root.cfg_OverrideMenuPosition
    property alias cfg_overrideMenuRise: root.cfg_OverrideMenuRise
    property alias cfg_menuRiseDistance: root.cfg_MenuRiseDistance
    property alias cfg_iconSizeGrid: root.cfg_IconSizeGrid
    property alias cfg_iconSizeApps: root.cfg_IconSizeApps
    property alias cfg_iconSizeShortcuts: root.cfg_IconSizeShortcuts
    property alias cfg_iconSizeCategories: root.cfg_IconSizeCategories
    property alias cfg_iconSizeButtons: root.cfg_IconSizeButtons
    property alias cfg_iconSizeOther: root.cfg_IconSizeOther
    property alias cfg_showCategorySubmenus: root.cfg_ShowCategorySubmenus
    property alias cfg_showAppDescriptions: root.cfg_ShowAppDescriptions
    property alias cfg_showGenericNames: root.cfg_ShowGenericNames
    property alias cfg_showHiddenRecentFiles: root.cfg_ShowHiddenRecentFiles
    property alias cfg_multiLineLabels: root.cfg_MultiLineLabels
    property alias cfg_showTooltips: root.cfg_ShowTooltips
    property alias cfg_groupAppsAlphabeticallyList: root.cfg_GroupAppsAlphabeticallyList
    property alias cfg_groupAppsAlphabeticallyGrid: root.cfg_GroupAppsAlphabeticallyGrid
    property alias cfg_activateExistingWindow: root.cfg_ActivateExistingWindow
    property alias cfg_keepOpenOnCtrlClick: root.cfg_KeepOpenOnCtrlClick
    property alias cfg_scrollviewFadeEffects: root.cfg_ScrollviewFadeEffects
    property alias cfg_showScrollbars: root.cfg_ShowScrollbars
    property alias cfg_overlayScrollbars: root.cfg_OverlayScrollbars
    property alias cfg_categoryIconType: root.cfg_CategoryIconType
    property alias cfg_shortcutIconType: root.cfg_ShortcutIconType
    property alias cfg_allAppsButtonAction: root.cfg_AllAppsButtonAction
    property alias cfg_showUserAvatar: root.cfg_ShowUserAvatar
    property alias cfg_avatarShape: root.cfg_AvatarShape
    property alias cfg_showVerticalSeparator: root.cfg_ShowVerticalSeparator
    property alias cfg_showExternalDevices: root.cfg_ShowExternalDevices
    property alias cfg_showBookmarks: root.cfg_ShowBookmarks
    property alias cfg_quickLinksOrder: root.cfg_QuickLinksOrder
    property alias cfg_quickLinksEnabled: root.cfg_QuickLinksEnabled
    property alias cfg_quickLinkPosition: root.cfg_QuickLinkPosition
    property alias cfg_pinnedApps: root.cfg_PinnedApps
    property alias cfg_directoryShortcuts: root.cfg_DirectoryShortcuts
    property alias cfg_placeSectionOrder: root.cfg_PlaceSectionOrder
    property alias cfg_systemPlaceOrder: root.cfg_SystemPlaceOrder
    property alias cfg_hiddenSystemPlaces: root.cfg_HiddenSystemPlaces
    property alias cfg_dolphinPlaceOrder: root.cfg_DolphinPlaceOrder
    property alias cfg_hiddenDolphinPlaces: root.cfg_HiddenDolphinPlaces
    property alias cfg_hiddenCustomPlaces: root.cfg_HiddenCustomPlaces
    property alias cfg_applicationShortcuts: root.cfg_ApplicationShortcuts
    property alias cfg_extraCategoriesOrder: root.cfg_ExtraCategoriesOrder
    property alias cfg_extraCategoriesEnabled: root.cfg_ExtraCategoriesEnabled
    property alias cfg_extraCategoriesUserSet: root.cfg_ExtraCategoriesUserSet
    property alias cfg_sidebarOrder: root.cfg_SidebarOrder
    property alias cfg_sidebarHidden: root.cfg_SidebarHidden
    property alias cfg_contextMenuItems: root.cfg_ContextMenuItems
    property alias cfg_customQuickLinks: root.cfg_CustomQuickLinks
    property alias cfg_customTypeGroups: root.cfg_CustomTypeGroups
    property alias cfg_customGroupApps: root.cfg_CustomGroupApps
    property alias cfg_groupViewOptions: root.cfg_GroupViewOptions
    property alias cfg_providers: root.cfg_Providers
    property alias cfg_placeholder: root.cfg_Placeholder
    property alias cfg_showDescription: root.cfg_ShowDescription
    property alias cfg_maxResults: root.cfg_MaxResults
    property alias cfg_hideSearchBar: root.cfg_HideSearchBar
    property alias cfg_highlightSearchTerms: root.cfg_HighlightSearchTerms
    property alias cfg_searchBoxRadiusEnabled: root.cfg_SearchBoxRadiusEnabled
    property alias cfg_searchBoxRadius: root.cfg_SearchBoxRadius
    property alias cfg_searchWindows: root.cfg_SearchWindows
    property alias cfg_searchRecentFiles: root.cfg_SearchRecentFiles
    property alias cfg_options: root.cfg_Options
    property alias cfg_powerOptionsOrder: root.cfg_PowerOptionsOrder
    property alias cfg_confirm: root.cfg_Confirm
    property alias cfg_softwareCenterCmd: root.cfg_SoftwareCenterCmd
    property alias cfg_powerDisplayStyle: root.cfg_PowerDisplayStyle
    property alias cfg_order: root.cfg_Order
    property alias cfg_hidden: root.cfg_Hidden
    property alias cfg_customNames: root.cfg_CustomNames
    property alias cfg_customIcons: root.cfg_CustomIcons
    property alias cfg_showEmpty: root.cfg_ShowEmpty
    property alias cfg_pinnedCols: root.cfg_PinnedCols
    property alias cfg_syncWithPlasma: root.cfg_SyncWithPlasma
    property alias cfg_enabled: root.cfg_Enabled
    property alias cfg_maxItems: root.cfg_MaxItems
    property alias cfg_recentApps: root.cfg_RecentApps

    readonly property var cfgKeys: [
        "MenuLayoutId", "FlipHorizontal", "SearchbarLocation", "SearchbarLocationUserSet", "MenuWidth", "MenuHeight", "LayoutSizes",
        "SidebarWidth", "CategoryColumnWidth", "LeftPanelWidth", "RightPanelWidth", "WidthOffset",
        "ThemeMode", "OverrideMenuTheme", "MenuThemeName", "CustomThemes",
        "BgColor", "FgColor", "BorderColor", "BorderWidth", "CornerRadius", "Font", "FontSize",
        "SeparatorColor", "HoverBg", "HoverFg", "ActiveBg", "ActiveFg", "SelectedBg", "SelectedFg",
        "CategoryIconSize", "AppIconSize", "FollowColorScheme",
        "OverrideMenuPosition", "OverrideMenuRise", "MenuRiseDistance",
        "IconSizeGrid", "IconSizeApps", "IconSizeShortcuts", "IconSizeCategories",
        "IconSizeButtons", "IconSizeOther",
        "ShowCategorySubmenus", "ShowAppDescriptions", "ShowGenericNames", "ShowHiddenRecentFiles",
        "MultiLineLabels", "ShowTooltips", "GroupAppsAlphabeticallyList", "GroupAppsAlphabeticallyGrid",
        "ActivateExistingWindow", "KeepOpenOnCtrlClick", "ScrollviewFadeEffects",
        "ShowScrollbars", "OverlayScrollbars", "CategoryIconType", "ShortcutIconType",
        "AllAppsButtonAction", "ShowUserAvatar", "AvatarShape", "ShowVerticalSeparator",
        "ShowExternalDevices", "ShowBookmarks", "QuickLinksOrder", "QuickLinksEnabled", "QuickLinkPosition",
        "PinnedApps", "DirectoryShortcuts", "PlaceSectionOrder", "SystemPlaceOrder",
        "HiddenSystemPlaces", "DolphinPlaceOrder", "HiddenDolphinPlaces", "HiddenCustomPlaces", "ApplicationShortcuts",
        "ExtraCategoriesOrder", "ExtraCategoriesEnabled", "ExtraCategoriesUserSet",
        "SidebarOrder", "SidebarHidden", "ContextMenuItems",
        "CustomQuickLinks", "CustomTypeGroups", "CustomGroupApps", "GroupViewOptions",
        "Providers", "Placeholder", "ShowDescription", "MaxResults", "HideSearchBar",
        "HighlightSearchTerms", "SearchBoxRadiusEnabled", "SearchBoxRadius",
        "SearchWindows", "SearchRecentFiles",
        "Options", "PowerOptionsOrder", "Confirm", "SoftwareCenterCmd", "PowerDisplayStyle",
        "Order", "Hidden", "CustomNames", "CustomIcons", "ShowEmpty", "PinnedCols",
        "SyncWithPlasma", "Enabled", "MaxItems", "RecentApps"
    ]

    property string subpageTitle: ""

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function cfgName(key) { return "cfg_" + key; }

    /** kcfg entries are PascalCase in main.xml but plasmoid.configuration
     *  exposes camelCase properties; try camelCase first, then the raw key. */
    function liveValue(key) {
        try {
            var camel = key.charAt(0).toLowerCase() + key.slice(1);
            var v = plasmoid.configuration[camel];
            if (v !== undefined && v !== null)
                return v;
        } catch (e) {}
        try { return plasmoid.configuration[key]; } catch (e) { return undefined; }
    }

    /** Pull the live config into the cfg_* mirrors of an item. */
    function syncFromLive(toItem) {
        if (!toItem)
            return;
        for (var i = 0; i < cfgKeys.length; ++i) {
            var ck = cfgName(cfgKeys[i]);
            if (!(ck in toItem))
                continue;
            var v = liveValue(cfgKeys[i]);
            if (v !== undefined)
                toItem[ck] = v;
        }
    }

    /** Called by Plasma AppletConfiguration before reading root cfg_*. All edits
     *  are already live-written, so just re-pull the live config: the following
     *  cfg->config write-back becomes a value-identical no-op, and the root
     *  cfg_* mirrors never change while the page is open (no dirty re-eval). */
    function saveConfig() {
        console.log("ArcMenu saveConfig: re-syncing root mirrors from live config (no stale write-back)");
        syncFromLive(root);
    }

    /** Keys each subpage actually declares (auto-scanned at patch time).
     *  Only these get pushed as initial properties; pushing all 96 keys
     *  spammed "Cannot assign to non-existent property" errors per open. */
    readonly property var subPageKeys: ({
        "ConfigLayout": ["MenuLayoutId", "FlipHorizontal", "SearchbarLocation", "SearchbarLocationUserSet", "MenuWidth", "MenuHeight", "SidebarWidth", "CategoryColumnWidth", "LeftPanelWidth", "RightPanelWidth", "WidthOffset", "LayoutSizes"],
        "ConfigTheme": ["ThemeMode", "OverrideMenuTheme", "MenuThemeName", "CustomThemes", "BgColor", "FgColor", "BorderColor", "BorderWidth", "CornerRadius", "Font", "FontSize", "SeparatorColor", "HoverBg", "HoverFg", "ActiveBg", "ActiveFg", "SelectedBg", "SelectedFg", "CategoryIconSize", "AppIconSize", "FollowColorScheme"],
        "ConfigVisual": ["OverrideMenuPosition", "OverrideMenuRise", "MenuRiseDistance", "IconSizeGrid", "IconSizeApps", "IconSizeShortcuts", "IconSizeCategories", "IconSizeButtons", "IconSizeOther"],
        "ConfigFineTune": ["ShowCategorySubmenus", "ShowAppDescriptions", "ShowGenericNames", "ShowHiddenRecentFiles", "MultiLineLabels", "ShowTooltips", "GroupAppsAlphabeticallyList", "GroupAppsAlphabeticallyGrid", "ActivateExistingWindow", "KeepOpenOnCtrlClick", "ScrollviewFadeEffects", "ShowScrollbars", "OverlayScrollbars", "CategoryIconType", "ShortcutIconType"],
        "ConfigArcLayout": ["AllAppsButtonAction", "ShowUserAvatar", "AvatarShape", "SearchbarLocation", "SearchbarLocationUserSet", "FlipHorizontal", "ShowVerticalSeparator", "ShowExternalDevices", "ShowBookmarks", "QuickLinksOrder", "QuickLinksEnabled", "QuickLinkPosition", "CustomQuickLinks", "CustomGroupApps"],
        "ConfigDirectoryShortcuts": ["DirectoryShortcuts", "PlaceSectionOrder", "SystemPlaceOrder", "HiddenSystemPlaces", "DolphinPlaceOrder", "HiddenDolphinPlaces", "HiddenCustomPlaces"],
        "ConfigAppShortcuts": ["ApplicationShortcuts"],
        "ConfigSearch": ["Providers", "Placeholder", "ShowDescription", "MaxResults", "HideSearchBar", "HighlightSearchTerms", "SearchBoxRadiusEnabled", "SearchBoxRadius", "SearchWindows", "SearchRecentFiles"],
        "ConfigPower": ["Options", "PowerOptionsOrder", "Confirm", "SoftwareCenterCmd", "PowerDisplayStyle"],
        "ConfigExtraCategories": ["ExtraCategoriesOrder", "ExtraCategoriesEnabled", "ExtraCategoriesUserSet", "SidebarOrder", "SidebarHidden", "CustomQuickLinks", "CustomTypeGroups", "CustomGroupApps", "GroupViewOptions", "PinnedApps", "Order", "Hidden", "CustomNames", "CustomIcons", "ShowEmpty", "Enabled", "MaxItems", "RecentApps"]
    })

    function subPageKeyFor(component) {
        if (component === pageLayout) return "ConfigLayout";
        if (component === pageTheme) return "ConfigTheme";
        if (component === pageVisual) return "ConfigVisual";
        if (component === pageFineTune) return "ConfigFineTune";
        if (component === pageArcLayout) return "ConfigArcLayout";
        if (component === pageDirs) return "ConfigDirectoryShortcuts";
        if (component === pageApps) return "ConfigAppShortcuts";
        if (component === pageSearch) return "ConfigSearch";
        if (component === pagePower) return "ConfigPower";
        if (component === pageExtra) return "ConfigExtraCategories";
        return "";
    }

    function openSubPage(component, title) {
        subpageTitle = title || "";
        // Initialize the subpage straight from the live config -- the root
        // mirrors are not the source of truth anymore (they must stay frozen).
        var key = subPageKeyFor(component);
        var allowed = subPageKeys[key] || cfgKeys;
        var props = {};
        for (var i = 0; i < allowed.length; ++i) {
            var v = liveValue(allowed[i]);
            if (v !== undefined)
                props[cfgName(allowed[i])] = v;
        }
        console.log("ArcMenu openSubPage", key || "<unknown>", "injecting", Object.keys(props).length, "props");
        var page = stack.push(component, props);
        if (page) {
            page.width = Qt.binding(function () { return stack.width; });
            page.height = Qt.binding(function () { return stack.height; });
            if (typeof page.rebuildModel === "function")
                page.rebuildModel();
        }
    }

    function goBack() {
        if (stack.depth <= 1)
            return;
        // Subpage edits are live-written to plasmoid.configuration already --
        // nothing to propagate back into the root cfg_* mirrors.
        stack.pop();
        subpageTitle = "";
    }

    /**
     * Hub row — 图3 style: tinted icon badge + title/subtitle + chevron.
     * accent: hue key used to tint the badge (blue/purple/green/…).
     */
    component NavRow: Item {
        id: nav
        property string title: ""
        property string subtitle: ""
        property string iconName: "configure"
        property string accent: "blue"
        signal activated()

        Layout.fillWidth: true
        implicitHeight: Math.max(Kirigami.Units.gridUnit * 3.2,
                                 row.implicitHeight + Kirigami.Units.largeSpacing)

        readonly property color accentColor: {
            switch (nav.accent) {
            case "purple": return "#8B5CF6";
            case "green": return "#22C55E";
            case "orange": return "#F59E0B";
            case "pink": return "#EC4899";
            case "teal": return "#14B8A6";
            case "red": return "#EF4444";
            case "cyan": return "#06B6D4";
            case "indigo": return "#6366F1";
            default: return Kirigami.Theme.highlightColor;
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Kirigami.Units.smallSpacing
            color: navMouse.containsMouse
                ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                          Kirigami.Theme.highlightColor.b, 0.12)
                : "transparent"
        }

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // Colored badge (图3)
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.1
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.1
                Layout.alignment: Qt.AlignVCenter
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(nav.accentColor.r, nav.accentColor.g, nav.accentColor.b, 0.22)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: width
                    source: nav.iconName
                    color: nav.accentColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3
                QQC2.Label {
                    text: nav.title
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.weight: Font.Medium
                }
                QQC2.Label {
                    visible: nav.subtitle.length > 0
                    text: nav.subtitle
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.55
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            Kirigami.Icon {
                source: "go-next-symbolic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                Layout.alignment: Qt.AlignVCenter
                opacity: 0.4
            }
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.activated()
        }
        Accessible.role: Accessible.Button
        Accessible.name: nav.title
        Accessible.onPressAction: nav.activated()
    }

    component NavSep: Kirigami.Separator {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.gridUnit * 3.5
        opacity: 0.12
    }

    /** Section: title + card of rows (图3 启动/界面/性能 blocks) */
    component NavGroup: ColumnLayout {
        id: group
        property string title: ""
        default property alias content: body.data
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            text: group.title
            font.weight: Font.DemiBold
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
            opacity: 0.9
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.leftMargin: Kirigami.Units.smallSpacing / 2
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: bodyCol.implicitHeight + Kirigami.Units.smallSpacing
            radius: Kirigami.Units.largeSpacing
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g,
                           Kirigami.Theme.backgroundColor.b, 0.55)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                  Kirigami.Theme.textColor.b, 0.08)

            // Slight lift vs page background
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, 0.04)
            }

            ColumnLayout {
                id: bodyCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                ColumnLayout {
                    id: body
                    Layout.fillWidth: true
                    spacing: 0
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: stack.depth > 1 ? Kirigami.Units.gridUnit * 2.2 : 0
            visible: stack.depth > 1
            spacing: Kirigami.Units.smallSpacing

            QQC2.ToolButton {
                icon.name: "go-previous"
                text: root.tr("Back")
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: root.goBack()
            }
            QQC2.Label {
                text: root.subpageTitle
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: stack.depth > 1
        }

        QQC2.StackView {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            initialItem: hubPage
        }
    }

    Component {
        id: hubPage
        Flickable {
            contentWidth: width
            contentHeight: hubCol.height + Kirigami.Units.largeSpacing * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: hubCol
                x: Kirigami.Units.largeSpacing
                width: Math.max(0, parent.width - Kirigami.Units.largeSpacing * 2)
                spacing: Kirigami.Units.largeSpacing

                // Page title (图3)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        text: root.tr("Menu settings")
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.35
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }
                }

                // Tip banner (图3)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: tipRow.implicitHeight + Kirigami.Units.largeSpacing
                    radius: Kirigami.Units.smallSpacing
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                                   Kirigami.Theme.highlightColor.b, 0.14)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                                          Kirigami.Theme.highlightColor.b, 0.28)

                    RowLayout {
                        id: tipRow
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            source: "help-hint"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            color: Kirigami.Theme.highlightColor
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: root.tr("Open a section to edit settings. Changes are applied immediately.")
                            opacity: 0.9
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }
                }

                NavGroup {
                    title: root.tr("What should show on the menu?")
                    NavRow {
                        title: root.tr("Menu Layout")
                        subtitle: root.tr("Choose a layout style for the menu")
                        iconName: "view-grid-symbolic"
                        accent: "blue"
                        onActivated: root.openSubPage(pageLayout, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Frequent Locations")
                        subtitle: root.tr("Folders and files on the left sidebar")
                        iconName: "folder-favorites"
                        accent: "cyan"
                        onActivated: root.openSubPage(pageDirs, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Application Shortcuts")
                        subtitle: root.tr("Apps and custom commands on the left sidebar")
                        iconName: "applications-all-symbolic"
                        accent: "green"
                        onActivated: root.openSubPage(pageApps, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Search Options")
                        subtitle: root.tr("Providers, highlight, and result limits")
                        iconName: "search-symbolic"
                        accent: "blue"
                        onActivated: root.openSubPage(pageSearch, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Menu Groups")
                        subtitle: root.tr("Preference groups and type groups")
                        iconName: "view-list-details-symbolic"
                        accent: "purple"
                        onActivated: root.openSubPage(pageExtra, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("ArcMenu layout adjustment")
                        subtitle: root.tr("Settings specific to the current menu layout")
                        iconName: "settings-configure-symbolic"
                        accent: "indigo"
                        onActivated: root.openSubPage(pageArcLayout, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Power Options")
                        subtitle: root.tr("Select power options and display style")
                        iconName: "system-shutdown-symbolic"
                        accent: "red"
                        onActivated: root.openSubPage(pagePower, title)
                    }
                }

                NavGroup {
                    title: root.tr("How should the menu look?")
                    NavRow {
                        title: root.tr("Menu Theme")
                        subtitle: root.tr("Modify menu colors, font size, and border")
                        iconName: "preferences-desktop-theme-symbolic"
                        accent: "purple"
                        onActivated: root.openSubPage(pageTheme, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Menu Visual Appearance")
                        subtitle: root.tr("Menu position and icon sizes")
                        iconName: "preferences-desktop-display-symbolic"
                        accent: "teal"
                        onActivated: root.openSubPage(pageVisual, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Fine-tuning")
                        subtitle: root.tr("Adjust less commonly used settings")
                        iconName: "preferences-other-symbolic"
                        accent: "orange"
                        onActivated: root.openSubPage(pageFineTune, title)
                    }
                }

                Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
            }
        }
    }

    Component { id: pageLayout; ConfigLayout {} }
    Component { id: pageTheme; ConfigTheme {} }
    Component { id: pageVisual; ConfigVisual {} }
    Component { id: pageFineTune; ConfigFineTune {} }
    Component { id: pageArcLayout; ConfigArcLayout {} }
    Component { id: pageDirs; ConfigDirectoryShortcuts {} }
    Component { id: pageApps; ConfigAppShortcuts {} }
    Component { id: pageSearch; ConfigSearch {} }
    Component { id: pagePower; ConfigPower {} }
    Component { id: pageExtra; ConfigExtraCategories {} }

    Component.onCompleted: {
        // Never leave Extra Categories as [] before Plasma injects — that made
        // Apply / subpage sync wipe pinned+all-apps while the menu still showed defaults.
        if (!cfg_ExtraCategoriesOrder || !cfg_ExtraCategoriesOrder.length)
            cfg_ExtraCategoriesOrder = SC.DEFAULT_EXTRA_ORDER.slice();
        if (!cfg_ExtraCategoriesUserSet) {
            cfg_ExtraCategoriesEnabled = SC.DEFAULT_EXTRA_ON.slice();
        } else if (cfg_ExtraCategoriesEnabled === undefined || cfg_ExtraCategoriesEnabled === null) {
            cfg_ExtraCategoriesEnabled = SC.DEFAULT_EXTRA_ON.slice();
        }
    }
}
