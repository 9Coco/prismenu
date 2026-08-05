.pragma library

function parseColor(value, fallback) {
    if (!value || value === "") {
        return fallback;
    }
    return value;
}

function relativeLuminance(hex) {
    if (!hex || hex.length < 7) {
        return 0.5;
    }
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
    if (!fg || !bg || fg === "" || bg === "") {
        return false;
    }
    return contrastRatio(fg, bg) < 4.5;
}

function buildStyle(cfg, plasmaColors) {
    var system = cfg.themeMode !== "custom";
    return {
        system: system,
        bg: system ? plasmaColors.background : parseColor(cfg.bgColor, plasmaColors.background),
        fg: system ? plasmaColors.foreground : parseColor(cfg.fgColor, plasmaColors.foreground),
        border: system ? plasmaColors.border : parseColor(cfg.borderColor, plasmaColors.border),
        borderWidth: cfg.borderWidth >= 0 ? cfg.borderWidth : 1,
        radius: cfg.cornerRadius < 0 ? plasmaColors.radius : cfg.cornerRadius,
        fontFamily: (!system || !cfg.font || cfg.font === "") ? plasmaColors.fontFamily : cfg.font,
        fontSize: cfg.fontSize < 0 ? plasmaColors.fontSize : cfg.fontSize,
        selectedBg: system ? plasmaColors.highlight : parseColor(cfg.selectedBg, plasmaColors.highlight),
        selectedFg: system ? plasmaColors.highlightedText : parseColor(cfg.selectedFg, plasmaColors.highlightedText),
        categoryIconSize: cfg.categoryIconSize || 24,
        appIconSize: cfg.appIconSize || 24,
        followColorScheme: cfg.followColorScheme !== false
    };
}
