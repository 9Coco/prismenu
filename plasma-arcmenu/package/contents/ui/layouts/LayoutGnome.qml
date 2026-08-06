import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * GNOME Menu layout (ArcMenu GNOME style).
 *
 * Search top | Sidebar (pinned / all / categories) | Content
 * Bottom: Activities Overview
 */
LayoutBase {
    id: root

    property string gnomeSelectedId: "pinned"

    readonly property bool searching: menuData ? menuData.isSearching : false

    readonly property var categories: [
        { id: "Office", name: i18n("Office"), icon: "applications-office" },
        { id: "Development", name: i18n("Development"), icon: "applications-development" },
        { id: "Accessories", name: i18n("Accessories"), icon: "applications-accessories" },
        { id: "Utility", name: i18n("Utilities"), icon: "applications-utilities" },
        { id: "Network", name: i18n("Internet"), icon: "applications-internet" },
        { id: "Graphics", name: i18n("Graphics"), icon: "applications-graphics" },
        { id: "System", name: i18n("System Tools"), icon: "applications-system" }
    ]

    readonly property var defaultPinned: [
        {
            id: "org.kde.dolphin.desktop",
            name: i18n("Files"),
            icon: "system-file-manager",
            exec: "dolphin",
            noDisplay: false
        },
        {
            id: "arcmenu-settings",
            name: i18n("ArcMenu Settings"),
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
        if (gnomeSelectedId === "pinned") {
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (gnomeSelectedId === "all") {
            if (menuData && menuData.allApps && menuData.allApps.length)
                return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
            return [];
        }
        if (menuData && menuData.allApps)
            return AppsModel.appsInCategory(menuData.allApps, gnomeSelectedId);
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

    function selectGnome(id) {
        gnomeSelectedId = id;
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
            placeholder: menuData ? menuData.searchPlaceholder : i18n("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Flickable {
                id: sideFlick
                Layout.preferredWidth: Math.max(Kirigami.Units.gridUnit * 11, parent.width * 0.34)
                Layout.maximumWidth: Kirigami.Units.gridUnit * 15
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
                        label: i18n("Pinned Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.gnomeSelectedId === "pinned"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.selectGnome("pinned")
                    }

                    Components.ShortcutRow {
                        width: sideCol.width
                        iconName: "view-app-grid-symbolic"
                        label: i18n("All Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.gnomeSelectedId === "all"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.selectGnome("all")
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
                            selected: !root.searching && root.gnomeSelectedId === root.categories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            fg: root.fg
                            onActivated: root.selectGnome(root.categories[index].id)
                        }
                    }
                }
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
                                width: contentCol.width
                                app: root.contentItems[index]
                                iconSize: Math.max(root.appIconSize, 28)
                                showDescription: false
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
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
                          ? i18n("No matching applications found")
                          : (root.gnomeSelectedId === "pinned"
                             ? i18n("Pin applications from the context menu")
                             : i18n("No applications"))
                    opacity: 0.45
                    color: root.fg
                    width: parent.width * 0.8
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Bottom: Activities Overview (GNOME hallmark)
        Components.ShortcutRow {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
            iconName: "overview"
            label: i18n("Activities Overview")
            iconSize: Math.max(root.categoryIconSize, 24)
            selectedBg: root.selectedBg
            selectedFg: root.selectedFg
            fg: root.fg
            onActivated: root.powerAction("overview")
        }
    }
}
