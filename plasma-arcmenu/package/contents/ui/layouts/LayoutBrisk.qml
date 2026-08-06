import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Brisk Menu — self-contained (no sub-Loaders) so layout switch always works.
 * Extra pieces for later integration still live under layouts/brisk/.
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

    readonly property var categories: {
        var out = [];
        if (!menuData || !menuData.categories) return out;
        var cats = menuData.categories;
        for (var i = 0; i < cats.length; ++i) {
            if (cats[i].id !== "all") out.push(cats[i]);
        }
        return out;
    }

    readonly property var extras: [
        { id: "shortcut-software", name: i18n("Software"), icon: "plasmadiscover", action: "discover" },
        { id: "shortcut-settings", name: i18n("Settings"), icon: "preferences-system", action: "settings" }
    ]

    readonly property var contentItems: {
        if (!menuData) return [];
        if (root.searching) return menuData.searchResults || [];
        if (briskSelectedId === "pinned") return menuData.pinnedApps || [];
        return menuData.categoryApps || [];
    }

    function categoryLabel(cat) {
        if (!cat) return "";
        switch (cat.id) {
        case "Office": return i18n("Office");
        case "Development": return i18n("Development");
        case "Accessories": return i18n("Accessories");
        case "Utility": return i18n("Utilities");
        case "Network": return i18n("Internet");
        case "Graphics": return i18n("Graphics");
        case "System": return i18n("System Tools");
        case "Game": return i18n("Games");
        case "Education": return i18n("Education");
        case "AudioVideo": return i18n("Multimedia");
        case "Settings": return i18n("Settings");
        default: return cat.name || "";
        }
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
            menuData.selectCategory("all");
            return;
        }
        menuData.selectCategory(id);
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

            // ---- Left sidebar ----
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
                        selected: !root.searching && root.briskSelectedId === "pinned"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.selectBrisk("pinned")
                    }

                    Components.ShortcutRow {
                        width: sideCol.width
                        iconName: "view-app-grid-symbolic"
                        label: i18n("All Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.briskSelectedId === "all"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
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
                            iconName: root.categories[index].icon || "applications-other"
                            label: root.categoryLabel(root.categories[index])
                            iconSize: root.categoryIconSize
                            selected: !root.searching && root.briskSelectedId === root.categories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
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
                                showDescription: root.searching && menuData ? menuData.showSearchDescription : false
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
                          : (root.briskSelectedId === "pinned"
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

        RowLayout {
            Layout.fillWidth: true
            Components.SessionButtons {
                enabledOptions: root.powerOptions
                onActionRequested: (id) => root.powerAction(id)
            }
            Item { Layout.fillWidth: true }
        }
    }
}
