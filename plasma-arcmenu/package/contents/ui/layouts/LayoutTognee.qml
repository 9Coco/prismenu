import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Tognee layout (ArcMenu Tognee).
 *
 * Left: icon rail (places → software/settings/tweaks → expand → power)
 * Right: category list (home) or app list (drill-in) + search at bottom
 */
LayoutBase {
    id: root

    // Home shows category nav (matches reference). Drill-in shows apps.
    property bool showingApps: false
    property string selectedId: "pinned"

    readonly property bool searching: menuData ? menuData.isSearching : false
    readonly property int railWidth: Kirigami.Units.gridUnit * 2.8

    readonly property var placeActions: [
        { id: "place-home", icon: "user-home", tip: i18n("Home"), exec: "xdg-open $HOME" },
        { id: "place-docs", icon: "folder-documents", tip: i18n("Documents"), exec: "xdg-open xdg:Documents" },
        { id: "place-dl", icon: "folder-download", tip: i18n("Downloads"), exec: "xdg-open xdg:Download" },
        { id: "place-music", icon: "folder-music", tip: i18n("Music"), exec: "xdg-open xdg:Music" },
        { id: "place-pics", icon: "folder-pictures", tip: i18n("Pictures"), exec: "xdg-open xdg:Pictures" },
        { id: "place-videos", icon: "folder-videos", tip: i18n("Videos"), exec: "xdg-open xdg:Videos" }
    ]

    readonly property var systemActions: [
        { id: "shortcut-software", icon: "plasmadiscover", tip: i18n("Software"), action: "discover" },
        { id: "shortcut-settings", icon: "preferences-system", tip: i18n("Settings"), action: "settings" },
        { id: "shortcut-tweaks", icon: "preferences-desktop-display", tip: i18n("Tweaks"), exec: "systemsettings kcm_lookandfeel" }
    ]

    readonly property var categories: [
        { id: "Office", name: i18n("Office"), icon: "applications-office" },
        { id: "Development", name: i18n("Programming"), icon: "applications-development" },
        { id: "Accessories", name: i18n("Accessories"), icon: "applications-accessories" },
        { id: "Utility", name: i18n("Tools"), icon: "applications-utilities" },
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

    readonly property string selectionTitle: {
        if (selectedId === "pinned")
            return i18n("Pinned Applications");
        if (selectedId === "all")
            return i18n("All Applications");
        for (var i = 0; i < categories.length; ++i) {
            if (categories[i].id === selectedId)
                return categories[i].name;
        }
        return i18n("Applications");
    }

    readonly property var contentItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        if (selectedId === "pinned") {
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (selectedId === "all") {
            if (menuData && menuData.allApps && menuData.allApps.length)
                return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
            return [];
        }
        if (menuData && menuData.allApps)
            return AppsModel.appsInCategory(menuData.allApps, selectedId);
        return [];
    }

    // Show apps list when searching or after selecting a nav entry
    readonly property bool inAppsView: root.searching || root.showingApps

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

    function selectNav(id) {
        selectedId = id;
        showingApps = true;
        if (!menuData) return;
        menuData.setSearch("");
        if (id === "pinned") return;
        if (id === "all") {
            menuData.currentCategoryId = "all";
            return;
        }
        menuData.currentCategoryId = id;
    }

    function goHome() {
        showingApps = false;
        if (menuData)
            menuData.setSearch("");
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Left icon rail ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: root.railWidth
            Layout.maximumWidth: root.railWidth
            Layout.fillWidth: false
            spacing: Kirigami.Units.smallSpacing / 2

            Repeater {
                model: root.placeActions.length
                PlasmaComponents.ToolButton {
                    required property int index
                    readonly property var def: root.placeActions[index]
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                    flat: true
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

            Kirigami.Separator {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.4
                opacity: 0.35
            }

            Repeater {
                model: root.systemActions.length
                PlasmaComponents.ToolButton {
                    required property int index
                    readonly property var def: root.systemActions[index]
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                    flat: true
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

            Kirigami.Separator {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.4
                opacity: 0.35
            }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                flat: true
                icon.name: "view-fullscreen"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: i18n("Activities Overview")
                onClicked: root.powerAction("overview")
                PlasmaComponents.ToolTip.text: i18n("Activities Overview")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                flat: true
                icon.name: "system-shutdown"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: i18n("Shut Down")
                onClicked: root.powerAction("shutdown")
                PlasmaComponents.ToolTip.text: i18n("Shut Down")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: root.borderColor
            opacity: 0.35
        }

        // ---- Main column: categories or apps + search ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Home: pinned / all / categories (reference screenshot)
                Flickable {
                    id: navFlick
                    anchors.fill: parent
                    visible: !root.inAppsView
                    contentWidth: width
                    contentHeight: navCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: navCol
                        width: navFlick.width
                        spacing: Kirigami.Units.smallSpacing / 2

                        Components.ShortcutRow {
                            width: navCol.width
                            iconName: "pin"
                            label: i18n("Pinned Applications")
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            fg: root.fg
                            onActivated: root.selectNav("pinned")
                        }

                        Components.ShortcutRow {
                            width: navCol.width
                            iconName: "view-app-grid-symbolic"
                            label: i18n("All Applications")
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            fg: root.fg
                            onActivated: root.selectNav("all")
                        }

                        Kirigami.Separator {
                            width: navCol.width
                            opacity: 0.4
                        }

                        Repeater {
                            model: root.categories.length
                            Components.ShortcutRow {
                                required property int index
                                width: navCol.width
                                iconName: root.categories[index].icon
                                label: root.categories[index].name
                                iconSize: root.categoryIconSize
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                fg: root.fg
                                onActivated: root.selectNav(root.categories[index].id)
                            }
                        }
                    }
                }

                // Drill-in / search: app list
                ColumnLayout {
                    anchors.fill: parent
                    visible: root.inAppsView
                    spacing: Kirigami.Units.smallSpacing / 2

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !root.searching
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.ToolButton {
                            flat: true
                            icon.name: "go-previous"
                            Accessible.name: i18n("Back")
                            onClicked: root.goHome()
                        }

                        PlasmaComponents.Label {
                            text: root.selectionTitle
                            font.bold: true
                            color: root.fg
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Flickable {
                            id: appsFlick
                            anchors.fill: parent
                            contentWidth: width
                            contentHeight: appsCol.height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: appsCol
                                width: appsFlick.width
                                spacing: Kirigami.Units.smallSpacing / 2

                                Repeater {
                                    model: root.contentItems.length
                                    Components.AppListItem {
                                        required property int index
                                        width: appsCol.width
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
                                  : (root.selectedId === "pinned"
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
            }

            Components.SearchField {
                Layout.fillWidth: true
                placeholder: menuData ? menuData.searchPlaceholder : i18n("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: {
                    if (menuData) menuData.setSearch(text);
                    if (!(text && text.length) && root.showingApps === false)
                        return;
                }
            }
        }
    }
}
