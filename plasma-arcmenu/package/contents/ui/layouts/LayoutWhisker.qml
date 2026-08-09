import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Whisker Menu layout (XFCE Whisker / ArcMenu Whisker style).
 *
 * Search top
 * User row (avatar + name | settings + session buttons)
 * Categories | Content
 */
LayoutBase {
    id: root

    property string whiskerSelectedId: "pinned"

    readonly property bool searching: menuData ? menuData.isSearching : false

    readonly property var sessionActions: [
        { id: "settings", icon: "preferences-system", tip: root.tr("Settings"), action: "settings" },
        { id: "logout", icon: "system-log-out", tip: root.tr("Log Out"), action: "logout" },
        { id: "lock", icon: "system-lock-screen", tip: root.tr("Lock"), action: "lock" },
        { id: "restart", icon: "system-reboot", tip: root.tr("Restart"), action: "restart" },
        { id: "shutdown", icon: "system-shutdown", tip: root.tr("Shut Down"), action: "shutdown" }
    ]

    readonly property var categories: [
        { id: "Office", name: root.tr("Office"), icon: "arcmenu-cat-office-barchart" },
        { id: "Development", name: root.tr("Development"), icon: "arcmenu-cat-dev-brush" },
        { id: "Accessories", name: root.tr("Accessories"), icon: "arcmenu-cat-accessories-handyman" },
        { id: "Utility", name: root.tr("Utilities"), icon: "arcmenu-cat-tools-build" },
        { id: "Network", name: root.tr("Internet"), icon: "arcmenu-cat-internet-public" },
        { id: "Graphics", name: root.tr("Graphics"), icon: "arcmenu-cat-graphics-image" },
        { id: "System", name: root.tr("System Tools"), icon: "arcmenu-cat-system-settings" }
    ]

    readonly property var defaultPinned: [
        {
            id: "org.kde.dolphin.desktop",
            name: root.tr("Files"),
            icon: "system-file-manager",
            exec: "dolphin",
            noDisplay: false
        },
        {
            id: "arcmenu-settings",
            name: root.tr("ArcMenu Settings"),
            icon: "preferences-system-windows",
            exec: "",
            action: "configure",
            noDisplay: false
        }
    ]

    readonly property var contentItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        if (whiskerSelectedId === "pinned") {
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (whiskerSelectedId === "all") {
            if (menuData && menuData.allApps && menuData.allApps.length)
                return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
            return [];
        }
        if (menuData && menuData.allApps)
            return AppsModel.appsInCategory(menuData.allApps, whiskerSelectedId);
        return [];
    }

    function activateItem(item) {
        if (!item || item.isSection)
            return;
        if (item.action === "configure") {
            if (menuData) menuData.requestConfigure();
            return;
        }
        if (item.action) {
            root.powerAction(item.action);
            return;
        }
        root.appActivated(item);
    }

    function selectWhisker(id) {
        whiskerSelectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        if (id === "pinned") return;
        if (id === "all") {
            menuData.currentCategoryId = "all";
            return;
        }
        menuData.currentCategoryId = id;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.SearchField {
            Layout.fillWidth: true
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        // User + session header (Whisker hallmark)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                Components.UserFace {
                    anchors.fill: parent
                    userIcon: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                            userName: (menuData && menuData.userName) ? menuData.userName : ""
                            fallbackColor: root.fg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    Accessible.name: root.tr("User")
                    onClicked: root.userMenu()
                    PlasmaComponents.ToolTip.text: root.tr("User account")
                    PlasmaComponents.ToolTip.visible: containsMouse
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                elide: Text.ElideRight
                font.bold: true
                color: root.fg

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userMenu()
                }
            }

            Repeater {
                model: root.sessionActions.length
                PlasmaComponents.ToolButton {
                    required property int index
                    readonly property var def: root.sessionActions[index]
                    flat: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    icon.name: def.icon
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    Accessible.name: def.tip
                    onClicked: root.activateItem(def)
                    PlasmaComponents.ToolTip.text: def.tip
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Flickable {
                id: sideFlick
                Layout.preferredWidth: root.sidebarW
                Layout.minimumWidth: root.elasticColumnMin
                Layout.maximumWidth: root.sidebarMax
                Layout.fillHeight: true
                Layout.fillWidth: false
                contentWidth: width
                contentHeight: sideCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sideCol
                    width: sideFlick.width
                    spacing: Kirigami.Units.smallSpacing / 2

                    Components.ShortcutRow {
                        width: sideCol.width
                        iconName: "pin"
                        label: root.tr("Pinned Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.whiskerSelectedId === "pinned"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.selectWhisker("pinned")
                    }

                    Components.ShortcutRow {
                        width: sideCol.width
                        iconName: "view-app-grid-symbolic"
                        label: root.tr("All Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.whiskerSelectedId === "all"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.selectWhisker("all")
                    }

                    Kirigami.Separator {
                        width: sideCol.width
                        opacity: 0.4
                    }

                    Repeater {
                        model: root.categories.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.categories[index].icon
                            label: root.categories[index].name
                            iconSize: root.categoryIconSize
                            selected: !root.searching && root.whiskerSelectedId === root.categories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectWhisker(root.categories[index].id)
                        }
                    }
                }
            }

            Components.ColumnSplitHandle {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                z: 5
                fg: root.fg
                currentWidth: root.sidebarW
                minWidth: root.sidebarMin
                maxWidth: root.sidebarMax
                sidebarOnRight: false
                flipped: root.flip
                onWidthDragged: (w) => root.setSidebarFromDrag(w)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: contentFlick
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: contentCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: contentCol
                        width: contentFlick.width
                        spacing: Kirigami.Units.smallSpacing / 2

                        Repeater {
                            model: root.contentItems.length
                            Components.AppListItem {
                                required property int index
                                menuData: menuData
                                width: contentCol.width
                                app: root.contentItems[index]
                                iconSize: Math.max(root.appIconSize, 28)
                                showDescription: root.showAppDescriptions
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.activateItem(root.contentItems[index])
                                onContextMenuRequested: (x, y) => {
                                    var a = root.contentItems[index];
                                    if (a && !a.action) root.appContextMenu(a, x, y);
                                }
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.contentItems.length === 0
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : (root.whiskerSelectedId === "pinned"
                             ? root.tr("Pin applications from the context menu")
                             : root.tr("No applications"))
                    opacity: 0.45
                    color: root.fg
                    width: parent.width * 0.8
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
