import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/** Deepin launcher: category-filtered window mode or full-screen A-Z mode. */
LayoutBase {
    id: root

    readonly property bool fullMode: menuData && menuData.currentLayoutId === "deepin-full"
    readonly property int categorySidebarMax: Math.max(
        root.elasticColumnMin,
        Math.min(root.sidebarMax, root.width - Kirigami.Units.gridUnit * 12))
    readonly property int categorySidebarWidth: Math.max(
        root.elasticColumnMin,
        Math.min(root.sidebarW, root.categorySidebarMax))
    property string selectedId: "all"
    function resetForOpen() { root.selectedId = root.homeGroupId; }
    readonly property var categories: root.typeCategories
    readonly property var extraCategories: root.preferenceGroups
    readonly property var appItems: {
        if (root.searching && menuData)
            return menuData.searchResultsFlat;
        if (selectedId === "all")
            return root.computeContentItems("all-apps");
        return root.computeContentItems(selectedId);
    }

    function selectCategory(id) {
        selectedId = id;
        if (!menuData)
            return;
        menuData.setSearch("");
        root.refreshNavData(id);
        if (id === "pinned" || id === "favorites" || id === "frequent"
                || id === "recent-files" || String(id).indexOf("qgrp-") === 0
                || String(id).indexOf("tgrp-") === 0)
            return;
        menuData.currentCategoryId = (id === "all-apps" || id === "all") ? "all" : id;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
            Layout.maximumWidth: root.fullMode ? 760 : 10000
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing
            layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

            Flickable {
                id: sideFlick
                visible: !root.fullMode
                // ShortcutRow children fill this column. Without an explicit
                // maximum the RowLayout lets their implicit width grow the
                // category column across the whole popup and pushes the app
                // grid outside the visible menu.
                Layout.fillWidth: false
                Layout.preferredWidth: root.categorySidebarWidth
                Layout.minimumWidth: root.categorySidebarWidth
                Layout.maximumWidth: root.categorySidebarWidth
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                contentWidth: width
                contentHeight: sideCol.height
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

                Column {
                    id: sideCol
                    width: sideFlick.width
                    spacing: Kirigami.Units.smallSpacing / 2

                    Repeater {
                        model: root.extraCategories.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.extraCategories[index].icon
                            label: root.extraCategories[index].name
                            selected: root.selectedId === root.extraCategories[index].id
                            selectedBg: root.selectedBg; selectedFg: root.selectedFg
                            hoverBg: root.hoverBg; hoverFg: root.hoverFg; fg: root.fg
                            onActivated: root.selectCategory(root.extraCategories[index].id)
                        }
                    }
                    Kirigami.Separator {
                        width: sideCol.width
                        visible: root.extraCategories.length > 0
                    }
                    Repeater {
                        model: root.categories.length
                        Components.ShortcutRow {
                            required property int index
                            width: sideCol.width
                            iconName: root.categories[index].icon
                            label: root.categories[index].name
                            selected: root.selectedId === root.categories[index].id
                            selectedBg: root.selectedBg; selectedFg: root.selectedFg
                            hoverBg: root.hoverBg; hoverFg: root.hoverFg; fg: root.fg
                            onActivated: root.selectCategory(root.categories[index].id)
                        }
                    }
                }
            }

            Components.ColumnSplitHandle {
                visible: !root.fullMode
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                z: 5
                fg: root.fg
                currentWidth: root.categorySidebarWidth
                minWidth: root.elasticColumnMin
                maxWidth: root.categorySidebarMax
                sidebarOnRight: false
                flipped: root.flip
                onWidthDragged: (w) => root.setSidebarFromDrag(w)
            }

            Components.LayoutGroupPane {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                layoutRoot: root
                items: root.appItems
                navId: root.selectedId === "all" ? "all-apps" : root.selectedId
                useGrid: !root.searching && root.usesGridView(
                    root.selectedId === "all" ? "all-apps" : root.selectedId)
                showDescription: root.searching
            }

            ColumnLayout {
                visible: root.fullMode && !root.searching
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                Layout.fillHeight: true
                Repeater {
                    model: ["A", "D", "G", "J", "M", "P", "S", "V", "Z"]
                    PlasmaComponents.Label {
                        required property string modelData
                        Layout.fillHeight: true
                        text: modelData
                        color: root.fg
                        opacity: 0.62
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
