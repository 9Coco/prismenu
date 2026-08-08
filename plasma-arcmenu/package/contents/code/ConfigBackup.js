.pragma library

/**
 * Export / import Arc Menu plasmoid configuration as JSON.
 * Keys match Plasma camelCase properties from contents/config/main.xml.
 */

var FORMAT_ID = "org.kde.plasma.arcmenu.config";
var FORMAT_VERSION = 1;

var CONFIG_KEYS = [
    "activateExistingWindow",
    "activeBg",
    "activeFg",
    "allAppsButtonAction",
    "appIconSize",
    "applicationShortcuts",
    "avatarShape",
    "bgColor",
    "borderColor",
    "borderWidth",
    "buttonIcon",
    "buttonLabelText",
    "buttonLabelVisible",
    "buttonStyleActiveBg",
    "buttonStyleActiveBgEnabled",
    "buttonStyleActiveFg",
    "buttonStyleActiveFgEnabled",
    "buttonStyleBg",
    "buttonStyleBgEnabled",
    "buttonStyleBorderColor",
    "buttonStyleBorderColorEnabled",
    "buttonStyleBorderWidth",
    "buttonStyleBorderWidthEnabled",
    "buttonStyleFg",
    "buttonStyleFgEnabled",
    "buttonStyleHoverBg",
    "buttonStyleHoverBgEnabled",
    "buttonStyleHoverFg",
    "buttonStyleHoverFgEnabled",
    "buttonStyleRadius",
    "buttonStyleRadiusEnabled",
    "categoryColumnWidth",
    "categoryIconSize",
    "categoryIconType",
    "confirm",
    "contextMenuItems",
    "cornerRadius",
    "customButtonIcon",
    "customIcons",
    "customNames",
    "customThemes",
    "directoryShortcuts",
    "enabled",
    "extraCategoriesEnabled",
    "extraCategoriesOrder",
    "extraCategoriesUserSet",
    "fgColor",
    "filterByActivity",
    "flipHorizontal",
    "followColorScheme",
    "font",
    "fontSize",
    "groupAppsAlphabeticallyGrid",
    "groupAppsAlphabeticallyList",
    "hidden",
    "hideSearchBar",
    "highlightSearchTerms",
    "hoverBg",
    "hoverFg",
    "iconSizeApps",
    "iconSizeButtons",
    "iconSizeCategories",
    "iconSizeGrid",
    "iconSizeOther",
    "iconSizeShortcuts",
    "keepOpenOnCtrlClick",
    "leftClickAction",
    "leftPanelWidth",
    "maxItems",
    "maxResults",
    "menuButtonAppearance",
    "menuHeight",
    "menuHotkey",
    "menuLayoutId",
    "menuRiseDistance",
    "menuThemeName",
    "menuWidth",
    "middleClickAction",
    "multiLineLabels",
    "options",
    "order",
    "overlayScrollbars",
    "overrideMenuPosition",
    "overrideMenuRise",
    "overrideMenuTheme",
    "panelButtonIconSize",
    "panelButtonPadding",
    "panelButtonPositionOffset",
    "pinnedApps",
    "pinnedCols",
    "placeholder",
    "popupAnimation",
    "powerDisplayStyle",
    "powerOptionsOrder",
    "providers",
    "quickLinkPosition",
    "quickLinksEnabled",
    "quickLinksOrder",
    "recentApps",
    "rightClickAction",
    "rightPanelWidth",
    "scrollviewFadeEffects",
    "searchbarLocation",
    "searchBoxRadius",
    "searchBoxRadiusEnabled",
    "searchRecentFiles",
    "searchWindows",
    "selectedBg",
    "selectedFg",
    "separatorColor",
    "shareConfigAcrossInstances",
    "shortcutIconType",
    "showAppDescriptions",
    "showBookmarks",
    "showCategorySubmenus",
    "showDescription",
    "showEmpty",
    "showExternalDevices",
    "showGenericNames",
    "showHiddenRecentFiles",
    "showScrollbars",
    "showTooltips",
    "showUserAvatar",
    "showVerticalSeparator",
    "sidebarWidth",
    "softwareCenterCmd",
    "syncWithPlasma",
    "themeMode",
    "uiLanguage",
    "widthOffset"
];

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
