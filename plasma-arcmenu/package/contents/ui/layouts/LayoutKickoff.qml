import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/SidebarModel.js" as SidebarModel

/**
 * Plasma 6 Kickoff layout.
 *
 * The chrome follows Plasma's current default launcher while application,
 * category, places, search, context-menu, and power behavior stays on the
 * shared LayoutBase/MenuData contracts.
 */
LayoutBase {
    id: root

    property string section: "applications" // applications | places
    property string applicationsPage: "special:favorites"
    property string placesPage: "computer"
    property bool menuPinned: false

    signal keepOpenRequested(bool pinned)

    readonly property bool showingSearch: !!(menuData && menuData.isSearching)
    readonly property var activeApplicationItem: {
        var nav = root.applicationNavigation;
        for (var i = 0; i < nav.length; ++i) {
            if (nav[i].id === root.applicationsPage)
                return nav[i];
        }
        return nav.length ? nav[0] : null;
    }
    readonly property bool showingFavorites: !showingSearch
        && section === "applications" && activeApplicationItem
        && activeApplicationItem.kind === "favorites"

    readonly property var applicationNavigation: {
        var cats = menuData && menuData.categories ? menuData.categories : [];
        var groups = menuData && menuData.customQuickLinkDefs
            ? menuData.customQuickLinkDefs : [];
        var order = menuData && menuData.sidebarOrder ? menuData.sidebarOrder : [];
        var hidden = menuData && menuData.sidebarHidden ? menuData.sidebarHidden : [];
        return SidebarModel.orderedItems(cats, groups, order, hidden, root.tr);
    }

    readonly property var placesNavigation: [
        { id: "computer", name: root.tr("Computer"), icon: "computer" },
        { id: "history", name: root.tr("History"), icon: "view-history" },
        { id: "frequent", name: root.tr("Frequently Used"), icon: "view-history" }
    ]

    readonly property var favoriteItems: {
        var pinned = menuData && menuData.pinnedApps ? menuData.pinnedApps : [];
        return pinned.length ? pinned : root.defaultPinned;
    }

    readonly property var listItems: {
        if (root.showingSearch)
            return menuData && menuData.searchResults ? menuData.searchResults : [];
        if (root.section === "applications") {
            var item = root.activeApplicationItem;
            if (!item)
                return [];
            if (item.kind === "all")
                return root.allApplicationRows;
            if (item.kind === "group")
                return menuData && menuData.customGroupApps
                    ? menuData.customGroupApps(item.target) : [];
            if (item.kind === "category")
                return root.computeContentItems(item.target);
            return root.favoriteItems;
        }
        if (root.placesPage === "computer")
            return root.computerItems();
        if (root.placesPage === "history") {
            var recentApps = menuData && menuData.recentApps ? menuData.recentApps : [];
            var recentFiles = menuData && menuData.recentFileResults ? menuData.recentFileResults : [];
            return recentApps.concat(recentFiles);
        }
        return menuData && menuData.recentApps ? menuData.recentApps : [];
    }

    function sectionRow(name) {
        return { id: "section-" + name, name: root.tr(name), isSection: true };
    }

    function catalogApp(ids, fallback) {
        var apps = root.allApplications;
        for (var i = 0; i < ids.length; ++i) {
            for (var j = 0; j < apps.length; ++j) {
                var appId = String(apps[j].id || apps[j].desktopId || "").toLowerCase();
                if (appId.indexOf(ids[i]) >= 0)
                    return apps[j];
            }
        }
        return fallback;
    }

    function computerItems() {
        var apps = [
            root.catalogApp(["krunner"], {
                id: "kickoff-krunner", name: root.tr("Show KRunner"), icon: "krunner",
                exec: "krunner", genericName: root.tr("Search, calculate, or run commands")
            }),
            root.catalogApp(["systemsettings"], {
                id: "kickoff-settings", name: root.tr("System Settings"), icon: "preferences-system",
                action: "settings", genericName: root.tr("Configure system behavior and appearance")
            }),
            root.catalogApp(["kinfocenter"], {
                id: "kickoff-info", name: root.tr("Info Center"), icon: "hwinfo",
                exec: "kinfocenter", genericName: root.tr("View system hardware and status")
            }),
            root.catalogApp(["discover"], {
                id: "kickoff-discover", name: root.tr("Discover"), icon: "plasmadiscover",
                action: "discover", genericName: root.tr("Install and remove applications")
            })
        ];
        var places = menuData && menuData.places ? menuData.places : [];
        return [root.sectionRow("Applications")].concat(apps)
            .concat([root.sectionRow("Places")]).concat(places);
    }

    function powerEnabled(id) {
        return !!(menuData && menuData.powerOptions
            && menuData.powerOptions.indexOf(id) >= 0);
    }

    function chooseApplicationPage(id) {
        root.section = "applications";
        root.applicationsPage = id;
        if (menuData) {
            menuData.setSearch("");
            var item = root.activeApplicationItem;
            if (item && item.kind === "category")
                menuData.currentCategoryId = item.target;
        }
    }

    function choosePlacesPage(id) {
        root.section = "places";
        root.placesPage = id;
        if (menuData)
            menuData.setSearch("");
        if (id === "history" && menuData && menuData.requestRecentFilesRefresh)
            menuData.requestRecentFilesRefresh();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header: account, search, settings, keep-open pin.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.6
            Layout.minimumHeight: Layout.preferredHeight
            Layout.maximumHeight: Layout.preferredHeight
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.preferredWidth: Math.max(150, root.sidebarW - Kirigami.Units.smallSpacing)
                Layout.fillHeight: true

                RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    Components.UserFace {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        userIcon: menuData ? menuData.userIcon : "user-identity"
                        userName: menuData ? menuData.userName : ""
                        fallbackColor: root.fg
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: menuData ? menuData.userName : root.tr("User")
                        elide: Text.ElideRight
                        font.weight: Font.Medium
                        color: root.fg
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userMenu()
                }
            }

            Components.LayoutSearchField {
                id: searchField
                layoutRoot: root
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                autoFocus: true
                showSettingsButton: false
            }

            RowLayout {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.minimumWidth: Layout.preferredWidth
                spacing: 0

                Components.ArcMenuSettingsButton {
                    layoutRoot: root
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                }

                PlasmaComponents.ToolButton {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                    checkable: true
                    checked: root.menuPinned
                    icon.name: checked ? "window-pin" : "window-unpin"
                    Accessible.name: root.tr("Keep Open")
                    onToggled: {
                        root.menuPinned = checked;
                        root.keepOpenRequested(checked);
                    }
                    PlasmaComponents.ToolTip.text: Accessible.name
                    PlasmaComponents.ToolTip.visible: hovered
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            spacing: 0

            // Left navigation mirrors Kickoff's application/category and
            // computer/history/frequent sidebars.
            ListView {
                id: navigation
                Layout.preferredWidth: root.sidebarW
                Layout.minimumWidth: root.elasticColumnMin
                Layout.maximumWidth: root.sidebarMax
                Layout.fillHeight: true
                Layout.fillWidth: false
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
                model: root.section === "applications"
                    ? root.applicationNavigation : root.placesNavigation

                delegate: Item {
                    id: navDelegate
                    required property int index
                    readonly property var navItem: navigation.model[index]
                    readonly property bool selected: root.section === "applications"
                        ? root.applicationsPage === navItem.id
                        : root.placesPage === navItem.id
                    width: navigation.width
                    height: Math.max(Kirigami.Units.gridUnit * 2.05,
                                     root.categoryIconSize + Kirigami.Units.smallSpacing * 2)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing / 2
                        radius: Kirigami.Units.smallSpacing
                        color: navDelegate.selected || navMouse.containsMouse
                            ? root.selectedBg : "transparent"
                    }

                    Kirigami.Separator {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        visible: root.section === "applications" && navDelegate.index === 2
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Components.ResolvedIcon {
                            iconName: navDelegate.navItem.icon || "applications-other"
                            // Bundled category SVGs remain masks on their own;
                            // keep theme-only icons (Help, Edge, Chrome…) intact.
                            preferSymbolic: false
                            tintColor: navDelegate.selected || navMouse.containsMouse
                                ? root.selectedFg : root.fg
                            Layout.preferredWidth: root.categoryIconSize
                            Layout.preferredHeight: root.categoryIconSize
                        }

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: navDelegate.navItem.name || ""
                            elide: Text.ElideRight
                            font.weight: Font.Medium
                            color: navDelegate.selected || navMouse.containsMouse
                                ? root.selectedFg : root.fg
                        }
                    }

                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.section === "applications")
                                root.chooseApplicationPage(navDelegate.navItem.id);
                            else
                                root.choosePlacesPage(navDelegate.navItem.id);
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
                Layout.margins: Kirigami.Units.smallSpacing

                Components.LayoutAppGrid {
                    anchors.fill: parent
                    visible: root.showingFavorites
                    layoutRoot: root
                    items: root.favoriteItems
                    columns: Math.max(4, Math.floor(width / (Kirigami.Units.gridUnit * 5)))
                    iconSize: Math.max(root.gridIconSize, Kirigami.Units.iconSizes.large)
                }

                Components.LayoutAppList {
                    anchors.fill: parent
                    visible: !root.showingFavorites
                    layoutRoot: root
                    items: root.listItems
                    showDescription: true
                    inlineDescription: root.showingSearch || root.section === "places"
                    iconSize: Math.max(root.appIconSize, Kirigami.Units.iconSizes.smallMedium)
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.showingFavorites
                        ? root.favoriteItems.length === 0 : root.listItems.length === 0
                    text: root.showingSearch
                        ? root.tr("No matching results found")
                        : root.tr("No applications")
                    opacity: 0.55
                    color: root.fg
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // Footer: primary sections on the left, direct power actions on the right.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
            Layout.minimumHeight: Layout.preferredHeight
            Layout.maximumHeight: Layout.preferredHeight
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing / 2

            QQC2.ToolButton {
                checkable: true
                checked: root.section === "applications"
                text: root.tr("Applications")
                icon.name: "view-app-grid-symbolic"
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: root.section = "applications"
            }

            QQC2.ToolButton {
                checkable: true
                checked: root.section === "places"
                text: root.tr("Places")
                icon.name: "compass"
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: root.section = "places"
            }

            Item { Layout.fillWidth: true }

            QQC2.ToolButton {
                visible: root.powerEnabled("suspend")
                text: root.tr("Suspend")
                icon.name: "system-suspend"
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: root.powerAction("suspend")
            }

            QQC2.ToolButton {
                visible: root.powerEnabled("restart")
                text: root.tr("Restart")
                icon.name: "system-reboot"
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: root.powerAction("restart")
            }

            QQC2.ToolButton {
                visible: root.powerEnabled("shutdown")
                text: root.tr("Shut Down")
                icon.name: "system-shutdown"
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: root.powerAction("shutdown")
            }

            QQC2.ToolButton {
                id: sessionButton
                text: root.tr("Session")
                icon.name: "system-log-out"
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: sessionMenu.open()
            }
        }
    }

    // Keep the popup out of the footer's layout calculation. Nesting a Menu
    // in ToolButton makes some Plasma styles derive the button presentation
    // from popup content instead of the explicit Session label.
    QQC2.Menu {
        id: sessionMenu
        parent: sessionButton
        y: -height

        QQC2.MenuItem {
            visible: root.powerEnabled("lock")
            text: root.tr("Lock")
            icon.name: "system-lock-screen"
            onTriggered: root.powerAction("lock")
        }
        QQC2.MenuItem {
            visible: root.powerEnabled("logout")
            text: root.tr("Log Out")
            icon.name: "system-log-out"
            onTriggered: root.powerAction("logout")
        }
        QQC2.MenuItem {
            visible: root.powerEnabled("switchuser")
            text: root.tr("Switch User")
            icon.name: "system-switch-user"
            onTriggered: root.powerAction("switchuser")
        }
        QQC2.MenuItem {
            visible: root.powerEnabled("hibernate")
            text: root.tr("Hibernate")
            icon.name: "system-suspend-hibernate"
            onTriggered: root.powerAction("hibernate")
        }
    }

    Component.onDestruction: {
        if (root.menuPinned)
            root.keepOpenRequested(false);
    }
}
