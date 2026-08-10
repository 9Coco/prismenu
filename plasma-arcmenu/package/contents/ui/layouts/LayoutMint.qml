import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Mint Menu layout (Linux Mint / ArcMenu Mint style).
 * Upstream mint.js: icon rail (mint-layout-extra-shortcuts, configurable) |
 * search top/bottom + (extra-categories + categories, hover activation) | content
 */
LayoutBase {
    id: root

    readonly property var categories: root.categorySubset(["Office", "Development", "Accessories", "Utility", "Network", "Graphics", "System"])

    property string mintSelectedId: "pinned"
    activeNavId: mintSelectedId
    defaultSearchOnTop: true


    // Top group: places / shortcuts — upstream mint-layout-extra-shortcuts
    // is user configurable; fall back to the standard set when empty.
    readonly property var railTopActions: (menuData && menuData.systemShortcuts
        && menuData.systemShortcuts.length)
        ? menuData.systemShortcuts.map(function (s) {
            return { id: s.id, icon: s.icon, tip: s.name, exec: s.exec, action: s.action,
                     kickerUrl: s.kickerUrl, entryPath: s.entryPath };
        })
        : [
            { id: "settings", icon: "preferences-system", tip: root.tr("Settings"), action: "settings" },
            { id: "software", icon: "plasmadiscover", tip: root.tr("Software"), action: "discover" },
            { id: "files", icon: "system-file-manager", tip: root.tr("Files"), exec: "dolphin" }
        ]

    // Bottom group: session (separated from folder by a larger gap)
    readonly property var railSessionActions: [
        { id: "logout", icon: "system-log-out", tip: root.tr("Log Out"), action: "logout" },
        { id: "lock", icon: "system-lock-screen", tip: root.tr("Lock"), action: "lock" },
        { id: "shutdown", icon: "system-shutdown", tip: root.tr("Shut Down"), action: "shutdown" }
    ]




    function activateItem(item) {
        if (!item || item.isSection)
            return;
        if (item.action === "configure") {
            if (menuData) menuData.requestConfigure();
            return;
        }
        if (item.action) {
            root.powerAction(item.action);
            return;
        }
        if (item.exec) {
            root.appActivated(item);
            return;
        }
        root.appActivated(item);
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

    function selectMint(id) {
        mintSelectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        root.refreshNavData(id);
        if (id === "pinned" || id === "favorites" || id === "frequent" || id === "recent-files")
            return;
        menuData.currentCategoryId = (id === "all-apps") ? "all" : id;
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Far-left icon rail: vertically centered, gap between files & logout ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            Layout.maximumWidth: Kirigami.Units.gridUnit * 3.5
            spacing: 0

            // Equal flex spacers �?whole icon stack is vertically centered
            Item { Layout.fillHeight: true }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.railTopActions.length
                    PlasmaComponents.ToolButton {
                        required property int index
                        readonly property var def: root.railTopActions[index]
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                        flat: true
                        icon.name: def.icon
                        icon.width: Kirigami.Units.iconSizes.medium
                        icon.height: Kirigami.Units.iconSizes.medium
                        Accessible.name: def.tip
                        onClicked: root.activateItem(def)
                        PlasmaComponents.ToolTip.text: def.tip
                        PlasmaComponents.ToolTip.visible: hovered
                        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }

                // Distinct gap between folder and session buttons (Mint style)
                Item {
                    Layout.preferredHeight: Kirigami.Units.largeSpacing * 2
                    Layout.minimumHeight: Kirigami.Units.gridUnit
                }

                Kirigami.Separator {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                    opacity: 0.35
                }

                Item {
                    Layout.preferredHeight: Kirigami.Units.smallSpacing
                }

                Repeater {
                    model: root.railSessionActions.length
                    PlasmaComponents.ToolButton {
                        required property int index
                        readonly property var def: root.railSessionActions[index]
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                        flat: true
                        icon.name: def.icon
                        icon.width: Kirigami.Units.iconSizes.medium
                        icon.height: Kirigami.Units.iconSizes.medium
                        Accessible.name: def.tip
                        onClicked: root.activateItem(def)
                        PlasmaComponents.ToolTip.text: def.tip
                        PlasmaComponents.ToolTip.visible: hovered
                        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ---- Main body: search + categories | content ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Components.SearchField {
                Layout.fillWidth: true
                visible: root.searchOnTop
                placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
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

                Flickable {
                    id: sideFlick
                    Layout.preferredWidth: root.sidebarW
                    Layout.minimumWidth: root.elasticColumnMin
                    Layout.maximumWidth: root.sidebarMax
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
                                selected: !root.searching && root.mintSelectedId === root.extraCategories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectMint(root.extraCategories[index].id)
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
                                selected: !root.searching && root.mintSelectedId === root.categories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectMint(root.categories[index].id)
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

                    ListView {
                        id: contentFlick
                        anchors.fill: parent
                        model: root.contentItems
                        spacing: Kirigami.Units.smallSpacing / 2
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
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
                              : (root.mintSelectedId === "pinned"
                                 ? root.tr("Pin applications from the context menu")
                                 : (root.mintSelectedId === "recent-files"
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
                visible: !root.searchOnTop
                opacity: 0.5
            }

            Components.SearchField {
                Layout.fillWidth: true
                visible: !root.searchOnTop
                placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: if (menuData) menuData.setSearch(text)
            }
        }
    }
}
