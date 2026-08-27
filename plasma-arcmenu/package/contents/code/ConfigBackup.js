.pragma library

/**
 * Export / import Arc Menu plasmoid configuration as JSON.
 * Keys match the PascalCase entry names from contents/config/main.xml
 * (plasmoid.configuration property access is case-sensitive).
 */

var FORMAT_ID = "org.kde.plasma.arcmenu.config";
var FORMAT_VERSION = 1;

var CONFIG_KEYS = [
    "ActivateExistingWindow",
    "ActiveBg",
    "ActiveFg",
    "AllAppsButtonAction",
    "AppIconSize",
    "ApplicationShortcuts",
    "AvatarShape",
    "BgColor",
    "BorderColor",
    "BorderWidth",
    "ButtonIcon",
    "ButtonLabelText",
    "ButtonLabelVisible",
    "ButtonStyleActiveBg",
    "ButtonStyleActiveBgEnabled",
    "ButtonStyleActiveFg",
    "ButtonStyleActiveFgEnabled",
    "ButtonStyleBg",
    "ButtonStyleBgEnabled",
    "ButtonStyleBorderColor",
    "ButtonStyleBorderColorEnabled",
    "ButtonStyleBorderWidth",
    "ButtonStyleBorderWidthEnabled",
    "ButtonStyleFg",
    "ButtonStyleFgEnabled",
    "ButtonStyleHoverBg",
    "ButtonStyleHoverBgEnabled",
    "ButtonStyleHoverFg",
    "ButtonStyleHoverFgEnabled",
    "ButtonStyleRadius",
    "ButtonStyleRadiusEnabled",
    "CategoryColumnWidth",
    "CategoryIconSize",
    "CategoryIconType",
    "Confirm",
    "ContextMenuItems",
    "CornerRadius",
    "CustomButtonIcon",
    "CustomGroupApps",
    "GroupViewOptions",
    "CustomIcons",
    "CustomNames",
    "CustomQuickLinks",
    "CustomTypeGroups",
    "CustomThemes",
    "DirectoryShortcuts",
    "PlaceSectionOrder",
    "SystemPlaceOrder",
    "HiddenSystemPlaces",
    "DolphinPlaceOrder",
    "HiddenDolphinPlaces",
    "HiddenCustomPlaces",
    "Enabled",
    "ExtraCategoriesEnabled",
    "ExtraCategoriesOrder",
    "ExtraCategoriesUserSet",
    "SidebarOrder",
    "SidebarHidden",
    "FgColor",
    "FilterByActivity",
    "FlipHorizontal",
    "FollowColorScheme",
    "Font",
    "FontSize",
    "GroupAppsAlphabeticallyGrid",
    "GroupAppsAlphabeticallyList",
    "Hidden",
    "HideSearchBar",
    "HighlightSearchTerms",
    "HoverBg",
    "HoverFg",
    "IconSizeApps",
    "IconSizeButtons",
    "IconSizeCategories",
    "IconSizeGrid",
    "IconSizeOther",
    "IconSizeShortcuts",
    "KeepOpenOnCtrlClick",
    "LeftClickAction",
    "LeftPanelWidth",
    "MaxItems",
    "MaxResults",
    "MenuButtonAppearance",
    "LayoutSizes",
    "MenuHeight",
    "MenuHotkey",
    "MenuLayoutId",
    "MenuRiseDistance",
    "MenuThemeName",
    "MenuWidth",
    "MiddleClickAction",
    "MultiLineLabels",
    "Options",
    "Order",
    "OverlayScrollbars",
    "OverrideMenuPosition",
    "OverrideMenuRise",
    "OverrideMenuTheme",
    "PanelButtonIconSize",
    "PanelButtonPadding",
    "PanelButtonPositionOffset",
    "PinnedApps",
    "PinnedCols",
    "Placeholder",
    "PopupAnimation",
    "PowerDisplayStyle",
    "PowerOptionsOrder",
    "Providers",
    "QuickLinkPosition",
    "QuickLinksEnabled",
    "QuickLinksOrder",
    "RecentApps",
    "RightClickAction",
    "RightPanelWidth",
    "ScrollviewFadeEffects",
    "SearchbarLocation",
    "SearchbarLocationUserSet",
    "SearchBoxRadius",
    "SearchBoxRadiusEnabled",
    "SearchRecentFiles",
    "SearchWindows",
    "SelectedBg",
    "SelectedFg",
    "SeparatorColor",
    "ShareConfigAcrossInstances",
    "ShortcutIconType",
    "ShowAppDescriptions",
    "ShowBookmarks",
    "ShowCategorySubmenus",
    "ShowDescription",
    "ShowEmpty",
    "ShowExternalDevices",
    "ShowGenericNames",
    "ShowHiddenRecentFiles",
    "ShowScrollbars",
    "ShowTooltips",
    "ShowUserAvatar",
    "ShowVerticalSeparator",
    "SidebarWidth",
    "SoftwareCenterCmd",
    "SyncWithPlasma",
    "ThemeMode",
    "UiLanguage",
    "widthOffset"
];

