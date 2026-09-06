.pragma library

/**
 * Registry of all Prismenu layouts and their capabilities.
 * Categories describe the source platform (Linux, Windows, …). Each layout
 * also has a `desktop` id for a second-level group (KDE, GNOME, Windows 7, …).
 * Empty groups stay hidden until a layout references them.
 */

var LAYOUTS = [
    {
        id: "arcmenu",
        name: "ArcMenu (Classic)",
        description: "Official ArcMenu layout (pinned + places)",
        category: "other",
        desktop: "arcmenu",
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
        name: "Linux Mint Cinnamon Menu",
        description: "Cinnamon-style icon rail, categories, and application list",
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
        description: "Windows 7-style recent program list, All Programs, places, and bottom search",
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
        name: "Windows 11 (Pinned + A-Z)",
        description: "Compact Windows 11-style pinned page with an A-Z list",
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
        name: "ChromeOS Ash Launcher (Half)",
        description: "Half-height launcher with search and adaptive application grid",
        category: "chromeos",
        desktop: "chromeos",
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
        source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "raven",
        name: "ArcMenu Raven (Sidebar)",
        description: "ArcMenu Raven-inspired full-height application sidebar",
        category: "other",
        desktop: "arcmenu",
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
        id: "application-menu",
        name: "KDE Plasma Application Menu",
        description: "Plasma Application Menu (compact Kicker flyouts)",
        category: "linux",
        desktop: "plasma",
        hasCategories: true,
        hasPinned: true,
        hasSearch: true,
        hasUser: false,
        hasPower: true,
        supportsFlip: true,
        supportsSearchbarLocation: false,
        compactPopup: true,
        defaultWidth: 360,
        defaultHeight: 540,
        defaultSidebarWidth: 56,
        previewKind: "runner",
        source: "layouts/LayoutApplicationMenu.qml"
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
    },
    {
        id: "runner",
        name: "KDE Plasma KRunner",
        description: "Centered Plasma Runner with grouped native search results",
        category: "linux", desktop: "plasma",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 760, defaultHeight: 500,
        previewKind: "runner", source: "layouts/LayoutRunner.qml"
    },
    {
        id: "kickoff-compact",
        name: "KDE Plasma Kickoff (Compact)",
        description: "Single-column compact Kickoff for narrow screens",
        category: "linux", desktop: "plasma",
        hasCategories: true, hasPinned: true, hasSearch: true,
        hasUser: true, hasPower: true,
        supportsFlip: false, supportsSearchbarLocation: false,
        compactPopup: true, defaultWidth: 380, defaultHeight: 560,
        previewKind: "plasma", source: "layouts/LayoutKickoffCompact.qml"
    },
    {
        id: "gnome-grid",
        name: "GNOME Applications Grid",
        description: "Full application grid with persistent favorite Dash",
        category: "linux", desktop: "gnome",
        hasCategories: false, hasPinned: true, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 1100, defaultHeight: 760, heightPolicy: "available", maxHeight: 1600,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "gnome-classic",
        name: "GNOME Classic Applications Menu",
        description: "Compact category flyout inspired by GNOME Classic",
        category: "linux", desktop: "gnome",
        hasCategories: true, hasPinned: false, hasSearch: false,
        hasUser: false, hasPower: false,
        supportsFlip: true, supportsSearchbarLocation: false,
        compactPopup: true, defaultWidth: 360, defaultHeight: 540,
        previewKind: "runner", source: "layouts/LayoutApplicationMenu.qml"
    },
    {
        id: "cosmic-launcher",
        name: "COSMIC Launcher",
        description: "Search-first launcher prioritizing open windows and recent items",
        category: "linux", desktop: "cosmic",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 760, defaultHeight: 520,
        previewKind: "runner", source: "layouts/LayoutRunner.qml"
    },
    {
        id: "cosmic-library",
        name: "COSMIC Applications Library",
        description: "Searchable application library organized by category",
        category: "linux", desktop: "cosmic",
        hasCategories: true, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 900, defaultHeight: 680,
        previewKind: "enterprise", source: "layouts/LayoutLibrary.qml"
    },
    {
        id: "deepin-window",
        name: "Deepin Launcher (Window)",
        description: "Resizable category sidebar and application grid",
        category: "linux", desktop: "deepin",
        hasCategories: true, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: true, supportsSearchbarLocation: false,
        defaultWidth: 760, defaultHeight: 600,
        previewKind: "enterprise", source: "layouts/LayoutDeepin.qml"
    },
    {
        id: "deepin-full",
        name: "Deepin Launcher (Fullscreen)",
        description: "Fullscreen application grid with an A-Z index",
        category: "linux", desktop: "deepin",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 1200, defaultHeight: 800, heightPolicy: "available", maxHeight: 1600,
        previewKind: "searchGrid", source: "layouts/LayoutDeepin.qml"
    },
    {
        id: "win11-categories",
        name: "Windows 11 (Category View)",
        description: "Top-level application category cards with grid drill-down",
        category: "windows", desktop: "win11",
        hasCategories: true, hasPinned: false, hasSearch: true,
        hasUser: true, hasPower: true,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 860, defaultHeight: 680,
        previewKind: "enterprise", source: "layouts/LayoutLibrary.qml"
    },
    {
        id: "win11-compact-grid",
        name: "Windows 11 (Compact Grid)",
        description: "Search, dense all-applications grid, and no recommendation area",
        category: "windows", desktop: "win11",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: true, hasPower: true,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 700, defaultHeight: 620,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "android-pixel",
        name: "Android Pixel App Drawer",
        description: "Suggested applications followed by an A-Z application grid",
        category: "android", desktop: "android",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 620, defaultHeight: 760,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "android-oneui",
        name: "Samsung One UI App Drawer",
        description: "Paged customizable application grid",
        category: "android", desktop: "android",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 620, defaultHeight: 720,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "android-dex",
        name: "Samsung DeX Desktop Launcher",
        description: "Desktop popup application grid with optional session actions",
        category: "android", desktop: "android",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: true,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 660, defaultHeight: 580,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "chromeos-full",
        name: "ChromeOS Ash Launcher (Fullscreen)",
        description: "Fullscreen searchable application grid",
        category: "chromeos", desktop: "chromeos",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 1100, defaultHeight: 760, heightPolicy: "available", maxHeight: 1600,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "chromeos-tablet",
        name: "ChromeOS Tablet Home",
        description: "Paged tablet application grid",
        category: "chromeos", desktop: "chromeos",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 1000, defaultHeight: 720, heightPolicy: "available", maxHeight: 1600,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "macos-launchpad",
        name: "macOS Launchpad",
        description: "Paged full-screen application grid",
        category: "apple", desktop: "macos",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 1100, defaultHeight: 760, heightPolicy: "available", maxHeight: 1600,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "spotlight",
        name: "macOS Spotlight",
        description: "Compact centered search and result list",
        category: "apple", desktop: "macos",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 680, defaultHeight: 420,
        previewKind: "runner", source: "layouts/LayoutRunner.qml"
    },
    {
        id: "ipados-home",
        name: "iPadOS Home Screen",
        description: "Paged touch-oriented application grid",
        category: "apple", desktop: "ipados",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 1000, defaultHeight: 720, heightPolicy: "available", maxHeight: 1600,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    },
    {
        id: "ipados-library",
        name: "iPadOS App Library",
        description: "Automatic application category wall",
        category: "apple", desktop: "ipados",
        hasCategories: true, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 900, defaultHeight: 700,
        previewKind: "enterprise", source: "layouts/LayoutLibrary.qml"
    },
    {
        id: "ipados-spotlight",
        name: "iPadOS Spotlight",
        description: "Centered touch-friendly search results",
        category: "apple", desktop: "ipados",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 720, defaultHeight: 480,
        previewKind: "runner", source: "layouts/LayoutRunner.qml"
    },
    {
        id: "xfce-applications",
        name: "Xfce Applications Menu",
        description: "Compact traditional category flyout",
        category: "linux", desktop: "xfce",
        hasCategories: true, hasPinned: false, hasSearch: false,
        hasUser: false, hasPower: false,
        supportsFlip: true, supportsSearchbarLocation: false,
        compactPopup: true, defaultWidth: 360, defaultHeight: 540,
        previewKind: "runner", source: "layouts/LayoutApplicationMenu.qml"
    },
    {
        id: "cinnamenu-grid",
        name: "Linux Mint Cinnamenu (Grid)",
        description: "Category sidebar with a searchable application grid",
        category: "linux", desktop: "mint",
        hasCategories: true, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: true, supportsSearchbarLocation: false,
        defaultWidth: 760, defaultHeight: 600,
        previewKind: "enterprise", source: "layouts/LayoutDeepin.qml"
    },
    {
        id: "elementary-full",
        name: "elementary OS Applications (Fullscreen)",
        description: "Fullscreen Pantheon-style searchable application grid",
        category: "linux", desktop: "elementary",
        hasCategories: false, hasPinned: false, hasSearch: true,
        hasUser: false, hasPower: false,
        supportsFlip: false, supportsSearchbarLocation: false,
        defaultWidth: 1100, defaultHeight: 760, heightPolicy: "available", maxHeight: 1600,
        previewKind: "searchGrid", source: "layouts/LayoutDrawer.qml"
    }
];

