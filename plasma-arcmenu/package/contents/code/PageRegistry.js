.pragma library

/**
 * Page display registry — layouts load pages by id, independent of chrome modules.
 * `source` is a filename inside ui/pages/ (resolved by PageHost).
 */

var PAGES = [
    {
        id: "home",
        name: "Home",
        description: "Pinned applications",
        source: "ArcHomePage.qml"
    },
    {
        id: "apps",
        name: "All Applications",
        description: "Category browser",
        source: "ArcAppsPage.qml"
    },
    {
        id: "search",
        name: "Search",
        description: "Search results",
        source: "ArcSearchPage.qml"
    }
];

function allPages() {
    return PAGES.slice();
}

function getPage(id) {
    for (var i = 0; i < PAGES.length; ++i) {
        if (PAGES[i].id === id) {
            return PAGES[i];
        }
    }
    return PAGES[0];
}
