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
        console.warn("Prismenu: failed to parse JSON map:", e);
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
    return appsAzSectionsFromSorted(sorted);
}

/**
 * Group an already filtered and sorted app array without copying/sorting it.
 * MenuData exposes exactly this shape as sortedVisibleApps.
 */
function appsAzSectionsFromSorted(sortedApps) {
    var sorted = sortedApps || [];
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

/**
 * Flatten A–Z sections into one ListView-friendly model. Keeping section headers
 * and applications in a single model lets QML virtualize and reuse delegates;
 * nested Repeaters eagerly instantiate every application and are expensive to
 * tear down when navigating back to categories.
 */
function appsAzRowsFromSorted(sortedApps) {
    var sections = appsAzSectionsFromSorted(sortedApps || []);
    return appsAzRowsFromSections(sections);
}

/** Flatten precomputed A–Z sections without regrouping the catalog. */
function appsAzRowsFromSections(sections) {
    var grouped = sections || [];
    var rows = [];
    for (var i = 0; i < grouped.length; ++i) {
        rows.push({
            id: "__az_section_" + grouped[i].letter,
            name: grouped[i].letter,
            isSection: true
        });
        for (var j = 0; j < grouped[i].apps.length; ++j) {
            rows.push(grouped[i].apps[j]);
        }
    }
    return rows;
}

function categoryMatches(appCats, categoryId) {
    if (!categoryId) {
        return false;
    }
    var cats = appCats || [];
    for (var j = 0; j < cats.length; ++j) {
        if (cats[j] === categoryId) {
            return true;
        }
    }
    // Prismenu "系统工具" also includes Settings-tagged apps
    if (categoryId === "System") {
        for (var s = 0; s < cats.length; ++s) {
            if (cats[s] === "Settings") {
                return true;
            }
        }
    }
    // "附件" and "工具" overlap on many desktops
    if (categoryId === "Accessories") {
        for (var a = 0; a < cats.length; ++a) {
            if (cats[a] === "Utility") {
                return true;
            }
        }
    }
    return false;
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
        if (categoryMatches(app.categories, categoryId)) {
            result.push(app);
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
    { id: "Development", name: "Development", icon: "prismenu-cat-dev-brush" },
    { id: "Education", name: "Education", icon: "prismenu-cat-edu-school" },
    { id: "Game", name: "Games", icon: "prismenu-cat-games-esports" },
    { id: "Graphics", name: "Graphics", icon: "prismenu-cat-graphics-image" },
    { id: "Network", name: "Internet", icon: "prismenu-cat-internet-public" },
    { id: "AudioVideo", name: "Multimedia", icon: "prismenu-cat-av-movie" },
    { id: "Office", name: "Office", icon: "prismenu-cat-office-barchart" },
    { id: "Settings", name: "Settings", icon: "prismenu-cat-tools-tune" },
    { id: "System", name: "System", icon: "prismenu-cat-system-settings" },
    { id: "Utility", name: "Utilities", icon: "prismenu-cat-tools-build" },
    { id: "Accessories", name: "Accessories", icon: "prismenu-cat-accessories-handyman" }
];

function defaultCategories() {
    return DEFAULT_CATEGORIES.slice();
}

/** Normalize extra-category / drill-down ids onto one storage key. */
function canonicalGroupId(groupId) {
    var id = String(groupId || "");
    if (id === "all")
        return "all-apps";
    if (id === "favorites")
        return "pinned";
    return id;
}

function isSectionId(id) {
    id = String(id || "");
    return id.indexOf("__az_section_") === 0 || id.indexOf("__section_") === 0;
}

function itemsHaveSections(items) {
    var list = items || [];
    for (var i = 0; i < list.length; ++i) {
        if (list[i] && (list[i].isSection || isSectionId(list[i].id)))
            return true;
    }
    return false;
}

/**
 * Groups whose rows have a user-mutable order: pinned, all-apps, system
 * categories, and custom groups. Recency / places lists stay read-only.
 */
function canReorderGroup(groupId) {
    var id = canonicalGroupId(groupId);
    if (!id)
        return false;
    if (id === "frequent" || id === "recent-files" || id === "bookmarks"
            || id === "devices" || id === "search" || id === "computer"
            || id === "leave" || id === "history")
        return false;
    if (id.indexOf("__") === 0)
        return false;
    return true;
}

/**
 * Re-apply a stored id order onto a live app array. Unknown / uninstalled
 * ids are dropped; apps missing from the stored list keep their incoming
 * relative order and are appended (so newly installed apps still appear).
 */
function applyAppListOrder(apps, storedIds) {
    var list = apps || [];
    var order = storedIds || [];
    if (!order.length)
        return list;
    var byId = {};
    var i;
    for (i = 0; i < list.length; ++i) {
        if (!list[i])
            continue;
        var key = String(list[i].id || "");
        if (key && !byId[key])
            byId[key] = list[i];
    }
    var out = [];
    var seen = {};
    for (i = 0; i < order.length; ++i) {
        var id = String(order[i] || "");
        if (!id || seen[id] || !byId[id])
            continue;
        seen[id] = true;
        out.push(byId[id]);
    }
    for (i = 0; i < list.length; ++i) {
        var app = list[i];
        if (!app)
            continue;
        var appId = String(app.id || "");
        if (appId && seen[appId])
            continue;
        if (appId)
            seen[appId] = true;
        out.push(app);
    }
    return out;
}
