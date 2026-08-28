import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Budgie Menu layout (ArcMenu Budgie style).
 * Upstream budgie.js: search top/bottom | sidebar (extra-categories +
 * categories, category icons hidden, hover activation) | content.
 * No Software/Settings extras, no session bar (matches reference screenshot).
 */
LayoutBase {
    id: root

    readonly property var categories: root.typeCategories

    property string budgieSelectedId: "pinned"
    activeNavId: budgieSelectedId
    function resetForOpen() { root.budgieSelectedId = root.homeGroupId; }






    readonly property var extraCategories: root.preferenceGroups






    function selectBudgie(id) {
        budgieSelectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        root.refreshNavData(id);
        if (id === "pinned" || id === "favorites" || id === "frequent" || id === "recent-files" || String(id).indexOf("qgrp-") === 0 || String(id).indexOf("tgrp-") === 0)
            return;
        menuData.currentCategoryId = (id === "all-apps") ? "all" : id;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
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
                    // as upstream "extra-categories" setting.
                    // Upstream hides category icons (iconSizeCategories=HIDDEN).
                    Repeater {
                        model: root.extraCategories.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.extraCategories[index].icon
                            label: root.extraCategories[index].name
                            iconSize: 0
                            selected: !root.searching && root.budgieSelectedId === root.extraCategories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectBudgie(root.extraCategories[index].id)
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
                            iconSize: 0
                            activateOnHover: true
                            selected: !root.searching && root.budgieSelectedId === root.categories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectBudgie(root.categories[index].id)
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
                useGrid: !root.searching && root.usesGridView(root.budgieSelectedId)
                showDescription: root.showAppDescriptions
                emptyText: root.searching
                          ? root.tr("No matching applications found")
                          : (root.budgieSelectedId === "pinned"
                             ? root.tr("Pin applications from the context menu")
                             : (root.budgieSelectedId === "recent-files"
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
