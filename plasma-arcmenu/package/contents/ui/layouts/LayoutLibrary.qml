import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/** Shared automatic category wall: Win11 categories, iPad Library, COSMIC. */
LayoutBase {
    id: root

    property string selectedCategory: ""
    readonly property bool windowsVariant: menuData
        && menuData.currentLayoutId === "win11-categories"
    readonly property var categories: root.typeCategories
    readonly property var selectedItems: {
        if (!selectedCategory || !menuData)
            return [];
        return root.computeContentItems(selectedCategory);
    }

    function openCategory(id) {
        selectedCategory = id;
        if (menuData) {
            menuData.setSearch("");
            menuData.currentCategoryId = id;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Button {
                visible: root.selectedCategory.length > 0 && !root.searching
                text: root.tr("Back")
                icon.name: "go-previous-symbolic"
                onClicked: root.selectedCategory = ""
            }
            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
            }
        }

        Components.LayoutAppList {
            visible: root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutRoot: root
            items: menuData ? menuData.searchResults : []
            showDescription: true
            inlineDescription: true
        }

        Components.LayoutAppGrid {
            visible: !root.searching && root.selectedCategory.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutRoot: root
            items: root.selectedItems
            columns: Math.max(4, Math.floor(width / (Kirigami.Units.gridUnit * 5.5)))
            iconSize: Math.max(42, root.gridIconSize)
        }

        GridView {
            id: categoryWall
            visible: !root.searching && !root.selectedCategory
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.categories.length
            cellWidth: Math.max(210, width / 3)
            cellHeight: Math.max(165, height / 2)
            delegate: Rectangle {
                required property int index
                readonly property var category: root.categories[index]
                width: categoryWall.cellWidth - Kirigami.Units.largeSpacing
                height: categoryWall.cellHeight - Kirigami.Units.largeSpacing
                radius: Kirigami.Units.cornerRadius * 1.5
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, hover.hovered ? 0.16 : 0.08)
                border.width: 1
                border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.18)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.Icon {
                            source: category.icon
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: category.name
                            font.weight: Font.DemiBold
                            color: root.fg
                            elide: Text.ElideRight
                        }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 2
                        Repeater {
                            model: Math.min(4, category.apps ? category.apps.length : 0)
                            Item {
                                required property int index
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, parent.height) * 0.62
                                    height: width
                                    source: category.apps[index].icon
                                }
                            }
                        }
                    }
                }
                HoverHandler { id: hover }
                TapHandler { onTapped: root.openCategory(category.id) }
            }
        }

        RowLayout {
            visible: root.windowsVariant && !root.searching
            Layout.fillWidth: true

            Components.UserFace {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                userIcon: menuData ? menuData.userIcon : "user-identity"
                userName: menuData ? menuData.userName : ""
                fallbackColor: root.fg
            }
            Item { Layout.fillWidth: true }
            Components.SessionButtons {
                menuData: root.menuData
                enabledOptions: ["lock", "shutdown"]
                onActionRequested: (id) => root.powerAction(id)
            }
        }
    }
}
