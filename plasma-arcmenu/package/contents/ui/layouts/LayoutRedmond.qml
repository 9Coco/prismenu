import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Redmond layout (ArcMenu Redmond / Windows-style).
 *
 * Left: pinned/recent program list + in-place All Programs + bottom search
 * Right: user, places, system shortcuts, session buttons
 */
LayoutBase {
    id: root

    property bool showAllPrograms: false


    readonly property var placeItems: [
        { id: "place-home", name: root.tr("Home"), icon: "user-home", place: "HOME" },
        { id: "place-docs", name: root.tr("Documents"), icon: "folder-documents", place: "DOCUMENTS" },
        { id: "place-dl", name: root.tr("Downloads"), icon: "folder-download", place: "DOWNLOAD" },
        { id: "place-music", name: root.tr("Music"), icon: "folder-music", place: "MUSIC" },
        { id: "place-pics", name: root.tr("Pictures"), icon: "folder-pictures", place: "PICTURES" },
        { id: "place-videos", name: root.tr("Videos"), icon: "folder-videos", place: "VIDEOS" }
    ]

    readonly property var shortcutItems: [
        { id: "shortcut-software", name: root.tr("Software"), icon: "plasmadiscover", action: "discover" },
        { id: "shortcut-settings", name: root.tr("Settings"), icon: "preferences-system", action: "settings" },
        { id: "shortcut-tweaks", name: root.tr("Tweaks"), icon: "preferences-desktop-display", exec: "systemsettings kcm_lookandfeel" }
    ]

    readonly property var programItems: {
        if (root.searching)
            return menuData && menuData.searchResults ? menuData.searchResults : [];
        if (root.showAllPrograms)
            return root.allApplicationRows;
        var pinned = menuData && menuData.pinnedApps ? menuData.pinnedApps : [];
        var recent = menuData && menuData.recentApps ? menuData.recentApps : [];
        var combined = pinned.concat(recent);
        var out = [], seen = {};
        for (var i = 0; i < combined.length; ++i) {
            var item = combined[i];
            var id = String(item.id || item.name || "");
            if (!seen[id]) { seen[id] = true; out.push(item); }
        }
        return out.length ? out.slice(0, 12) : root.defaultPinned;
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: 0
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Left: Win7-style program list ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Components.LayoutAppList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                layoutRoot: root
                items: root.programItems
                showDescription: root.searching
                iconSize: Math.max(28, root.appIconSize)
            }

            PlasmaComponents.Button {
                Layout.fillWidth: true
                visible: !root.searching
                text: root.showAllPrograms ? root.tr("Back") : root.tr("All Applications") + "  ›"
                icon.name: root.showAllPrograms ? "go-previous-symbolic" : "view-app-list"
                onClicked: root.showAllPrograms = !root.showAllPrograms
            }

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
                Layout.fillHeight: false
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
            sidebarOnRight: true
            flipped: root.flip
            onWidthDragged: (w) => root.setSidebarFromDrag(w)
        }

        // ---- Right sidebar ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: root.sidebarW
            Layout.minimumWidth: root.elasticColumnMin
            Layout.maximumWidth: root.sidebarMax
            spacing: Kirigami.Units.smallSpacing / 2

            Item {
                id: userRow
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(avatarBox.height + Kirigami.Units.smallSpacing * 2,
                                                 Kirigami.Units.gridUnit * 2.1)
                Accessible.name: userLabel.text
                Accessible.role: Accessible.Button
                Accessible.onPressAction: root.userMenu()

                readonly property bool showAvatar: !menuData || menuData.showUserAvatar !== false
                readonly property string avatarShape: (menuData && menuData.avatarShape)
                    ? menuData.avatarShape : "circle"

                Rectangle {
                    anchors.fill: parent
                    radius: Kirigami.Units.smallSpacing
                    color: userMouse.containsMouse ? root.hoverBg : "transparent"
                    opacity: userMouse.containsMouse ? 1 : 0
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Item {
                        id: avatarBox
                        readonly property int avSize: Math.max(root.categoryIconSize,
                                                               Kirigami.Units.iconSizes.medium)
                        Layout.preferredWidth: userRow.showAvatar ? avSize : 0
                        Layout.preferredHeight: avSize
                        visible: userRow.showAvatar
                        // Do not clip — Kirigami Avatar layer-effects paint a solid
                        // disc under a clipped ancestor (same rule as ArcMenu).

                        Components.UserFace {
                            anchors.fill: parent
                            userIcon: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                            userName: (menuData && menuData.userName) ? menuData.userName : ""
                            fallbackColor: userMouse.containsMouse ? root.hoverFg : root.fg
                            shape: userRow.avatarShape
                            showRing: true
                        }
                    }

                    PlasmaComponents.Label {
                        id: userLabel
                        Layout.fillWidth: true
                        text: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                        elide: Text.ElideRight
                        color: userMouse.containsMouse ? root.hoverFg : root.fg
                    }
                }

                MouseArea {
                    id: userMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userMenu()
                }
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
                        model: root.placeItems.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.placeItems[index].icon
                            label: root.placeItems[index].name
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.activateItem(root.placeItems[index])
                        }
                    }

                    Kirigami.Separator {
                        width: sideCol.width
                        opacity: 0.4
                    }

                    Repeater {
                        model: root.shortcutItems.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.shortcutItems[index].icon
                            label: root.shortcutItems[index].name
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.activateItem(root.shortcutItems[index])
                        }
                    }
                }
            }

            Components.SessionButtons {
                menuData: root.menuData
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignLeft
                enabledOptions: ["logout", "lock", "restart", "shutdown"]
                onActionRequested: (id) => root.powerAction(id)
            }
        }
    }
}
