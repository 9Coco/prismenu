import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/**
 * Windows layout (ArcMenu Windows / Win10 Start style).
 *
 * Home: left rail + frequent/A–Z list + pinned grid
 * Hamburger: back + shortcuts/places/devices sidebar + pinned grid
 */
LayoutBase {
    id: root

    property bool showSideMenu: false

    readonly property bool onHome: !showSideMenu
    readonly property int railWidth: Kirigami.Units.gridUnit * 2.8
    readonly property int pinIconSize: Math.max(40, root.appIconSize + 12)
    readonly property int pinCellWidth: Kirigami.Units.gridUnit * 5.5
    readonly property int pinCellHeight: pinIconSize + Kirigami.Units.gridUnit * 1.8
    readonly property int frequentMax: 6
    readonly property int sideWidth: root.sidebarW


    readonly property var defaultFrequent: [
        {
            id: "org.kde.konsole.desktop",
            name: root.tr("Terminal"),
            icon: "utilities-terminal",
            exec: "konsole",
            noDisplay: false
        },
        {
            id: "shortcut-settings",
            name: root.tr("Settings"),
            icon: "preferences-system",
            exec: "",
            action: "settings",
            noDisplay: false
        },
        {
            id: "org.kde.dolphin.desktop",
            name: root.tr("Files"),
            icon: "system-file-manager",
            exec: "dolphin",
            noDisplay: false
        }
    ]

    readonly property var appShortcuts: root.applicationShortcuts
    readonly property var placeItems: root.placeShortcuts

    readonly property string deviceLabel: {
        if (menuData && menuData.osPrettyName)
            return menuData.osPrettyName;
        return root.tr("Computer");
    }

    readonly property var pinnedItems: {
        return root.homeItems;
    }

    function resetForOpen() { root.showSideMenu = false; }

    readonly property var frequentItems: {
        if (menuData && menuData.recentApps && menuData.recentApps.length)
            return menuData.recentApps.slice(0, root.frequentMax);
        if (root.allApplications.length)
            return root.allApplications.slice(0, Math.min(root.frequentMax, root.allApplications.length));
        return root.defaultFrequent;
    }

    readonly property var azSections: {
        return root.allApplicationSections;
    }

    readonly property var searchItems: {
        if (menuData && menuData.searchResults)
            return menuData.searchResults;
        return [];
    }

    readonly property var applicationListItems: root.searching
        ? root.searchItems
        : root.frequentItems.concat(root.allApplicationRows)


    function openFiles() {
        root.activateItem({
            id: "org.kde.dolphin.desktop",
            name: root.tr("Files"),
            icon: "system-file-manager",
            exec: "dolphin"
        });
    }

    function openComputer() {
        // computer:/ (KDE4 KIO slave) no longer exists on Plasma 5/6 — open
        // the filesystem root; Dolphin's Places sidebar lists the devices.
        root.activateItem({
            id: "place-computer",
            name: root.deviceLabel,
            icon: "drive-harddisk",
            exec: "kioclient exec file:/// || dolphin / || xdg-open /"
        });
    }

    function openSideMenu() {
        if (menuData) menuData.setSearch("");
        showSideMenu = true;
    }

    function goHome() {
        showSideMenu = false;
    }

    // Shared pinned grid content
    component PinnedPanel: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: root.tr("Pinned")
            font.bold: true
            color: root.fg
            Layout.fillWidth: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Components.LayoutAppGrid {
                anchors.fill: parent
                layoutRoot: root
                items: root.pinnedItems
                reorderEnabled: root.isPinnedGroup(root.homeGroupId)
                columns: Math.max(1, Math.floor(width / root.pinCellWidth))
                cellWidth: root.pinCellWidth
                cellHeight: root.pinCellHeight
                iconSize: root.pinIconSize
                multiLineLabels: true
            }
        }
    }

    // ===================== Side menu (hamburger) =====================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing
        visible: root.showSideMenu

        PlasmaComponents.ToolButton {
            flat: true
            Layout.alignment: Qt.AlignLeft
            icon.name: "go-previous"
            text: root.tr("Back")
            onClicked: root.goHome()
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            opacity: 0.4
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Flickable {
                id: sideFlick
                Layout.preferredWidth: root.sideWidth
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

                    Repeater {
                        model: root.appShortcuts.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.appShortcuts[index].icon
                            label: root.appShortcuts[index].name
                            iconSize: root.categoryIconSize
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.activateItem(root.appShortcuts[index])
                        }
                    }

                    PlasmaComponents.Label {
                        width: sideCol.width
                        text: root.tr("Places")
                        color: root.fg
                        opacity: 0.65
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        topPadding: Kirigami.Units.smallSpacing
                        leftPadding: Kirigami.Units.smallSpacing
                    }

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

                    PlasmaComponents.Label {
                        width: sideCol.width
                        text: root.tr("Devices")
                        color: root.fg
                        opacity: 0.65
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        topPadding: Kirigami.Units.smallSpacing
                        leftPadding: Kirigami.Units.smallSpacing
                    }

                    Item {
                        width: sideCol.width
                        height: Math.max(root.categoryIconSize + Kirigami.Units.smallSpacing * 2,
                                         Kirigami.Units.gridUnit * 1.85)

                        Rectangle {
                            anchors.fill: parent
                            radius: Kirigami.Units.smallSpacing
                            color: deviceMouse.containsMouse ? root.selectedBg : "transparent"
                            opacity: deviceMouse.containsMouse ? 1 : 0
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Kirigami.Units.smallSpacing
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "media-optical"
                                Layout.preferredWidth: root.categoryIconSize
                                Layout.preferredHeight: root.categoryIconSize
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: root.deviceLabel
                                elide: Text.ElideRight
                                color: deviceMouse.containsMouse ? root.selectedFg : root.fg
                            }

                            PlasmaComponents.ToolButton {
                                flat: true
                                icon.name: "media-eject"
                                icon.width: Kirigami.Units.iconSizes.small
                                icon.height: Kirigami.Units.iconSizes.small
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                                Accessible.name: root.tr("Eject")
                                onClicked: root.openComputer()
                                PlasmaComponents.ToolTip.text: root.tr("Eject")
                                PlasmaComponents.ToolTip.visible: hovered
                                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                            }
                        }

                        MouseArea {
                            id: deviceMouse
                            anchors.fill: parent
                            anchors.rightMargin: Kirigami.Units.gridUnit * 2
                            hoverEnabled: true
                            onClicked: root.openComputer()
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

            PinnedPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    // ===================== Home =====================
    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing
        visible: root.onHome
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Left rail ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: root.railWidth
            Layout.maximumWidth: root.railWidth
            Layout.fillWidth: false
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "application-menu"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Menu")
                onClicked: root.openSideMenu()
                PlasmaComponents.ToolTip.text: root.tr("Menu")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "system-file-manager"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Files")
                onClicked: root.openFiles()
                PlasmaComponents.ToolTip.text: root.tr("Files")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "preferences-system"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Settings")
                onClicked: root.powerAction("settings")
                PlasmaComponents.ToolTip.text: root.tr("Settings")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                icon.name: "system-shutdown"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Shut Down")
                onClicked: root.powerAction("shutdown")
                PlasmaComponents.ToolTip.text: root.tr("Shut Down")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        // ---- Center: frequent + A–Z + search ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 8
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                visible: !root.searching
                text: root.tr("Frequent Applications")
                font.bold: true
                color: root.fg
                Layout.fillWidth: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Components.LayoutAppList {
                    layoutRoot: root
                    anchors.fill: parent
                    items: root.applicationListItems
                    iconSize: Math.max(root.appIconSize, 24)
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.searching
                             ? root.searchItems.length === 0
                             : (root.frequentItems.length === 0 && root.azSections.length === 0)
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : root.tr("No applications")
                    opacity: 0.45
                    color: root.fg
                    width: parent.width * 0.8
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
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

        PinnedPanel {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: root.sidebarW
            Layout.minimumWidth: root.elasticColumnMin
            Layout.maximumWidth: root.sidebarMax
        }
    }
}
