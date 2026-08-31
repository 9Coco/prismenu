import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/** Shared search-first shell: KRunner, Spotlight and COSMIC Launcher. */
LayoutBase {
    id: root

    readonly property string variant: menuData ? menuData.currentLayoutId : "runner"
    readonly property bool cosmic: variant === "cosmic-launcher"
    readonly property bool spotlight: variant === "spotlight"
    readonly property var idleItems: {
        return root.homeItems;
    }
    readonly property var resultItems: root.searching && menuData
        ? menuData.searchResults : root.idleItems

    Component.onCompleted: {
        if (cosmic && menuData && menuData.appsBackend && menuData.appsBackend.refreshOpenWindows)
            menuData.appsBackend.refreshOpenWindows();
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2,
                        root.spotlight ? 620 : 760)
        height: Math.min(parent.height - Kirigami.Units.largeSpacing * 2,
                         root.spotlight ? 360 : 520)
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            id: query
            layoutRoot: root
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.8
            Component.onCompleted: forceActiveFocus()
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: root.searching ? root.tr("Results")
                : root.homeGroupName
            font.weight: Font.DemiBold
            color: root.fg
            opacity: 0.72
        }

        Components.LayoutAppList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutRoot: root
            items: root.resultItems
            reorderEnabled: !root.searching && root.isPinnedGroup(root.homeGroupId)
            showDescription: true
            inlineDescription: true
            iconSize: Math.max(28, root.appIconSize)
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            visible: root.resultItems.length === 0
            text: root.tr("Type to search applications")
            color: root.fg
            opacity: 0.55
        }
    }
}
