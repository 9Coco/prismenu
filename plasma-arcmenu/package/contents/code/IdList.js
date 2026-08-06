.pragma library

/**
 * Normalize Plasma StringList / QStringList / comma-string into a clean id array.
 */
function normalizeIdList(raw) {
    if (raw === undefined || raw === null || raw === "") {
        return [];
    }
    if (typeof raw === "string") {
        return raw.split(",").map(function (s) {
            return String(s).trim();
        }).filter(function (s) {
            return s.length > 0;
        });
    }
    var out = [];
    for (var i = 0; i < raw.length; ++i) {
        var s = String(raw[i] === undefined || raw[i] === null ? "" : raw[i]).trim();
        if (s.length > 0) {
            out.push(s);
        }
    }
    return out;
}

function defaultPinnedIds() {
    return ["org.kde.dolphin.desktop", "arcmenu-settings"];
}
