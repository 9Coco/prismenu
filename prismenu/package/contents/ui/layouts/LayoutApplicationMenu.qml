import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui
import "../../code/ShortcutsConfig.js" as SC

/**
 * Plasma Application Menu (official Kicker).
 * Narrow cascade: category rows with side flyout, search + session on the bottom.
 */
LayoutBase {
    id: root

    defaultSearchOnTop: false
    readonly property string variant: menuData ? menuData.currentLayoutId : "application-menu"
    readonly property bool pureTraditional: variant === "gnome-classic"
        || variant === "xfce-applications"
    property int hoverIndex: -1
    property string hoverId: ""
    property real flyoutAnchorY: 0

    readonly property int rowH: Math.max(Kirigami.Units.gridUnit * 1.85,
        Math.min(root.categoryIconSize, Kirigami.Units.iconSizes.smallMedium) + Kirigami.Units.smallSpacing)
    readonly property int flyoutWidth: Kirigami.Units.gridUnit * 15
    readonly property int iconSz: Math.min(root.categoryIconSize, Kirigami.Units.iconSizes.smallMedium)
    readonly property int favIcon: Math.max(Kirigami.Units.iconSizes.medium, Math.min(root.appIconSize, Kirigami.Units.iconSizes.large))
    readonly property int favCell: favIcon + Kirigami.Units.gridUnit * 2.2
    readonly property int railMin: favCell
    readonly property int leftColW: {
        var maxW = Math.max(root.railMin, Math.min(360, Math.round(width * 0.55)));
        var stored = root.sidebarW > 0 ? root.sidebarW : root.railMin;
        return Math.max(root.railMin, Math.min(stored, maxW));
    }

    readonly property var favoriteItems: {
        return root.homeItems;
    }

    readonly property var navItems: {
        var _ = root.uiLang;
        var _sig = menuData ? menuData.extrasSignature : "";
        var out = [];
        var i;
        if (!root.pureTraditional) {
            var extras = root.preferenceGroups;
            for (i = 0; i < extras.length; ++i) {
                if (extras[i] && extras[i].id)
                    out.push({
                        id: extras[i].id,
                        name: extras[i].name,
                        icon: extras[i].icon || "applications-other"
                    });
            }
        }
        var cats = root.typeCategories;
        for (i = 0; i < cats.length; ++i) {
            var c = cats[i];
            if (!c || !c.id || c.id === "all" || c.id === "all-apps")
                continue;
            out.push({ id: c.id, name: c.name, icon: c.icon || "applications-other" });
        }
        if (!root.pureTraditional)
            out.push({ id: "session", name: root.tr("Power / Session"), icon: "system-shutdown" });
        return out;
    }

    readonly property var sessionActions: {
        var _ = root.uiLang;
        var defs = SC.powerDefs(function (m) { return root.tr(m); });
        var enabled = (menuData && menuData.powerOptions && menuData.powerOptions.length)
            ? menuData.powerOptions
            : ["lock", "logout", "switchuser", "suspend", "restart", "shutdown"];
        var prefer = ["lock", "logout", "switchuser", "suspend", "restart", "shutdown"];
        var byId = {};
        for (var i = 0; i < defs.length; ++i)
            byId[defs[i].id] = defs[i];
        var out = [];
        var seen = {};
        function add(id) {
            if (seen[id] || enabled.indexOf(id) < 0)
                return;
            var d = byId[id];
            if (!d)
                return;
            seen[id] = true;
            var name = d.name;
            if (id === "lock") name = root.tr("Lock");
            else if (id === "logout") name = root.tr("Log Out");
            else if (id === "switchuser") name = root.tr("Switch User");
            else if (id === "suspend") name = root.tr("Suspend");
            else if (id === "restart") name = root.tr("Restart");
            else if (id === "shutdown") name = root.tr("Shut Down");
            out.push({ id: d.id, name: name, icon: d.icon, action: d.id });
        }
        for (var p = 0; p < prefer.length; ++p)
            add(prefer[p]);
        for (var e = 0; e < enabled.length; ++e)
            add(enabled[e]);
        return out;
    }

    readonly property var footerActions: {
        var ids = ["logout", "restart", "shutdown"];
        var all = root.sessionActions;
        var out = [];
        for (var i = 0; i < ids.length; ++i) {
            for (var j = 0; j < all.length; ++j) {
                if (all[j].id === ids[i]) {
                    out.push(all[j]);
                    break;
                }
            }
        }
        return out.length ? out : [
            { id: "logout", name: root.tr("Log Out"), icon: "system-log-out", action: "logout" },
            { id: "restart", name: root.tr("Restart"), icon: "system-reboot", action: "restart" },
            { id: "shutdown", name: root.tr("Shut Down"), icon: "system-shutdown", action: "shutdown" }
        ];
    }

    readonly property var flyoutItems: {
        if (root.searching || !root.hoverId)
            return [];
        if (root.hoverId === "recent" || root.hoverId === "frequent")
            return root.computeContentItems("frequent");
        if (root.hoverId === "recent-files")
            return root.computeContentItems("recent-files");
        if (root.hoverId === "session")
            return root.sessionActions;
        return root.computeContentItems(root.hoverId);
    }

    function itemHasChildren(id) {
        if (id === "recent" || id === "frequent")
            return !!(root.computeContentItems("frequent") || []).length;
        if (id === "recent-files")
            return !!(root.computeContentItems("recent-files") || []).length;
        if (id === "session")
            return root.sessionActions.length > 0;
        var apps = root.computeContentItems(id);
        return !!(apps && apps.length);
    }

    function openFlyoutFor(index, id, rowItem) {
        root.hoverIndex = index;
        root.hoverId = id;
        if (id === "recent-files")
            root.refreshNavData("recent-files");
        var local = rowItem.mapToItem(root, 0, 0);
        root.flyoutAnchorY = local.y;
        if (!root.itemHasChildren(id)) {
            root.hideFlyout();
            return;
        }
        Qt.callLater(root.placeFlyout);
    }

    function placeFlyout() {
        var count = root.flyoutItems.length;
        if (count <= 0) {
            root.hideFlyout();
            return;
        }
        flyoutWin.height = Math.min(root.height,
            count * root.rowH + Kirigami.Units.largeSpacing);
        flyoutWin.width = root.flyoutWidth;
        var g = root.mapToGlobal(root.flip ? 0 : root.width, Math.round(root.flyoutAnchorY));
        flyoutWin.x = root.flip ? (g.x - flyoutWin.width) : g.x;
        flyoutWin.y = g.y;
        flyoutWin.visible = true;
    }

    function hideFlyout() {
        flyoutWin.visible = false;
    }

    function scheduleClose() {
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 240
        onTriggered: {
            if (!flyoutWin.hovered)
                root.hideFlyout();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing / 2
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // Favorite apps — width is draggable; icons wrap into extra columns.
        ColumnLayout {
            visible: !root.pureTraditional
            Layout.preferredWidth: root.leftColW
            Layout.minimumWidth: root.railMin
            Layout.maximumWidth: 360
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing / 2

            Components.LayoutAppGrid {
                id: favRail
                Layout.fillWidth: true
                Layout.fillHeight: true
                layoutRoot: root
                items: root.favoriteItems
                reorderEnabled: root.canReorderGroup(root.homeGroupId)
                reorderGroupId: root.homeGroupId
                columns: Math.max(1, Math.floor(Math.max(1, width) / root.favCell))
                cellHeight: root.favIcon + Kirigami.Units.gridUnit * 2.1
                iconSize: root.favIcon
                multiLineLabels: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing / 2
                Repeater {
                    model: root.footerActions
                    PlasmaComponents.ToolButton {
                        required property var modelData
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.7
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.7
                        Layout.alignment: Qt.AlignHCenter
                        icon.name: modelData.icon
                        icon.width: Kirigami.Units.iconSizes.smallMedium
                        icon.height: Kirigami.Units.iconSizes.smallMedium
                        Accessible.name: modelData.name
                        onClicked: root.powerAction(modelData.id)
                        PlasmaComponents.ToolTip.text: modelData.name
                        PlasmaComponents.ToolTip.visible: hovered && root.showTooltips
                        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                        background: Rectangle {
                            radius: width / 2
                            color: parent.hovered ? root.hoverBg : "transparent"
                            border.width: 1
                            border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, parent.hovered ? 0.45 : 0.28)
                        }
                    }
                }
            }
        }

        Components.ColumnSplitHandle {
            visible: !root.pureTraditional
            Layout.fillHeight: true
            Layout.preferredWidth: implicitWidth
            z: 5
            fg: root.fg
            currentWidth: root.leftColW
            minWidth: root.railMin
            maxWidth: 360
            sidebarOnRight: false
            flipped: root.flip
            onWidthDragged: (w) => root.setSidebarFromDrag(w)
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing / 2

        ListView {
            id: searchList
            visible: root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            clip: true
            model: searchModel
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
            QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
            delegate: Components.AppListItem {
                menuData: menuData
                width: searchList.width
                app: model
                iconSize: root.iconSz
                showDescription: false
                selected: searchList.currentIndex === index
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                hoverBg: root.hoverBg
                hoverFg: root.hoverFg
                fg: root.fg
                onActivated: root.activateItem(model)
                onContextMenuRequested: (x, y, anchor) => root.appContextMenu(model, x, y, anchor)
            }
        }

        ListView {
            id: navList
            visible: !root.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            clip: true
            model: root.navItems
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
            QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

            delegate: Item {
                id: row
                required property int index
                required property var modelData
                width: navList.width
                height: root.rowH
                readonly property bool hot: root.hoverIndex === index
                readonly property bool empty: !root.itemHasChildren(modelData.id)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Kirigami.Units.smallSpacing
                    color: row.hot ? root.selectedBg : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing
                    opacity: row.empty && modelData.id === "recent-files" ? 0.45 : 1

                    Components.ResolvedIcon {
                        iconName: row.modelData.icon || "applications-other"
                        preferSymbolic: false
                        tintColor: row.hot ? root.selectedFg : root.fg
                        Layout.preferredWidth: root.iconSz
                        Layout.preferredHeight: root.iconSz
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: row.modelData.name || ""
                        elide: Text.ElideRight
                        color: row.hot ? root.selectedFg : root.fg
                    }
                    Kirigami.Icon {
                        visible: !row.empty
                        source: "go-next"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        color: row.hot ? root.selectedFg : root.fg
                        opacity: 0.7
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        closeTimer.stop();
                        root.openFlyoutFor(row.index, row.modelData.id, row);
                    }
                    onExited: root.scheduleClose()
                    onClicked: root.openFlyoutFor(row.index, row.modelData.id, row)
                }
            }
        }

            Components.LayoutSearchField {
                visible: !root.pureTraditional
                layoutRoot: root
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
            }

            Components.PrismenuSettingsButton {
                visible: root.pureTraditional
                layoutRoot: root
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Window {
        id: flyoutWin
        property bool hovered: false
        flags: Qt.Popup | Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint
        color: "transparent"
        visible: false
        width: root.flyoutWidth
        height: Kirigami.Units.gridUnit * 8

        Rectangle {
            anchors.fill: parent
            color: root.bg
            border.color: root.borderColor
            border.width: Math.max(1, root.borderWidth)
            radius: root.radius

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: {
                    closeTimer.stop();
                    flyoutWin.hovered = true;
                }
                onExited: {
                    flyoutWin.hovered = false;
                    root.scheduleClose();
                }
            }

            ListView {
                id: flyoutList
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing / 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.flyoutItems
                QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }

                delegate: Item {
                    id: fdel
                    required property int index
                    required property var modelData
                    width: flyoutList.width
                    height: root.rowH
                    readonly property bool isAction: !!(modelData && modelData.action)

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.smallSpacing
                        color: fMouse.containsMouse ? root.selectedBg : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: modelData && modelData.icon ? modelData.icon : "application-x-executable"
                            Layout.preferredWidth: root.iconSz
                            Layout.preferredHeight: root.iconSz
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: modelData ? (modelData.name || "") : ""
                            elide: Text.ElideRight
                            color: fMouse.containsMouse ? root.selectedFg : root.fg
                        }
                    }

                    MouseArea {
                        id: fMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (!modelData)
                                return;
                            if (mouse.button === Qt.RightButton && !fdel.isAction) {
                                root.appContextMenu(modelData, mouse.x, mouse.y, fMouse);
                                return;
                            }
                            if (fdel.isAction)
                                root.powerAction(modelData.action);
                            else
                                root.activateItem(modelData);
                            root.hideFlyout();
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (!visible && !closeTimer.running)
                root.hoverIndex = -1;
        }
    }

    onSearchingChanged: root.hideFlyout()
    Component.onDestruction: root.hideFlyout()

    Connections {
        target: menuData
        function onSearchQueryChanged() {
            if (root.searching)
                root.hideFlyout();
        }
    }

    Ui.ListModelBridge { id: searchModel; source: menuData ? menuData.searchResults : [] }
}
