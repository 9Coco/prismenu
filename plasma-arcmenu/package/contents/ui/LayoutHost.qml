import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../code/LayoutRegistry.js" as LayoutRegistry

Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)
    signal powerAction(string actionId)
    signal userMenu()

    // Read layout id from configuration DIRECTLY so Apply always triggers reload.
    // Fallback to menuData for tests / if config is empty.
    readonly property string layoutId: {
        var fromConfig = "";
        try {
            fromConfig = String(plasmoid.configuration.menuLayoutId || "");
        } catch (e) {
            fromConfig = "";
        }
        if (fromConfig.length)
            return fromConfig;
        if (menuData && menuData.currentLayoutId)
            return menuData.currentLayoutId;
        return "arcmenu";
    }

    readonly property var layoutMeta: LayoutRegistry.getLayout(layoutId)

    readonly property int sidePanelWidth: (layoutLoader.item && layoutLoader.item.sidePanelWidth !== undefined)
            ? layoutLoader.item.sidePanelWidth
            : 0

    width: (menuData ? menuData.menuWidth : 600) + sidePanelWidth
    // Prefer parent height when fullRepresentation sizes us (e.g. Raven fill)
    height: (parent && parent.height >= 400) ? parent.height : (menuData ? menuData.menuHeight : 550)

    function layoutUrl() {
        if (layoutMeta && layoutMeta.source) {
            return Qt.resolvedUrl(layoutMeta.source);
        }
        return Qt.resolvedUrl("layouts/LayoutArcMenu.qml");
    }

    function reloadLayout() {
        var src = layoutUrl();
        console.log("ArcMenu LayoutHost reload:", root.layoutId, src);
        layoutLoader.source = "";
        layoutLoader.source = src;
    }

    function wireItem() {
        var item = layoutLoader.item;
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
        if (item.powerAction) {
            try { item.powerAction.disconnect(root.powerAction); } catch (e3) {}
            item.powerAction.connect(root.powerAction);
        }
        if (item.userMenu) {
            try { item.userMenu.disconnect(root.userMenu); } catch (e4) {}
            item.userMenu.connect(root.userMenu);
        }
    }

    Loader {
        id: layoutLoader
        anchors.fill: parent
        asynchronous: false

        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("ArcMenu LayoutHost failed:", source, "layoutId=", root.layoutId);
            }
        }
        onLoaded: root.wireItem()
    }

    Rectangle {
        anchors.fill: parent
        visible: layoutLoader.status === Loader.Error
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.disabledTextColor
        border.width: 1
        z: 10

        Column {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            width: parent.width * 0.85

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.textColor
                text: i18n("Failed to load layout: %1", root.layoutId)
            }
        }
    }

    // Tiny debug badge so you can see which layout is actually loaded
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        z: 20
        radius: 3
        color: "#80000000"
        width: dbg.implicitWidth + 10
        height: dbg.implicitHeight + 4
        Text {
            id: dbg
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 10
            text: root.layoutId + (layoutLoader.status === Loader.Error ? " ERR" : "")
        }
    }

    onLayoutIdChanged: reloadLayout()
    onMenuDataChanged: {
        if (layoutLoader.item) {
            wireItem();
        } else if (layoutLoader.status !== Loader.Loading) {
            reloadLayout();
        }
    }
    onThemeStyleChanged: wireItem()

    Connections {
        target: plasmoid.configuration
        function onMenuLayoutIdChanged() {
            root.reloadLayout();
        }
    }

    Component.onCompleted: reloadLayout()
}
