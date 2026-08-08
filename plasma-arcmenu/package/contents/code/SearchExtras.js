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

function mergeSearchResults(apps, extras, maxResults) {
    var out = (apps || []).slice();
    var seen = {};
    for (var i = 0; i < out.length; ++i)
        seen[String(out[i].id || "")] = true;
    for (var j = 0; j < (extras || []).length; ++j) {
        if (out.length >= maxResults)
            break;
        var e = extras[j];
        if (!e || seen[String(e.id || "")])
            continue;
        seen[String(e.id || "")] = true;
        out.push(e);
    }
    return out.slice(0, maxResults > 0 ? maxResults : out.length);
}
