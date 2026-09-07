.pragma library

/**
 * Process-wide pointer to the live MenuData instance.
 * Avoids Loader/LayoutHost dropping property var menuData (catalog → 0).
 */
var menuDataRef = null;

function setMenuData(md) {
    menuDataRef = md || null;
}

function menuData() {
    return menuDataRef;
}

function allApps() {
    if (!menuDataRef || !menuDataRef.allApps)
        return [];
    return menuDataRef.allApps;
}

function appCount() {
    return allApps().length;
}
