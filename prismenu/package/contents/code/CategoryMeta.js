.pragma library

/**
 * Shared semantic metadata for categories supplied by Plasma Kicker.
 *
 * Most XDG categories already provide a useful decoration. Some synthetic
 * categories (Help and browser-hosted application groups) only expose the
 * generic applications icon, so normalize those here for every layout.
 */

var ID_ICONS = {
    Help: "help-browser"
};

var NAMED_GROUP_ICONS = [
    { terms: ["microsoft edge", "edge applications", "edge apps", "edge 应用"], icon: "microsoft-edge" },
    { terms: ["google chrome", "chrome applications", "chrome apps", "chrome 应用"], icon: "google-chrome" },
    { terms: ["chromium"], icon: "chromium" },
    { terms: ["firefox"], icon: "firefox" }
];

function iconForCategory(name, categoryId, backendIcon) {
    if (ID_ICONS[categoryId])
        return ID_ICONS[categoryId];

    var normalized = String(name || "").trim().toLowerCase();
    for (var i = 0; i < NAMED_GROUP_ICONS.length; ++i) {
        var rule = NAMED_GROUP_ICONS[i];
        for (var j = 0; j < rule.terms.length; ++j) {
            if (normalized.indexOf(rule.terms[j]) >= 0)
                return rule.icon;
        }
    }

    return backendIcon || "applications-other";
}
