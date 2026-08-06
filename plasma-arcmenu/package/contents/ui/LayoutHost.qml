import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/LayoutRegistry.js" as LayoutRegistry

Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)
    signal powerAction(string actionId)
    signal userMenu()

    readonly property string layoutId: menuData ? menuData.currentLayoutId : "arcmenu"
    readonly property var layoutMeta: LayoutRegistry.getLayout(layoutId)

    width: menuData ? menuData.menuWidth : 600
    height: menuData ? menuData.menuHeight : 550

    Loader {
        id: layoutLoader
        anchors.fill: parent
        asynchronous: false
        source: layoutMeta ? Qt.resolvedUrl(layoutMeta.source) : Qt.resolvedUrl("layouts/LayoutArcMenu.qml")

        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("ArcMenu LayoutHost failed to load layout:", source, layoutId);
            }
        }

        onLoaded: {
            if (!item) {
                return;
            }
            item.menuData = root.menuData;
            item.themeStyle = root.themeStyle;
            if (item.appActivated) {
                item.appActivated.connect(root.appActivated);
            }
            if (item.appContextMenu) {
                item.appContextMenu.connect(root.appContextMenu);
            }
            if (item.powerAction) {
                item.powerAction.connect(root.powerAction);
            }
            if (item.userMenu) {
                item.userMenu.connect(root.userMenu);
            }
        }
    }

    // Visible fallback when a layout fails to compile/load (avoids empty black box)
    Rectangle {
        anchors.fill: parent
        visible: layoutLoader.status === Loader.Error || (layoutLoader.status === Loader.Ready && !layoutLoader.item)
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.disabledTextColor
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            width: parent.width * 0.8

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.textColor
                text: i18n("Failed to load menu layout.\nReinstall Arc Menu or check journalctl for QML errors.")
            }
        }
    }

    onLayoutIdChanged: {
        // Force reload so layout switch re-creates the tree
        var src = layoutMeta ? Qt.resolvedUrl(layoutMeta.source) : Qt.resolvedUrl("layouts/LayoutArcMenu.qml");
        layoutLoader.source = "";
        layoutLoader.source = src;
    }

    onMenuDataChanged: {
        if (layoutLoader.item) {
            layoutLoader.item.menuData = menuData;
        }
    }

    onThemeStyleChanged: {
        if (layoutLoader.item) {
            layoutLoader.item.themeStyle = themeStyle;
        }
    }
}
