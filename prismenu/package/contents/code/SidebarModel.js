.pragma library

/**
 * Shared application-sidebar model.
 *
 * Layouts consume stable item ids while settings own order/visibility. Native
 * categories and custom app groups are appended automatically when discovered,
 * so an older saved order never hides newly installed categories.
 */

function normalizeList(raw) {
    if (raw === undefined || raw === null || raw === "")
        return [];
    if (typeof raw === "string")
        raw = raw.split(",");
    var out = [];
    for (var i = 0; i < (raw || []).length; ++i) {
        var value = String(raw[i] || "").trim();
        if (value && out.indexOf(value) < 0)
            out.push(value);
    }
    return out;
}

function definitions(categories, customGroups, tr) {
    var out = [
        { id: "special:favorites", kind: "favorites", target: "favorites",
          name: tr("Favorite Applications"), icon: "bookmarks" },
        { id: "special:all", kind: "all", target: "all",
          name: tr("All Applications"), icon: "view-app-grid-symbolic" }
    ];

    for (var i = 0; i < (categories || []).length; ++i) {
        var category = categories[i];
        if (!category || !category.id || category.id === "all")
            continue;
        out.push({
            id: "category:" + category.id,
            kind: "category",
            target: category.id,
            name: category.name || category.id,
            icon: category.icon || "applications-other"
        });
    }

    for (var j = 0; j < (customGroups || []).length; ++j) {
        var group = customGroups[j];
        if (!group || !group.id)
            continue;
        out.push({
            id: "group:" + group.id,
            kind: "group",
            target: group.id,
            name: group.name || group.id,
            icon: group.icon || "folder-favorites"
        });
    }
    return out;
}

function orderedItems(categories, customGroups, orderRaw, hiddenRaw, tr) {
    var defs = definitions(categories, customGroups, tr);
    var order = normalizeList(orderRaw);
    var hidden = normalizeList(hiddenRaw);
    var byId = {};
    var out = [];
    var seen = {};
    for (var i = 0; i < defs.length; ++i)
        byId[defs[i].id] = defs[i];

    for (var o = 0; o < order.length; ++o) {
        var id = order[o];
        if (byId[id] && hidden.indexOf(id) < 0 && !seen[id]) {
            out.push(byId[id]);
            seen[id] = true;
        }
    }
    for (var d = 0; d < defs.length; ++d) {
        var def = defs[d];
        if (!seen[def.id] && hidden.indexOf(def.id) < 0)
            out.push(def);
    }
    return out;
}

function fullOrder(categories, customGroups, orderRaw, tr) {
    var defs = definitions(categories, customGroups, tr);
    var order = normalizeList(orderRaw);
    var byId = {};
    var out = [];
    for (var i = 0; i < defs.length; ++i)
        byId[defs[i].id] = true;
    for (var o = 0; o < order.length; ++o) {
        if (byId[order[o]] && out.indexOf(order[o]) < 0)
            out.push(order[o]);
    }
    for (var d = 0; d < defs.length; ++d) {
        if (out.indexOf(defs[d].id) < 0)
            out.push(defs[d].id);
    }
    return out;
}
