import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/** Deepin launcher: category-filtered window mode or full-screen A-Z mode. */
LayoutBase {
    id: root

    readonly property bool fullMode: menuData && menuData.currentLayoutId === "deepin-full"
    property string selectedId: "all"
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

            ColumnLayout {
                visible: !root.fullMode
                Layout.preferredWidth: root.sidebarW
                Layout.minimumWidth: root.elasticColumnMin
                Layout.fillHeight: true
                Repeater {
                    model: root.extraCategories.length
                    Components.ShortcutRow {
                        required property int index
                        Layout.fillWidth: true
                        iconName: root.extraCategories[index].icon
                        label: root.extraCategories[index].name
                        selected: root.selectedId === root.extraCategories[index].id
                        selectedBg: root.selectedBg; selectedFg: root.selectedFg
                        hoverBg: root.hoverBg; hoverFg: root.hoverFg; fg: root.fg
                        onActivated: root.selectCategory(root.extraCategories[index].id)
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; visible: root.extraCategories.length > 0 }
                Repeater {
                    model: root.categories.length
                    Components.ShortcutRow {
                        required property int index
                        Layout.fillWidth: true
                        iconName: root.categories[index].icon
                        label: root.categories[index].name
                        selected: root.selectedId === root.categories[index].id
                        selectedBg: root.selectedBg; selectedFg: root.selectedFg
                        hoverBg: root.hoverBg; hoverFg: root.hoverFg; fg: root.fg
                        onActivated: root.selectCategory(root.categories[index].id)
                    }
                }
                Item { Layout.fillHeight: true }
            }

            Kirigami.Separator { visible: !root.fullMode; Layout.fillHeight: true }

            Components.LayoutGroupPane {
                Layout.fillWidth: true
                Layout.fillHeight: true
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
