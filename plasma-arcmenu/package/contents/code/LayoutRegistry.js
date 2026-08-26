.pragma library

/**
 * Registry of all Arc Menu layouts and their capabilities.
 * Categories describe the source platform (Linux, Windows, …). Each layout
 * also has a `desktop` id for a second-level group (KDE, GNOME, Windows 7, …).
 * Empty groups stay hidden until a layout references them.
 */

var LAYOUTS = [
    {
        id: "arcmenu",
        name: "ArcMenu (Classic)",
        description: "Official ArcMenu layout (pinned + places)",
        category: "linux",
        desktop: "gnome",
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
        name: "Solus Brisk",
        description: "Solus Brisk Menu (sidebar + apps)",
        category: "linux",
        desktop: "solus",
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
        name: "Linux Mint",
        description: "Linux Mint Menu (icon rail + categories)",
        category: "linux",
        desktop: "mint",
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
        name: "Xfce Whisker",
        description: "XFCE Whisker (user bar + categories)",
        category: "linux",
        desktop: "xfce",
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
        name: "elementary OS Launcher",
        description: "Elementary (search + 6-column app grid)",
        category: "linux",
        desktop: "elementary",
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
        name: "KDE Plasma Dashboard",
        description: "Plasma Application Dashboard (favorites | grid | categories)",
        category: "linux",
        desktop: "plasma",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        searchbarDefaultTop: true,
        defaultWidth: 1200,
        defaultHeight: 800,
        heightPolicy: "available",
        maxHeight: 1600,
        previewKind: "searchGrid",
        source: "layouts/LayoutPlasmaDash.qml"
    },
    {
        id: "plasma",
        name: "KDE Plasma (Tabbed)",
        description: "Plasma (header + list + bottom tabs)",
        category: "linux",
        desktop: "plasma",
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
        name: "Pop!_OS Launcher",
        description: "Pop!_OS (search + grid + category tabs)",
        category: "linux",
        desktop: "pop",
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
        name: "Ubuntu Unity Dash",
        description: "Ubuntu Unity style",
        category: "linux",
        desktop: "unity",
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
        name: "Ubuntu Unity Menu",
        description: "Unity (pinned + shortcuts + bottom places/session)",
        category: "linux",
        desktop: "unity",
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
        name: "Windows 7 (Two-column)",
        description: "Windows 7-inspired two-column menu with an app grid and places",
        category: "windows",
        desktop: "win7",
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
        name: "ArcMenu Sleek (Grid)",
        description: "Sleek (pinned grid + avatar sidebar + power)",
        category: "other",
        desktop: "arcmenu",
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
        name: "ArcMenu Tognee (Sidebar)",
        description: "Tognee (icon rail + categories + bottom search)",
        category: "other",
        desktop: "arcmenu",
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
        name: "Windows 11 (Standard)",
        description: "Windows 11-style pinned apps, recommendations, and footer",
        category: "windows",
        desktop: "win11",
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
        name: "Windows 11 (Compact)",
        description: "Compact Windows 11-style pinned apps with an A–Z app list",
        category: "windows",
        desktop: "win11",
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
        name: "Enterprise Grid",
        description: "Category sidebar and application grid for managed desktops",
        category: "other",
        desktop: "generic",
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
        name: "Windows 10 (Early)",
        description: "Early Windows 10-inspired app grid with an account header and utility rail",
        category: "windows",
        desktop: "win10",
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
        name: "Windows 10 (Classic)",
        description: "Windows 10-style app list, pinned tiles, and expandable side rail",
        category: "windows",
        desktop: "win10",
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
        name: "ArcMenu Zest (Three-column)",
        description: "Zest (places | categories → apps | search)",
        category: "other",
        desktop: "arcmenu",
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
        name: "ChromeOS Launcher",
        description: "Chromebook (portrait: search + 4-column grid)",
        category: "chromeos",
        desktop: "chromeos",
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
        name: "Budgie Raven",
        description: "Raven (full-height rail + pinned/shortcuts panel)",
        category: "linux",
        desktop: "budgie",
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
        name: "Budgie Application Menu",
        description: "Budgie desktop style (pinned + categories)",
        category: "linux",
        desktop: "budgie",
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
        name: "KDE Plasma Kickoff",
        description: "Current Plasma 6 Kickoff with applications, places, and power actions",
        category: "linux",
        desktop: "plasma",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 800,
        defaultHeight: 600,
        defaultSidebarWidth: 185,
        previewKind: "kickoff6",
        source: "layouts/LayoutKickoff.qml"
    },
    {
        id: "kicker",
        name: "KDE Plasma Kicker",
        description: "Plasma Kicker cascading style",
        category: "linux",
        desktop: "plasma",
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
        name: "Minimal Search Launcher",
        description: "Minimal search-focused style",
        category: "other",
        desktop: "generic",
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

/**
 * Second-level grouping inside a source-platform category. Empty desktops stay
 * hidden until a layout references them (same rule as CATEGORIES).
 */
var DESKTOPS = [
    { id: "plasma", category: "linux", name: "KDE Desktop", icon: "start-here-kde" },
    { id: "gnome", category: "linux", name: "GNOME Desktop", icon: "desktop" },
    { id: "mint", category: "linux", name: "Linux Mint Desktop", icon: "folder" },
    { id: "xfce", category: "linux", name: "Xfce Desktop", icon: "applications-system" },
    { id: "solus", category: "linux", name: "Solus Desktop", icon: "desktop" },
    { id: "budgie", category: "linux", name: "Budgie Desktop", icon: "desktop" },
    { id: "unity", category: "linux", name: "Ubuntu Unity Desktop", icon: "computer" },
    { id: "elementary", category: "linux", name: "elementary Desktop", icon: "desktop" },
    { id: "pop", category: "linux", name: "Pop!_OS Desktop", icon: "desktop" },
    { id: "win7", category: "windows", name: "Windows 7 Desktop", icon: "computer" },
    { id: "win10", category: "windows", name: "Windows 10 Desktop", icon: "computer" },
    { id: "win11", category: "windows", name: "Windows 11 Desktop", icon: "computer" },
    { id: "chromeos", category: "chromeos", name: "ChromeOS Desktop", icon: "computer-laptop" },
    { id: "android", category: "android", name: "Android Desktop", icon: "phone" },
    { id: "arcmenu", category: "other", name: "ArcMenu Original", icon: "applications-other" },
    { id: "generic", category: "other", name: "Other Desktops", icon: "applications-other" }
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

function layoutDesktops() {
    var used = {};
    for (var i = 0; i < LAYOUTS.length; ++i) {
        if (LAYOUTS[i].desktop)
            used[LAYOUTS[i].desktop] = true;
    }
    return DESKTOPS.filter(function(desktop) { return !!used[desktop.id]; });
}

function desktopsInCategory(categoryId) {
    var used = {};
    for (var i = 0; i < LAYOUTS.length; ++i) {
        if (LAYOUTS[i].category === categoryId && LAYOUTS[i].desktop)
            used[LAYOUTS[i].desktop] = true;
    }
    return DESKTOPS.filter(function(desktop) {
        return desktop.category === categoryId && !!used[desktop.id];
    });
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

function layoutsInDesktop(desktopId) {
    var out = [];
    for (var i = 0; i < LAYOUTS.length; ++i) {
        if (LAYOUTS[i].desktop === desktopId)
            out.push(LAYOUTS[i]);
    }
    return out;
}

function getDesktop(id) {
    for (var i = 0; i < DESKTOPS.length; ++i) {
        if (DESKTOPS[i].id === id)
            return DESKTOPS[i];
    }
    return null;
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
