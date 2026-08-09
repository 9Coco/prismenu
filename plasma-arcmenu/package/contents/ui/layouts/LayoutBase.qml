import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components
import ".." as Ui
import "../../code/Locale.js" as Locale

Item {
    id: root

    // Safety net: when the menu is dragged narrower than the columns'
    // combined minimums, never paint content outside the menu surface.
    clip: true

    property var menuData: null
    property var themeStyle: ({})

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)
    signal powerAction(string actionId)
    signal userMenu()

    // Explicit language — layout string lists must depend on this to rebind
    readonly property string uiLang: {
        if (menuData && menuData.uiLang)
            return menuData.uiLang;
        return Locale.resolveLanguage("system", Qt.locale().name, Qt.locale().uiLanguages);
    }

    readonly property color bg: themeStyle.bg || Kirigami.Theme.backgroundColor
    readonly property color fg: themeStyle.fg || Kirigami.Theme.textColor
    readonly property color borderColor: themeStyle.border || Kirigami.Theme.disabledTextColor
    readonly property int borderWidth: themeStyle.borderWidth !== undefined ? themeStyle.borderWidth : 1
    readonly property real radius: themeStyle.radius !== undefined ? themeStyle.radius : Kirigami.Units.cornerRadius
    readonly property color separatorColor: themeStyle.separator || Kirigami.Theme.disabledTextColor
    readonly property color hoverBg: themeStyle.hoverBg || themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color hoverFg: themeStyle.hoverFg || themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    readonly property color activeBg: themeStyle.activeBg || themeStyle.selectedBg || Kirigami.Theme.highlightColor
    readonly property color activeFg: themeStyle.activeFg || themeStyle.selectedFg || Kirigami.Theme.highlightedTextColor
    /** selected* kept as aliases of active* for existing layout bindings */
    readonly property color selectedBg: root.activeBg
    readonly property color selectedFg: root.activeFg
    readonly property int menuFontSize: {
        var n = themeStyle.fontSize;
        return (n !== undefined && n > 0) ? n : Kirigami.Theme.defaultFont.pointSize;
    }
    readonly property int appIconSize: menuData ? menuData.appIconSize : 24
    readonly property int categoryIconSize: menuData ? menuData.categoryIconSize : 24
    readonly property int gridIconSize: menuData && menuData.gridIconSize ? menuData.gridIconSize : Math.max(appIconSize + 12, 36)
    readonly property int shortcutIconSize: menuData && menuData.shortcutIconSize ? menuData.shortcutIconSize : categoryIconSize
    readonly property int buttonIconSize: menuData && menuData.buttonIconSize ? menuData.buttonIconSize : 22
    readonly property int otherIconSize: menuData && menuData.otherIconSize ? menuData.otherIconSize : 22
    readonly property bool showAppDescriptions: menuData ? menuData.showAppDescriptions : false
    readonly property bool showGenericNames: menuData ? menuData.showGenericNames : false
    readonly property bool multiLineLabels: !menuData || menuData.multiLineLabels
    readonly property bool showTooltips: !menuData || menuData.showTooltips
    readonly property bool categoryIconsSymbolic: !menuData || menuData.categoryIconsSymbolic
    readonly property bool shortcutIconsSymbolic: !menuData || menuData.shortcutIconsSymbolic
    readonly property bool flip: menuData ? menuData.flipHorizontal : false
    readonly property bool searchOnTop: !menuData || menuData.searchbarLocation !== "bottom"
    readonly property bool searching: menuData ? menuData.isSearching : false

    /** Shared column width (persisted SidebarWidth); used by multi-column layouts */
    readonly property int sidebarW: (menuData && menuData.sidebarWidth) ? menuData.sidebarWidth : 220
    readonly property int categoryColW: (menuData && menuData.categoryColumnWidth) ? menuData.categoryColumnWidth : 220
    readonly property int sidebarMin: 160
    readonly property int sidebarMax: 360

    function setSidebarFromDrag(w) {
        if (menuData && menuData.setSidebarWidth)
            menuData.setSidebarWidth(w);
    }

    function setCategoryColumnFromDrag(w) {
        if (menuData && menuData.setCategoryColumnWidth)
            menuData.setCategoryColumnWidth(w);
    }

    function tr(msgid) {
        return Locale.tr(msgid, root.uiLang);
    }

    function appsModel() {
        if (!menuData) {
            return [];
        }
        // Prefer flat results for shared grid helpers; list layouts that want
        // section headers bind menuData.searchResults directly.
        return searching
            ? (menuData.searchResultsFlat || menuData.searchResults)
            : menuData.categoryApps;
    }

    /**
     * Shared launcher for pinned / places / shortcuts across all layouts.
     * Handles configure, power actions, place: keys, and normal apps.
     */
    function activateItem(item) {
        if (!item || item.isSection)
            return;
        if (item.action === "configure") {
            if (menuData)
                menuData.requestConfigure();
            return;
        }
        if (item.action) {
            powerAction(item.action);
            return;
        }
        appActivated(item);
    }

    Rectangle {
        anchors.fill: parent
        z: -2
        color: root.bg
        border.color: root.borderColor
        border.width: root.borderWidth
        radius: root.radius
    }

    // Catch right-clicks on layout empty space (not on app/shortcut MouseAreas)
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.RightButton
        onPressed: (mouse) => { mouse.accepted = true; }
        onClicked: (mouse) => { mouse.accepted = true; }
    }
}
