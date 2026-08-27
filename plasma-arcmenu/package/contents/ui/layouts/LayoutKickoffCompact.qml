import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/** Single-column compact Kickoff for narrow screens and vertical panels. */
LayoutBase {
    id: root

    property string selectedId: ""
    readonly property bool categoryPage: selectedId !== ""
    readonly property var navigation: {
        var _sig = menuData ? menuData.extrasSignature : "";
        var extras = root.preferenceGroups;
        var out = [];
        for (var i = 0; i < extras.length; ++i) {
            if (extras[i] && extras[i].id)
                out.push(extras[i]);
        }
        return out.concat(root.typeCategories);
    }
    readonly property var items: {
        if (root.searching && menuData)
            return menuData.searchResults;
        return root.computeContentItems(selectedId || "all-apps");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
        }

        Components.LayoutGroupPane {
            visible: root.searching || root.categoryPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutRoot: root
            items: root.items
            navId: root.selectedId
            useGrid: !root.searching && root.usesGridView(root.selectedId)
            showDescription: root.searching
            inlineDescription: false
        }

        ListView {
            visible: !root.searching && !root.categoryPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.navigation.length
            delegate: Components.AppListItem {
                required property int index
                readonly property var row: root.navigation[index]
                width: ListView.view.width
                app: row
                iconSize: Math.max(24, root.appIconSize)
                showDescription: false
                selectedBg: root.selectedBg; selectedFg: root.selectedFg
                hoverBg: root.hoverBg; hoverFg: root.hoverFg; fg: root.fg
                onActivated: root.selectedId = row.id
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
