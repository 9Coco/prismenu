.pragma library

/**
 * Search helpers aligned with Prismenu (highlight + secondary providers).
 */

function escapeHtml(s) {
    return String(s || "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
}

/**
 * Highlight query terms in plain text → HTML (for Text.RichText).
 * Mirrors GNOME Highlighter / ArcMenu highlight-search-result-terms.
 */
function highlightMarkup(text, query) {
    var raw = String(text || "");
    if (!query || !String(query).trim())
        return escapeHtml(raw);
    var terms = String(query).trim().toLowerCase().split(/\s+/).filter(function (t) {
        return t.length > 0;
    });
    if (!terms.length)
        return escapeHtml(raw);

    var lower = raw.toLowerCase();
    var marks = [];
    for (var t = 0; t < terms.length; ++t) {
        var term = terms[t];
        var from = 0;
        while (from < lower.length) {
            var idx = lower.indexOf(term, from);
            if (idx < 0)
                break;
            marks.push({ start: idx, end: idx + term.length });
            from = idx + term.length;
        }
    }
    if (!marks.length)
        return escapeHtml(raw);

    marks.sort(function (a, b) { return a.start - b.start; });
    var merged = [];
    for (var i = 0; i < marks.length; ++i) {
        var m = marks[i];
        if (!merged.length || m.start > merged[merged.length - 1].end) {
            merged.push({ start: m.start, end: m.end });
        } else if (m.end > merged[merged.length - 1].end) {
            merged[merged.length - 1].end = m.end;
        }
    }

    var out = "";
    var cursor = 0;
    for (var j = 0; j < merged.length; ++j) {
        var g = merged[j];
        out += escapeHtml(raw.substring(cursor, g.start));
        out += "<b>" + escapeHtml(raw.substring(g.start, g.end)) + "</b>";
        cursor = g.end;
    }
    out += escapeHtml(raw.substring(cursor));
    return out;
}

/**
 * Icon for a search/app/Places row. Prefer the live native `decoration` so
 * place icons, favicons, MIME icons, and window pixmaps survive; fall back to a theme name.
 */
function resultIconSource(app) {
    if (!app)
        return "application-x-executable";
    var dec = null;
    try {
        if (app.iconHolder && app.iconHolder.decoration !== undefined)
            dec = app.iconHolder.decoration;
    } catch (e0) {}
    if (dec === undefined || dec === null || dec === "")
        dec = app.decoration;
    if (dec !== undefined && dec !== null && dec !== "") {
        try {
            if (dec.isNull === true)
                dec = null;
        } catch (e) {}
        if (dec) {
            if (typeof dec !== "string")
                return dec;
            if (dec.length)
                return dec;
        }
    }
    if (app.icon && String(app.icon).length)
        return app.icon;
    return "application-x-executable";
}

function fallbackSearchIcon(item) {
    var section = classifySearchItem(item);
    var url = String(item.kickerUrl || item.entryPath || item.url || "").toLowerCase();
    if (section === "bookmarks" || /^https?:/.test(url))
        return "bookmarks";
    if (section === "places") {
        if (/^(sftp|ftp|smb|nfs|fish|webdav|davs?|remote|mtp|kdeconnect|bluetooth|phone):/.test(url))
            return "folder-remote";
        return "folder";
    }
    if (section === "windows")
        return "window";
    if (section === "files")
        return "text-x-generic";
    if (section === "settings")
        return "preferences-system";
    return "application-x-executable";
}

function filterByQuery(items, query, nameKey) {
    nameKey = nameKey || "name";
    var q = String(query || "").trim().toLowerCase();
    if (!q)
        return (items || []).slice();
    var out = [];
    for (var i = 0; i < (items || []).length; ++i) {
        var it = items[i];
        if (!it)
            continue;
        var name = String(it[nameKey] || "").toLowerCase();
        var desc = String(it.genericName || it.description || it.path
            || it.kickerUrl || it.entryPath || "").toLowerCase();
        if (name.indexOf(q) >= 0 || desc.indexOf(q) >= 0)
            out.push(it);
    }
    return out;
}

/**
 * Merge app hits with secondary providers (windows / recent files).
 * Reserve a share of the maxResults budget for extras so they are not
 * crowded out when many apps match (ArcMenu-style multi-provider search).
 */
function mergeSearchResults(apps, extras, maxResults) {
    var limit = maxResults > 0 ? maxResults : 50;
    apps = apps || [];
    extras = extras || [];
    var extrasBudget = 0;
    if (extras.length)
        extrasBudget = Math.min(extras.length, Math.max(2, Math.floor(limit / 3)));
    var appBudget = Math.max(1, limit - extrasBudget);

    var out = [];
    var seen = {};
    for (var i = 0; i < apps.length && out.length < appBudget; ++i) {
        var a = apps[i];
        if (!a)
            continue;
        var aid = String(a.id || "");
        if (aid && seen[aid])
            continue;
        if (aid)
            seen[aid] = true;
        out.push(a);
    }
    for (var j = 0; j < extras.length && out.length < limit; ++j) {
        var e = extras[j];
        if (!e)
            continue;
        var eid = String(e.id || "");
        if (eid && seen[eid])
            continue;
        if (eid)
            seen[eid] = true;
        out.push(e);
    }
    return out;
}

/**
 * Classify a result into an ArcMenu-style search section.
 * Kickoff groups: Applications / Locations / Windows / Bookmarks / Files / Settings.
 * @returns {"applications"|"settings"|"places"|"windows"|"bookmarks"|"files"|"other"}
 */
function classifySearchItem(item) {
    if (!item)
        return "other";
    if (item.isSection)
        return "other";
    var provider = String(item.provider || "").toLowerCase();
    if (provider === "windows" || provider === "window")
        return "windows";
    if (provider === "kfileplaces" || provider === "places" || provider === "locations")
        return "places";
    if (provider === "bookmarks" || provider === "bookmark")
        return "bookmarks";
    if (provider === "recent-files" || provider === "files")
        return "files";
    if (provider === "settings" || provider === "kcm")
        return "settings";
    if (provider === "applications" || provider === "apps" || provider === "services")
        return "applications";

    var group = String(item.group || item.category || "").toLowerCase();
    if (group) {
        if (group.indexOf("bookmark") >= 0 || group.indexOf("书签") >= 0
            || group.indexOf("收藏") >= 0)
            return "bookmarks";
        if (group.indexOf("place") >= 0 || group.indexOf("location") >= 0
            || group.indexOf("位置") >= 0 || group.indexOf("地点") >= 0)
            return "places";
        if (group.indexOf("setting") >= 0 || group.indexOf("设置") >= 0
            || group.indexOf("system setting") >= 0 || group.indexOf("kcm") >= 0)
            return "settings";
        if (group.indexOf("file") >= 0 || group.indexOf("document") >= 0
            || group.indexOf("文件") >= 0 || group.indexOf("baloo") >= 0
            || group.indexOf("recent") >= 0)
            return "files";
        if (group.indexOf("window") >= 0 || group.indexOf("窗口") >= 0
            || group.indexOf("task") >= 0)
            return "windows";
        if (group.indexOf("app") >= 0 || group.indexOf("application") >= 0
            || group.indexOf("应用") >= 0 || group.indexOf("program") >= 0
            || group.indexOf("software") >= 0 || group.indexOf("软件") >= 0)
            return "applications";
        if (group.indexOf("clock") >= 0 || group.indexOf("时钟") >= 0
            || group.indexOf("calculator") >= 0 || group.indexOf("unit") >= 0)
            return "other";
    }

    var url = String(item.kickerUrl || item.entryPath || item.url || "").toLowerCase();
    var fav = String(item.favoriteId || item.id || "").toLowerCase();
    var detail = String(item.genericName || item.description || "").trim().toLowerCase();
    if (/^https?:/.test(url) || /^https?:/.test(detail))
        return "bookmarks";
    if (/^(sftp|ftp|smb|nfs|fish|webdav|davs?|remote|mtp|kdeconnect|bluetooth|timeline|phone):/.test(url)
        || /^(sftp|ftp|smb|nfs|fish|webdav|davs?|remote|mtp|kdeconnect|bluetooth|timeline|phone):/.test(detail)
        || url.indexOf("locations:") === 0)
        return "places";
    if (url.indexOf("applications:") === 0 || fav.indexOf(".desktop") >= 0)
        return "applications";
    if (url.indexOf("file:") === 0 || url.indexOf("/") === 0
        || detail.indexOf("~/") === 0 || detail.indexOf("/") === 0) {
        var leaf = (url || detail).split("/").pop() || "";
        try { leaf = decodeURIComponent(leaf); } catch (e) {}
        if (leaf && /\.[a-z0-9]{1,8}$/i.test(leaf))
            return "files";
        return "places";
    }
    if (/\.(md|txt|pdf|png|jpg|jpeg|svg|odt|docx?|xlsx?|csv)$/i.test(url)
        || /\.(md|txt|pdf)$/i.test(String(item.name || "")))
        return "files";
    if (url.indexOf("kcm") >= 0 || url.indexOf("systemsettings") >= 0
        || fav.indexOf("kcm_") >= 0 || String(item.id || "").indexOf("kcm_") >= 0)
        return "settings";
    if (String(item.id || "").indexOf("window:") === 0)
        return "windows";
    if (String(item.id || "").indexOf("bookmark:") === 0)
        return "bookmarks";

    if (provider === "runner")
        return "applications";
    return "applications";
}

/**
 * Insert section headers between providers (GNOME ArcMenu / target screenshot).
 * trFn(msgid) → localized string. Headers look like "文件" or "设置 6 more".
 */
function groupSearchResults(items, maxResults, trFn) {
    var limit = maxResults > 0 ? maxResults : 50;
    trFn = trFn || function (s) { return s; };
    var order = ["applications", "settings", "places", "windows", "bookmarks", "files", "other"];
    var labelKey = {
        applications: "Applications",
        settings: "Settings",
        places: "Locations",
        windows: "Windows",
        bookmarks: "Bookmarks",
        files: "Files",
        other: "Other"
    };
    var buckets = {};
    var b;
    for (b = 0; b < order.length; ++b)
        buckets[order[b]] = [];

    var list = items || [];
    for (var i = 0; i < list.length; ++i) {
        var it = list[i];
        if (!it || it.isSection)
            continue;
        var key = classifySearchItem(it);
        if (!buckets[key])
            key = "other";
        buckets[key].push(it);
    }

    // Soft per-section caps so one provider cannot eat the whole list
    var sectionCap = Math.max(3, Math.ceil(limit / 2));
    var out = [];
    for (var o = 0; o < order.length; ++o) {
        var id = order[o];
        var all = buckets[id] || [];
        if (!all.length)
            continue;
        var shown = all.slice(0, sectionCap);
        // Stop if we already filled the global budget (headers don't count against it much)
        var room = limit - out.filter(function (x) { return !x.isSection; }).length;
        if (room <= 0)
            break;
        if (shown.length > room)
            shown = shown.slice(0, room);
        var hidden = Math.max(0, all.length - shown.length);
        var title = trFn(labelKey[id] || id);
        if (hidden > 0)
            title = title + " " + String(hidden) + " " + trFn("more");
        out.push({
            id: "section:" + id,
            name: title,
            icon: "",
            isSection: true,
            sectionId: id,
            sectionCount: all.length,
            noDisplay: false
        });
        for (var s = 0; s < shown.length; ++s)
            out.push(shown[s]);
    }
    return out;
}

function _resultKey(item) {
    if (!item)
        return "";
    var url = String(item.kickerUrl || item.entryPath || item.url || "").toLowerCase();
    if (url)
        return "url:" + url;
    var detail = String(item.genericName || item.description || "").toLowerCase();
    if (/^(file|sftp|ftp|smb|nfs|fish|webdav|dav|remote|mtp|kdeconnect|https?):/.test(detail)
        || detail.indexOf("~/") === 0 || detail.indexOf("/") === 0)
        return "location:" + detail;
    var id = String(item.favoriteId || item.id || "").toLowerCase();
    if (id)
        return "id:" + id;
    return "name:" + String(item.name || "").toLowerCase();
}

/**
 * Build the shared, sectioned search model used by list layouts.
 *
 * `maxPerSection` deliberately applies to each provider group. Applying one
 * global cap made application hits consume the entire budget, so Places and
 * Recent Files never appeared even when their native models had matches.
 */
function composeSearchResults(primary, places, recentFiles, windows, bookmarks, query,
                              maxPerSection, trFn) {
    // Compat with the previous (…, windows, query, max, trFn) signature.
    if (typeof bookmarks === "string") {
        trFn = maxPerSection;
        maxPerSection = query;
        query = bookmarks;
        bookmarks = [];
    }
    var cap = maxPerSection > 0 ? maxPerSection : 20;
    trFn = trFn || function (s) { return s; };
    var order = ["applications", "settings", "places", "windows", "bookmarks", "files", "other"];
    var labelKey = {
        applications: "Applications",
        settings: "Settings",
        places: "Locations",
        windows: "Windows",
        bookmarks: "Bookmarks",
        files: "Recent Files",
        other: "Other"
    };
    var buckets = {};
    var seen = {};
    var seenInSection = {};
    for (var i = 0; i < order.length; ++i)
        buckets[order[i]] = [];

    function add(item, forcedSection) {
        if (!item || item.isSection || item.special)
            return;
        var section = forcedSection || classifySearchItem(item);
        if (!buckets[section])
            section = "other";
        var key = _resultKey(item);
        if (key && seen[key])
            return;
        var nameKey = String(item.name || "").trim().toLowerCase();
        var sectionName = section + "\0" + nameKey;
        // Same URL (runner + native adapter) is one hit. Same name in another
        // section is not — Kickoff shows Clash Verge as both an app and a window.
        if (nameKey && seenInSection[sectionName])
            return;
        if (key)
            seen[key] = true;
        if (nameKey)
            seenInSection[sectionName] = true;
        buckets[section].push(item);
    }

    var main = primary || [];
    for (var p = 0; p < main.length; ++p)
        add(main[p], "");

    var matchingPlaces = filterByQuery(places || [], query);
    for (var l = 0; l < matchingPlaces.length; ++l)
        add(matchingPlaces[l], "places");

    var matchingFiles = filterByQuery(recentFiles || [], query);
    for (var f = 0; f < matchingFiles.length; ++f)
        add(matchingFiles[f], "files");

    var matchingWindows = filterByQuery(windows || [], query);
    for (var w = 0; w < matchingWindows.length; ++w)
        add(matchingWindows[w], "windows");

    var matchingBookmarks = filterByQuery(bookmarks || [], query);
    for (var b = 0; b < matchingBookmarks.length; ++b)
        add(matchingBookmarks[b], "bookmarks");

    var out = [];
    for (var o = 0; o < order.length; ++o) {
        var sectionId = order[o];
        var all = buckets[sectionId];
        if (!all.length)
            continue;
        var shown = all.slice(0, cap);
        var hidden = Math.max(0, all.length - shown.length);
        var title = trFn(labelKey[sectionId]);
        if (hidden > 0)
            title += " " + String(hidden) + " " + trFn("more");
        out.push({
            id: "section:" + sectionId,
            name: title,
            isSection: true,
            sectionId: sectionId,
            sectionCount: all.length,
            noDisplay: false
        });
        for (var s = 0; s < shown.length; ++s)
            out.push(shown[s]);
    }
    return out;
}
