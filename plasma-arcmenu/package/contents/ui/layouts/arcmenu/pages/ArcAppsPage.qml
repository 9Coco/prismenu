import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../../components" as Components
import "../../../../code/AppsModel.js" as AppsModel
import "../../../../code/Locale.js" as Locale

/**
 * ArcMenu apps page: header + category list, or drilled-in apps.
 */
Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    property string drillCategoryId: ""

    readonly property bool showingCategories: drillCategoryId.length === 0
    readonly property bool canGoBackToCategories: drillCategoryId.length > 0

    readonly property color fg: themeStyle.fg || Kirigami.Theme.textColor
    readonly property color selectedBg: themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color selectedFg: themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    readonly property int appIconSize: menuData ? menuData.appIconSize : 24
    readonly property int categoryIconSize: menuData ? menuData.categoryIconSize : 24
    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"

    readonly property var categoryItems: {
        var _ = root.uiLang;
        var raw = (menuData && menuData.categories) ? menuData.categories : [];
        var out = [];
        for (var i = 0; i < raw.length; ++i) {
            if (!raw[i] || raw[i].id === "all")
                continue;
            out.push(raw[i]);
        }
        return out;
    }

    readonly property var drilledApps: {
        if (!menuData || root.drillCategoryId.length === 0)
            return [];
        return AppsModel.appsInCategory(menuData.allApps || [], root.drillCategoryId);
    }

    function goBackToCategories() {
        drillCategoryId = "";
        if (menuData)
            menuData.currentCategoryId = "all";
    }

    function resetToCategories() {
        drillCategoryId = "";
    }

    function openCategory(id) {
        if (!id)
            return;
        drillCategoryId = id;
        if (menuData)
            menuData.selectCategory(id);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "view-app-grid-symbolic"
                Layout.preferredWidth: Math.max(root.categoryIconSize, 24)
                Layout.preferredHeight: Math.max(root.categoryIconSize, 24)
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: {
                    if (root.showingCategories)
                        return Locale.tr("All Applications", root.uiLang);
                    var cats = root.categoryItems;
                    for (var i = 0; i < cats.length; ++i) {
                        if (cats[i].id === root.drillCategoryId)
                            return cats[i].name || "";
                    }
                    return Locale.tr("All Applications", root.uiLang);
                }
                elide: Text.ElideRight
                font.weight: Font.Medium
                color: root.fg
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: catColumn.height
            visible: root.showingCategories
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: catColumn
                width: parent.width
                spacing: 0

                Repeater {
                    model: root.categoryItems.length

                    Item {
                        id: catDel
                        required property int index
                        readonly property var cat: root.categoryItems[index]
                        width: catColumn.width
                        height: Math.max(root.categoryIconSize + Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 2)

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: Kirigami.Units.smallSpacing
                            color: catMouse.containsMouse ? root.selectedBg : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Kirigami.Units.smallSpacing
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: (catDel.cat && catDel.cat.icon) ? catDel.cat.icon : "applications-other"
                                Layout.preferredWidth: root.categoryIconSize
                                Layout.preferredHeight: root.categoryIconSize
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: (catDel.cat && catDel.cat.name) ? catDel.cat.name : ""
                                elide: Text.ElideRight
                                color: catMouse.containsMouse ? root.selectedFg : root.fg
                            }
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openCategory(catDel.cat ? catDel.cat.id : "")
                        }
                    }
                }

                PlasmaComponents.Label {
                    visible: root.categoryItems.length === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.55
                    text: Locale.tr("No applications", root.uiLang)
                    color: root.fg
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: appColumn.height
            visible: !root.showingCategories
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: appColumn
                width: parent.width
                spacing: Kirigami.Units.smallSpacing / 2

                Repeater {
                    model: root.drilledApps.length

                    Components.AppListItem {
                        required property int index
                        width: appColumn.width
                        app: root.drilledApps[index]
                        iconSize: root.appIconSize
                        showDescription: false
                        selectedBg: root.selectedBg
                        selectedFg: root.selectedFg
                        fg: root.fg
                        onActivated: root.appActivated(root.drilledApps[index])
                        onContextMenuRequested: (x, y) => root.appContextMenu(root.drilledApps[index], x, y)
                    }
                }

                PlasmaComponents.Label {
                    visible: root.drilledApps.length === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.55
                    text: Locale.tr("No applications", root.uiLang)
                    color: root.fg
                }
            }
        }
    }
}
