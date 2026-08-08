import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Zest layout (ArcMenu Zest) ï¿?three columns.
 *
 * Left:   avatar + places/software/settings + session
 * Middle: pinned / all / categories  (controls right)
 * Right:  apps for the middle selection (Aâ€“Z when â€œallï¿?
 * Search spans middle + right at the bottom
 */
LayoutBase {
    id: root

    // Middle column selection ï¿?drives right column content
    property string selectedId: "all"

    readonly property bool searching: menuData ? menuData.isSearching : false
    readonly property int avatarSize: Kirigami.Units.gridUnit * 4

    readonly property var sideItems: {
        var _ = root.uiLang;
        return [
            { id: "place-home", name: root.tr("Home"), icon: "user-home", place: "HOME" },
            { id: "place-docs", name: root.tr("Documents"), icon: "folder-documents", place: "DOCUMENTS" },
            { id: "place-dl", name: root.tr("Downloads"), icon: "folder-download", place: "DOWNLOAD" },
            { id: "place-music", name: root.tr("Music"), icon: "folder-music", place: "MUSIC" },
            { id: "place-pics", name: root.tr("Pictures"), icon: "folder-pictures", place: "PICTURES" },
            { id: "shortcut-software", name: root.tr("Software"), icon: "plasmadiscover", action: "discover" },
            { id: "shortcut-settings", name: root.tr("Settings"), icon: "preferences-system", action: "settings" }
        ];
    }

    readonly property var categories: {
        var _ = root.uiLang;
        return [
            { id: "Office", name: root.tr("Office"), icon: "arcmenu-cat-office-barchart" },
            { id: "Development", name: root.tr("Programming"), icon: "arcmenu-cat-dev-brush" },
            { id: "Accessories", name: root.tr("Accessories"), icon: "arcmenu-cat-accessories-handyman" },
            { id: "Utility", name: root.tr("Tools"), icon: "arcmenu-cat-tools-build" },
            { id: "Network", name: root.tr("Internet"), icon: "arcmenu-cat-internet-public" },
            { id: "Graphics", name: root.tr("Graphics"), icon: "arcmenu-cat-graphics-image" },
            { id: "System", name: root.tr("System Tools"), icon: "arcmenu-cat-system-settings" }
        ];
    }

    readonly property var defaultPinned: {
        var _ = root.uiLang;
        return [
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
        ];
    }

    readonly property var pinnedItems: {
        if (menuData && menuData.pinnedApps && menuData.pinnedApps.length)
            return menuData.pinnedApps;
        return root.defaultPinned;
    }

    readonly property var flatItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        if (selectedId === "pinned")
            return root.pinnedItems;
        if (selectedId === "all")
            return []; // use azSections instead
        if (menuData && menuData.allApps)
            return AppsModel.appsInCategory(menuData.allApps, selectedId);
        return [];
    }

    readonly property var azSections: {
        if (root.searching || selectedId !== "all")
            return [];
        if (!menuData || !menuData.allApps)
            return [];
        return AppsModel.appsAzSections(menuData.allApps);
    }

    readonly property bool rightEmpty: {
        if (root.searching)
            return flatItems.length === 0;
        if (selectedId === "all")
            return azSections.length === 0;
        return flatItems.length === 0;
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

    function selectNav(id) {
        selectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        if (id === "pinned") return;
        if (id === "all") {
            menuData.currentCategoryId = "all";
            return;
        }
        menuData.currentCategoryId = id;
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: 0
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- 1. Left: avatar / places / session ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: root.sidebarW
            Layout.minimumWidth: root.sidebarMin
            Layout.maximumWidth: root.sidebarMax
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.avatarSize
                    Layout.preferredHeight: root.avatarSize

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.color: root.fg
                        border.width: 1
                        opacity: 0.55
                    }

                    Item {
                        anchors.centerIn: parent
                        width: root.avatarSize - Kirigami.Units.smallSpacing * 2
                        height: width
                        Components.UserFace {
                            anchors.fill: parent
                            userIcon: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                            userName: (menuData && menuData.userName) ? menuData.userName : ""
                            fallbackColor: root.fg
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            Accessible.name: root.tr("User")
                            onClicked: root.userMenu()
                        }
                    }
                }

                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                    color: root.fg
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.userMenu()
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                opacity: 0.4
            }

            Flickable {
                id: sideFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: sideCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sideCol
                    width: sideFlick.width
                    spacing: Kirigami.Units.smallSpacing / 2

                    Repeater {
                        model: root.sideItems.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.sideItems[index].icon
                            label: root.sideItems[index].name
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.activateItem(root.sideItems[index])
                        }
                    }
                }
            }

            Components.SessionButtons {
                menuData: root.menuData
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                enabledOptions: ["logout", "lock", "restart", "shutdown"]
                onActionRequested: (id) => root.powerAction(id)
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

        // ---- Middle + right + shared search ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

                // ---- 2. Middle: controls right content ----
                Flickable {
                    id: midFlick
                    Layout.preferredWidth: root.categoryColW
                    Layout.minimumWidth: root.sidebarMin
                    Layout.maximumWidth: root.sidebarMax
                    Layout.fillHeight: true
                    Layout.fillWidth: false
                    contentWidth: width
                    contentHeight: midCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: midCol
                        width: midFlick.width
                        spacing: Kirigami.Units.smallSpacing / 2

                        Components.ShortcutRow {
                            width: midCol.width
                            iconName: "pin"
                            label: root.tr("Pinned Applications")
                            iconSize: root.categoryIconSize
                            selected: !root.searching && root.selectedId === "pinned"
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectNav("pinned")
                        }

                        Components.ShortcutRow {
                            width: midCol.width
                            iconName: "view-app-grid-symbolic"
                            label: root.tr("All Applications")
                            iconSize: root.categoryIconSize
                            selected: !root.searching && root.selectedId === "all"
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectNav("all")
                        }

                        Kirigami.Separator {
                            width: midCol.width
                            opacity: 0.4
                        }

                        Repeater {
                            model: root.categories.length
                            Components.ShortcutRow {
                                required property int index
                                width: midCol.width
                                iconName: root.categories[index].icon
                                label: root.categories[index].name
                                iconSize: root.categoryIconSize
                                selected: !root.searching && root.selectedId === root.categories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectNav(root.categories[index].id)
                            }
                        }
                    }
                }

                Components.ColumnSplitHandle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: implicitWidth
                    z: 5
                    fg: root.fg
                    currentWidth: root.categoryColW
                    minWidth: root.sidebarMin
                    maxWidth: root.sidebarMax
                    sidebarOnRight: false
                    flipped: root.flip
                    onWidthDragged: (w) => root.setCategoryColumnFromDrag(w)
                }

                // ---- 3. Right: content for middle selection ----
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 12

                    Flickable {
                        id: rightFlick
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: rightCol.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: rightCol
                            width: rightFlick.width
                            spacing: Kirigami.Units.smallSpacing / 2

                            // Search results or pinned / category flat list
                            Repeater {
                                model: (root.searching || root.selectedId !== "all")
                                       ? root.flatItems.length : 0
                                Components.AppListItem {
                                    required property int index
                                    width: rightCol.width
                                    app: root.flatItems[index]
                                    iconSize: Math.max(root.appIconSize, 28)
                                    showDescription: root.showAppDescriptions
                                    selectedBg: root.selectedBg
                                    selectedFg: root.selectedFg
                                    hoverBg: root.hoverBg
                                    hoverFg: root.hoverFg
                                    fg: root.fg
                                    onActivated: root.activateItem(root.flatItems[index])
                                    onContextMenuRequested: (x, y) => {
                                        var a = root.flatItems[index];
                                        if (a && !a.action) root.appContextMenu(a, x, y);
                                    }
                                }
                            }

                            // All apps ï¿?Aâ€“Z sections
                            Repeater {
                                model: (!root.searching && root.selectedId === "all")
                                       ? root.azSections.length : 0

                                Column {
                                    required property int index
                                    readonly property var section: root.azSections[index]
                                    width: rightCol.width
                                    spacing: Kirigami.Units.smallSpacing / 2

                                    RowLayout {
                                        width: parent.width
                                        spacing: Kirigami.Units.smallSpacing

                                        PlasmaComponents.Label {
                                            text: section.letter
                                            font.bold: true
                                            color: root.fg
                                            opacity: 0.75
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: root.borderColor
                                            opacity: 0.35
                                        }
                                    }

                                    Repeater {
                                        model: section.apps.length
                                        Components.AppListItem {
                                            required property int index
                                            width: rightCol.width
                                            app: section.apps[index]
                                            iconSize: Math.max(root.appIconSize, 28)
                                            showDescription: root.showAppDescriptions
                                            selectedBg: root.selectedBg
                                            selectedFg: root.selectedFg
                                            hoverBg: root.hoverBg
                                            hoverFg: root.hoverFg
                                            fg: root.fg
                                            onActivated: root.activateItem(section.apps[index])
                                            onContextMenuRequested: (x, y) => {
                                                var a = section.apps[index];
                                                if (a && !a.action) root.appContextMenu(a, x, y);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        visible: root.rightEmpty
                        text: root.searching
                              ? root.tr("No matching applications found")
                              : (root.selectedId === "pinned"
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

            Kirigami.Separator {
                Layout.fillWidth: true
                opacity: 0.35
            }

            // Search under middle + right only
            Components.SearchField {
                Layout.fillWidth: true
                placeholder: menuData ? menuData.searchPlaceholder : root.tr("Searchâ€?)
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
            }
        }
    }
}
