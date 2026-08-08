import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Unity layout (ArcMenu Unity compact menu �?not Unity Dash).
 *
 * Search + hamburger �?category flyout
 * 已固�?| pinned icon grid
 * 快捷方式 | software / settings / tweaks / overview
 * Bottom: places + session (centered darker strip)
 */
LayoutBase {
    id: root

    // "" / "home" = pinned+shortcuts home; "all" / category id = app list
    property string selectedId: "home"

    readonly property bool searching: menuData ? menuData.isSearching : false
    readonly property bool onHome: !root.searching && (selectedId === "" || selectedId === "home")
    readonly property bool onApps: root.searching || !root.onHome
    readonly property int gridIconSize: Math.max(40, root.appIconSize + 12)
    readonly property int gridCellWidth: Kirigami.Units.gridUnit * 5.5
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 1.8
    readonly property int footIcon: Kirigami.Units.iconSizes.smallMedium

    readonly property var categories: [
        { id: "Office", name: root.tr("Office"), icon: "arcmenu-cat-office-barchart" },
        { id: "Development", name: root.tr("Programming"), icon: "arcmenu-cat-dev-brush" },
        { id: "Accessories", name: root.tr("Accessories"), icon: "arcmenu-cat-accessories-handyman" },
        { id: "Utility", name: root.tr("Tools"), icon: "arcmenu-cat-tools-build" },
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

    readonly property var shortcutItems: [
        { id: "shortcut-software", name: root.tr("Software"), icon: "plasmadiscover", action: "discover" },
        { id: "shortcut-settings", name: root.tr("Settings"), icon: "preferences-system", action: "settings" },
        { id: "shortcut-tweaks", name: root.tr("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel" }
    ]

    readonly property var footPlaces: [
        { id: "place-home", icon: "user-home", tip: root.tr("Home"), place: "HOME" },
        { id: "place-docs", icon: "folder-documents", tip: root.tr("Documents"), place: "DOCUMENTS" },
        { id: "place-dl", icon: "folder-download", tip: root.tr("Downloads"), place: "DOWNLOAD" },
        { id: "shortcut-software-foot", icon: "plasmadiscover", tip: root.tr("Software"), action: "discover" },
        { id: "place-files", icon: "system-file-manager", tip: root.tr("Files"), exec: "dolphin" }
    ]

    readonly property var pinnedItems: {
        if (menuData && menuData.pinnedApps && menuData.pinnedApps.length)
            return menuData.pinnedApps;
        return root.defaultPinned;
    }

    readonly property string appsTitle: {
        if (selectedId === "all")
            return root.tr("All Applications");
        for (var i = 0; i < categories.length; ++i) {
            if (categories[i].id === selectedId)
                return categories[i].name;
        }
        return root.tr("Applications");
    }

    readonly property var allAppsItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        if (selectedId === "all") {
            if (menuData && menuData.allApps && menuData.allApps.length)
                return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
            return [];
        }
        if (selectedId !== "" && selectedId !== "home" && menuData && menuData.allApps)
            return AppsModel.appsInCategory(menuData.allApps, selectedId);
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

    function selectNav(id) {
        selectedId = id;
        if (menuData) {
            menuData.setSearch("");
            if (id === "all")
                menuData.currentCategoryId = "all";
            else if (id !== "home" && id !== "")
                menuData.currentCategoryId = id;
        }
        // Keep panel open so user can switch categories; Home also closes it
        if (id === "home")
            categoryPanelOpen = false;
    }

    function toggleCategoryPopup() {
        categoryPanelOpen = !categoryPanelOpen;
    }

    property bool categoryPanelOpen: false
    // LayoutHost / main.qml widen the plasmoid when this is non-zero
    readonly property int sidePanelWidth: categoryPanelOpen
            ? (Kirigami.Units.gridUnit * 12 + Kirigami.Units.smallSpacing)
            : 0

    readonly property var footSession: [
        { id: "logout", icon: "system-log-out", tip: root.tr("Log Out"), action: "logout" },
        { id: "lock", icon: "system-lock-screen", tip: root.tr("Lock Screen"), action: "lock" },
        { id: "shutdown", icon: "system-shutdown", tip: root.tr("Shut Down"), action: "shutdown" }
    ]

    readonly property int footBtn: Kirigami.Units.gridUnit * 2
    readonly property int footBarHeight: Kirigami.Units.gridUnit * 2.6

    RowLayout {
        anchors.fill: parent
        spacing: 0

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        // ---- Padded main content ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

        // ---- Search + hamburger ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Components.SearchField {
                Layout.fillWidth: true
                placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: {
                    if (menuData) menuData.setSearch(text);
                }
            }

            PlasmaComponents.ToolButton {
                id: menuBtn
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "application-menu"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Categories")
                checked: root.categoryPanelOpen
                onClicked: root.toggleCategoryPopup()
                PlasmaComponents.ToolTip.text: root.tr("Categories")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        // ---- Home: pinned + shortcuts ----
        Flickable {
            visible: root.onHome
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: homeCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: homeCol
                width: parent.width
                spacing: Kirigami.Units.largeSpacing

                // Section: 已固�?
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: root.tr("Pinned")
                            color: root.fg
                            opacity: 0.75
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.borderColor
                            opacity: 0.4
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Repeater {
                            model: root.pinnedItems.length
                            Item {
                                required property int index
                                readonly property var app: root.pinnedItems[index]
                                width: root.gridCellWidth
                                height: root.gridCellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Kirigami.Units.smallSpacing
                                    color: pinMouse.containsMouse ? root.selectedBg : "transparent"
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    width: parent.width - Kirigami.Units.smallSpacing * 2
                                    spacing: Kirigami.Units.smallSpacing / 2

                                    Kirigami.Icon {
                                        source: app.icon || "application-x-executable"
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: root.gridIconSize
                                        Layout.preferredHeight: root.gridIconSize
                                    }

                                    PlasmaComponents.Label {
                                        text: app.name || ""
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                        maximumLineCount: 2
                                        wrapMode: Text.WordWrap
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        color: pinMouse.containsMouse ? root.selectedFg : root.fg
                                    }
                                }

                                MouseArea {
                                    id: pinMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            if (app && !app.action)
                                                root.appContextMenu(app, mouse.x, mouse.y);
                                        } else {
                                            root.activateItem(app);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Section: 快捷方式
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: root.tr("Shortcuts")
                            color: root.fg
                            opacity: 0.75
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.borderColor
                            opacity: 0.4
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Repeater {
                            model: root.shortcutItems.length
                            Item {
                                required property int index
                                readonly property var app: root.shortcutItems[index]
                                width: root.gridCellWidth
                                height: root.gridCellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Kirigami.Units.smallSpacing
                                    color: scMouse.containsMouse ? root.selectedBg : "transparent"
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    width: parent.width - Kirigami.Units.smallSpacing * 2
                                    spacing: Kirigami.Units.smallSpacing / 2

                                    Kirigami.Icon {
                                        source: app.icon || "application-x-executable"
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: root.gridIconSize
                                        Layout.preferredHeight: root.gridIconSize
                                    }

                                    PlasmaComponents.Label {
                                        text: app.name || ""
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                        maximumLineCount: 2
                                        wrapMode: Text.WordWrap
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        color: scMouse.containsMouse ? root.selectedFg : root.fg
                                    }
                                }

                                MouseArea {
                                    id: scMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.activateItem(app)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- All apps / category / search results ----
        ColumnLayout {
            visible: root.onApps
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing / 2

            RowLayout {
                Layout.fillWidth: true
                visible: !root.searching
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.ToolButton {
                    flat: true
                    icon.name: "go-previous"
                    Accessible.name: root.tr("Home")
                    onClicked: root.selectNav("home")
                }

                PlasmaComponents.Label {
                    text: root.appsTitle
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
                            model: root.allAppsItems.length
                            Components.AppListItem {
                                required property int index
                                width: appsCol.width
                                app: root.allAppsItems[index]
                                iconSize: Math.max(root.appIconSize, 28)
                                showDescription: false
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                fg: root.fg
                                onActivated: root.activateItem(root.allAppsItems[index])
                                onContextMenuRequested: (x, y) => {
                                    var a = root.allAppsItems[index];
                                    if (a && !a.action) root.appContextMenu(a, x, y);
                                }
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.allAppsItems.length === 0
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : root.tr("No applications")
                    opacity: 0.45
                    color: root.fg
                }
            }
        }
        } // end padded main content

        // ---- Bottom bar: darker strip, icons centered as one group ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.footBarHeight
            Layout.fillHeight: false
            color: Qt.rgba(0, 0, 0, 0.22)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: root.borderColor
                opacity: 0.35
            }

            Row {
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.footPlaces.length
                    PlasmaComponents.ToolButton {
                        required property int index
                        readonly property var def: root.footPlaces[index]
                        flat: true
                        width: root.footBtn
                        height: root.footBtn
                        icon.name: def.icon
                        icon.width: root.footIcon
                        icon.height: root.footIcon
                        Accessible.name: def.tip
                        onClicked: root.activateItem(def)
                        PlasmaComponents.ToolTip.text: def.tip
                        PlasmaComponents.ToolTip.visible: hovered
                        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }

                Item {
                    width: Kirigami.Units.smallSpacing
                    height: 1
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: Kirigami.Units.gridUnit * 1.2
                    color: root.borderColor
                    opacity: 0.45
                }

                Item {
                    width: Kirigami.Units.smallSpacing
                    height: 1
                }

                Repeater {
                    model: root.footSession.length
                    PlasmaComponents.ToolButton {
                        required property int index
                        readonly property var def: root.footSession[index]
                        flat: true
                        width: root.footBtn
                        height: root.footBtn
                        icon.name: def.icon
                        icon.width: root.footIcon
                        icon.height: root.footIcon
                        Accessible.name: def.tip
                        onClicked: root.activateItem(def)
                        PlasmaComponents.ToolTip.text: def.tip
                        PlasmaComponents.ToolTip.visible: hovered
                        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }
            }
        }
    } // end main ColumnLayout

        // ---- Category side panel (hamburger) ----
        Rectangle {
            visible: root.categoryPanelOpen
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            Layout.maximumWidth: Kirigami.Units.gridUnit * 12
            Layout.fillHeight: true
            Layout.fillWidth: false
            color: root.bg

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: root.borderColor
                opacity: 0.4
            }

            Flickable {
                id: popFlick
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                contentWidth: width
                contentHeight: popCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: popCol
                    width: popFlick.width
                    spacing: Kirigami.Units.smallSpacing / 2

                    Components.ShortcutRow {
                        width: popCol.width
                        iconName: "user-home"
                        label: root.tr("Home")
                        iconSize: root.categoryIconSize
                        selected: root.onHome
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.selectNav("home")
                    }

                    Components.ShortcutRow {
                        width: popCol.width
                        iconName: "view-app-grid-symbolic"
                        label: root.tr("All Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.selectedId === "all"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.selectNav("all")
                    }

                    Kirigami.Separator {
                        width: popCol.width
                        opacity: 0.4
                    }

                    Repeater {
                        model: root.categories.length
                        Components.ShortcutRow {
                            required property int index
                            width: popCol.width
                            iconName: root.categories[index].icon
                            label: root.categories[index].name
                            iconSize: root.categoryIconSize
                            selected: !root.searching && root.selectedId === root.categories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            fg: root.fg
                            onActivated: root.selectNav(root.categories[index].id)
                        }
                    }
                }
            }
        }
    } // end RowLayout
}