/**
 * Schema defaults mirrored from contents/config/main.xml
 * (camelCase plasmoid.configuration keys).
 */
var CONFIG_DEFAULTS = {
    // General
    buttonIcon: "auto-distro",
    customButtonIcon: "",
    buttonLabelVisible: false,
    buttonLabelText: "Applications",
    menuButtonAppearance: "icon",
    panelButtonPositionOffset: 0,
    menuHotkey: "Meta",
    popupAnimation: "expand",
    shareConfigAcrossInstances: true,
    filterByActivity: false,
    uiLanguage: "zh_CN",
    panelButtonIconSize: 20,
    panelButtonPadding: -1,
    leftClickAction: "arcmenu",
    rightClickAction: "context",
    middleClickAction: "arcmenu",
    buttonStyleFgEnabled: false,
    buttonStyleFg: "",
    buttonStyleBgEnabled: false,
    buttonStyleBg: "",
    buttonStyleHoverBgEnabled: false,
    buttonStyleHoverBg: "",
    buttonStyleHoverFgEnabled: false,
    buttonStyleHoverFg: "",
    buttonStyleActiveBgEnabled: false,
    buttonStyleActiveBg: "",
    buttonStyleActiveFgEnabled: false,
    buttonStyleActiveFg: "",
    buttonStyleRadiusEnabled: false,
    buttonStyleRadius: 20,
    buttonStyleBorderWidthEnabled: false,
    buttonStyleBorderWidth: 3,
    buttonStyleBorderColorEnabled: false,
    buttonStyleBorderColor: "",
    // Layout
    menuLayoutId: "arcmenu",
    flipHorizontal: false,
    searchbarLocation: "bottom",
    searchbarLocationUserSet: false,
    allAppsButtonAction: "category-list",
    showUserAvatar: true,
    avatarShape: "circle",
    showVerticalSeparator: false,
    showExternalDevices: false,
    showBookmarks: true,
    quickLinksOrder: ["frequent", "all-apps", "pinned", "recent-files"],
    quickLinksEnabled: [],
    quickLinkPosition: "bottom",
    menuWidth: 620,
    menuHeight: 540,
    layoutSizes: "{}",
    sidebarWidth: 220,
    categoryColumnWidth: 220,
    leftPanelWidth: 380,
    rightPanelWidth: 220,
    widthOffset: 0,
    overrideMenuPosition: "off",
    overrideMenuRise: false,
    menuRiseDistance: 6,
    iconSizeGrid: -1,
    iconSizeApps: -1,
    iconSizeShortcuts: -1,
    iconSizeCategories: -1,
    iconSizeButtons: -1,
    iconSizeOther: -1,
    // Theme
    themeMode: "system",
    overrideMenuTheme: false,
    menuThemeName: "ArcMenu Style",
    customThemes: "[]",
    bgColor: "",
    fgColor: "",
    borderColor: "",
    borderWidth: 1,
    cornerRadius: -1,
    font: "",
    fontSize: -1,
    separatorColor: "",
    hoverBg: "",
    hoverFg: "",
    activeBg: "",
    activeFg: "",
    selectedBg: "",
    selectedFg: "",
    categoryIconSize: 24,
    appIconSize: 24,
    followColorScheme: true,
    // Favorites
    pinnedApps: ["org.kde.dolphin.desktop"],
    pinnedCols: 6,
    syncWithPlasma: true,
    // Recent
    enabled: true,
    maxItems: 5,
    recentApps: [],
    // Categories
    order: [],
    hidden: [],
    customNames: "{}",
    customIcons: "{}",
    showEmpty: true,
    // Shortcuts
    directoryShortcuts: ["HOME", "DOCUMENTS", "DOWNLOAD", "MUSIC", "PICTURES", "VIDEOS"],
    applicationShortcuts: ["discover", "settings", "tweaks"],
    extraCategoriesOrder: ["pinned", "all-apps", "frequent", "recent-files"],
    extraCategoriesEnabled: ["pinned", "all-apps"],
    extraCategoriesUserSet: false,
    sidebarOrder: [],
    sidebarHidden: [],
    contextMenuItems: ["configure", "separator", "power", "overview", "show-desktop"],
    customQuickLinks: [],
    customTypeGroups: [],
    customGroupApps: "{}",
    groupViewOptions: "{}",
    // Search
    providers: ["applications", "places", "files"],
    placeholder: "Search…",
    showDescription: true,
    maxResults: 5,
    hideSearchBar: false,
    highlightSearchTerms: true,
    searchBoxRadiusEnabled: true,
    searchBoxRadius: 25,
    searchWindows: true,
    searchRecentFiles: false,
    // FineTune
    showCategorySubmenus: false,
    showAppDescriptions: false,
    showGenericNames: false,
    showHiddenRecentFiles: false,
    multiLineLabels: true,
    showTooltips: true,
    groupAppsAlphabeticallyList: true,
    groupAppsAlphabeticallyGrid: false,
    activateExistingWindow: false,
    keepOpenOnCtrlClick: true,
    scrollviewFadeEffects: true,
    showScrollbars: true,
    overlayScrollbars: true,
    categoryIconType: "symbolic",
    shortcutIconType: "symbolic",
    // Power
    options: ["logout", "lock", "restart", "shutdown"],
    powerOptionsOrder: ["logout", "lock", "restart", "shutdown", "suspend", "hybridsleep", "hibernate", "switchuser"],
    confirm: true,
    softwareCenterCmd: "auto-detect",
    powerDisplayStyle: "off"
};

