.pragma library

/**
 * ArcMenu-compatible menu themes.
 * Preset fields: name, bg, fg, border, borderWidth, cornerRadius, fontSize,
 *                separator, hoverBg, hoverFg, activeBg, activeFg
 */

function parseColor(value, fallback) {
    if (value === undefined || value === null || value === "")
        return fallback;
    return value;
}

function relativeLuminance(hex) {
    if (!hex || typeof hex !== "string" || hex.charAt(0) !== "#" || hex.length < 7)
        return 0.5;
    var r = parseInt(hex.substr(1, 2), 16) / 255;
    var g = parseInt(hex.substr(3, 2), 16) / 255;
    var b = parseInt(hex.substr(5, 2), 16) / 255;
    function lin(c) {
        return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    }
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
}

function contrastRatio(fg, bg) {
    var l1 = relativeLuminance(fg);
    var l2 = relativeLuminance(bg);
    var lighter = Math.max(l1, l2);
    var darker = Math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
}

function hasLowContrast(fg, bg) {
    if (!fg || !bg || fg === "" || bg === "")
        return false;
    if (fg.charAt(0) !== "#" || bg.charAt(0) !== "#")
        return false;
    return contrastRatio(fg, bg) < 4.5;
}

/** Built-in presets from GNOME ArcMenu */
function builtinPresets() {
    return [
        {
            name: "ArcMenu Style",
            bg: "rgba(48,48,49,0.98)",
            fg: "rgb(223,223,223)",
            border: "rgb(60,60,60)",
            borderWidth: 1,
            cornerRadius: 14,
            fontSize: 11,
            separator: "rgba(255,255,255,0.1)",
            hoverBg: "rgb(21,83,158)",
            hoverFg: "rgb(255,255,255)",
            activeBg: "rgb(25,98,163)",
            activeFg: "rgb(255,255,255)"
        },
        {
            name: "Simply Dark",
            bg: "rgba(28,28,28,0.98)",
            fg: "rgb(211,218,227)",
            border: "rgb(63,62,64)",
            borderWidth: 1,
            cornerRadius: 14,
            fontSize: 11,
            separator: "rgb(63,62,64)",
            hoverBg: "rgba(238,238,236,0.08)",
            hoverFg: "rgb(255,255,255)",
            activeBg: "rgba(228,228,226,0.15)",
            activeFg: "rgb(255,255,255)"
        },
        {
            name: "Dark Blue",
            bg: "rgb(30,37,41)",
            fg: "rgb(189,230,251)",
            border: "rgb(41,50,55)",
            borderWidth: 1,
            cornerRadius: 14,
            fontSize: 11,
            separator: "rgba(99,99,98,0.56)",
            hoverBg: "rgba(189,230,251,0.08)",
            hoverFg: "rgb(189,230,251)",
            activeBg: "rgba(189,230,251,0.15)",
            activeFg: "rgb(189,230,251)"
        },
        {
            name: "Light Blue",
            bg: "rgb(245,247,250)",
            fg: "rgb(18,51,84)",
            border: "rgba(18,51,84,0.2)",
            borderWidth: 1,
            cornerRadius: 14,
            fontSize: 11,
            separator: "rgba(18,51,84,0.15)",
            hoverBg: "rgba(18,51,84,0.08)",
            hoverFg: "rgb(18,51,84)",
            activeBg: "rgba(18,51,84,0.15)",
            activeFg: "rgb(18,51,84)"
        }
    ];
}

function themeToArray(t) {
    return [
        t.name || "Custom",
        t.bg || "",
        t.fg || "",
        t.border || "",
        String(t.borderWidth !== undefined ? t.borderWidth : 1),
        String(t.cornerRadius !== undefined ? t.cornerRadius : 14),
        String(t.fontSize !== undefined ? t.fontSize : 11),
        t.separator || "",
        t.hoverBg || "",
        t.hoverFg || "",
        t.activeBg || "",
        t.activeFg || ""
    ];
}

function arrayToTheme(arr) {
    if (!arr || !arr.length)
        return null;
    return {
        name: arr[0] || "Custom",
        bg: arr[1] || "",
        fg: arr[2] || "",
        border: arr[3] || "",
        borderWidth: parseInt(arr[4], 10) || 1,
        cornerRadius: parseInt(arr[5], 10),
        fontSize: parseInt(arr[6], 10),
        separator: arr[7] || "",
        hoverBg: arr[8] || "",
        hoverFg: arr[9] || "",
        activeBg: arr[10] || "",
        activeFg: arr[11] || ""
    };
}

