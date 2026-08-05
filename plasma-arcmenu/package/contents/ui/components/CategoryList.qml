import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ListView {
    id: root

    property int iconSize: 24
    property string currentCategoryId: ""
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color fg: Kirigami.Theme.textColor
    property bool collapsible: false
    property bool collapsed: false

    signal categorySelected(string categoryId)
    signal toggleCollapsed()

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: -1
    keyNavigationWraps: true
    Accessible.role: Accessible.List
    Accessible.name: i18n("Categories")

    highlight: Rectangle {
        color: root.selectedBg
        radius: Kirigami.Units.smallSpacing
    }
    highlightMoveDuration: Kirigami.Units.shortDuration

    header: Loader {
        active: root.collapsible
        width: root.width
        sourceComponent: Item {
            height: Kirigami.Units.gridUnit * 1.6
            width: root.width
            PlasmaComponents.ToolButton {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing / 2
                icon.name: root.collapsed ? "sidebar-expand" : "sidebar-collapse"
                text: root.collapsed ? i18n("Show categories") : i18n("Hide categories")
                onClicked: root.toggleCollapsed()
                Accessible.name: text
            }
        }
    }

    delegate: Item {
        id: del
        required property var model
        required property int index
        width: root.width
        height: root.collapsed ? 0 : Math.max(root.iconSize + Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 1.8)
        visible: !root.collapsed
        opacity: root.collapsed ? 0 : 1

        property bool isCurrent: model.id === root.currentCategoryId

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Kirigami.Units.smallSpacing
            color: del.isCurrent || mouse.containsMouse ? root.selectedBg : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: model.icon || "applications-other"
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
            }

            PlasmaComponents.Label {
                text: model.name || ""
                elide: Text.ElideRight
                Layout.fillWidth: true
                color: del.isCurrent || mouse.containsMouse ? root.selectedFg : root.fg
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.currentIndex = del.index;
                root.categorySelected(model.id);
            }
        }

        Accessible.name: model.name || ""
        Accessible.role: Accessible.ListItem
        Accessible.onPressAction: {
            root.currentIndex = del.index;
            root.categorySelected(model.id);
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentItem && model && currentIndex >= 0) {
                var item = model.get ? model.get(currentIndex) : null;
                if (item) {
                    categorySelected(item.id);
                }
            }
            event.accepted = true;
        }
    }
}
