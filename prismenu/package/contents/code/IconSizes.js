.pragma library

/**
 * ArcMenu-style icon size overrides.
 * Levels: -1 Off (use fallback), 0 Extra Small … 4 Extra Large
 */

var LEVEL_OFF = -1;

function levelLabels() {
    return ["off", "xs", "s", "m", "l", "xl"];
}

function pxForLevel(level) {
    var n = parseInt(level, 10);
    if (isNaN(n) || n < 0)
        return -1;
    switch (n) {
    case 0: return 16;  // Extra Small
    case 1: return 22;  // Small
    case 2: return 28;  // Medium
    case 3: return 36;  // Large
    case 4: return 48;  // Extra Large
    default: return -1;
    }
}

function resolve(level, fallback) {
    var px = pxForLevel(level);
    if (px < 0) {
        var fb = parseInt(fallback, 10);
        return (!fb || isNaN(fb)) ? 24 : Math.max(16, fb);
    }
    return px;
}

function clampLevel(level) {
    var n = parseInt(level, 10);
    if (isNaN(n) || n < -1)
        return -1;
    if (n > 4)
        return 4;
    return n;
}
