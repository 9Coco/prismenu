import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import "../../code/AppsModel.js" as AppsModel

/**
 * Tognee layout (ArcMenu Tognee).
 *
 * Left: icon rail (places �?software/settings/tweaks �?expand �?power)
 * Right: category list (home) or app list (drill-in) + search at bottom
 */
LayoutBase {
    id: root

    readonly property var categories: root.typeCategories

    // Home shows category nav (matches reference). Drill-in shows apps.
    property bool showingApps: false
    property string selectedId: "pinned"
    activeNavId: selectedId

    readonly property int railWidth: Kirigami.Units.gridUnit * 2.8

    readonly property var placeActions: root.asRailItems(root.placeShortcuts)
    readonly property var systemActions: root.asRailItems(root.applicationShortcuts)



    readonly property string selectionTitle: {
        if (selectedId === "pinned")
            return root.tr("Pinned Applications");
        if (selectedId === "all")
            return root.tr("All Applications");
        for (var i = 0; i < categories.length; ++i) {
            if (categories[i].id === selectedId)
                return categories[i].name;
        }
        return root.tr("Applications");
    }


    // Show apps list when searching or after selecting a nav entry
    readonly property bool inAppsView: root.searching || root.showingApps


    readonly property var extraCategories: root.preferenceGroups

    function selectNav(id) {
        selectedId = id;
        showingApps = true;
        if (!menuData) return;
        menuData.setSearch("");
        root.refreshNavData(id);
        if (id === "pinned" || id === "favorites" || id === "frequent" || id === "recent-files" || String(id).indexOf("qgrp-") === 0 || String(id).indexOf("tgrp-") === 0)
            return;
        menuData.currentCategoryId = (id === "all-apps") ? "all" : id;
    }

    function goHome() {
        showingApps = false;
        if (menuData)
            menuData.setSearch("");
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        layoutDirection: root.flip ? Qt.RightToLeft : Qt.LeftToRight

        // ---- Left icon rail ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: root.railWidth
            Layout.maximumWidth: root.railWidth
            Layout.fillWidth: false
            spacing: Kirigami.Units.smallSpacing / 2

            Repeater {
                model: root.placeActions.length
                PlasmaComponents.ToolButton {
                    required property int index
                    readonly property var def: root.placeActions[index]
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                    flat: true
                    icon.name: def.icon
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    Accessible.name: def.tip
                    onClicked: root.activateItem(def)
                    PlasmaComponents.ToolTip.text: def.tip
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            Kirigami.Separator {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.4
                opacity: 0.35
            }

            Repeater {
                model: root.systemActions.length
                PlasmaComponents.ToolButton {
                    required property int index
                    readonly property var def: root.systemActions[index]
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                    flat: true
                    icon.name: def.icon
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    Accessible.name: def.tip
                    onClicked: root.activateItem(def)
                    PlasmaComponents.ToolTip.text: def.tip
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            Kirigami.Separator {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.4
                opacity: 0.35
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                flat: true
                icon.name: "system-shutdown"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: root.tr("Shut Down")
                onClicked: root.powerAction("shutdown")
                PlasmaComponents.ToolTip.text: root.tr("Shut Down")
                PlasmaComponents.ToolTip.visible: hovered
                PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: root.borderColor
            opacity: 0.35
        }

        // ---- Main column: categories or apps + search ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Home: pinned / all / categories (reference screenshot)
                Flickable {
                    id: navFlick
                    anchors.fill: parent
                    visible: !root.inAppsView
                    contentWidth: width
                    contentHeight: navCol.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: Components.MenuScrollBar { menuData: root.menuData }
                    QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }

                    Column {
                        id: navCol
                        width: navFlick.width
                        spacing: Kirigami.Units.smallSpacing / 2

                        // Extra categories (pinned / all-apps / favorites /
                        // frequent / recent-files) — user configurable, same
                        // as upstream "extra-categories" setting
                        Repeater {
                            model: root.extraCategories.length
                            Components.ShortcutRow {
                                required property int index
                                width: navCol.width
                                iconName: root.extraCategories[index].icon
                                label: root.extraCategories[index].name
                                iconSize: root.categoryIconSize
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectNav(root.extraCategories[index].id)
                            }
                        }

                        Kirigami.Separator {
                            width: navCol.width
                            opacity: 0.4
                        }

                        Repeater {
                            model: root.categories.length
                            Components.ShortcutRow {
                                required property int index
                                width: navCol.width
                                iconName: root.categories[index].icon
                                label: root.categories[index].name
                                iconSize: root.categoryIconSize
                                selectedBg: root.selectedBg
                                selectedFg: root.selectedFg
                                hoverBg: root.hoverBg
                                hoverFg: root.hoverFg
                                fg: root.fg
                                onActivated: root.selectNav(root.categories[index].id)
                            }
                        }
                    }
                }

                // Drill-in / search: app list
                ColumnLayout {
                    anchors.fill: parent
                    visible: root.inAppsView
                    spacing: Kirigami.Units.smallSpacing / 2

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !root.searching
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.ToolButton {
                            flat: true
                            icon.name: "go-previous"
                            Accessible.name: root.tr("Back")
                            onClicked: root.goHome()
                        }

                        PlasmaComponents.Label {
                            text: root.selectionTitle
                            font.bold: true
                            color: root.fg
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Components.LayoutGroupPane {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        layoutRoot: root
                        items: root.contentItems
                        useGrid: !root.searching && root.usesGridView(root.selectedId)
                        showDescription: root.showAppDescriptions
                        emptyText: root.searching
                                  ? root.tr("No matching applications found")
                                  : (root.selectedId === "pinned"
                                     ? root.tr("Pin applications from the context menu")
                                     : root.tr("No applications"))
                    }
                }
            }

            Components.LayoutSearchField {
                layoutRoot: root
                Layout.fillWidth: true
            }
        }
    }
}
