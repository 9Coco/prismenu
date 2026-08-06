import QtQuick
import "../../code/PageRegistry.js" as PageRegistry

/**
 * Page display host — loads the active page module by id.
 * Chrome (sidebar / search / session) stays outside this host.
 */
Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})
    property string pageId: "home"

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    readonly property var pageMeta: PageRegistry.getPage(pageId)

    function pageUrl(meta) {
        if (!meta || !meta.source) {
            return "";
        }
        // PageRegistry sources are filenames relative to this pages/ folder
        return Qt.resolvedUrl(meta.source);
    }

    Loader {
        id: pageLoader
        anchors.fill: parent
        asynchronous: false
        source: root.pageUrl(root.pageMeta)

        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("ArcMenu PageHost failed to load:", source);
            }
        }
        onLoaded: wire()
    }

    onPageIdChanged: {
        var src = root.pageUrl(root.pageMeta);
        if (String(pageLoader.source) !== String(src)) {
            pageLoader.source = src;
        } else {
            wire();
        }
    }

    onMenuDataChanged: wire()
    onThemeStyleChanged: wire()

    function wire() {
        var item = pageLoader.item;
        if (!item) {
            return;
        }
        item.menuData = root.menuData;
        item.themeStyle = root.themeStyle;
        if (item.appActivated) {
            try { item.appActivated.disconnect(root.appActivated); } catch (e) {}
            item.appActivated.connect(root.appActivated);
        }
        if (item.appContextMenu) {
            try { item.appContextMenu.disconnect(root.appContextMenu); } catch (e2) {}
            item.appContextMenu.connect(root.appContextMenu);
        }
    }
}
