import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Enterprise layout (ArcMenu Enterprise style).
 *
 * Header: user | search
 * Left: pinned / all / categories + session buttons
 * Right: content (pinned as icon grid; lists otherwise)
 */
LayoutBase {
    id: root

    readonly property var categories: root.typeCategories

    property string enterpriseSelectedId: "pinned"
    activeNavId: enterpriseSelectedId
    function resetForOpen() { root.enterpriseSelectedId = root.homeGroupId; }

    readonly property bool showPinnedGrid: !root.searching
        && root.usesGridView(enterpriseSelectedId)
    readonly property int gridIconSize: (menuData && menuData.gridIconOverride) ? menuData.gridIconSize : Math.max(40, root.appIconSize + 12)
    readonly property int gridCellWidth: Kirigami.Units.gridUnit * 5.5
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 1.8





    readonly property var extraCategories: root.preferenceGroups





    function selectEnterprise(id) {
        enterpriseSelectedId = id;
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

        // Header: user | search
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            spacing: Kirigami.Units.largeSpacing

            Item {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
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

            PlasmaComponents.Label {
                text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                elide: Text.ElideRight
                font.bold: true
                color: root.fg
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                Layout.maximumWidth: Kirigami.Units.gridUnit * 10
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userMenu()
                }
            }

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            // Left sidebar
            ColumnLayout {
                Layout.preferredWidth: root.sidebarW
                Layout.minimumWidth: root.elasticColumnMin
                Layout.maximumWidth: root.sidebarMax
                Layout.fillHeight: true
                Layout.fillWidth: false
                spacing: Kirigami.Units.smallSpacing / 2

                Flickable {
                    id: sideFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                                selected: !root.searching && root.enterpriseSelectedId === root.extraCategories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectEnterprise(root.extraCategories[index].id)
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
                                selected: !root.searching && root.enterpriseSelectedId === root.categories[index].id
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectEnterprise(root.categories[index].id)
                            }
                        }
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    opacity: 0.4
                }

                Components.SessionButtons {
                    menuData: root.menuData
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
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

            Components.LayoutGroupPane {
                Layout.fillWidth: true
                Layout.fillHeight: true
                layoutRoot: root
                items: root.contentItems
                useGrid: root.showPinnedGrid
                showDescription: root.searching || root.showAppDescriptions
                emptyText: root.searching
                           ? root.tr("No matching applications found")
                           : (root.enterpriseSelectedId === "pinned"
                              ? root.tr("Pin applications from the context menu")
                              : root.tr("No applications"))
            }
        }
    }
}
