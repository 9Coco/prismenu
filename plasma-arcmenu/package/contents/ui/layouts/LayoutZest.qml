import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Zest layout (ArcMenu Zest) �?three columns.
 *
 * Left:   avatar + places/software/settings + session
 * Middle: pinned / all / categories  (controls right)
 * Right:  apps for the middle selection (A–Z when “all�?
 * Search spans middle + right at the bottom
 */
LayoutBase {
    id: root

    readonly property var categories: root.categorySubset(["Office", "Development", "Accessories", "Utility", "Network", "Graphics", "System"])

    // Middle column selection �?drives right column content
    property string selectedId: "all"

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



    readonly property var flatItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        // "all" (the default tab) renders the A–Z sections below instead.
        // "all-apps" (extra category) renders a plain flat list of every app.
        if (selectedId === "all")
            return [];
        return root.computeContentItems(selectedId);
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


    /** Upstream extra-categories: user-configurable sidebar entries
     * (pinned / all-apps / favorites / frequent / recent-files). */
    readonly property var extraCategories: (menuData && menuData.enabledExtraCategories
        && menuData.enabledExtraCategories.length)
        ? menuData.enabledExtraCategories
        : [
            { id: "pinned", name: root.tr("Pinned Applications"), icon: "pin" },
            { id: "all-apps", name: root.tr("All Applications"), icon: "view-app-grid-symbolic" }
        ]

    function selectNav(id) {
        selectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        root.refreshNavData(id);
        if (id === "pinned" || id === "favorites" || id === "frequent" || id === "recent-files")
            return;
        menuData.currentCategoryId = (id === "all-apps") ? "all" : id;
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
            Layout.minimumWidth: root.elasticColumnMin
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
                    Layout.minimumWidth: root.elasticColumnMin
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

                        // Extra categories (pinned / all-apps / favorites /
                        // frequent / recent-files) — user configurable, same
                        // as upstream "extra-categories" setting
                        Repeater {
                            model: root.extraCategories.length
                            Components.ShortcutRow {
                                required property int index
                                width: midCol.width
                                iconName: root.extraCategories[index].icon
                                label: root.extraCategories[index].name
                                iconSize: root.categoryIconSize
                                selected: !root.searching && root.selectedId === root.extraCategories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectNav(root.extraCategories[index].id)
                            }
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
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 8

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
                                    menuData: menuData
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

                            // All apps �?A–Z sections
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
                                            menuData: menuData
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
                              : ((root.selectedId === "pinned" || root.selectedId === "favorites")
                                 ? root.tr("Pin applications from the context menu")
                                 : (root.selectedId === "recent-files"
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

            Kirigami.Separator {
                Layout.fillWidth: true
                opacity: 0.35
            }

            // Search under middle + right only
            Components.SearchField {
                Layout.fillWidth: true
                placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
            }
        }
    }
}
