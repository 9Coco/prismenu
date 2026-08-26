import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/** Single-column compact Kickoff for narrow screens and vertical panels. */
LayoutBase {
    id: root

    property string selectedId: "favorites"
    readonly property bool categoryPage: selectedId !== "favorites" && selectedId !== ""
    readonly property var navigation: {
        var out = [
            { id: "favorites", name: root.tr("Favorites"), icon: "emblem-favorite" },
            { id: "all", name: root.tr("All Applications"), icon: "view-app-grid-symbolic" }
        ];
        return out.concat(root.standardCategories);
    }
    readonly property var items: {
        if (root.searching && menuData)
            return menuData.searchResults;
        if (selectedId === "favorites") {
            var pinned = menuData && menuData.pinnedApps ? menuData.pinnedApps : [];
            return pinned.length ? pinned : root.defaultPinned;
        }
        if (selectedId === "all")
            return root.allApplicationRows;
        return root.computeContentItems(selectedId);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
        }

        Components.LayoutAppList {
            visible: root.searching || root.categoryPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutRoot: root
            items: root.items
            showDescription: root.searching
            inlineDescription: false
            iconSize: Math.max(24, root.appIconSize)
        }

        ListView {
            visible: !root.searching && !root.categoryPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.selectedId === "favorites" ? root.items.length : root.navigation.length
            delegate: Components.AppListItem {
                required property int index
                readonly property var row: root.selectedId === "favorites"
                    ? root.items[index] : root.navigation[index]
                width: ListView.view.width
                app: row
                iconSize: Math.max(24, root.appIconSize)
                showDescription: false
                selectedBg: root.selectedBg; selectedFg: root.selectedFg
                hoverBg: root.hoverBg; hoverFg: root.hoverFg; fg: root.fg
                onActivated: {
                    if (root.selectedId === "favorites")
                        root.activateItem(row);
                    else
                        root.selectedId = row.id;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Button {
                text: root.categoryPage ? root.tr("Back") : root.tr("Applications")
                icon.name: root.categoryPage ? "go-previous-symbolic" : "view-app-grid-symbolic"
                onClicked: root.selectedId = ""
            }
            Item { Layout.fillWidth: true }
            Components.UserFace {
                Layout.preferredWidth: 28; Layout.preferredHeight: 28
                userIcon: menuData ? menuData.userIcon : "user-identity"
                userName: menuData ? menuData.userName : ""
                fallbackColor: root.fg
            }
            Components.SessionButtons {
                menuData: root.menuData
                enabledOptions: ["lock", "shutdown"]
                onActionRequested: (id) => root.powerAction(id)
            }
        }
    }
}
