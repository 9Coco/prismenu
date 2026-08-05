import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui

Item {
    id: root

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)
    signal powerAction(string actionId)
    signal userMenu()

    readonly property color bg: themeStyle.bg || Kirigami.Theme.backgroundColor
    readonly property color fg: themeStyle.fg || Kirigami.Theme.textColor
    readonly property color borderColor: themeStyle.border || Kirigami.Theme.disabledTextColor
    readonly property int borderWidth: themeStyle.borderWidth !== undefined ? themeStyle.borderWidth : 1
    readonly property real radius: themeStyle.radius !== undefined ? themeStyle.radius : Kirigami.Units.cornerRadius
    readonly property color selectedBg: themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color selectedFg: themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    readonly property int appIconSize: menuData ? menuData.appIconSize : 24
    readonly property int categoryIconSize: menuData ? menuData.categoryIconSize : 24
    readonly property bool flip: menuData ? menuData.flipHorizontal : false
    readonly property bool searchOnTop: !menuData || menuData.searchbarLocation !== "bottom"
    readonly property bool searching: menuData ? menuData.isSearching : false

    function appsModel() {
        if (!menuData) {
            return [];
        }
        return searching ? menuData.searchResults : menuData.categoryApps;
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg
        border.color: root.borderColor
        border.width: root.borderWidth
        radius: root.radius
    }
}
