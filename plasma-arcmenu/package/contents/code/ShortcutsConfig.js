.pragma library

/**
 * Resolve configurable directory / application shortcut id lists.
 */

var DEFAULT_DIRS = ["HOME", "DOCUMENTS", "DOWNLOAD", "MUSIC", "PICTURES", "VIDEOS"];
var DEFAULT_APPS = ["discover", "settings", "tweaks"];
var DEFAULT_EXTRA_ORDER = ["pinned", "all-apps", "favorites", "frequent", "recent-files"];
// Default: pinned only — “all-apps” duplicates the ArcAppsPage header
var DEFAULT_EXTRA_ON = ["pinned"];
var DEFAULT_CTX = ["configure", "separator", "power", "overview", "show-desktop"];
var DEFAULT_POWER_ORDER = ["logout", "lock", "restart", "shutdown", "suspend", "hybridsleep", "hibernate", "switchuser"];

function normalizeList(raw, fallback) {
    if (raw === undefined || raw === null)
        return (fallback || []).slice();
    if (raw === "")
        return (fallback || []).slice();
    if (typeof raw === "string") {
        var parts = raw.split(",").map(function (s) { return String(s).trim(); }).filter(function (s) { return s.length; });
        // Explicit empty string after split → empty list (not fallback)
        if (!parts.length && raw.length === 0)
            return [];
        return parts.length ? parts : (fallback || []).slice();
    }
    var out = [];
    for (var i = 0; i < raw.length; ++i) {
        var s = String(raw[i] === undefined || raw[i] === null ? "" : raw[i]).trim();
        if (s.length)
            out.push(s);
    }
    // Empty array is intentional (e.g. all extras disabled) — do not reinstate defaults
    if (raw.length === 0)
        return [];
    return out.length ? out : (fallback || []).slice();
}

function dirMeta(key, tr) {
    var map = {
        "HOME": { id: "place-home", name: tr("Home"), icon: "user-home", place: "HOME" },
        "DOCUMENTS": { id: "place-docs", name: tr("Documents"), icon: "folder-documents", place: "DOCUMENTS" },
        "DOWNLOAD": { id: "place-dl", name: tr("Downloads"), icon: "folder-download", place: "DOWNLOAD" },
        "MUSIC": { id: "place-music", name: tr("Music"), icon: "folder-music", place: "MUSIC" },
        "PICTURES": { id: "place-pics", name: tr("Pictures"), icon: "folder-pictures", place: "PICTURES" },
        "VIDEOS": { id: "place-videos", name: tr("Videos"), icon: "folder-videos", place: "VIDEOS" }
    };
    return map[key] || null;
}

function resolveDirectory(id, tr) {
    id = String(id || "");
    if (id.indexOf("custom:") === 0) {
        var rest = id.substring(7).split("|");
        var name = rest[0] || tr("Custom shortcut");
        var icon = rest[1] || "folder";
        var path = rest[2] || "";
        return {
            id: id,
            name: name,
            icon: icon,
            exec: path ? ("xdg-open " + path) : "",
            path: path
        };
    }
    var key = id.indexOf("place-") === 0 ? id.replace("place-", "").toUpperCase() : id.toUpperCase();
    if (key === "DOCS") key = "DOCUMENTS";
    if (key === "DL") key = "DOWNLOAD";
    if (key === "PICS") key = "PICTURES";
    var meta = dirMeta(key, tr);
    if (meta)
        return meta;
    return { id: id, name: id, icon: "folder", invalid: true };
}

function resolveDirectories(list, tr) {
    var ids = normalizeList(list, DEFAULT_DIRS);
    var out = [];
    for (var i = 0; i < ids.length; ++i)
        out.push(resolveDirectory(ids[i], tr));
    return out;
}

