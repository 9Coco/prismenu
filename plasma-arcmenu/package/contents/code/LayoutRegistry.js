.pragma library

/**
 * Registry of all Arc Menu layouts and their capabilities.
 * Categories describe the platform/style family a menu comes from. They are
 * independent from ArcMenu's historical layout-type grouping so layouts from
 * other desktop and mobile ecosystems can be added cleanly.
 */

var LAYOUTS = [
    {
        id: "arcmenu",
        name: "Arc Menu",
        description: "Official ArcMenu layout (pinned + places)",
        category: "linux",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 620,
        defaultHeight: 540,
        previewKind: "arcmenu",
        source: "layouts/LayoutArcMenu.qml"
    },
    {
        id: "brisk",
        name: "Brisk",
        description: "Solus Brisk Menu (sidebar + apps)",
        category: "linux",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 580,
        defaultHeight: 560,
        searchbarDefaultTop: true,
        previewKind: "brisk",
        source: "layouts/LayoutBrisk.qml"
    },
    {
        id: "mint",
        name: "Mint",
        description: "Linux Mint Menu (icon rail + categories)",
        category: "linux",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 640,
        defaultHeight: 540,
        searchbarDefaultTop: true,
        previewKind: "mint",
        source: "layouts/LayoutMint.qml"
    },
    {
        id: "whisker",
        name: "Whisker",
        description: "XFCE Whisker (user bar + categories)",
        category: "linux",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 560,
        defaultHeight: 520,
        searchbarDefaultTop: true,
        previewKind: "whisker",
        source: "layouts/LayoutWhisker.qml"
    },
    {
        id: "elementary",
        name: "Elementary",
        description: "Elementary (search + 6-column app grid)",
        category: "linux",
        hasCategories: false,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        previewKind: "searchGrid",
        source: "layouts/LayoutElementary.qml"
    },
    {
        id: "plasma-dash",
        name: "Plasma Dash",
        description: "Plasma overview grid",
        category: "linux",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        previewKind: "searchGrid",
        source: "layouts/LayoutPlasmaDash.qml"
    },
    {
        id: "plasma",
        name: "Plasma",
        description: "Plasma (header + list + bottom tabs)",
        category: "linux",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 420,
        defaultHeight: 560,
        previewKind: "plasma",
        source: "layouts/LayoutPlasma.qml"
    },
    {
        id: "pop",
        name: "Pop",
        description: "Pop!_OS (search + grid + category tabs)",
        category: "linux",
        hasCategories: true,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        previewKind: "pop",
        source: "layouts/LayoutPop.qml"
    },
    {
        id: "unity-dash",
        name: "Unity Dash",
        description: "Ubuntu Unity style",
        category: "linux",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        previewKind: "searchGrid",
        source: "layouts/LayoutUnityDash.qml"
    },
    {
        id: "unity",
        name: "Unity",
        description: "Unity (pinned + shortcuts + bottom places/session)",
        category: "linux",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 420,
        defaultHeight: 560,
        previewKind: "plasma",
        source: "layouts/LayoutUnity.qml"
    },
    {
        id: "redmond",
        name: "Redmond",
        description: "Windows-style (app grid + places sidebar)",
        category: "windows",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        previewKind: "redmond",
        source: "layouts/LayoutRedmond.qml"
    },
    {
        id: "sleek",
        name: "Sleek",
        description: "Sleek (pinned grid + avatar sidebar + power)",
        category: "other",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 640,
        defaultHeight: 560,
        previewKind: "redmond",
        source: "layouts/LayoutSleek.qml"
    },
    {
        id: "tognee",
        name: "Tognee",
        description: "Tognee (icon rail + categories + bottom search)",
        category: "other",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 420,
        defaultHeight: 560,
        previewKind: "mint",
        source: "layouts/LayoutTognee.qml"
    },
    {
        id: "eleven",
        name: "Eleven",
        description: "Windows 11 (pinned grid + recommended + footer)",
        category: "windows",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 680,
        defaultHeight: 620,
        previewKind: "eleven",
        source: "layouts/LayoutEleven.qml"
    },
    {
        id: "az",
        name: "A-Z",
        description: "Compact pinned + alphabetical A–Z app list",
        category: "other",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 520,
        defaultHeight: 560,
        previewKind: "az",
        source: "layouts/LayoutAz.qml"
    },
    {
        id: "enterprise",
        name: "Enterprise",
        description: "Enterprise (user+search header, sidebar, grid)",
        category: "windows",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        previewKind: "enterprise",
        source: "layouts/LayoutEnterprise.qml"
    },
    {
        id: "insider",
        name: "Insider",
        description: "Insider (avatar + app grid + utility rail)",
        category: "windows",
        hasCategories: false,
        hasPinned: false,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 560,
        defaultHeight: 640,
        previewKind: "insider",
        source: "layouts/LayoutInsider.qml"
    },
    {
        id: "windows",
        name: "Windows",
        description: "Windows (rail + frequent/A–Z list + pinned grid)",
        category: "windows",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        previewKind: "windows",
        source: "layouts/LayoutWindows.qml"
    },
    {
        id: "zest",
        name: "Zest",
        description: "Zest (places | categories → apps | search)",
        category: "other",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        previewKind: "enterprise",
        source: "layouts/LayoutZest.qml"
    },
    {
        id: "chromebook",
        name: "Chromebook",
        description: "Chromebook (portrait: search + 4-column grid)",
        category: "chromeos",
        hasCategories: false,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 420,
        defaultHeight: 620,
        previewKind: "searchGrid",
        source: "layouts/LayoutChromebook.qml"
    },
    {
        id: "raven",
        name: "Raven",
        description: "Raven (full-height rail + pinned/shortcuts panel)",
        category: "linux",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 460,
        defaultHeight: 900,
        previewKind: "raven",
        heightPolicy: "available",
        maxHeight: 1400,
        resizableHeight: false,
        source: "layouts/LayoutRaven.qml"
    },
    {
        id: "budgie",
        name: "Budgie",
        description: "Budgie desktop style (pinned + categories)",
        category: "linux",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 560,
        defaultHeight: 520,
        searchbarDefaultTop: true,
        previewKind: "budgie",
        source: "layouts/LayoutBudgie.qml"
    },
    {
        id: "kickoff",
        name: "Kickoff",
        description: "Plasma Kickoff tabbed style",
        category: "linux",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 600,
        defaultHeight: 540,
        previewKind: "plasma",
        source: "layouts/LayoutKickoff.qml"
    },
    {
        id: "kicker",
        name: "Kicker",
        description: "Plasma Kicker cascading style",
        category: "linux",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 320,
        defaultHeight: 480,
        previewKind: "runner",
        source: "layouts/LayoutKicker.qml"
    },
    {
        id: "simple",
        name: "Simple",
        description: "Minimal search-focused style",
        category: "other",
        hasCategories: false,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 480,
        defaultHeight: 420,
        previewKind: "runner",
        source: "layouts/LayoutSimple.qml"
    }
];