function parseCustomThemesJson(jsonStr) {
    if (!jsonStr || typeof jsonStr !== "string" || !jsonStr.length)
        return [];
    try {
        var raw = JSON.parse(jsonStr);
        if (!raw || !raw.length)
            return [];
        var out = [];
        for (var i = 0; i < raw.length; ++i) {
            var item = raw[i];
            if (Array.isArray(item)) {
                var t = arrayToTheme(item);
                if (t)
                    out.push(t);
            } else if (item && item.name) {
                out.push(item);
            }
        }
        return out;
    } catch (e) {
        return [];
    }
}

function customThemesToJson(themes) {
    var arr = [];
    for (var i = 0; i < themes.length; ++i)
        arr.push(themeToArray(themes[i]));
    return JSON.stringify(arr);
}

function allPresets(customJson) {
    return builtinPresets().concat(parseCustomThemesJson(customJson));
}

function findPreset(name, customJson) {
    var all = allPresets(customJson);
    for (var i = 0; i < all.length; ++i) {
        if (all[i].name === name)
            return all[i];
    }
    return null;
}

function isBuiltinName(name) {
    var b = builtinPresets();
    for (var i = 0; i < b.length; ++i) {
        if (b[i].name === name)
            return true;
    }
    return false;
}

function buildStyle(cfg, plasmaColors) {
    var override = cfg.overrideMenuTheme === true || cfg.themeMode === "custom";
    var highlight = plasmaColors.highlight;
    var highlightedText = plasmaColors.highlightedText;
    var sepFallback = plasmaColors.border;

    if (!override) {
        return {
            system: true,
            override: false,
            bg: plasmaColors.background,
            fg: plasmaColors.foreground,
            border: plasmaColors.border,
            borderWidth: cfg.borderWidth >= 0 ? cfg.borderWidth : 1,
            radius: cfg.cornerRadius < 0 ? plasmaColors.radius : cfg.cornerRadius,
            fontFamily: (!cfg.font || cfg.font === "") ? plasmaColors.fontFamily : cfg.font,
            fontSize: cfg.fontSize < 0 ? plasmaColors.fontSize : cfg.fontSize,
            separator: sepFallback,
            hoverBg: highlight,
            hoverFg: highlightedText,
            activeBg: highlight,
            activeFg: highlightedText,
            // aliases used by existing layouts
            selectedBg: highlight,
            selectedFg: highlightedText,
            categoryIconSize: cfg.categoryIconSize || 24,
            appIconSize: cfg.appIconSize || 24,
            followColorScheme: cfg.followColorScheme !== false,
            themeName: cfg.menuThemeName || ""
        };
    }

    var activeBg = parseColor(cfg.activeBg || cfg.selectedBg, highlight);
    var activeFg = parseColor(cfg.activeFg || cfg.selectedFg, highlightedText);
    var hoverBg = parseColor(cfg.hoverBg, activeBg);
    var hoverFg = parseColor(cfg.hoverFg, activeFg);

    return {
        system: false,
        override: true,
        bg: parseColor(cfg.bgColor, plasmaColors.background),
        fg: parseColor(cfg.fgColor, plasmaColors.foreground),
        border: parseColor(cfg.borderColor, plasmaColors.border),
        borderWidth: cfg.borderWidth >= 0 ? cfg.borderWidth : 1,
        radius: cfg.cornerRadius < 0 ? plasmaColors.radius : cfg.cornerRadius,
        fontFamily: (!cfg.font || cfg.font === "") ? plasmaColors.fontFamily : cfg.font,
        fontSize: cfg.fontSize < 0 ? plasmaColors.fontSize : cfg.fontSize,
        separator: parseColor(cfg.separatorColor, sepFallback),
        hoverBg: hoverBg,
        hoverFg: hoverFg,
        activeBg: activeBg,
        activeFg: activeFg,
        selectedBg: activeBg,
        selectedFg: activeFg,
        categoryIconSize: cfg.categoryIconSize || 24,
        appIconSize: cfg.appIconSize || 24,
        followColorScheme: cfg.followColorScheme !== false,
        themeName: cfg.menuThemeName || ""
    };
}
