.pragma library

/**
 * Bundled category icons (Material Symbols Outlined via Google Fonts Icons).
 * Multiple options per category for a future custom-icon picker.
 *
 * Icon files live at: package/contents/icons/categories/<id>.svg
 * Use isBundled() + relativeSvgPath() from QML to resolve for Kirigami.Icon.
 *
 * Source: https://fonts.google.com/icons
 */

var CATALOG = {
    Office: {
        defaultId: "arcmenu-cat-office-barchart",
        options: [
            { id: "arcmenu-cat-office-barchart", material: "bar_chart", label: "Bar chart" },
            { id: "arcmenu-cat-office-document", material: "description", label: "Document" },
            { id: "arcmenu-cat-office-work", material: "work", label: "Work" }
        ]
    },
    Development: {
        defaultId: "arcmenu-cat-dev-brush",
        options: [
            { id: "arcmenu-cat-dev-brush", material: "brush", label: "Brush" },
            { id: "arcmenu-cat-dev-code", material: "code", label: "Code" },
            { id: "arcmenu-cat-dev-terminal", material: "terminal", label: "Terminal" },
            { id: "arcmenu-cat-dev-data", material: "data_object", label: "Data" }
        ]
    },
    Accessories: {
        defaultId: "arcmenu-cat-accessories-handyman",
        options: [
            { id: "arcmenu-cat-accessories-handyman", material: "handyman", label: "Handyman" },
            { id: "arcmenu-cat-accessories-construction", material: "construction", label: "Construction" },
            { id: "arcmenu-cat-accessories-hardware", material: "hardware", label: "Hardware" }
        ]
    },
    Utility: {
        defaultId: "arcmenu-cat-tools-build",
        options: [
            { id: "arcmenu-cat-tools-build", material: "build", label: "Build / wrench" },
            { id: "arcmenu-cat-tools-tune", material: "tune", label: "Tune" },
            { id: "arcmenu-cat-tools-manufacturing", material: "manufacturing", label: "Manufacturing" }
        ]
    },
    Network: {
        defaultId: "arcmenu-cat-internet-public",
        options: [
            { id: "arcmenu-cat-internet-public", material: "public", label: "Public / globe" },
            { id: "arcmenu-cat-internet-language", material: "language", label: "Language" },
            { id: "arcmenu-cat-internet-explore", material: "travel_explore", label: "Explore" }
        ]
    },
    Graphics: {
        defaultId: "arcmenu-cat-graphics-image",
        options: [
            { id: "arcmenu-cat-graphics-image", material: "image", label: "Image" },
            { id: "arcmenu-cat-graphics-palette", material: "palette", label: "Palette" },
            { id: "arcmenu-cat-graphics-photo", material: "photo_camera", label: "Camera" }
        ]
    },
    System: {
        defaultId: "arcmenu-cat-system-settings",
        options: [
            { id: "arcmenu-cat-system-settings", material: "settings", label: "Settings" },
            { id: "arcmenu-cat-system-dns", material: "dns", label: "DNS / server" },
            { id: "arcmenu-cat-system-computer", material: "computer", label: "Computer" }
        ]
    },
    Settings: {
        defaultId: "arcmenu-cat-tools-tune",
        options: [
            { id: "arcmenu-cat-tools-tune", material: "tune", label: "Tune" },
            { id: "arcmenu-cat-system-settings", material: "settings", label: "Settings" },
            { id: "arcmenu-cat-system-computer", material: "computer", label: "Computer" }
        ]
    },
    Education: {
        defaultId: "arcmenu-cat-edu-school",
        options: [
            { id: "arcmenu-cat-edu-school", material: "school", label: "School" },
            { id: "arcmenu-cat-edu-book", material: "menu_book", label: "Book" }
        ]
    },
    Game: {
        defaultId: "arcmenu-cat-games-esports",
        options: [
            { id: "arcmenu-cat-games-esports", material: "sports_esports", label: "Esports" },
            { id: "arcmenu-cat-games-controller", material: "stadia_controller", label: "Controller" }
        ]
    },
    AudioVideo: {
        defaultId: "arcmenu-cat-av-movie",
        options: [
            { id: "arcmenu-cat-av-movie", material: "movie", label: "Movie" },
            { id: "arcmenu-cat-av-headphones", material: "headphones", label: "Headphones" }
        ]
    },
    Science: {
        defaultId: "arcmenu-cat-science-flask",
        options: [
            { id: "arcmenu-cat-science-flask", material: "science", label: "Science" }
        ]
    },
    Other: {
        defaultId: "arcmenu-cat-other-apps",
        options: [
            { id: "arcmenu-cat-other-apps", material: "apps", label: "Apps grid" }
        ]
    }
};

function isBundled(iconId) {
    return typeof iconId === "string" && iconId.indexOf("arcmenu-cat-") === 0;
}

function relativeSvgPath(iconId) {
    return "icons/categories/" + iconId + ".svg";
}

function defaultIcon(categoryId) {
    var entry = CATALOG[categoryId];
    if (entry && entry.defaultId) {
        return entry.defaultId;
    }
    return "arcmenu-cat-other-apps";
}

function hasCategory(categoryId) {
    return !!(CATALOG[categoryId] && CATALOG[categoryId].defaultId);
}

function optionsFor(categoryId) {
    var entry = CATALOG[categoryId];
    if (!entry) {
        return CATALOG.Other.options.slice();
    }
    return entry.options.slice();
}

function allOptions() {
    var seen = {};
    var list = [];
    var keys = Object.keys(CATALOG);
    for (var i = 0; i < keys.length; ++i) {
        var opts = CATALOG[keys[i]].options || [];
        for (var j = 0; j < opts.length; ++j) {
            var o = opts[j];
            if (!seen[o.id]) {
                seen[o.id] = true;
                list.push(Object.assign({ category: keys[i] }, o));
            }
        }
    }
    return list;
}

function catalogKeys() {
    return Object.keys(CATALOG);
}