var CATEGORIES = [
    { id: "linux", name: "Linux-style Menus", icon: "start-here-kde" },
    { id: "windows", name: "Windows-style Menus", icon: "computer" },
    { id: "chromeos", name: "ChromeOS-style Menus", icon: "computer-laptop" },
    // Extensibility point: empty categories remain hidden until first use.
    { id: "android", name: "Android-style Menus", icon: "phone" },
    { id: "other", name: "Other Menu Styles", icon: "applications-other" }
];

function allLayouts() {
    return LAYOUTS.slice();
}

function layoutCategories() {
    var used = {};
    for (var i = 0; i < LAYOUTS.length; ++i)
        used[LAYOUTS[i].category] = true;
    return CATEGORIES.filter(function(category) { return !!used[category.id]; });
}

function layoutsInCategory(categoryId) {
    var out = [];
    for (var i = 0; i < LAYOUTS.length; ++i) {
        if (LAYOUTS[i].category === categoryId) {
            out.push(LAYOUTS[i]);
        }
    }
    return out;
}

function getLayout(id) {
    for (var i = 0; i < LAYOUTS.length; ++i) {
        if (LAYOUTS[i].id === id) {
            return LAYOUTS[i];
        }
    }
    return LAYOUTS[0];
}

function supportsOption(layoutId, option) {
    var layout = getLayout(layoutId);
    if (!layout) {
        return false;
    }
    if (option === "flip") {
        return !!layout.supportsFlip;
    }
    if (option === "searchbarLocation") {
        return !!layout.supportsSearchbarLocation;
    }
    if (option === "categories") {
        return !!layout.hasCategories;
    }
    if (option === "pinned") {
        return !!layout.hasPinned;
    }
    return true;
}

/** Layouts whose search bar defaults to the top (upstream schema default is
 * "Top" for them). The global config default is "bottom" (ArcMenu layout), so
 * an untouched value must fall back to the per-layout default. */
function searchbarDefaultsToTop(layoutId) {
    var layout = getLayout(layoutId);
    return !!(layout && layout.searchbarDefaultTop);
}

function clampSize(value, min, max, fallback) {
    var n = parseInt(value, 10);
    if (isNaN(n)) {
        return fallback;
    }
    return Math.max(min, Math.min(max, n));
}
