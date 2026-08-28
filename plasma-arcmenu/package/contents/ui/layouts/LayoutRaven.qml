import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Raven layout (ArcMenu Raven / Budgie Raven style).
 *
 * Full-height left icon rail | search + pinned + shortcuts + world-clock button
 * Default size is a tall side panel (near screen height).
 */
LayoutBase {
    id: root

    property string railSelectedId: "desktop"
    property bool showAllApps: false

    readonly property int railWidth: Kirigami.Units.gridUnit * 3.2
    readonly property int gridIconSize: (menuData && menuData.gridIconOverride) ? menuData.gridIconSize : Math.max(40, root.appIconSize + 12)
    readonly property int gridCellWidth: Kirigami.Units.gridUnit * 5.5
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 1.8

    // Top rail icons (settings sits at bottom separately)
    readonly property var railTop: [
        { id: "desktop", icon: "video-display", tip: root.tr("Desktop") },
        { id: "all", icon: "view-app-grid-symbolic", tip: root.tr("All Applications") },
        { id: "windows", icon: "window-duplicate", tip: root.tr("Windows") },
        { id: "tweaks", icon: "preferences-desktop-theme", tip: root.tr("Tweaks"), exec: "systemsettings kcm_lookandfeel" },
        { id: "contacts", icon: "x-office-contact", tip: root.tr("Contacts"), place: "DOCUMENTS" },
        { id: "user", icon: "user-identity", tip: root.tr("User") },
        { id: "network", icon: "applications-internet", tip: root.tr("Internet"), exec: "xdg-open https://" },
        { id: "pictures", icon: "folder-pictures", tip: root.tr("Pictures"), place: "PICTURES" }
    ]


    readonly property var shortcutItems: root.applicationShortcuts

    readonly property var pinnedItems: {
        return root.homeItems;
    }

    function resetForOpen() {
        root.railSelectedId = "desktop";
        root.showAllApps = false;
    }

    readonly property var allAppsItems: {
        if (root.searching)
            return (menuData && menuData.searchResults) ? menuData.searchResults : [];
        return root.allApplications;
    }

    readonly property bool onHome: !root.searching && !root.showAllApps


    function activateRail(def) {
        if (!def) return;
        railSelectedId = def.id;
        if (def.id === "desktop") {
            showAllApps = false;
            if (menuData) menuData.setSearch("");
            return;
        }
        if (def.id === "all") {
            showAllApps = true;
            if (menuData) menuData.setSearch("");
            return;
        }
        if (def.id === "user") {
            root.userMenu();
            return;
        }
        if (def.exec || def.action || def.place) {
            root.activateItem(def);
        }
    }

    function openWorldClock() {
        root.activateItem({
            id: "world-clock",
            name: root.tr("World Clock"),
            icon: "preferences-system-time",
            exec: "plasmawindowed org.kde.plasma.worldclock"
        });
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- Full-height left rail (edge to edge) ----
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.railWidth
            Layout.maximumWidth: root.railWidth
            color: Qt.rgba(0, 0, 0, 0.18)

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: Kirigami.Units.smallSpacing
                anchors.bottomMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing / 2

                Repeater {
                    model: root.railTop.length
                    PlasmaComponents.ToolButton {
                        required property int index
                        readonly property var def: root.railTop[index]
                        readonly property bool isUser: def.id === "user"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                        flat: true
                        checkable: true
                        checked: root.railSelectedId === def.id
                        icon.name: isUser ? "" : def.icon
                        icon.width: Kirigami.Units.iconSizes.smallMedium
                        icon.height: Kirigami.Units.iconSizes.smallMedium
                        Accessible.name: isUser && menuData && menuData.userName
                            ? menuData.userName
                            : def.tip
                        onClicked: root.activateRail(def)
                        PlasmaComponents.ToolTip.text: isUser && menuData && menuData.userName
                            ? menuData.userName
                            : def.tip
                        PlasmaComponents.ToolTip.visible: hovered
                        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay

                        Components.UserFace {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.smallMedium
                            height: width
                            visible: parent.isUser
                            userIcon: (menuData && menuData.userIcon) ? menuData.userIcon : "user-identity"
                            userName: (menuData && menuData.userName) ? menuData.userName : ""
                            showRing: false
                            shape: "circle"
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                PlasmaComponents.ToolButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                    flat: true
                    icon.name: "preferences-system"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    Accessible.name: root.tr("Settings")
                    onClicked: root.powerAction("settings")
                    PlasmaComponents.ToolTip.text: root.tr("Settings")
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }

        // ---- Main content ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
                onTextChanged: {
                    if (text && text.length)
                        root.showAllApps = false;
                }
            }

            // Home: pinned + shortcuts
            Flickable {
                visible: root.onHome
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: homeCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

                ColumnLayout {
                    id: homeCol
                    width: parent.width
                    spacing: Kirigami.Units.largeSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            PlasmaComponents.Label {
                                text: root.tr("Pinned")
                                color: root.fg
                                opacity: 0.75
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: root.borderColor
                                opacity: 0.4
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Repeater {
                                model: root.pinnedItems.length
                                Item {
                                    required property int index
                                    readonly property var app: root.pinnedItems[index]
                                    width: root.gridCellWidth
                                    height: root.gridCellHeight

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: Kirigami.Units.smallSpacing
                                        color: pinMouse.containsMouse ? root.selectedBg : "transparent"
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
                                            color: pinMouse.containsMouse ? root.selectedFg : root.fg
                                        }
                                    }

                                    MouseArea {
                                        id: pinMouse
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            PlasmaComponents.Label {
                                text: root.tr("Shortcuts")
                                color: root.fg
                                opacity: 0.75
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: root.borderColor
                                opacity: 0.4
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Repeater {
                                model: root.shortcutItems.length
                                Item {
                                    required property int index
                                    readonly property var app: root.shortcutItems[index]
                                    width: root.gridCellWidth
                                    height: root.gridCellHeight

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: Kirigami.Units.smallSpacing
                                        color: scMouse.containsMouse ? root.selectedBg : "transparent"
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
                                            color: scMouse.containsMouse ? root.selectedFg : root.fg
                                        }
                                    }

                                    MouseArea {
                                        id: scMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.activateItem(app)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // All apps / search
            Item {
                visible: !root.onHome
                Layout.fillWidth: true
                Layout.fillHeight: true

                Components.LayoutAppList {
                    layoutRoot: root
                    anchors.fill: parent
                    items: root.allAppsItems
                    iconSize: Math.max(root.appIconSize, 28)
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.allAppsItems.length === 0
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : root.tr("No applications")
                    opacity: 0.45
                    color: root.fg
                }
            }

            PlasmaComponents.Button {
                Layout.fillWidth: true
                text: root.tr("Add world clock…")
                icon.name: "preferences-system-time"
                onClicked: root.openWorldClock()
            }
        }
    }
}
