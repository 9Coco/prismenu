import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/ShortcutsConfig.js" as SC

/**
 * Plasma Application Dashboard (kickerdash).
 *
 * Search is centered above three columns:
 *   left  — favorite apps (3-col grid) + logout / reboot / shutdown
 *   center — heading + icon grid (or A–Z / files / session / search)
 *   right — recent / files / all apps / categories / power
 *
 * Column widths and icon sizes follow the menu size; the three-pane
 * arrangement is fixed.
 */
LayoutBase {
    id: root

    defaultSearchOnTop: true
    property string selectedId: "frequent"

    readonly property int dashIcon: Kirigami.Units.iconSizes.medium
    readonly property int dashCellH: dashIcon + Kirigami.Units.gridUnit * 1.7
    readonly property int favMinCell: Kirigami.Units.gridUnit * 4
    readonly property int centerMinCell: Kirigami.Units.gridUnit * 4.1
    readonly property int leftColW: Math.max(root.sidebarMin, Math.min(root.sidebarW, root.sidebarMax))
    readonly property int rightColW: Math.max(140, Math.min(root.categoryColW, 280))

    readonly property var favoriteItems: {
        if (menuData && menuData.pinnedApps && menuData.pinnedApps.length)
            return menuData.pinnedApps;
        return root.defaultPinned;
    }

    readonly property var navItems: {
        var _ = root.uiLang;
        var _sig = menuData ? menuData.extrasSignature : "";
        var out = [];
        var extras = root.preferenceGroups;
        var i;
        for (i = 0; i < extras.length; ++i) {
            if (extras[i] && extras[i].id)
                out.push({ id: extras[i].id, name: extras[i].name, icon: extras[i].icon });
        }
        var cats = root.typeCategories;
        for (i = 0; i < cats.length; ++i) {
            if (cats[i] && cats[i].id)
                out.push({ id: cats[i].id, name: cats[i].name, icon: cats[i].icon });
        }
        out.push({ id: "session", name: root.tr("Power / Session"), icon: "system-shutdown" });
        return out;
    }

    readonly property string centerTitle: {
        if (root.searching)
            return "";
        if (root.selectedId === "recent-files")
            return root.tr("Files");
        if (root.selectedId === "session")
            return root.tr("System Actions");
        if (root.selectedId === "all" || root.selectedId === "all-apps")
            return "";
        return root.tr("Applications");
    }

    readonly property var centerItems: {
        if (root.searching)
            return [];
        if (root.selectedId === "all" || root.selectedId === "all-apps"
                || root.selectedId === "session")
            return [];
        return root.computeContentItems(root.selectedId === "recent" ? "frequent" : root.selectedId);
    }

    readonly property var azSections: root.allApplicationSections

    readonly property var searchGroups: {
        if (!root.searching || !menuData)
            return [];
        var rows = menuData.searchResults || [];
        var out = [];
        var cur = null;
        for (var i = 0; i < rows.length; ++i) {
            var it = rows[i];
            if (!it)
                continue;
            if (it.isSection) {
                cur = { id: it.sectionId || it.id, name: it.name, items: [] };
                out.push(cur);
                continue;
            }
            if (!cur) {
                cur = { id: "applications", name: root.tr("Applications"), items: [] };
                out.push(cur);
            }
            cur.items.push(it);
        }
        return out;
    }

    readonly property var sessionActions: {
        var _ = root.uiLang;
        var defs = SC.powerDefs(function (m) { return root.tr(m); });
        var enabled = (menuData && menuData.powerOptions && menuData.powerOptions.length)
            ? menuData.powerOptions
            : ["lock", "logout", "switchuser", "suspend", "restart", "shutdown"];
        var prefer = ["lock", "logout", "switchuser", "suspend", "restart", "shutdown"];
        var byId = {};
        for (var i = 0; i < defs.length; ++i)
            byId[defs[i].id] = defs[i];
        var out = [];
        var seen = {};
        function add(id) {
            if (seen[id] || enabled.indexOf(id) < 0)
                return;
            var d = byId[id];
            if (!d)
                return;
            seen[id] = true;
            out.push(d);
        }
        for (var p = 0; p < prefer.length; ++p)
            add(prefer[p]);
        for (var e = 0; e < enabled.length; ++e)
            add(enabled[e]);
        return out;
    }

    readonly property var footerActions: {
        var ids = ["logout", "restart", "shutdown"];
        var all = root.sessionActions;
        var out = [];
        for (var i = 0; i < ids.length; ++i) {
            for (var j = 0; j < all.length; ++j) {
                if (all[j].id === ids[i]) {
                    out.push(all[j]);
                    break;
                }
            }
        }
        if (out.length)
            return out;
        return [
            { id: "logout", name: root.tr("Log Out"), icon: "system-log-out" },
            { id: "restart", name: root.tr("Restart"), icon: "system-reboot" },
            { id: "shutdown", name: root.tr("Shut Down"), icon: "system-shutdown" }
        ];
    }

    function selectNav(id) {
        root.selectedId = id;
        if (id === "recent-files")
            root.refreshNavData("recent-files");
        if (menuData && menuData.isSearching)
            menuData.setSearch("");
    }

    component DashTile: Item {
        id: tile
        property string iconName: "application-x-executable"
        property string label: ""
        property int glyph: root.dashIcon
        property bool compact: false

        signal clicked()

        Layout.fillWidth: compact
        Layout.minimumWidth: compact ? Kirigami.Units.gridUnit * 4 : Kirigami.Units.gridUnit * 5
        Layout.preferredWidth: compact ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 6
        width: compact ? Kirigami.Units.gridUnit * 5 : (glyph + Kirigami.Units.gridUnit * 2.2)
        height: glyph + Kirigami.Units.gridUnit * (compact ? 2.2 : 2.6)

        Rectangle {
            id: ring
            anchors.horizontalCenter: parent.horizontalCenter
            y: Kirigami.Units.smallSpacing
            width: tile.glyph + Kirigami.Units.largeSpacing
            height: width
            radius: width / 2
            color: tileMouse.containsMouse ? root.hoverBg : "transparent"
            border.width: 1
            border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b,
                                  tileMouse.containsMouse ? 0.65 : 0.35)

            Kirigami.Icon {
                anchors.centerIn: parent
                width: tile.glyph * 0.55
                height: width
                source: tile.iconName
                color: root.fg
                isMask: true
            }
        }

        PlasmaComponents.Label {
            anchors.top: ring.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing / 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Kirigami.Units.smallSpacing
            text: tile.label
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: root.fg
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.largeSpacing * 2
        anchors.bottomMargin: Kirigami.Units.largeSpacing
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4

            Components.LayoutSearchField {
                id: searchField
                layoutRoot: root
                Layout.fillWidth: false
                width: Math.min(Kirigami.Units.gridUnit * 28, parent.width * 0.38)
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing * 2
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            // ---- Favorites ----
            ColumnLayout {
                Layout.preferredWidth: root.leftColW
                Layout.minimumWidth: root.sidebarMin
                Layout.maximumWidth: root.sidebarMax
                Layout.fillWidth: false
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: root.tr("Favorite Applications")
                    font.weight: Font.DemiBold
                    color: root.fg
                    Layout.fillWidth: true
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: root.fg
                    opacity: 0.28
                }

                Components.LayoutAppGrid {
                    layoutRoot: root
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    items: root.favoriteItems
                    columns: 3
                    minCellWidth: root.favMinCell
                    iconSize: root.dashIcon
                    multiLineLabels: true
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: root.footerActions
                        DashTile {
                            required property var modelData
                            iconName: modelData.icon
                            label: {
                                if (modelData.id === "logout")
                                    return root.tr("Log Out");
                                if (modelData.id === "restart")
                                    return root.tr("Restart");
                                if (modelData.id === "shutdown")
                                    return root.tr("Shut Down");
                                return modelData.name;
                            }
                            glyph: Kirigami.Units.iconSizes.smallMedium
                            compact: true
                            onClicked: root.powerAction(modelData.id)
                        }
                    }
                }
            }

            Components.ColumnSplitHandle {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                z: 5
                fg: root.fg
                currentWidth: root.leftColW
                minWidth: root.sidebarMin
                maxWidth: root.sidebarMax
                sidebarOnRight: false
                flipped: root.flip
                onWidthDragged: (w) => root.setSidebarFromDrag(w)
            }

            // ---- Center pane ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 12
                Layout.preferredWidth: 1
                clip: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    visible: root.centerTitle.length > 0
                    text: root.centerTitle
                    font.weight: Font.DemiBold
                    color: root.fg
                    Layout.fillWidth: true
                }
                Rectangle {
                    visible: root.centerTitle.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: root.fg
                    opacity: 0.28
                }

                // Category / recent / files grid
                Components.LayoutGroupPane {
                    visible: !root.searching && root.selectedId !== "all"
                             && root.selectedId !== "all-apps" && root.selectedId !== "session"
                    layoutRoot: root
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    items: root.centerItems
                    navId: root.selectedId === "recent" ? "frequent" : root.selectedId
                    useGrid: root.usesGridView(root.selectedId === "recent" ? "frequent" : root.selectedId)
                    showDescription: false
                }

                // All applications A–Z
                ListView {
                    visible: !root.searching && (root.selectedId === "all" || root.selectedId === "all-apps")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: Kirigami.Units.largeSpacing
                    QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
                    model: root.azSections.length
                    delegate: Column {
                        required property int index
                        readonly property var section: root.azSections[index] || ({ letter: "", apps: [] })
                        width: ListView.view.width
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: section.letter || ""
                            font.weight: Font.DemiBold
                            color: root.fg
                        }
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.fg
                            opacity: 0.28
                        }
                        Components.LayoutAppGrid {
                            id: azGrid
                            width: parent.width
                            height: azGrid.cellHeight * Math.max(1,
                                Math.ceil((section.apps ? section.apps.length : 0)
                                    / Math.max(1, azGrid.resolvedColumns)))
                            layoutRoot: root
                            items: section.apps || []
                            columns: 6
                            minCellWidth: root.centerMinCell
                            iconSize: root.dashIcon
                            interactive: false
                            multiLineLabels: true
                        }
                    }
                }

                // Session actions
                Flow {
                    visible: !root.searching && root.selectedId === "session"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Kirigami.Units.largeSpacing * 2
                    Repeater {
                        model: root.sessionActions
                        DashTile {
                            required property var modelData
                            iconName: modelData.icon
                            label: {
                                if (modelData.id === "lock")
                                    return root.tr("Lock");
                                if (modelData.id === "logout")
                                    return root.tr("Log Out");
                                if (modelData.id === "switchuser")
                                    return root.tr("Switch User");
                                if (modelData.id === "suspend")
                                    return root.tr("Suspend");
                                if (modelData.id === "restart")
                                    return root.tr("Restart");
                                if (modelData.id === "shutdown")
                                    return root.tr("Shut Down");
                                return modelData.name;
                            }
                            glyph: root.dashIcon
                            onClicked: root.powerAction(modelData.id)
                        }
                    }
                }

                // Search results (sectioned)
                ListView {
                    visible: root.searching
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: Kirigami.Units.largeSpacing
                    QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
                    model: root.searchGroups.length
                    delegate: Column {
                        required property int index
                        readonly property var group: root.searchGroups[index] || ({ id: "", name: "", items: [] })
                        readonly property bool textOnly: group.id === "bookmarks"
                        width: ListView.view.width
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            visible: group.name && group.id !== "applications"
                            text: group.name || ""
                            font.weight: Font.DemiBold
                            color: root.fg
                        }
                        Rectangle {
                            visible: group.name && group.id !== "applications"
                            width: parent.width
                            height: 1
                            color: root.fg
                            opacity: 0.28
                        }

                        Components.LayoutAppGrid {
                            id: searchGrid
                            visible: !textOnly
                            width: parent.width
                            height: searchGrid.cellHeight * Math.max(1,
                                Math.ceil((group.items ? group.items.length : 0)
                                    / Math.max(1, searchGrid.resolvedColumns)))
                            layoutRoot: root
                            items: group.items || []
                            columns: 6
                            minCellWidth: root.centerMinCell
                            iconSize: root.dashIcon
                            interactive: false
                            multiLineLabels: true
                        }

                        Flow {
                            visible: textOnly
                            width: parent.width
                            spacing: Kirigami.Units.largeSpacing
                            Repeater {
                                model: textOnly ? (group.items ? group.items.length : 0) : 0
                                PlasmaComponents.Label {
                                    required property int index
                                    readonly property var bm: group.items[index]
                                    text: bm ? (bm.name || "") : ""
                                    color: root.fg
                                    wrapMode: Text.WordWrap
                                    width: Math.min(implicitWidth, Kirigami.Units.gridUnit * 10)
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (bm) root.activateItem(bm)
                                    }
                                }
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    visible: {
                        if (root.searching)
                            return root.searchGroups.length === 0;
                        if (root.selectedId === "all" || root.selectedId === "all-apps")
                            return root.azSections.length === 0;
                        if (root.selectedId === "session")
                            return root.sessionActions.length === 0;
                        return root.centerItems.length === 0;
                    }
                    Layout.alignment: Qt.AlignHCenter
                    text: root.searching
                        ? root.tr("No matching results found")
                        : root.tr("No applications")
                    opacity: 0.5
                    color: root.fg
                }
            }

            // ---- Categories ----
            Components.ColumnSplitHandle {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                z: 5
                fg: root.fg
                currentWidth: root.rightColW
                minWidth: 140
                maxWidth: 280
                sidebarOnRight: true
                flipped: root.flip
                onWidthDragged: (w) => root.setCategoryColumnFromDrag(w)
            }

            ListView {
                id: navList
                Layout.preferredWidth: root.rightColW
                Layout.minimumWidth: 140
                Layout.maximumWidth: 280
                Layout.fillWidth: false
                Layout.fillHeight: true
                clip: true
                enabled: !root.searching
                opacity: root.searching ? 0.35 : 1
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
                model: root.navItems
                spacing: Kirigami.Units.smallSpacing / 4

                delegate: Item {
                    id: navDel
                    required property var modelData
                    width: navList.width
                    height: Kirigami.Units.gridUnit * 1.85
                    readonly property bool selected: !root.searching && root.selectedId === modelData.id

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.smallSpacing
                        color: navDel.selected || navMouse.containsMouse ? root.selectedBg : "transparent"
                    }

                    PlasmaComponents.Label {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        text: navDel.modelData.name || ""
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        color: navDel.selected || navMouse.containsMouse ? root.selectedFg : root.fg
                    }

                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectNav(navDel.modelData.id)
                    }
                }
            }
        }
    }
}
