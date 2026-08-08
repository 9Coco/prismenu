import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Brisk Menu �?matches ArcMenu Brisk reference:
 *   Search top | Sidebar (pinned / all / categories / software / settings) | Content | Session bottom
 */
LayoutBase {
    id: root

    property string briskSelectedId: "pinned"

    readonly property bool searching: menuData ? menuData.isSearching : false

    readonly property var powerOptions: {
        if (!menuData) return ["logout", "lock", "restart", "shutdown"];
        var opts = menuData.powerOptions;
        if (!opts || (opts.length !== undefined && opts.length === 0))
            return ["logout", "lock", "restart", "shutdown"];
        return opts;
    }

    // Always show the standard category set (do not hide empty ones)
    readonly property var categories: [
        { id: "Office", name: root.tr("Office"), icon: "arcmenu-cat-office-barchart" },
        { id: "Development", name: root.tr("Development"), icon: "arcmenu-cat-dev-brush" },
        { id: "Accessories", name: root.tr("Accessories"), icon: "arcmenu-cat-accessories-handyman" },
        { id: "Utility", name: root.tr("Utilities"), icon: "arcmenu-cat-tools-build" },
        { id: "Network", name: root.tr("Internet"), icon: "arcmenu-cat-internet-public" },
        { id: "Graphics", name: root.tr("Graphics"), icon: "arcmenu-cat-graphics-image" },
        { id: "System", name: root.tr("System Tools"), icon: "arcmenu-cat-system-settings" }
    ]

    readonly property var extras: [
        { id: "shortcut-software", name: root.tr("Software"), icon: "plasmadiscover", action: "discover" },
        { id: "shortcut-settings", name: root.tr("Settings"), icon: "preferences-system", action: "settings" }
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
        if (briskSelectedId === "pinned") {
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (briskSelectedId === "all") {
            if (menuData && menuData.allApps && menuData.allApps.length)
                return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
            return [];
        }
        // Category
        if (menuData && menuData.allApps)
            return AppsModel.appsInCategory(menuData.allApps, briskSelectedId);
        return [];
    }

    function activateItem(item) {
        if (!item) return;
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

    function selectBrisk(id) {
        briskSelectedId = id;
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

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            // ---- Left sidebar ----
            Flickable {
                id: sideFlick
                Layout.preferredWidth: root.sidebarW
                Layout.minimumWidth: root.sidebarMin
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
                        selected: !root.searching && root.briskSelectedId === "pinned"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.selectBrisk("pinned")
                    }

                    Components.ShortcutRow {
                        width: sideCol.width
                        iconName: "view-app-grid-symbolic"
                        label: root.tr("All Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.briskSelectedId === "all"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.selectBrisk("all")
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
                            selected: !root.searching && root.briskSelectedId === root.categories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectBrisk(root.categories[index].id)
                        }
                    }

                    Kirigami.Separator {
                        width: sideCol.width
                        opacity: 0.4
                    }

                    Repeater {
                        model: root.extras.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.extras[index].icon
                            label: root.extras[index].name
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.activateItem(root.extras[index])
                        }
                    }

                    Kirigami.Separator {
                        width: sideCol.width
                        opacity: 0.4
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

            // ---- Right content ----
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
                          : (root.briskSelectedId === "pinned"
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

        RowLayout {
            Layout.fillWidth: true
            Components.SessionButtons {
                menuData: root.menuData
                enabledOptions: root.powerOptions
                onActionRequested: (id) => root.powerAction(id)
            }
            Item { Layout.fillWidth: true }
        }
    }
}
