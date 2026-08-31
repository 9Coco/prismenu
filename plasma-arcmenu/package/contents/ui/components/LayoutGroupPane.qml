import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import ".." as Ui

/** Content pane that honors a group's grid vs list display setting. */
Item {
    id: root

    required property var layoutRoot
    property var items: []
    property bool useGrid: false
    property bool showDescription: false
    property bool inlineDescription: false
    property string emptyText: ""
    property string navId: (layoutRoot && layoutRoot.activeNavId) ? layoutRoot.activeNavId : ""
    /** Search can replace a selected pinned group's items without changing
     * its navigation id. Never let that turn search results into a reorder
     * target; only the visible Plasma favorites projection is mutable. */
    readonly property bool pinnedView: !!root.layoutRoot
        && !root.layoutRoot.searching
        && root.layoutRoot.isPinnedGroup(root.navId)

    readonly property int paneIconSize: {
        var custom = 0;
        if (root.layoutRoot && root.navId && root.layoutRoot.groupIconSize)
            custom = root.layoutRoot.groupIconSize(root.navId);
        if (custom > 0)
            return custom;
        return Math.max(root.layoutRoot ? root.layoutRoot.gridIconSize : 48,
                        Kirigami.Units.iconSizes.large);
    }

    // Reorderable favorite views need a ListModel so GridView/ListView can
    // animate row moves (ListModel.move → rowsMoved → move transitions).
    Ui.ListModelBridge {
        id: pinnedBridge
        wrapApp: true
        source: root.items
    }

    LayoutAppGrid {
        anchors.fill: parent
        visible: root.useGrid
        layoutRoot: root.layoutRoot
        items: root.items
        reorderEnabled: root.pinnedView
        reorderModel: root.pinnedView ? pinnedBridge : null
        iconSize: root.paneIconSize
        columns: {
            var cell = Math.max(root.paneIconSize + Kirigami.Units.gridUnit * 1.8,
                                Kirigami.Units.gridUnit * 3.2);
            return Math.max(2, Math.floor(Math.max(width, cell) / cell));
        }
    }

    LayoutAppList {
        anchors.fill: parent
        visible: !root.useGrid
        layoutRoot: root.layoutRoot
        items: root.items
        reorderEnabled: root.pinnedView
        reorderModel: root.pinnedView ? pinnedBridge : null
        showDescription: root.showDescription
        inlineDescription: root.inlineDescription
        iconSize: Math.max(root.layoutRoot ? root.layoutRoot.appIconSize : 24,
                           Kirigami.Units.iconSizes.smallMedium)
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: root.items.length === 0 && root.emptyText.length > 0
        text: root.emptyText
        opacity: 0.55
        color: root.layoutRoot ? root.layoutRoot.fg : "white"
        width: parent.width * 0.8
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
