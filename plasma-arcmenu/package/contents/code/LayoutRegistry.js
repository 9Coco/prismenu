.pragma library

/**
 * Registry of all Arc Menu layouts and their capabilities.
 * Categories align with GNOME ArcMenu: traditional / modern / touch / launcher / alternative
 */

var LAYOUTS = [
    {
        id: "arcmenu",
        name: "Arc Menu",
        description: "Official ArcMenu layout (pinned + places)",
        category: "traditional",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 620,
        defaultHeight: 540,
        source: "layouts/LayoutArcMenu.qml"
    },
    {
        id: "brisk",
        name: "Brisk",
        description: "Solus Brisk Menu (sidebar + apps)",
        category: "traditional",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 580,
        defaultHeight: 560,
        source: "layouts/LayoutBrisk.qml"
    },
    {
        id: "mint",
        name: "Mint",
        description: "Linux Mint Menu (icon rail + categories)",
        category: "traditional",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 640,
        defaultHeight: 540,
        source: "layouts/LayoutMint.qml"
    },
    {
        id: "whisker",
        name: "Whisker",
        description: "XFCE Whisker (user bar + categories)",
        category: "traditional",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 560,
        defaultHeight: 520,
        source: "layouts/LayoutWhisker.qml"
    },
    {
        id: "elementary",
        name: "Elementary",
        description: "Elementary (search + 6-column app grid)",
        category: "touch",
        hasCategories: false,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        source: "layouts/LayoutElementary.qml"
    },
    {
        id: "gnome",
        name: "GNOME",
        description: "GNOME style (pinned + categories)",
        category: "traditional",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 560,
        defaultHeight: 540,
        source: "layouts/LayoutGnome.qml"
    },
    {
        id: "plasma-dash",
        name: "Plasma Dash",
        description: "Plasma overview grid",
        category: "launcher",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        source: "layouts/LayoutPlasmaDash.qml"
    },
    {
        id: "plasma",
        name: "Plasma",
        description: "Plasma (header + list + bottom tabs)",
        category: "modern",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 420,
        defaultHeight: 560,
        source: "layouts/LayoutPlasma.qml"
    },
    {
        id: "pop",
        name: "Pop",
        description: "Pop!_OS (search + grid + category tabs)",
        category: "launcher",
        hasCategories: true,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        source: "layouts/LayoutPop.qml"
    },
    {
        id: "unity-dash",
        name: "Unity Dash",
        description: "Ubuntu Unity style",
        category: "launcher",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        source: "layouts/LayoutUnityDash.qml"
    },
    {
        id: "unity",
        name: "Unity",
        description: "Unity (pinned + shortcuts + bottom places/session)",
        category: "modern",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 420,
        defaultHeight: 560,
        source: "layouts/LayoutUnity.qml"
    },
    {
        id: "redmond",
        name: "Redmond",
        description: "Windows-style (app grid + places sidebar)",
        category: "modern",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        source: "layouts/LayoutRedmond.qml"
    },
    {
        id: "sleek",
        name: "Sleek",
        description: "Sleek (pinned grid + avatar sidebar + power)",
        category: "alternative",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 640,
        defaultHeight: 560,
        source: "layouts/LayoutSleek.qml"
    },
    {
        id: "tognee",
        name: "Tognee",
        description: "Tognee (icon rail + categories + bottom search)",
        category: "touch",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 420,
        defaultHeight: 560,
        source: "layouts/LayoutTognee.qml"
    },
    {
        id: "eleven",
        name: "Eleven",
        description: "Windows 11 (pinned grid + recommended + footer)",
        category: "modern",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 680,
        defaultHeight: 620,
        source: "layouts/LayoutEleven.qml"
    },
    {
        id: "az",
        name: "A-Z",
        description: "Compact pinned + alphabetical A–Z app list",
        category: "alternative",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 520,
        defaultHeight: 560,
        source: "layouts/LayoutAz.qml"
    },
    {
        id: "enterprise",
        name: "Enterprise",
        description: "Enterprise (user+search header, sidebar, grid)",
        category: "alternative",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        source: "layouts/LayoutEnterprise.qml"
    },
    {
        id: "insider",
        name: "Insider",
        description: "Insider (avatar + app grid + utility rail)",
        category: "modern",
        hasCategories: false,
        hasPinned: false,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 560,
        defaultHeight: 640,
        source: "layouts/LayoutInsider.qml"
    },
    {
        id: "windows",
        name: "Windows",
        description: "Windows (rail + frequent/A–Z list + pinned grid)",
        category: "modern",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        source: "layouts/LayoutWindows.qml"
    },
    {
        id: "zest",
        name: "Zest",
        description: "Zest (places | categories → apps | search)",
        category: "alternative",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 720,
        defaultHeight: 560,
        source: "layouts/LayoutZest.qml"
    },
    {
        id: "chromebook",
        name: "Chromebook",
        description: "Chromebook (portrait: search + 4-column grid)",
        category: "touch",
        hasCategories: false,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 420,
        defaultHeight: 620,
        source: "layouts/LayoutChromebook.qml"
    },
    {
        id: "raven",
        name: "Raven",
        description: "Raven (full-height rail + pinned/shortcuts panel)",
        category: "launcher",
        hasCategories: false,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 460,
        defaultHeight: 900,
        source: "layouts/LayoutRaven.qml"
    },
    {
        id: "budgie",
        name: "Budgie",
        description: "Budgie desktop style (pinned + categories)",
        category: "traditional",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 560,
        defaultHeight: 520,
        source: "layouts/LayoutBudgie.qml"
    },
    {
        id: "kickoff",
        name: "Kickoff",
        description: "Plasma Kickoff tabbed style",
        category: "alternative",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 600,
        defaultHeight: 540,
        source: "layouts/LayoutKickoff.qml"
    },
    {
        id: "kicker",
        name: "Kicker",
        description: "Plasma Kicker cascading style",
        category: "alternative",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 320,
        defaultHeight: 480,
        source: "layouts/LayoutKicker.qml"
    },
    {
        id: "simple",
        name: "Simple",
        description: "Minimal search-focused style",
        category: "alternative",
        hasCategories: false,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 480,
        defaultHeight: 420,
        source: "layouts/LayoutSimple.qml"
    }
];

var CATEGORIES = [
    { id: "traditional", name: "Traditional Menu Layouts", icon: "computer" },
    { id: "modern", name: "Modern Menu Layouts", icon: "input-keyboard" },
    { id: "touch", name: "Touch Menu Layouts", icon: "tablet" },
    { id: "launcher", name: "Launcher Menu Layouts", icon: "view-grid-symbolic" },
    { id: "alternative", name: "Alternative Menu Layouts", icon: "folder-templates" }
];

function allLayouts() {
    return LAYOUTS.slice();
}

function layoutCategories() {
    return CATEGORIES.slice();
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

function clampSize(value, min, max, fallback) {
    var n = parseInt(value, 10);
    if (isNaN(n)) {
        return fallback;
    }
    return Math.max(min, Math.min(max, n));
}
