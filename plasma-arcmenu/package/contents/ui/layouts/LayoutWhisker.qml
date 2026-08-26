import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Whisker Menu layout (XFCE Whisker / ArcMenu Whisker style).
 * Upstream whisker.js: search + user header (avatar + session buttons) with a
 * separator below it, then categories (extra-categories, user configurable) |
 * content.
 */
LayoutBase {
    id: root

    readonly property var categories: root.typeCategories

    property string whiskerSelectedId: "pinned"
    activeNavId: whiskerSelectedId


    readonly property var sessionActions: [
        { id: "settings", icon: "preferences-system", tip: root.tr("Settings"), action: "settings" },
        { id: "logout", icon: "system-log-out", tip: root.tr("Log Out"), action: "logout" },
        { id: "lock", icon: "system-lock-screen", tip: root.tr("Lock"), action: "lock" },
        { id: "restart", icon: "system-reboot", tip: root.tr("Restart"), action: "restart" },
        { id: "shutdown", icon: "system-shutdown", tip: root.tr("Shut Down"), action: "shutdown" }
    ]





    readonly property var extraCategories: root.preferenceGroups





    function selectWhisker(id) {
        whiskerSelectedId = id;
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
        }

        // User + session header (Whisker hallmark)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            spacing: Kirigami.Units.smallSpacing

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
                    hoverEnabled: true
                    Accessible.name: root.tr("User")
                    onClicked: root.userMenu()
                    PlasmaComponents.ToolTip.text: root.tr("User account")
                    PlasmaComponents.ToolTip.visible: containsMouse
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
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

        // Upstream: separator below the user header row
        Kirigami.Separator {
            Layout.fillWidth: true
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
                    // as upstream "extra-categories" setting
                    Repeater {
                        model: root.extraCategories.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.extraCategories[index].icon
                            label: root.extraCategories[index].name
                            iconSize: root.categoryIconSize
                            selected: !root.searching && root.whiskerSelectedId === root.extraCategories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectWhisker(root.extraCategories[index].id)
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
                            selected: !root.searching && root.whiskerSelectedId === root.categories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectWhisker(root.categories[index].id)
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
                useGrid: !root.searching && root.usesGridView(root.whiskerSelectedId)
                showDescription: root.showAppDescriptions
                emptyText: root.searching
                          ? root.tr("No matching applications found")
                          : (root.whiskerSelectedId === "pinned"
                             ? root.tr("Pin applications from the context menu")
                             : (root.whiskerSelectedId === "recent-files"
                                ? root.tr("No recent files")
                                : root.tr("No applications")))
            }
        }
    }
}
