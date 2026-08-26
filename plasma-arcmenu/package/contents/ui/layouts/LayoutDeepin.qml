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
    readonly property var appItems: {
        if (root.searching && menuData)
            return menuData.searchResultsFlat;
        if (selectedId === "all")
            return root.allApplications;
        return root.computeContentItems(selectedId);
    }

    function selectCategory(id) {
        selectedId = id;
        if (menuData) {
            menuData.setSearch("");
            menuData.currentCategoryId = id;
        }
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
                Components.ShortcutRow {
                    Layout.fillWidth: true
                    iconName: "view-app-grid-symbolic"
                    label: root.tr("All Applications")
                    selected: root.selectedId === "all"
                    selectedBg: root.selectedBg; selectedFg: root.selectedFg
                    hoverBg: root.hoverBg; hoverFg: root.hoverFg; fg: root.fg
                    onActivated: root.selectCategory("all")
                }
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

            Components.LayoutAppGrid {
                Layout.fillWidth: true
                Layout.fillHeight: true
                layoutRoot: root
                items: root.appItems
                columns: Math.max(root.fullMode ? 7 : 4,
                    Math.floor(width / (Kirigami.Units.gridUnit * 5.5)))
                iconSize: Math.max(44, root.gridIconSize)
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
