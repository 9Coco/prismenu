import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Brisk Menu — matches ArcMenu Brisk reference (upstream brisk.js):
 *   Search top/bottom | Sidebar: extra-categories + categories (scroll, hover
 *   activation) then configurable shortcuts + power row pinned to the bottom
 *   of the sidebar (not a full-width session row)
 */
LayoutBase {
    id: root

    readonly property var categories: root.standardCategories

    property string briskSelectedId: "pinned"
    activeNavId: briskSelectedId


    readonly property var powerOptions: {
        if (!menuData) return ["logout", "lock", "restart", "shutdown"];
        var opts = menuData.powerOptions;
        if (!opts || (opts.length !== undefined && opts.length === 0))
            return ["logout", "lock", "restart", "shutdown"];
        return opts;
    }

    // Always show the standard category set (do not hide empty ones)

    /** Upstream extra-categories: user-configurable sidebar entries
     * (pinned / all-apps / favorites / frequent / recent-files). */
    readonly property var extraCategories: (menuData && menuData.enabledExtraCategories
        && menuData.enabledExtraCategories.length)
        ? menuData.enabledExtraCategories
        : [
            { id: "pinned", name: root.tr("Pinned Applications"), icon: "pin" },
            { id: "all-apps", name: root.tr("All Applications"), icon: "view-app-grid-symbolic" }
        ]

    /** Upstream brisk-layout-extra-shortcuts — configurable application
     * shortcuts above the power row (fallback: Software / Settings). */
    readonly property var briskShortcuts: (menuData && menuData.systemShortcuts
        && menuData.systemShortcuts.length)
        ? menuData.systemShortcuts
        : [
            { id: "shortcut-software", name: root.tr("Software"), icon: "plasmadiscover", action: "discover" },
            { id: "shortcut-settings", name: root.tr("Settings"), icon: "preferences-system", action: "settings" }
        ]




    function selectBrisk(id) {
        briskSelectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        root.refreshNavData(id);
        if (id === "pinned" || id === "favorites" || id === "frequent" || id === "recent-files")
            return;
        menuData.currentCategoryId = (id === "all-apps") ? "all" : id;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
            visible: root.searchOnTop
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: root.searchOnTop
            opacity: 0.5
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            // ---- Left sidebar ----
            ColumnLayout {
                Layout.preferredWidth: root.sidebarW
                Layout.minimumWidth: root.elasticColumnMin
                Layout.maximumWidth: root.sidebarMax
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing / 2

                Flickable {
                    id: sideFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: sideCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

                    Column {
                        id: sideCol
                        width: sideFlick.width
                        spacing: Kirigami.Units.smallSpacing / 2

                        // Extra categories (pinned / all-apps / favorites /
                        // frequent / recent-files) — user configurable, same
                        // as upstream "extra-categories" setting
                        Repeater {
                            model: root.extraCategories.length
                            Components.ShortcutRow {
                                required property int index
                                width: sideCol.width
                                iconName: root.extraCategories[index].icon
                                label: root.extraCategories[index].name
                                iconSize: root.categoryIconSize
                                selected: !root.searching && root.briskSelectedId === root.extraCategories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectBrisk(root.extraCategories[index].id)
                            }
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
                                activateOnHover: true
                                selected: !root.searching && root.briskSelectedId === root.categories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectBrisk(root.categories[index].id)
                            }
                        }
                    }
                }

                // Pinned shortcuts + power row at the sidebar bottom
                // (upstream actionsBox + powerOptionsItem, y_align END)
                Kirigami.Separator {
                    Layout.fillWidth: true
                    opacity: 0.4
                }

                Repeater {
                    model: root.briskShortcuts.length
                    Components.ShortcutRow {
                        required property int index
                        Layout.fillWidth: true
                        iconName: root.briskShortcuts[index].icon
                        label: root.briskShortcuts[index].name
                        iconSize: root.categoryIconSize
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.activateItem(root.briskShortcuts[index])
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    opacity: 0.4
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

                ListView {
                    id: contentFlick
                    anchors.fill: parent
                    model: root.contentItems
                    spacing: Kirigami.Units.smallSpacing / 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
                    delegate: Components.AppListItem {
                                    required property int index
                                    menuData: menuData
                                    width: contentFlick.width
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

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.contentItems.length === 0
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : (root.briskSelectedId === "pinned"
                             ? root.tr("Pin applications from the context menu")
                             : (root.briskSelectedId === "recent-files"
                                ? root.tr("No recent files")
                                : root.tr("No applications")))
                    opacity: 0.45
                    color: root.fg
                    width: parent.width * 0.8
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
            visible: !root.searchOnTop
        }
    }
}
