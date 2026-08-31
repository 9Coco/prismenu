import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../code/LayoutRegistry.js" as LayoutRegistry
import "../code/CatalogBridge.js" as CatalogBridge

Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y, var anchor)
    signal powerAction(string actionId)
    signal userMenu()
    signal keepOpenRequested(bool pinned)

    readonly property string layoutId: {
        var fromConfig = "";
        try {
            fromConfig = String(plasmoid.configuration.MenuLayoutId || "");
        } catch (e) {
            fromConfig = "";
        }
        if (fromConfig.length)
            return fromConfig;
        var md = root.resolvedMenuData();
        if (md && md.currentLayoutId)
            return md.currentLayoutId;
        return "arcmenu";
    }

    readonly property var layoutMeta: LayoutRegistry.getLayout(layoutId)

    readonly property int sidePanelWidth: (layoutLoader.item && layoutLoader.item.sidePanelWidth !== undefined)
            ? layoutLoader.item.sidePanelWidth
            : 0

    width: {
        var md = root.resolvedMenuData();
        return (md ? md.menuWidth : 600) + sidePanelWidth;
    }
    height: {
        var md = root.resolvedMenuData();
        return (parent && parent.height >= 400) ? parent.height : (md ? md.menuHeight : 550);
    }

    property string _loadedLayoutId: ""
    property bool _resetForOpenPending: false

    function resolvedMenuData() {
        if (root.menuData)
            return root.menuData;
        return CatalogBridge.menuData();
    }

    function layoutUrl() {
        if (layoutMeta && layoutMeta.source)
            return Qt.resolvedUrl(layoutMeta.source);
        return Qt.resolvedUrl("layouts/LayoutArcMenu.qml");
    }

    function reloadLayout() {
        var id = root.layoutId;
        // Only recreate when the layout *id* changes — never on catalog updates
        if (layoutLoader.item && root._loadedLayoutId === id) {
            wireItem();
            return;
        }
        console.log("ArcMenu LayoutHost reload:", id, layoutUrl(),
                    "catalog=", CatalogBridge.appCount());
        root._loadedLayoutId = id;
        layoutLoader.setSource(layoutUrl(), {
            menuData: root.resolvedMenuData(),
            themeStyle: root.themeStyle
        });
    }

    function wireItem() {
        var item = layoutLoader.item;
        if (!item)
            return;
        var md = root.resolvedMenuData();
        // Direct object reference (stable). Do not use Qt.binding here.
        item.menuData = md;
        item.themeStyle = root.themeStyle;
        if (item.reattachCatalog)
            item.reattachCatalog();
        if (item.appActivated) {
            try { item.appActivated.disconnect(root.appActivated); } catch (e) {}
            item.appActivated.connect(root.appActivated);
        }
        if (item.appContextMenu) {
            try { item.appContextMenu.disconnect(root.appContextMenu); } catch (e2) {}
            item.appContextMenu.connect(root.appContextMenu);
        }
        if (item.powerAction) {
            try { item.powerAction.disconnect(root.powerAction); } catch (e3) {}
            item.powerAction.connect(root.powerAction);
        }
        if (item.userMenu) {
            try { item.userMenu.disconnect(root.userMenu); } catch (e4) {}
            item.userMenu.connect(root.userMenu);
        }
        if (item.keepOpenRequested) {
            try { item.keepOpenRequested.disconnect(root.keepOpenRequested); } catch (e5) {}
            item.keepOpenRequested.connect(root.keepOpenRequested);
        }
        console.log("ArcMenu LayoutHost wireItem catalog=",
                    md && md.allApps ? md.allApps.length : 0);
    }

    /** Reset layout-local navigation without destroying/reloading the layout. */
    function resetForOpen() {
        var item = layoutLoader.item;
        if (!item || !item.resetForOpen) {
            root._resetForOpenPending = true;
            return;
        }
        root._resetForOpenPending = false;
        item.resetForOpen();
    }

    Loader {
        id: layoutLoader
        anchors.fill: parent
        asynchronous: false

        onStatusChanged: {
            if (status === Loader.Error)
                console.error("ArcMenu LayoutHost failed:", source, "layoutId=", root.layoutId);
        }
        onLoaded: {
            root.wireItem();
            if (root._resetForOpenPending)
                root.resetForOpen();
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: layoutLoader.status === Loader.Error
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.disabledTextColor
        border.width: 1
        z: 10

        Text {
            anchors.centerIn: parent
            width: parent.width * 0.85
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
            text: i18n("Failed to load layout: %1", root.layoutId)
        }
    }

    onLayoutIdChanged: {
        // Only when string id changes
        if (root.layoutId !== root._loadedLayoutId)
            Qt.callLater(root.reloadLayout);
    }
    onMenuDataChanged: Qt.callLater(root.wireItem)

    Connections {
        target: plasmoid.configuration
        function onMenuLayoutIdChanged() {
            Qt.callLater(root.reloadLayout);
        }
    }

    // When catalog fills, re-wire without destroying the layout
    Connections {
        target: root.menuData
        ignoreUnknownSignals: true
        function onCatalogEpochChanged() {
            Qt.callLater(root.wireItem);
        }
        function onAllAppsChanged() {
            Qt.callLater(root.wireItem);
        }
    }

    Component.onCompleted: Qt.callLater(root.reloadLayout)
}
