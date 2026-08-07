import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/LayoutRegistry.js" as LayoutRegistry

Item {
    id: root

    // KConfig form keys (Apply / OK still saves these)
    property string cfg_MenuLayoutId
    property bool cfg_FlipHorizontal
    property string cfg_SearchbarLocation
    property int cfg_MenuWidth
    property int cfg_MenuHeight

    property var layouts: LayoutRegistry.allLayouts()

    /**
     * Same path as the panel right-click actions that already work:
     * write plasmoid.configuration.menuLayoutId immediately.
     */
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
            widthSpin.value = meta.defaultWidth;
            heightSpin.value = h;
            heightSpin.to = 800;
        }

        // Instant apply (proven working via contextual actions)
        try {
            plasmoid.configuration.menuLayoutId = id;
            if (meta) {
                plasmoid.configuration.menuWidth = meta.defaultWidth;
                plasmoid.configuration.menuHeight = cfg_MenuHeight;
            }
        } catch (e) {
            console.warn("ArcMenu ConfigLayout: direct write failed", e);
        }
    }

    function layoutIndex() {
        var id = cfg_MenuLayoutId || "arcmenu";
        try {
            if (plasmoid.configuration.menuLayoutId) {
                id = plasmoid.configuration.menuLayoutId;
            }
        } catch (e) {}
        for (var i = 0; i < layouts.length; ++i) {
            if (layouts[i].id === id) {
                return i;
            }
        }
        return 0;
    }

    function layoutLabels() {
        var labels = [];
        for (var i = 0; i < layouts.length; ++i) {
            labels.push(layouts[i].name + " — " + layouts[i].description);
        }
        return labels;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            text: i18n("Menu Layout")
            level: 2
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Positive
            text: i18n("Layout switches immediately when you click a style. Current: %1", cfg_MenuLayoutId || "arcmenu")
        }

        QQC2.ComboBox {
            id: layoutCombo
            Layout.fillWidth: true
            model: root.layoutLabels()
            Component.onCompleted: currentIndex = root.layoutIndex()
            onActivated: root.selectLayout(root.layouts[currentIndex].id)
        }

        GridView {
            id: layoutGrid
            Layout.fillWidth: true
            Layout.preferredHeight: cellHeight * 2.2
            cellWidth: Kirigami.Units.gridUnit * 12
            cellHeight: Kirigami.Units.gridUnit * 8
            model: root.layouts.length
            clip: true

            delegate: Item {
                width: layoutGrid.cellWidth
                height: layoutGrid.cellHeight
                required property int index
                readonly property var layoutInfo: root.layouts[index] || {}

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    radius: Kirigami.Units.smallSpacing
                    color: cfg_MenuLayoutId === layoutInfo.id ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    border.width: 1
                    border.color: cfg_MenuLayoutId === layoutInfo.id ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                    opacity: cfg_MenuLayoutId === layoutInfo.id ? 0.35 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        QQC2.Label {
                            text: layoutInfo.name || ""
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        QQC2.Label {
                            text: layoutInfo.description || ""
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            opacity: 0.8
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.selectLayout(layoutInfo.id);
                            layoutCombo.currentIndex = index;
                        }
                    }
                }
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.CheckBox {
                id: flipBox
                Kirigami.FormData.label: i18n("Horizontal flip:")
                text: i18n("Swap categories and applications columns")
                checked: cfg_FlipHorizontal
                onToggled: {
                    cfg_FlipHorizontal = checked;
                    try { plasmoid.configuration.flipHorizontal = checked; } catch (e) {}
                }
                enabled: LayoutRegistry.supportsOption(cfg_MenuLayoutId, "flip")
            }

            QQC2.ComboBox {
                id: searchLoc
                Kirigami.FormData.label: i18n("Search bar location:")
                enabled: LayoutRegistry.supportsOption(cfg_MenuLayoutId, "searchbarLocation")
                model: [i18n("Top"), i18n("Bottom")]
                Component.onCompleted: currentIndex = cfg_SearchbarLocation === "bottom" ? 1 : 0
                onActivated: {
                    cfg_SearchbarLocation = currentIndex === 1 ? "bottom" : "top";
                    try { plasmoid.configuration.searchbarLocation = cfg_SearchbarLocation; } catch (e) {}
                }
            }

            QQC2.SpinBox {
                id: widthSpin
                Kirigami.FormData.label: i18n("Menu width:")
                from: 400
                to: 900
                stepSize: 10
                Component.onCompleted: value = cfg_MenuWidth
                onValueModified: {
                    cfg_MenuWidth = value;
                    try { plasmoid.configuration.menuWidth = value; } catch (e) {}
                }
                textFromValue: (v) => v + " px"
            }

            QQC2.SpinBox {
                id: heightSpin
                Kirigami.FormData.label: i18n("Menu height:")
                from: 400
                to: 800
                stepSize: 10
                Component.onCompleted: value = Math.min(cfg_MenuHeight || 540, 800)
                onValueModified: {
                    cfg_MenuHeight = value;
                    try { plasmoid.configuration.menuHeight = value; } catch (e) {}
                }
                textFromValue: (v) => v + " px"
            }
        }
    }

    // Keep UI in sync if layout was changed from panel right-click
    Connections {
        target: plasmoid.configuration
        function onMenuLayoutIdChanged() {
            cfg_MenuLayoutId = plasmoid.configuration.menuLayoutId || cfg_MenuLayoutId;
            layoutCombo.currentIndex = root.layoutIndex();
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
        layoutCombo.currentIndex = layoutIndex();
        widthSpin.value = cfg_MenuWidth || 620;
        // Clamp leftover Raven full-height values out of shared MenuHeight
        var h = cfg_MenuHeight || 540;
        if (h > 800) {
            h = 800;
            cfg_MenuHeight = h;
            try { plasmoid.configuration.menuHeight = h; } catch (e) {}
        }
        heightSpin.value = h;
    }
}
