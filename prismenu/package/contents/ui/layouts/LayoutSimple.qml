import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

LayoutBase {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            id: search
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            Component.onCompleted: forceActiveFocus()
        }

        Components.LayoutAppList {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutRoot: root
            items: root.searching && menuData ? menuData.searchResults : root.homeItems
            reorderEnabled: !root.searching && root.canReorderGroup(root.homeGroupId)
            reorderGroupId: root.homeGroupId
            iconSize: Math.max(28, root.appIconSize)
            showDescription: menuData ? menuData.showSearchDescription : true

            PlasmaComponents.Label {
                anchors.centerIn: parent
                visible: appList.count === 0
                text: root.searching ? root.tr("No matching applications found") : root.tr("Type to search applications")
                opacity: 0.6
            }
        }
    }
}
