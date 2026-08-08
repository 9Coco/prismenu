.pragma library

/**
 * Application and category data helpers.
 * Prefer KService / AppStream via QML models when available;
 * these helpers provide filtering, sorting, and fallback matching.
 */

function parseJsonMap(raw) {
    if (!raw || raw === "") {
        return {};
    }
    try {
        return JSON.parse(raw);
    } catch (e) {
        console.warn("ArcMenu: failed to parse JSON map:", e);
        return {};
    }
}

function stringifyJsonMap(obj) {
    try {
        return JSON.stringify(obj || {});
    } catch (e) {
        return "{}";
    }
}

function localizedCompare(a, b) {
    return String(a || "").localeCompare(String(b || ""), undefined, { sensitivity: "base" });
}

function filterVisibleApps(apps) {
    var result = [];
    for (var i = 0; i < apps.length; ++i) {
        var app = apps[i];
        if (!app) {
            continue;
        }
        if (app.noDisplay === true) {
            continue;
        }
        result.push(app);
    }
    return result;
}

function sortAppsByName(apps) {
    var copy = apps.slice();
    copy.sort(function (a, b) {
        return localizedCompare(a.name, b.name);
    });
    return copy;
}

/**
 * First letter key for A–Z sections. Latin → uppercase; digits/symbols → "#";
 * other scripts keep the first character.
 */
function firstLetterKey(name) {
    var ch = String(name || "").trim().charAt(0);
    if (!ch) {
        return "#";
    }
    if (/[0-9]/.test(ch)) {
        return "#";
    }
    if (/[a-zA-Z]/.test(ch)) {
        return ch.toUpperCase();
    }
    return ch;
}

/**
 * Group visible apps into A–Z sections: [{ letter, apps: [...] }, ...]
 */
function appsAzSections(apps) {
    var sorted = sortAppsByName(filterVisibleApps(apps || []));
    var sections = [];
    var current = null;
    for (var i = 0; i < sorted.length; ++i) {
        var app = sorted[i];
        var key = firstLetterKey(app.name);
        if (!current || current.letter !== key) {
            current = { letter: key, apps: [] };
            sections.push(current);
        }
        current.apps.push(app);
    }
    return sections;
}

function appsInCategory(apps, categoryId) {
    if (!categoryId || categoryId === "all") {
        return sortAppsByName(filterVisibleApps(apps));
    }
    var result = [];
    for (var i = 0; i < apps.length; ++i) {
        var app = apps[i];
        if (!app || app.noDisplay) {
            continue;
        }
        var cats = app.categories || [];
        for (var j = 0; j < cats.length; ++j) {
            if (cats[j] === categoryId) {
                result.push(app);
                break;
            }
        }
    }
    return sortAppsByName(result);
}

function applyCategoryCustomization(categories, order, hidden, customNames, customIcons, showEmpty) {
    var hiddenSet = {};
    for (var h = 0; h < (hidden || []).length; ++h) {
        hiddenSet[hidden[h]] = true;
    }
    var names = typeof customNames === "string" ? parseJsonMap(customNames) : (customNames || {});
    var icons = typeof customIcons === "string" ? parseJsonMap(customIcons) : (customIcons || {});

    var byId = {};
    for (var i = 0; i < categories.length; ++i) {
        byId[categories[i].id] = categories[i];
    }

    var ordered = [];
    var used = {};
    var orderList = order || [];
    for (var o = 0; o < orderList.length; ++o) {
        var id = orderList[o];
        if (byId[id] && !hiddenSet[id]) {
            var c = Object.assign({}, byId[id]);
            if (names[id]) {
                c.name = names[id];
            }
            if (icons[id]) {
                c.icon = icons[id];
            }
            if (showEmpty || (c.appCount && c.appCount > 0) || (c.apps && c.apps.length > 0)) {
                ordered.push(c);
            }
            used[id] = true;
        }
    }

    for (var k = 0; k < categories.length; ++k) {
        var cat = categories[k];
        if (used[cat.id] || hiddenSet[cat.id]) {
            continue;
        }
        var c2 = Object.assign({}, cat);
        if (names[cat.id]) {
            c2.name = names[cat.id];
        }
        if (icons[cat.id]) {
            c2.icon = icons[cat.id];
        }
        if (showEmpty || (c2.appCount && c2.appCount > 0) || (c2.apps && c2.apps.length > 0)) {
            ordered.push(c2);
        }
    }
    return ordered;
}

function matchApp(app, query) {
    if (!query) {
        return 0;
    }
    var q = query.toLowerCase();
    var name = (app.name || "").toLowerCase();
    var generic = (app.genericName || "").toLowerCase();
    var id = (app.id || "").toLowerCase();
    var keywords = app.keywords || [];

    if (name.indexOf(q) === 0) {
        return 100;
    }
    if (name.indexOf(q) >= 0) {
        return 80;
    }
    if (generic.indexOf(q) >= 0) {
        return 60;
    }
    for (var i = 0; i < keywords.length; ++i) {
        if (String(keywords[i]).toLowerCase().indexOf(q) >= 0) {
            return 40;
        }
    }
    if (id.indexOf(q) >= 0) {
        return 20;
    }
    return 0;
}

function searchApps(apps, query, maxResults) {
    var scored = [];
    for (var i = 0; i < apps.length; ++i) {
        var app = apps[i];
        if (!app || app.noDisplay) {
            continue;
        }
        var score = matchApp(app, query);
        if (score > 0) {
            scored.push({ app: app, score: score });
        }
    }
    scored.sort(function (a, b) {
        if (b.score !== a.score) {
            return b.score - a.score;
        }
        return localizedCompare(a.app.name, b.app.name);
    });
    var limit = maxResults > 0 ? maxResults : scored.length;
    var result = [];
    for (var j = 0; j < Math.min(limit, scored.length); ++j) {
        result.push(scored[j].app);
    }
    return result;
}

function findAppById(apps, id) {
    for (var i = 0; i < apps.length; ++i) {
        if (apps[i] && apps[i].id === id) {
            return apps[i];
        }
    }
    return null;
}

function resolveAppsByIds(apps, ids) {
    var result = [];
    for (var i = 0; i < (ids || []).length; ++i) {
        var app = findAppById(apps, ids[i]);
        if (app) {
            result.push(app);
        }
    }
    return result;
}

// Icons: Material Symbols Outlined (see CategoryIcons.js + icons/categories/)
var DEFAULT_CATEGORIES = [
    { id: "Development", name: "Development", icon: "arcmenu-cat-dev-brush" },
    { id: "Education", name: "Education", icon: "arcmenu-cat-edu-school" },
    { id: "Game", name: "Games", icon: "arcmenu-cat-games-esports" },
    { id: "Graphics", name: "Graphics", icon: "arcmenu-cat-graphics-image" },
    { id: "Network", name: "Internet", icon: "arcmenu-cat-internet-public" },
    { id: "AudioVideo", name: "Multimedia", icon: "arcmenu-cat-av-movie" },
    { id: "Office", name: "Office", icon: "arcmenu-cat-office-barchart" },
    { id: "Settings", name: "Settings", icon: "arcmenu-cat-tools-tune" },
    { id: "System", name: "System", icon: "arcmenu-cat-system-settings" },
    { id: "Utility", name: "Utilities", icon: "arcmenu-cat-tools-build" },
    { id: "Accessories", name: "Accessories", icon: "arcmenu-cat-accessories-handyman" }
];

function defaultCategories() {
    return DEFAULT_CATEGORIES.slice();
}
