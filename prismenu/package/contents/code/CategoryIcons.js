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
        defaultId: "prismenu-cat-office-barchart",
        options: [
            { id: "prismenu-cat-office-barchart", material: "bar_chart", label: "Bar chart" },
            { id: "prismenu-cat-office-document", material: "description", label: "Document" },
            { id: "prismenu-cat-office-work", material: "work", label: "Work" }
        ]
    },
    Development: {
        defaultId: "prismenu-cat-dev-brush",
        options: [
            { id: "prismenu-cat-dev-brush", material: "brush", label: "Brush" },
            { id: "prismenu-cat-dev-code", material: "code", label: "Code" },
            { id: "prismenu-cat-dev-terminal", material: "terminal", label: "Terminal" },
            { id: "prismenu-cat-dev-data", material: "data_object", label: "Data" }
        ]
    },
    Accessories: {
        defaultId: "prismenu-cat-accessories-handyman",
        options: [
            { id: "prismenu-cat-accessories-handyman", material: "handyman", label: "Handyman" },
            { id: "prismenu-cat-accessories-construction", material: "construction", label: "Construction" },
            { id: "prismenu-cat-accessories-hardware", material: "hardware", label: "Hardware" }
        ]
    },
    Utility: {
        defaultId: "prismenu-cat-tools-build",
        options: [
            { id: "prismenu-cat-tools-build", material: "build", label: "Build / wrench" },
            { id: "prismenu-cat-tools-tune", material: "tune", label: "Tune" },
            { id: "prismenu-cat-tools-manufacturing", material: "manufacturing", label: "Manufacturing" }
        ]
    },
    Network: {
        defaultId: "prismenu-cat-internet-public",
        options: [
            { id: "prismenu-cat-internet-public", material: "public", label: "Public / globe" },
            { id: "prismenu-cat-internet-language", material: "language", label: "Language" },
            { id: "prismenu-cat-internet-explore", material: "travel_explore", label: "Explore" }
        ]
    },
    Graphics: {
        defaultId: "prismenu-cat-graphics-image",
        options: [
            { id: "prismenu-cat-graphics-image", material: "image", label: "Image" },
            { id: "prismenu-cat-graphics-palette", material: "palette", label: "Palette" },
            { id: "prismenu-cat-graphics-photo", material: "photo_camera", label: "Camera" }
        ]
    },
    System: {
        defaultId: "prismenu-cat-system-settings",
        options: [
            { id: "prismenu-cat-system-settings", material: "settings", label: "Settings" },
            { id: "prismenu-cat-system-dns", material: "dns", label: "DNS / server" },
            { id: "prismenu-cat-system-computer", material: "computer", label: "Computer" }
        ]
    },
    Settings: {
        defaultId: "prismenu-cat-tools-tune",
        options: [
            { id: "prismenu-cat-tools-tune", material: "tune", label: "Tune" },
            { id: "prismenu-cat-system-settings", material: "settings", label: "Settings" },
            { id: "prismenu-cat-system-computer", material: "computer", label: "Computer" }
        ]
    },
    Education: {
        defaultId: "prismenu-cat-edu-school",
        options: [
            { id: "prismenu-cat-edu-school", material: "school", label: "School" },
            { id: "prismenu-cat-edu-book", material: "menu_book", label: "Book" }
        ]
    },
    Game: {
        defaultId: "prismenu-cat-games-esports",
        options: [
            { id: "prismenu-cat-games-esports", material: "sports_esports", label: "Esports" },
            { id: "prismenu-cat-games-controller", material: "stadia_controller", label: "Controller" }
        ]
    },
    AudioVideo: {
        defaultId: "prismenu-cat-av-movie",
        options: [
            { id: "prismenu-cat-av-movie", material: "movie", label: "Movie" },
            { id: "prismenu-cat-av-headphones", material: "headphones", label: "Headphones" }
        ]
    },
    Science: {
        defaultId: "prismenu-cat-science-flask",
        options: [
            { id: "prismenu-cat-science-flask", material: "science", label: "Science" }
        ]
    },
    Other: {
        defaultId: "prismenu-cat-other-apps",
        options: [
            { id: "prismenu-cat-other-apps", material: "apps", label: "Apps grid" }
        ]
    }
};

function isBundled(iconId) {
    return typeof iconId === "string" && iconId.indexOf("prismenu-cat-") === 0;
}

function relativeSvgPath(iconId) {
    return "icons/categories/" + iconId + ".svg";
}

function defaultIcon(categoryId) {
    var entry = CATALOG[categoryId];
    if (entry && entry.defaultId) {
        return entry.defaultId;
    }
    return "prismenu-cat-other-apps";
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
