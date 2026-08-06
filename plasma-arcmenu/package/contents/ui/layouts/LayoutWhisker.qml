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
        { id: "settings", icon: "preferences-system", tip: i18n("Settings"), action: "settings" },
        { id: "logout", icon: "system-log-out", tip: i18n("Log Out"), action: "logout" },
        { id: "lock", icon: "system-lock-screen", tip: i18n("Lock"), action: "lock" },
        { id: "restart", icon: "system-reboot", tip: i18n("Restart"), action: "restart" },
        { id: "shutdown", icon: "system-shutdown", tip: i18n("Shut Down"), action: "shutdown" }
    ]

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
            placeholder: menuData ? menuData.searchPlaceholder : i18n("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
        }

        // User + session header (Whisker hallmark)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.ToolButton {
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                icon.width: Kirigami.Units.iconSizes.medium
                icon.height: Kirigami.Units.iconSizes.medium
                Accessible.name: i18n("User")
                onClicked: root.userMenu()
                PlasmaComponents.ToolTip.text: i18n("User account")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: (menuData && menuData.userName) ? menuData.userName : i18n("User")
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
                        selected: !root.searching && root.whiskerSelectedId === "pinned"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.selectWhisker("pinned")
                    }

                    Components.ShortcutRow {
                        width: sideCol.width
                        iconName: "view-app-grid-symbolic"
                        label: i18n("All Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.whiskerSelectedId === "all"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
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
                            fg: root.fg
                            onActivated: root.selectWhisker(root.categories[index].id)
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
                          : (root.whiskerSelectedId === "pinned"
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
}