/** Restore every known setting to its main.xml default. Returns count. */
function resetToDefaults(config) {
    if (!config)
        return 0;
    var applied = 0;
    for (var key in CONFIG_DEFAULTS) {
        if (!Object.prototype.hasOwnProperty.call(CONFIG_DEFAULTS, key))
            continue;
        try {
            config[key] = cloneValue(CONFIG_DEFAULTS[key]);
            applied++;
        } catch (e) {}
    }
    return applied;
}

function cloneValue(v) {
    if (v === undefined || v === null)
        return v;
    if (typeof v === "object") {
        try {
            return JSON.parse(JSON.stringify(v));
        } catch (e) {
            return v;
        }
    }
    return v;
}

function collect(config) {
    var settings = {};
    if (!config)
        return settings;
    for (var i = 0; i < CONFIG_KEYS.length; ++i) {
        var key = CONFIG_KEYS[i];
        try {
            var val = config[key];
            if (val === undefined)
                continue;
            settings[key] = cloneValue(val);
        } catch (e) {}
    }
    return settings;
}

function buildExportObject(config) {
    return {
        format: FORMAT_ID,
        version: FORMAT_VERSION,
        exportedAt: new Date().toISOString(),
        settings: collect(config)
    };
}

function stringifyExport(config) {
    return JSON.stringify(buildExportObject(config), null, 2);
}

function parseImportText(text) {
    var raw = JSON.parse(String(text || ""));
    if (!raw || typeof raw !== "object")
        throw new Error("Invalid JSON object");
    var settings = raw.settings;
    if (!settings || typeof settings !== "object") {
        // Allow a bare settings map for convenience
        if (raw.format || raw.version)
            throw new Error("Missing settings object");
        settings = raw;
    }
    return {
        format: raw.format || "",
        version: raw.version || 0,
        settings: settings
    };
}

function applySettings(config, settings) {
    if (!config || !settings)
        return 0;
    var applied = 0;
    for (var i = 0; i < CONFIG_KEYS.length; ++i) {
        var key = CONFIG_KEYS[i];
        if (!Object.prototype.hasOwnProperty.call(settings, key))
            continue;
        try {
            config[key] = cloneValue(settings[key]);
            applied++;
        } catch (e) {}
    }
    return applied;
}

/** UTF-8 string → lowercase hex (for safe shell transport). */
function utf8ToHex(str) {
    var utf8 = unescape(encodeURIComponent(String(str)));
    var hex = "";
    for (var i = 0; i < utf8.length; ++i) {
        var h = utf8.charCodeAt(i).toString(16);
        hex += (h.length < 2 ? "0" : "") + h;
    }
    return hex;
}

function shellSingleQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
}

/** bash -lc payload: write UTF-8 file from hex. */
function writeFileCommand(path, text) {
    var hex = utf8ToHex(text);
    var py = "import pathlib,binascii; pathlib.Path("
        + JSON.stringify(path)
        + ").write_bytes(binascii.unhexlify("
        + JSON.stringify(hex)
        + "))";
    return "/bin/bash -lc " + shellSingleQuote("python3 -c " + shellSingleQuote(py));
}

/** bash -lc payload: print file contents to stdout with marker. */
function readFileCommand(path) {
    var py = "import pathlib,sys; sys.stdout.write('ARCMENU_CFG_JSON_BEGIN\\n'); sys.stdout.write(pathlib.Path("
        + JSON.stringify(path)
        + ").read_text(encoding='utf-8')); sys.stdout.write('\\nARCMENU_CFG_JSON_END\\n')";
    return "/bin/bash -lc " + shellSingleQuote("python3 -c " + shellSingleQuote(py));
}

function extractJsonFromStdout(stdout) {
    var out = String(stdout || "");
    var begin = out.indexOf("ARCMENU_CFG_JSON_BEGIN\n");
    var end = out.indexOf("\nARCMENU_CFG_JSON_END");
    if (begin < 0 || end < 0 || end <= begin)
        throw new Error("Could not read file");
    return out.substring(begin + "ARCMENU_CFG_JSON_BEGIN\n".length, end);
}

function defaultExportFileName() {
    var d = new Date();
    function pad(n) { return (n < 10 ? "0" : "") + n; }
    return "arcmenu-config-"
        + d.getFullYear()
        + pad(d.getMonth() + 1)
        + pad(d.getDate())
        + "-"
        + pad(d.getHours())
        + pad(d.getMinutes())
        + ".json";
}
