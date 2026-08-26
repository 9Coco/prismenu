import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/Locale.js" as Locale

/**
 * Page-display piece: pinned / favorite applications list (home page).
 */
Item {
    id: root

    property var menuData: null
    property var apps: []
    property int iconSize: 28
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color hoverBg: selectedBg
    property color hoverFg: selectedFg
    property color fg: Kirigami.Theme.textColor
    property bool showDescription: false
    property bool showGenericNames: false
    property bool multiLineLabels: false

    signal appActivated(var app)
    signal appContextMenu(var app, real x, real y)

    readonly property string uiLang: (menuData && menuData.uiLang) ? menuData.uiLang : "zh_CN"

    function localizeApp(app) {
        if (!app)
            return app;
        var copy = Object.assign({}, app);
        var id = copy.id || "";
        if (id === "arcmenu-settings") {
            copy.name = Locale.tr("ArcMenu Settings", root.uiLang);
        } else if (id.indexOf("dolphin") >= 0 || copy.name === "Files") {
            copy.name = Locale.tr("Files", root.uiLang);
        } else if (copy.name) {
            // Translate if this English UI label exists in our pack; else keep desktop name
            copy.name = Locale.tr(copy.name, root.uiLang);
        }
        return copy;
    }

    readonly property var items: {
        var _ = root.uiLang;
        var raw = [];
        if (apps && apps.length) {
            raw = apps;
        } else if (menuData && menuData.pinnedApps && menuData.pinnedApps.length) {
            raw = menuData.pinnedApps;
        } else {
            raw = [
                {
                    id: "org.kde.dolphin.desktop",
                    name: "Files",
                    icon: "system-file-manager",
                    exec: "dolphin",
                    noDisplay: false
                },
                {
                    id: "arcmenu-settings",
                    name: "ArcMenu Settings",
                    icon: "preferences-system-windows",
                    exec: "",
                    action: "configure",
                    noDisplay: false
                }
            ];
        }
        var out = [];
        for (var i = 0; i < raw.length; ++i) {
            out.push(root.localizeApp(raw[i]));
        }
        return out;
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: MenuScrollBar { menuData: root.menuData }
        QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AlwaysOff }
        Accessible.name: Locale.tr("Pinned applications", root.uiLang)

        Column {
            id: column
            width: flick.width
            spacing: Kirigami.Units.smallSpacing / 2

            Repeater {
                model: root.items
                AppListItem {
                    required property var modelData
                    width: column.width
                    app: modelData
                    iconSize: root.iconSize
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    hoverBg: root.hoverBg
                    hoverFg: root.hoverFg
                    fg: root.fg
                    showDescription: root.showDescription
                    showGenericNames: root.showGenericNames
                    multiLineLabels: root.multiLineLabels
                    onActivated: root.appActivated(modelData)
                    onContextMenuRequested: (x, y) => {
                        // Allow unpin / actions even for ArcMenu Settings (action: configure)
                        if (modelData)
                            root.appContextMenu(modelData, x, y);
                    }
                }
            }

            PlasmaComponents.Label {
                visible: root.items.length === 0
                width: column.width
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.55
                text: Locale.tr("Pin applications from the context menu", root.uiLang)
            }
        }
    }
}