function builtinApp(id, tr) {
    var map = {
        "discover": { id: "shortcut-software", name: tr("Software"), icon: "plasmadiscover", action: "discover" },
        "software": { id: "shortcut-software", name: tr("Software"), icon: "plasmadiscover", action: "discover" },
        "settings": { id: "shortcut-settings", name: tr("Settings"), icon: "preferences-system", action: "settings" },
        "tweaks": { id: "shortcut-tweaks", name: tr("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel" },
        "overview": { id: "shortcut-overview", name: tr("Activities Overview"), icon: "overview", action: "overview" }
    };
    return map[id] || null;
}

function resolveApplication(id, tr, findAppById) {
    id = String(id || "");
    if (id.indexOf("custom:") === 0) {
        var rest = id.substring(7).split("|");
        return {
            id: id,
            name: rest[0] || tr("Custom shortcut"),
            icon: rest[1] || "application-x-executable",
            exec: rest[2] || ""
        };
    }
    var bi = builtinApp(id, tr);
    if (bi)
        return bi;
    if (id.indexOf("shortcut-") === 0) {
        var key = id.substring(9);
        bi = builtinApp(key, tr);
        if (bi)
            return bi;
    }
    if (typeof findAppById === "function") {
        var app = findAppById(id);
        if (app)
            return {
                id: app.id || id,
                name: app.name || id,
                icon: app.icon || "application-x-executable",
                exec: app.exec || "",
                kickerUrl: app.kickerUrl,
                entryPath: app.entryPath
            };
    }
    return {
        id: id,
        name: tr("Invalid shortcut") + " - " + id,
        icon: "dialog-warning",
        invalid: true
    };
}

function resolveApplications(list, tr, findAppById) {
    var ids = normalizeList(list, DEFAULT_APPS);
    var out = [];
    for (var i = 0; i < ids.length; ++i)
        out.push(resolveApplication(ids[i], tr, findAppById));
    return out;
}

function moveItem(list, from, to) {
    var arr = (list || []).slice();
    if (from < 0 || to < 0 || from >= arr.length || to >= arr.length)
        return arr;
    var item = arr.splice(from, 1)[0];
    arr.splice(to, 0, item);
    return arr;
}

function powerDefs(tr) {
    return [
        { id: "logout", name: tr("Log Out…"), icon: "system-log-out" },
        { id: "lock", name: tr("Lock"), icon: "system-lock-screen" },
        { id: "restart", name: tr("Restart…"), icon: "system-reboot" },
        { id: "shutdown", name: tr("Shut Down…"), icon: "system-shutdown" },
        { id: "suspend", name: tr("Suspend"), icon: "system-suspend" },
        { id: "hybridsleep", name: tr("Hybrid Sleep"), icon: "system-suspend-hibernate" },
        { id: "hibernate", name: tr("Hibernate"), icon: "system-hibernate" },
        { id: "switchuser", name: tr("Switch User"), icon: "system-switch-user" }
    ];
}

function extraCategoryDefs(tr) {
    return [
        { id: "pinned", name: tr("Pinned Applications"), icon: "pin" },
        { id: "all-apps", name: tr("All Applications"), icon: "view-app-grid-symbolic" },
        { id: "favorites", name: tr("Favorites"), icon: "bookmarks" },
        { id: "frequent", name: tr("Frequent Apps"), icon: "view-calendar" },
        { id: "recent-files", name: tr("Recent Files"), icon: "document-open-recent" }
    ];
}

function contextMenuDefs(tr) {
    return [
        { id: "configure", name: tr("ArcMenu Settings"), icon: "preferences-system-windows" },
        { id: "panel-settings", name: tr("Panel Extension Settings"), icon: "preferences-plugin" },
        { id: "separator", name: tr("Separator"), icon: "menu_new" },
        { id: "power", name: tr("Power Options"), icon: "system-shutdown" },
        { id: "overview", name: tr("Activities Overview"), icon: "overview" },
        { id: "show-desktop", name: tr("Show Desktop"), icon: "user-desktop" }
    ];
}
