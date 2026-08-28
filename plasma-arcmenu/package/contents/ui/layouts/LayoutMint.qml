import QtQuick
import QtQuick.Controls as QQC2
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

    readonly property var categories: root.typeCategories

    property string mintSelectedId: "pinned"
    activeNavId: mintSelectedId
    function resetForOpen() { root.mintSelectedId = root.homeGroupId; }


    // Top group: places / shortcuts — upstream mint-layout-extra-shortcuts
    // is user configurable; fall back to the standard set when empty.
    readonly property var railTopActions: root.asRailItems(root.applicationShortcuts)

    // Bottom group: session (separated from folder by a larger gap)
    readonly property var railSessionActions: [
        { id: "logout", icon: "system-log-out", tip: root.tr("Log Out"), action: "logout" },
        { id: "lock", icon: "system-lock-screen", tip: root.tr("Lock"), action: "lock" },
        { id: "shutdown", icon: "system-shutdown", tip: root.tr("Shut Down"), action: "shutdown" }
    ]




    readonly property var extraCategories: root.preferenceGroups

    function selectMint(id) {
        mintSelectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        root.refreshNavData(id);
        if (id === "pinned" || id === "favorites" || id === "frequent" || id === "recent-files" || String(id).indexOf("qgrp-") === 0 || String(id).indexOf("tgrp-") === 0)
            return;
        menuData.currentCategoryId = (id === "all-apps") ? "all" : id;
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Far-left icon rail: centered when it fits, scrollable when not ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            Layout.maximumWidth: Kirigami.Units.gridUnit * 3.5
            spacing: 0

            Flickable {
                id: railFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                contentWidth: width
                contentHeight: Math.max(height, railCol.height)
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

                Column {
                    id: railCol
                    width: railFlick.width
                    y: Math.max(0, (railFlick.height - height) / 2)
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: root.railTopActions.length
                        PlasmaComponents.ToolButton {
                            required property int index
                            readonly property var def: root.railTopActions[index]
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Kirigami.Units.gridUnit * 2.4
                            height: Kirigami.Units.gridUnit * 2.4
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
                        width: 1
                        height: Kirigami.Units.largeSpacing * 2
                    }

                    Kirigami.Separator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Kirigami.Units.gridUnit * 1.6
                        opacity: 0.35
                    }

                    Item {
                        width: 1
                        height: Kirigami.Units.smallSpacing
                    }

                    Repeater {
                        model: root.railSessionActions.length
                        PlasmaComponents.ToolButton {
                            required property int index
                            readonly property var def: root.railSessionActions[index]
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Kirigami.Units.gridUnit * 2.4
                            height: Kirigami.Units.gridUnit * 2.4
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
            }
        }

        // ---- Main body: search + categories | content ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
                visible: root.searchOnTop
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
                    Layout.minimumHeight: 0
                    contentWidth: width
                    contentHeight: sideCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

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

                Components.LayoutGroupPane {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    layoutRoot: root
                    items: root.contentItems
                    useGrid: !root.searching && root.usesGridView(root.mintSelectedId)
                    showDescription: root.showAppDescriptions
                    emptyText: root.searching
                              ? root.tr("No matching applications found")
                              : (root.mintSelectedId === "pinned"
                                 ? root.tr("Pin applications from the context menu")
                                 : (root.mintSelectedId === "recent-files"
                                    ? root.tr("No recent files")
                                    : root.tr("No applications")))
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: !root.searchOnTop
                opacity: 0.5
            }

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
                visible: !root.searchOnTop
            }
        }
    }
}
