import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Redmond layout (ArcMenu Redmond / Windows-style).
 *
 * Left: search + All Apps / Pinned toggle + icon grid
 * Right: user, places, system shortcuts, session buttons
 */
LayoutBase {
    id: root

    property bool showPinned: false

    readonly property bool searching: menuData ? menuData.isSearching : false
    readonly property int gridColumns: 4
    readonly property int gridIconSize: Math.max(36, root.appIconSize + 8)
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 2

    readonly property var defaultPinned: [
        {
            id: "org.kde.dolphin.desktop",
            name: root.tr("Files"),
            icon: "system-file-manager",
            exec: "dolphin",
            noDisplay: false
        },
        {
            id: "arcmenu-settings",
            name: root.tr("ArcMenu Settings"),
            icon: "preferences-system-windows",
            exec: "",
            action: "configure",
            noDisplay: false
        }
    ]

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

    readonly property var gridItems: {
        if (root.searching) {
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        }
        if (root.showPinned) {
            var pinned = (menuData && menuData.pinnedApps) ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (menuData && menuData.allApps && menuData.allApps.length)
            return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
        return [];
    }

    function activateItem(item) {
        if (!item) return;
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

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Left: search + apps grid ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Components.SearchField {
                Layout.fillWidth: true
                Layout.fillHeight: false
                placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
                text: menuData ? menuData.searchQuery : ""
                onTextChanged: {
                    if (menuData) menuData.setSearch(text);
                    if (text && text.length)
                        root.showPinned = false;
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                visible: !root.searching

                PlasmaComponents.Label {
                    text: root.showPinned ? root.tr("Pinned") : root.tr("All Applications")
                    font.bold: true
                    color: root.fg
                    Layout.fillWidth: true
                }

                PlasmaComponents.ToolButton {
                    flat: true
                    text: root.showPinned
                          ? root.tr("All Applications") + " >"
                          : root.tr("Pinned") + " >"
                    onClicked: root.showPinned = !root.showPinned
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 10

                Flickable {
                    id: gridFlick
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: Math.max(height, gridFlow.height)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Flow {
                        id: gridFlow
                        width: gridFlick.width
                        spacing: Kirigami.Units.smallSpacing

                        Repeater {
                            model: root.gridItems.length
                            Item {
                                required property int index
                                readonly property var app: root.gridItems[index]
                                readonly property int cellW: Math.floor(
                                    (gridFlow.width - gridFlow.spacing * (root.gridColumns - 1))
                                    / root.gridColumns)

                                width: Math.max(Kirigami.Units.gridUnit * 5, cellW)
                                height: root.gridCellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Kirigami.Units.smallSpacing
                                    color: cellMouse.containsMouse ? root.selectedBg : "transparent"
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    width: parent.width - Kirigami.Units.smallSpacing * 2
                                    spacing: Kirigami.Units.smallSpacing / 2

                                    Kirigami.Icon {
                                        source: app.icon || "application-x-executable"
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: root.gridIconSize
                                        Layout.preferredHeight: root.gridIconSize
                                    }

                                    PlasmaComponents.Label {
                                        text: app.name || ""
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                        maximumLineCount: 2
                                        wrapMode: Text.WordWrap
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        color: cellMouse.containsMouse ? root.selectedFg : root.fg
                                    }
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            if (app && !app.action)
                                                root.appContextMenu(app, mouse.x, mouse.y);
                                        } else {
                                            root.activateItem(app);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.gridItems.length === 0
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : (root.showPinned
                             ? root.tr("Pin applications from the context menu")
                             : root.tr("No applications"))
                    opacity: 0.45
                    color: root.fg
                    width: parent.width * 0.8
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ---- Right sidebar ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            Layout.maximumWidth: Kirigami.Units.gridUnit * 13
            spacing: Kirigami.Units.smallSpacing / 2

            Components.ShortcutRow {
                Layout.fillWidth: true
                iconName: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                label: (menuData && menuData.userName) ? menuData.userName : root.tr("User")
                iconSize: Math.max(root.categoryIconSize, Kirigami.Units.iconSizes.medium)
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onActivated: root.userMenu()
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
                        model: root.placeItems.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.placeItems[index].icon
                            label: root.placeItems[index].name
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
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
