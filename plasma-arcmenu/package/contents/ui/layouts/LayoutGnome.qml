import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * GNOME Menu layout (ArcMenu GNOME style).
 *
 * Search top | Sidebar (pinned / all / categories) | Content
 */
LayoutBase {
    id: root

    readonly property var categories: root.categorySubset(["Office", "Development", "Accessories", "Utility", "Network", "Graphics", "System"])

    property string gnomeSelectedId: "pinned"
    activeNavId: gnomeSelectedId






    function selectGnome(id) {
        gnomeSelectedId = id;
        if (!menuData) return;
        menuData.setSearch("");
        if (id === "pinned") return;
        if (id === "all") {
            menuData.currentCategoryId = "all";
            return;
        }
        menuData.currentCategoryId = id;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.SearchField {
            Layout.fillWidth: true
            placeholder: menuData ? menuData.searchPlaceholder : root.tr("Search…")
            text: menuData ? menuData.searchQuery : ""
            onTextChanged: if (menuData) menuData.setSearch(text)
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

                Column {
                    id: sideCol
                    width: sideFlick.width
                    spacing: Kirigami.Units.smallSpacing / 2

                    Components.ShortcutRow {
                        width: sideCol.width
                        iconName: "pin"
                        label: root.tr("Pinned Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.gnomeSelectedId === "pinned"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.selectGnome("pinned")
                    }

                    Components.ShortcutRow {
                        width: sideCol.width
                        iconName: "view-app-grid-symbolic"
                        label: root.tr("All Applications")
                        iconSize: root.categoryIconSize
                        selected: !root.searching && root.gnomeSelectedId === "all"
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        hoverBg: root.hoverBg
                        hoverFg: root.hoverFg
                        fg: root.fg
                        onActivated: root.selectGnome("all")
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
                            selected: !root.searching && root.gnomeSelectedId === root.categories[index].id
                            selectedBg: root.selectedBg
                            selectedFg: root.selectedFg
                            hoverBg: root.hoverBg
                            hoverFg: root.hoverFg
                            fg: root.fg
                            onActivated: root.selectGnome(root.categories[index].id)
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

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: contentFlick
                    anchors.fill: parent
                    model: root.contentItems
                    spacing: Kirigami.Units.smallSpacing / 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Components.AppListItem {
                                    required property int index
                                    menuData: menuData
                                    width: contentFlick.width
                                    app: root.contentItems[index]
                                    iconSize: Math.max(root.appIconSize, 28)
                                    showDescription: root.showAppDescriptions
                                    selectedBg: root.selectedBg
                                    selectedFg: root.selectedFg
                                    hoverBg: root.hoverBg
                                    hoverFg: root.hoverFg
                                    fg: root.fg
                                    onActivated: root.activateItem(root.contentItems[index])
                                    onContextMenuRequested: (x, y) => {
                                        var a = root.contentItems[index];
                                        if (a && !a.action) root.appContextMenu(a, x, y);
                                    }
                                }
}

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: root.contentItems.length === 0
                    text: root.searching
                          ? root.tr("No matching applications found")
                          : (root.gnomeSelectedId === "pinned"
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
    }
}