var CATEGORIES = [
    { id: "linux", name: "Linux-style Menus", icon: "start-here-kde" },
    { id: "windows", name: "Windows-style Menus", icon: "computer" },
    { id: "chromeos", name: "ChromeOS-style Menus", icon: "computer-laptop" },
    // Extensibility point: empty categories remain hidden until first use.
    { id: "android", name: "Android-style Menus", icon: "phone" },
    { id: "apple", name: "Apple-style Menus", icon: "computer-laptop" },
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
    { id: "cosmic", category: "linux", name: "COSMIC Desktop", icon: "desktop" },
    { id: "deepin", category: "linux", name: "Deepin Desktop", icon: "desktop" },
    { id: "win7", category: "windows", name: "Windows 7 Desktop", icon: "computer" },
    { id: "win10", category: "windows", name: "Windows 10 Desktop", icon: "computer" },
    { id: "win11", category: "windows", name: "Windows 11 Desktop", icon: "computer" },
    { id: "chromeos", category: "chromeos", name: "ChromeOS Desktop", icon: "computer-laptop" },
    { id: "android", category: "android", name: "Android Desktop", icon: "phone" },
    { id: "macos", category: "apple", name: "macOS Desktop", icon: "computer-laptop" },
    { id: "ipados", category: "apple", name: "iPadOS Desktop", icon: "tablet" },
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
    var found = LAYOUTS[0];
    for (var i = 0; i < LAYOUTS.length; ++i) {
        if (LAYOUTS[i].id === id) {
            found = LAYOUTS[i];
            break;
        }
    }
    var copy = {};
    for (var k in found)
        copy[k] = found[k];
    copy.defaultWidth = SHARED_DEFAULT_WIDTH;
    copy.defaultHeight = SHARED_DEFAULT_HEIGHT;
    // First open is the shared popup size; users can still drag it larger.
    if (copy.heightPolicy === "available")
        copy.heightPolicy = "";
    return copy;
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

/** Shared first-open size for every layout. Per-layout user resizes are stored separately. */
var SHARED_DEFAULT_WIDTH = 620;
var SHARED_DEFAULT_HEIGHT = 540;
var SHARED_DEFAULT_SIDEBAR = 220;
var SHARED_DEFAULT_LEFT = 380;

function sharedDefaultSize() {
    return {
        w: SHARED_DEFAULT_WIDTH,
        h: SHARED_DEFAULT_HEIGHT,
        sidebar: SHARED_DEFAULT_SIDEBAR,
        category: SHARED_DEFAULT_SIDEBAR,
        left: SHARED_DEFAULT_LEFT,
        right: SHARED_DEFAULT_SIDEBAR,
        offset: 0
    };
}

function parseLayoutSizes(raw) {
    try {
        var obj = typeof raw === "string" ? JSON.parse(String(raw || "{}")) : (raw || {});
        return (obj && typeof obj === "object" && !Array.isArray(obj)) ? obj : {};
    } catch (e) {
        return {};
    }
}

function sizeForLayout(raw, layoutId) {
    var defaults = sharedDefaultSize();
    var map = parseLayoutSizes(raw);
    var entry = layoutId && map[layoutId] ? map[layoutId] : null;
    if (!entry || typeof entry !== "object")
        return defaults;
    var w = clampSize(entry.w, 400, 2400, defaults.w);
    var h = clampSize(entry.h, 400, 2000, defaults.h);
    return {
        w: w,
        h: h,
        sidebar: clampSize(entry.sidebar, 160, 360, defaults.sidebar),
        category: clampSize(entry.category, 160, 360, defaults.category),
        left: clampSize(entry.left, 180, 1600, defaults.left),
        right: clampSize(entry.right, 160, 360, defaults.right),
        offset: clampSize(entry.offset, -200, 400, defaults.offset)
    };
}

function setSizeForLayout(raw, layoutId, size) {
    if (!layoutId)
        return typeof raw === "string" ? raw : JSON.stringify(parseLayoutSizes(raw));
    var map = parseLayoutSizes(raw);
    var defaults = sharedDefaultSize();
    var src = size || {};
    map[layoutId] = {
        w: clampSize(src.w, 400, 2400, defaults.w),
        h: clampSize(src.h, 400, 2000, defaults.h),
        sidebar: clampSize(src.sidebar, 160, 360, defaults.sidebar),
        category: clampSize(src.category, 160, 360, defaults.category),
        left: clampSize(src.left, 180, 1600, defaults.left),
        right: clampSize(src.right, 160, 360, defaults.right),
        offset: clampSize(src.offset, -200, 400, defaults.offset)
    };
    return JSON.stringify(map);
}
