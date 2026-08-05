.pragma library

/**
 * Registry of all Arc Menu layouts and their capabilities.
 */

var LAYOUTS = [
    {
        id: "arcmenu",
        name: "Arc Menu",
        description: "Zorin OS style (default)",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 650,
        defaultHeight: 550,
        source: "layouts/LayoutArcMenu.qml"
    },
    {
        id: "brisk",
        name: "Brisk",
        description: "Solus Brisk Menu",
        hasCategories: true,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 550,
        defaultHeight: 500,
        source: "layouts/LayoutBrisk.qml"
    },
    {
        id: "mint",
        name: "Mint",
        description: "Linux Mint Menu",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 640,
        defaultHeight: 540,
        source: "layouts/LayoutMint.qml"
    },
    {
        id: "whisker",
        name: "Whisker",
        description: "XFCE Whisker Menu",
        hasCategories: true,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 560,
        defaultHeight: 520,
        source: "layouts/LayoutWhisker.qml"
    },
    {
        id: "elementary",
        name: "Elementary",
        description: "elementary OS style",
        hasCategories: true,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: false,
        supportsFlip: false,
        supportsSearchbarLocation: false,
        defaultWidth: 700,
        defaultHeight: 500,
        source: "layouts/LayoutElementary.qml"
    },
    {
        id: "gnome",
        name: "GNOME",
        description: "Classic GNOME 2 style",
        hasCategories: true,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 520,
        defaultHeight: 480,
        source: "layouts/LayoutGnome.qml"
    },
    {
        id: "plasma-dash",
        name: "Plasma Dash",
        description: "Plasma overview grid",
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
        id: "unity-dash",
        name: "Unity Dash",
        description: "Ubuntu Unity style",
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
        id: "redmond",
        name: "Redmond",
        description: "Windows 7 style",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: true,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        defaultWidth: 620,
        defaultHeight: 560,
        source: "layouts/LayoutRedmond.qml"
    },
    {
        id: "eleven",
        name: "Eleven",
        description: "Windows 11 style",
        hasCategories: true,
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
        id: "budgie",
        name: "Budgie",
        description: "Budgie desktop style",
        hasCategories: true,
        hasPinned: false,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: true,
        defaultWidth: 540,
        defaultHeight: 500,
        source: "layouts/LayoutBudgie.qml"
    },
    {
        id: "kickoff",
        name: "Kickoff",
        description: "Plasma Kickoff tabbed style",
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

function allLayouts() {
    return LAYOUTS.slice();
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
