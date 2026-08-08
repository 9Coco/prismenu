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
 * subpage keys and sync them when entering/leaving a subpage / on saveConfig().
 */
Item {
    id: root

    // —— cfg_* mirror (union of Menu subpages; Plasma injects values on load) ——
    property string cfg_MenuLayoutId
    property bool cfg_FlipHorizontal
    property string cfg_SearchbarLocation
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
    property var cfg_ApplicationShortcuts: []
    property var cfg_ExtraCategoriesOrder
    property var cfg_ExtraCategoriesEnabled
    property bool cfg_ExtraCategoriesUserSet: false
    property var cfg_ContextMenuItems: []

    property var cfg_Providers: ["applications"]
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

    readonly property var cfgKeys: [
        "MenuLayoutId", "FlipHorizontal", "SearchbarLocation", "MenuWidth", "MenuHeight",
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
        "PinnedApps", "DirectoryShortcuts", "ApplicationShortcuts",
        "ExtraCategoriesOrder", "ExtraCategoriesEnabled", "ExtraCategoriesUserSet", "ContextMenuItems",
        "Providers", "Placeholder", "ShowDescription", "MaxResults", "HideSearchBar",
        "HighlightSearchTerms", "SearchBoxRadiusEnabled", "SearchBoxRadius",
        "SearchWindows", "SearchRecentFiles",
        "Options", "PowerOptionsOrder", "Confirm", "SoftwareCenterCmd", "PowerDisplayStyle",
        "Order", "Hidden", "CustomNames", "CustomIcons", "ShowEmpty", "PinnedCols",
        "SyncWithPlasma", "Enabled", "MaxItems", "RecentApps"
    ]

    property string subpageTitle: ""
    property bool unsavedChanges: false
    signal configurationChanged()

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function cfgName(key) { return "cfg_" + key; }

    function syncCfg(fromItem, toItem) {
        if (!fromItem || !toItem)
            return;
        for (var i = 0; i < cfgKeys.length; ++i) {
            var ck = cfgName(cfgKeys[i]);
            if (!(ck in fromItem) || !(ck in toItem))
                continue;
            try {
                var v = fromItem[ck];
                if (toItem[ck] !== v)
                    toItem[ck] = v;
            } catch (e) {}
        }
    }

    function pageDiffersFromConfig(page) {
        if (!page)
            return false;
        var config = plasmoid.configuration;
        for (var i = 0; i < cfgKeys.length; ++i) {
            var key = cfgKeys[i];
            var ck = cfgName(key);
            if (!(ck in page))
                continue;
            try {
                var a = page[ck];
                var b = config[key];
                if (a === b)
                    continue;
                if (String(a) !== String(b))
                    return true;
            } catch (e) {}
        }
        return false;
    }

    function refreshUnsaved() {
        var dirty = false;
        if (stack.depth > 1)
            dirty = pageDiffersFromConfig(stack.currentItem);
        else
            dirty = pageDiffersFromConfig(root);
        if (unsavedChanges !== dirty)
            unsavedChanges = dirty;
        if (dirty)
            configurationChanged();
    }

    /** Called by Plasma AppletConfiguration before reading root cfg_*. */
    function saveConfig() {
        if (stack.depth > 1)
            syncCfg(stack.currentItem, root);
    }

    function openSubPage(component, title) {
        if (stack.depth > 1)
            syncCfg(stack.currentItem, root);
        subpageTitle = title || "";
        var page = stack.push(component);
        if (page) {
            page.width = Qt.binding(function () { return stack.width; });
            page.height = Qt.binding(function () { return stack.height; });
            syncCfg(root, page);
            if (typeof page.rebuildModel === "function")
                page.rebuildModel();
        }
        refreshUnsaved();
    }

    function goBack() {
        if (stack.depth <= 1)
            return;
        syncCfg(stack.currentItem, root);
        stack.pop();
        subpageTitle = "";
        refreshUnsaved();
    }

    Timer {
        id: dirtyPoll
        interval: 280
        repeat: true
        running: stack.depth > 1
        onTriggered: {
            if (stack.depth > 1)
                syncCfg(stack.currentItem, root);
            refreshUnsaved();
        }
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
                            text: root.tr("Open a section to edit settings. Click Apply in the dialog footer to save.")
                            opacity: 0.9
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }
                }

                NavGroup {
                    title: root.tr("How should the menu look?")
                    NavRow {
                        title: root.tr("Menu Layout")
                        subtitle: root.tr("Choose a layout style for the menu")
                        iconName: "view-grid-symbolic"
                        accent: "blue"
                        onActivated: root.openSubPage(pageLayout, title)
                    }
                    NavSep {}
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
                        subtitle: root.tr("Change menu height, width, location, and icon sizes")
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

                NavGroup {
                    title: root.tr("What should show on the menu?")
                    NavRow {
                        title: root.tr("ArcMenu layout adjustment")
                        subtitle: root.tr("Settings specific to the current menu layout")
                        iconName: "settings-configure-symbolic"
                        accent: "indigo"
                        onActivated: root.openSubPage(pageArcLayout, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Pinned Applications")
                        subtitle: root.tr("Reorder and manage pinned apps")
                        iconName: "pin"
                        accent: "pink"
                        onActivated: root.openSubPage(pagePinned, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Directory Shortcuts")
                        subtitle: root.tr("Folders shown in the places sidebar")
                        iconName: "folder-symbolic"
                        accent: "cyan"
                        onActivated: root.openSubPage(pageDirs, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Application Shortcuts")
                        subtitle: root.tr("Shortcuts shown under places")
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
                        title: root.tr("Power Options")
                        subtitle: root.tr("Select power options and display style")
                        iconName: "system-shutdown-symbolic"
                        accent: "red"
                        onActivated: root.openSubPage(pagePower, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Extra Categories")
                        subtitle: root.tr("Add or remove other custom categories")
                        iconName: "view-list-details-symbolic"
                        accent: "purple"
                        onActivated: root.openSubPage(pageExtra, title)
                    }
                    NavSep {}
                    NavRow {
                        title: root.tr("Menu Content")
                        subtitle: root.tr("Category order, visibility, and recent apps")
                        iconName: "view-catalog-symbolic"
                        accent: "teal"
                        onActivated: root.openSubPage(pageContent, title)
                    }
                }

                NavGroup {
                    title: root.tr("What should show on the context menu?")
                    NavRow {
                        title: root.tr("Modify ArcMenu Context Menu")
                        subtitle: root.tr("Actions shown when right-clicking an app")
                        iconName: "open-menu-symbolic"
                        accent: "orange"
                        onActivated: root.openSubPage(pageContext, title)
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
    Component { id: pagePinned; ConfigPinned {} }
    Component { id: pageDirs; ConfigDirectoryShortcuts {} }
    Component { id: pageApps; ConfigAppShortcuts {} }
    Component { id: pageSearch; ConfigSearch {} }
    Component { id: pagePower; ConfigPower {} }
    Component { id: pageExtra; ConfigExtraCategories {} }
    Component { id: pageContent; ConfigContent {} }
    Component { id: pageContext; ConfigContextMenu {} }

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
