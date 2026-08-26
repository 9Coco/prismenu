import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

/** Content pane that honors a group's grid vs list display setting. */
Item {
    id: root

    required property var layoutRoot
    property var items: []
    property bool useGrid: false
    property bool showDescription: false
    property bool inlineDescription: false
    property string emptyText: ""

    LayoutAppGrid {
        anchors.fill: parent
        visible: root.useGrid
        layoutRoot: root.layoutRoot
        items: root.items
        columns: Math.max(4, Math.floor(width / (Kirigami.Units.gridUnit * 5)))
        iconSize: Math.max(root.layoutRoot ? root.layoutRoot.gridIconSize : 48,
                           Kirigami.Units.iconSizes.large)
    }

    LayoutAppList {
        anchors.fill: parent
        visible: !root.useGrid
        layoutRoot: root.layoutRoot
        items: root.items
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
