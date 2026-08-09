import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Pop layout (ArcMenu Pop / Pop!_OS launcher style).
 *
 * Search top | 6-column app grid | bottom category tabs (Home / System / Utilities)
 */
LayoutBase {
    id: root

    property int popTab: 0 // 0 home, 1 system, 2 utilities

    readonly property int gridColumns: 6
    readonly property int gridIconSize: (menuData && menuData.gridIconOverride) ? menuData.gridIconSize : Math.max(40, root.appIconSize + 12)
    readonly property int gridCellHeight: gridIconSize + Kirigami.Units.gridUnit * 2.2
    readonly property int footerHeight: Kirigami.Units.gridUnit * 3.6

    readonly property var tabs: [
        { id: 0, name: root.tr("Library Home"), icon: "user-home" },
        { id: 1, name: root.tr("System"), icon: "arcmenu-cat-system-settings" },
        { id: 2, name: root.tr("Utility Tools"), icon: "arcmenu-cat-tools-build" }
    ]

    readonly property var gridItems: {
        if (root.searching) {
            return (menuData && menuData.searchResultsFlat) ? menuData.searchResultsFlat : [];
        }
        if (!menuData || !menuData.allApps)
            return [];
        if (popTab === 1)
            return AppsModel.appsInCategory(menuData.allApps, "System");
        if (popTab === 2)
            return AppsModel.appsInCategory(menuData.allApps, "Utility");
        return AppsModel.sortAppsByName(AppsModel.filterVisibleApps(menuData.allApps));
    }


    function selectTab(id) {
        popTab = id;
        if (menuData)
            menuData.setSearch("");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Components.SearchField {
            Layout.fillWidth: true
            Layout.fillHeight: false
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
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

                            width: Math.max(Kirigami.Units.gridUnit * 4, cellW)
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
                      : root.tr("No applications")
                opacity: 0.45
                color: root.fg
                width: parent.width * 0.8
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.fillHeight: false
            opacity: 0.35
        }

        // Fixed-height bottom category tabs (never stretch)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: root.footerHeight
            Layout.maximumHeight: root.footerHeight
            Layout.minimumHeight: root.footerHeight

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height - 4
                spacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: root.tabs.length

                    Item {
                        required property int index
                        readonly property var tab: root.tabs[index]
                        readonly property bool selected: !root.searching && root.popTab === tab.id

                        width: Math.max(Kirigami.Units.gridUnit * 7,
                                        tabLabel.implicitWidth + Kirigami.Units.largeSpacing * 2)
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            radius: Kirigami.Units.smallSpacing
                            color: selected ? Qt.rgba(1, 1, 1, 0.12)
                                   : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Kirigami.Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: tab.icon
                                width: Kirigami.Units.iconSizes.smallMedium
                                height: Kirigami.Units.iconSizes.smallMedium
                            }

                            PlasmaComponents.Label {
                                id: tabLabel
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tab.name
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                color: root.fg
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.selectTab(tab.id)
                        }

                        Accessible.name: tab.name
                        Accessible.role: Accessible.Button
                        Accessible.onPressAction: root.selectTab(tab.id)
                    }
                }
            }
        }
    }
}
