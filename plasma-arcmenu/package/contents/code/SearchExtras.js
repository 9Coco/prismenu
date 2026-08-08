.pragma library

/**
 * Search helpers aligned with ArcMenu (highlight + secondary providers).
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
        var desc = String(it.genericName || it.description || it.path || "").toLowerCase();
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
