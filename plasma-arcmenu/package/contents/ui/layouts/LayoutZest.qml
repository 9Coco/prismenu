import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

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

    readonly property var categories: root.typeCategories

    // Middle column selection �?drives right column content
    property string selectedId: "all"

    /** Both the default "all" tab and the "all-apps" extra category show the
     * A–Z sectioned view (upstream renders All Applications the same way). */
    readonly property bool allView: selectedId === "all" || selectedId === "all-apps"

    readonly property int avatarSize: Kirigami.Units.gridUnit * 4

    readonly property var sideItems: root.sidebarShortcuts



    readonly property var flatItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        // "all" / "all-apps" render the A–Z sections below instead.
        if (root.allView)
            return [];
        return root.computeContentItems(selectedId);
    }

    readonly property var azSections: {
        if (root.searching || !root.allView)
            return [];
        return root.allApplicationSections;
    }

    readonly property var rightItems: (!root.searching && root.allView)
        ? root.allApplicationRows : root.flatItems

    readonly property bool rightEmpty: {
        if (root.searching)
            return flatItems.length === 0;
        if (root.allView)
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
        if (id === "pinned" || id === "favorites" || id === "frequent"
                || id === "recent-files" || String(id).indexOf("qgrp-") === 0 || String(id).indexOf("tgrp-") === 0)
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
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

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
                    QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

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

                    Components.LayoutAppList {
                        layoutRoot: root
                        anchors.fill: parent
                        items: root.rightItems
                        iconSize: Math.max(root.appIconSize, 28)
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
            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
            }
        }
    }
}
