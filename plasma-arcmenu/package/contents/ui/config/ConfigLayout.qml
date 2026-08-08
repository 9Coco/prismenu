import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/LayoutRegistry.js" as LayoutRegistry
import "../../code/Locale.js" as Locale

Item {
    id: root

    // KConfig form keys (Apply / OK still saves these)
    property string cfg_MenuLayoutId
    property bool cfg_FlipHorizontal
    property string cfg_SearchbarLocation
    property int cfg_MenuWidth
    property int cfg_MenuHeight
    property int cfg_SidebarWidth
    property int cfg_CategoryColumnWidth
    property int cfg_LeftPanelWidth
    property int cfg_RightPanelWidth
    property int cfg_WidthOffset

    property var layouts: LayoutRegistry.allLayouts()
    property var categories: LayoutRegistry.layoutCategories()

    // Which category sections are expanded (keyed by category id)
    property var expandedCategories: ({})

    readonly property var currentLayout: LayoutRegistry.getLayout(cfg_MenuLayoutId || "arcmenu")
    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function selectLayout(id) {
        if (!id) {
            return;
        }
        cfg_MenuLayoutId = id;

        var meta = LayoutRegistry.getLayout(id);
        if (meta) {
            // Always restore this layout's defaults — do not keep Raven's tall height
            // in the shared MenuHeight (Raven fills at runtime in main.qml).
            var h = meta.defaultHeight;
            if (h > 800)
                h = 800;
            cfg_MenuWidth = meta.defaultWidth;
            cfg_MenuHeight = h;
            cfg_SidebarWidth = 220;
            cfg_CategoryColumnWidth = 220;
            cfg_RightPanelWidth = 220;
            cfg_LeftPanelWidth = Math.max(180, meta.defaultWidth - 220 - 24);
            cfg_WidthOffset = 0;

            // Keep the selected layout's category expanded
            ensureCategoryExpanded(meta.category);
        }

        try {
            plasmoid.configuration.menuLayoutId = id;
            if (meta) {
                plasmoid.configuration.menuWidth = meta.defaultWidth;
                plasmoid.configuration.menuHeight = cfg_MenuHeight;
                plasmoid.configuration.sidebarWidth = 220;
                plasmoid.configuration.categoryColumnWidth = 220;
                plasmoid.configuration.rightPanelWidth = 220;
                plasmoid.configuration.leftPanelWidth = cfg_LeftPanelWidth;
                plasmoid.configuration.widthOffset = 0;
            }
        } catch (e) {
            console.warn("ArcMenu ConfigLayout: direct write failed", e);
        }
    }

    function resetSizesToDefaults() {
        var meta = LayoutRegistry.getLayout(cfg_MenuLayoutId || "arcmenu");
        var w = meta && meta.defaultWidth ? meta.defaultWidth : 620;
        var h = meta && meta.defaultHeight ? meta.defaultHeight : 540;
        if (h > 800)
            h = 800;
        cfg_MenuWidth = w;
        cfg_MenuHeight = h;
        cfg_SidebarWidth = 220;
        cfg_CategoryColumnWidth = 220;
        cfg_RightPanelWidth = 220;
        cfg_LeftPanelWidth = Math.max(180, w - 220 - 24);
        cfg_WidthOffset = 0;
        try {
            plasmoid.configuration.menuWidth = w;
            plasmoid.configuration.menuHeight = h;
            plasmoid.configuration.sidebarWidth = 220;
            plasmoid.configuration.categoryColumnWidth = 220;
            plasmoid.configuration.rightPanelWidth = 220;
            plasmoid.configuration.leftPanelWidth = cfg_LeftPanelWidth;
            plasmoid.configuration.widthOffset = 0;
        } catch (e) {}
    }

    function ensureCategoryExpanded(categoryId) {
        if (!categoryId)
            return;
        var next = Object.assign({}, expandedCategories);
        next[categoryId] = true;
        expandedCategories = next;
    }

    function toggleCategory(categoryId) {
        var next = Object.assign({}, expandedCategories);
        next[categoryId] = !next[categoryId];
        expandedCategories = next;
    }

    function isCategoryExpanded(categoryId) {
        return !!expandedCategories[categoryId];
    }

    function categoryTitle(cat) {
        switch (cat.id) {
        case "traditional":
            return root.tr("Traditional Menu Layouts");
        case "modern":
            return root.tr("Modern Menu Layouts");
        case "touch":
            return root.tr("Touch Menu Layouts");
        case "launcher":
            return root.tr("Launcher Menu Layouts");
        case "alternative":
            return root.tr("Alternative Menu Layouts");
        default:
            return cat.name || cat.id;
        }
    }

    function initExpanded() {
        var next = {};
        var cur = LayoutRegistry.getLayout(cfg_MenuLayoutId || "arcmenu");
        var curCat = cur ? cur.category : "traditional";
        for (var i = 0; i < categories.length; ++i) {
            next[categories[i].id] = (categories[i].id === curCat);
        }
        expandedCategories = next;
    }

    QQC2.ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: scroll.availableWidth
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Heading {
                text: root.tr("Menu Layout")
                level: 2
                Layout.fillWidth: true
            }

            // ---- Current layout ----
            QQC2.Label {
                text: root.tr("Current Menu Layout")
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(parent.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 14)
                Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                radius: Kirigami.Units.cornerRadius
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: Kirigami.Theme.disabledTextColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    LayoutPreview {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        layoutId: root.cfg_MenuLayoutId || "arcmenu"
                        lineColor: Kirigami.Theme.textColor
                        lineOpacity: 0.65
                    }

                    QQC2.Label {
                        text: root.currentLayout ? root.currentLayout.name : ""
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }
            }

            // ---- Choose new layout ----
            QQC2.Label {
                text: root.tr("Select a new menu layout?")
                font.bold: true
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: categoryColumn.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                border.width: 1
                border.color: Kirigami.Theme.disabledTextColor

                ColumnLayout {
                    id: categoryColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 0

                    Repeater {
                        model: root.categories.length

                        ColumnLayout {
                            id: catBlock
                            Layout.fillWidth: true
                            spacing: 0

                            required property int index
                            readonly property var cat: root.categories[index]
                            readonly property var catLayouts: LayoutRegistry.layoutsInCategory(cat.id)
                            readonly property bool expanded: root.isCategoryExpanded(cat.id)

                            // Category header
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                                color: headerMa.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : "transparent"
                                radius: Kirigami.Units.smallSpacing

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Kirigami.Units.smallSpacing
                                    anchors.rightMargin: Kirigami.Units.smallSpacing
                                    spacing: Kirigami.Units.smallSpacing

                                    Kirigami.Icon {
                                        source: catBlock.cat.icon || "folder"
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                    }

                                    QQC2.Label {
                                        text: root.categoryTitle(catBlock.cat)
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Kirigami.Icon {
                                        source: catBlock.expanded ? "go-up" : "go-down"
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                    }
                                }

                                MouseArea {
                                    id: headerMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleCategory(catBlock.cat.id)
                                }
                            }

                            // Layout grid
                            Flow {
                                Layout.fillWidth: true
                                Layout.leftMargin: Kirigami.Units.smallSpacing
                                Layout.rightMargin: Kirigami.Units.smallSpacing
                                Layout.bottomMargin: catBlock.expanded ? Kirigami.Units.smallSpacing : 0
                                spacing: Kirigami.Units.smallSpacing
                                visible: catBlock.expanded

                                Repeater {
                                    model: catBlock.catLayouts.length

                                    Rectangle {
                                        id: card
                                        required property int index
                                        readonly property var layoutInfo: catBlock.catLayouts[index]
                                        readonly property bool selected: root.cfg_MenuLayoutId === layoutInfo.id

                                        width: Math.floor((categoryColumn.width - Kirigami.Units.smallSpacing * 4 - Kirigami.Units.smallSpacing * 2) / 3)
                                        height: width * 0.95
                                        radius: Kirigami.Units.smallSpacing
                                        color: selected
                                               ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                                               : Kirigami.Theme.backgroundColor
                                        border.width: selected ? 2 : 1
                                        border.color: selected ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: Kirigami.Units.smallSpacing
                                            spacing: Kirigami.Units.smallSpacing / 2

                                            LayoutPreview {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                layoutId: card.layoutInfo.id
                                                lineColor: Kirigami.Theme.textColor
                                                lineOpacity: 0.55
                                            }

                                            QQC2.Label {
                                                text: card.layoutInfo.name || ""
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectLayout(card.layoutInfo.id)
                                        }
                                    }
                                }
                            }

                            // Divider between categories
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                visible: catBlock.index < root.categories.length - 1
                                color: Kirigami.Theme.disabledTextColor
                                opacity: 0.35
                            }
                        }
                    }
                }
            }

            // ---- Options ----
            Kirigami.FormLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing

                QQC2.CheckBox {
                    id: flipBox
                    Kirigami.FormData.label: root.tr("Horizontal flip:")
                    text: root.tr("Swap categories and applications columns")
                    checked: cfg_FlipHorizontal
                    onToggled: {
                        cfg_FlipHorizontal = checked;
                        try { plasmoid.configuration.flipHorizontal = checked; } catch (e) {}
                    }
                    enabled: LayoutRegistry.supportsOption(cfg_MenuLayoutId, "flip")
                }

                QQC2.ComboBox {
                    id: searchLoc
                    Kirigami.FormData.label: root.tr("Search…")
                    enabled: LayoutRegistry.supportsOption(cfg_MenuLayoutId, "searchbarLocation")
                    model: [root.tr("Top"), root.tr("Bottom")]
                    Component.onCompleted: currentIndex = cfg_SearchbarLocation === "bottom" ? 1 : 0
                    onActivated: {
                        cfg_SearchbarLocation = currentIndex === 1 ? "bottom" : "top";
                        try { plasmoid.configuration.searchbarLocation = cfg_SearchbarLocation; } catch (e) {}
                    }
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.75
                    text: root.tr("Menu size, position, and icon overrides are in Menu Visual Appearance.")
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    text: root.tr("Tip: drag the menu edges to resize, or the divider between columns.")
                }

                QQC2.Button {
                    text: root.tr("Reset to defaults")
                    onClicked: root.resetSizesToDefaults()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.largeSpacing
            }
        }
    }

    Connections {
        target: plasmoid.configuration
        function onMenuLayoutIdChanged() {
            cfg_MenuLayoutId = plasmoid.configuration.menuLayoutId || cfg_MenuLayoutId;
            var meta = LayoutRegistry.getLayout(cfg_MenuLayoutId);
            if (meta)
                root.ensureCategoryExpanded(meta.category);
        }
    }

    Component.onCompleted: {
        try {
            if (plasmoid.configuration.menuLayoutId) {
                cfg_MenuLayoutId = plasmoid.configuration.menuLayoutId;
            }
        } catch (e) {}
        if (!cfg_MenuLayoutId) {
            cfg_MenuLayoutId = "arcmenu";
        }
        initExpanded();
        var h = cfg_MenuHeight || 540;
        if (h > 800) {
            h = 800;
            cfg_MenuHeight = h;
            try { plasmoid.configuration.menuHeight = h; } catch (e) {}
        }
    }
}
