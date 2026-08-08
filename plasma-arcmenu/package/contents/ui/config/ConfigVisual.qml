import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/IconSizes.js" as IconSizes

/**
 * Menu Visual Appearance — ArcMenu-style size, position, and icon overrides.
 */
Item {
    id: root

    property int cfg_MenuHeight
    property int cfg_LeftPanelWidth
    property int cfg_RightPanelWidth
    property int cfg_WidthOffset
    property int cfg_SidebarWidth
    property int cfg_MenuWidth
    property string cfg_OverrideMenuPosition
    property bool cfg_OverrideMenuRise
    property int cfg_MenuRiseDistance
    property int cfg_IconSizeGrid
    property int cfg_IconSizeApps
    property int cfg_IconSizeShortcuts
    property int cfg_IconSizeCategories
    property int cfg_IconSizeButtons
    property int cfg_IconSizeOther

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function writeLive(key, value) {
        try { plasmoid.configuration[key] = value; } catch (e) {}
    }

    function syncWidthFromPanels() {
        var w = cfg_LeftPanelWidth + cfg_RightPanelWidth + 24 + cfg_WidthOffset;
        if (w < 400) w = 400;
        if (w > 900) w = 900;
        cfg_MenuWidth = w;
        cfg_SidebarWidth = cfg_RightPanelWidth;
        writeLive("menuWidth", w);
        writeLive("sidebarWidth", cfg_RightPanelWidth);
        writeLive("leftPanelWidth", cfg_LeftPanelWidth);
        writeLive("rightPanelWidth", cfg_RightPanelWidth);
        writeLive("widthOffset", cfg_WidthOffset);
    }

    readonly property var iconLevelModel: [
        root.tr("Off"),
        root.tr("Extra Small"),
        root.tr("Small"),
        root.tr("Medium"),
        root.tr("Large"),
        root.tr("Extra Large")
    ]

    function levelToIndex(level) {
        var n = IconSizes.clampLevel(level);
        return n < 0 ? 0 : n + 1;
    }

    function indexToLevel(index) {
        return index <= 0 ? -1 : index - 1;
    }

    component IconOverrideRow: RowLayout {
        id: irow
        property string label: ""
        property string hint: ""
        property int level: -1
        signal levelEdited(int value)

        Kirigami.FormData.label: irow.label
        spacing: Kirigami.Units.smallSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            QQC2.ComboBox {
                Layout.fillWidth: true
                model: root.iconLevelModel
                currentIndex: root.levelToIndex(irow.level)
                onActivated: irow.levelEdited(root.indexToLevel(currentIndex))
            }
            QQC2.Label {
                visible: irow.hint.length > 0
                text: irow.hint
                opacity: 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            // ---- Menu size ----
            QQC2.Label {
                text: root.tr("Menu size")
                font.bold: true
            }

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.SpinBox {
                    id: heightSpin
                    Kirigami.FormData.label: root.tr("Height:")
                    from: 400
                    to: 800
                    stepSize: 10
                    value: cfg_MenuHeight
                    onValueModified: {
                        cfg_MenuHeight = value;
                        writeLive("menuHeight", value);
                    }
                    textFromValue: (v) => v + " px"
                }

                QQC2.SpinBox {
                    id: leftSpin
                    Kirigami.FormData.label: root.tr("Left panel width:")
                    from: 180
                    to: 600
                    stepSize: 5
                    value: cfg_LeftPanelWidth
                    onValueModified: {
                        cfg_LeftPanelWidth = value;
                        root.syncWidthFromPanels();
                    }
                    textFromValue: (v) => v + " px"
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: root.tr("Traditional layouts")
                }

                QQC2.SpinBox {
                    id: rightSpin
                    Kirigami.FormData.label: root.tr("Right panel width:")
                    from: 160
                    to: 360
                    stepSize: 5
                    value: cfg_RightPanelWidth
                    onValueModified: {
                        cfg_RightPanelWidth = value;
                        root.syncWidthFromPanels();
                    }
                    textFromValue: (v) => v + " px"
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: root.tr("Traditional layouts")
                }

                QQC2.SpinBox {
                    id: offsetSpin
                    Kirigami.FormData.label: root.tr("Width offset:")
                    from: -200
                    to: 400
                    stepSize: 10
                    value: cfg_WidthOffset
                    onValueModified: {
                        cfg_WidthOffset = value;
                        root.syncWidthFromPanels();
                    }
                    textFromValue: (v) => v + " px"
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: root.tr("Non-traditional layouts")
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            // ---- Menu position ----
            QQC2.Label {
                text: root.tr("Menu position")
                font.bold: true
            }

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.ComboBox {
                    id: posCombo
                    Kirigami.FormData.label: root.tr("Override menu position:")
                    model: [
                        root.tr("Off"),
                        root.tr("Top centered"),
                        root.tr("Bottom centered"),
                        root.tr("Center")
                    ]
                    property var keys: ["off", "top-centered", "bottom-centered", "center"]
                    Component.onCompleted: {
                        var i = keys.indexOf(cfg_OverrideMenuPosition || "off");
                        currentIndex = i >= 0 ? i : 0;
                    }
                    onActivated: {
                        cfg_OverrideMenuPosition = keys[currentIndex];
                        writeLive("overrideMenuPosition", cfg_OverrideMenuPosition);
                    }
                }

                RowLayout {
                    Kirigami.FormData.label: root.tr("Override menu rise:")
                    QQC2.Switch {
                        id: riseSwitch
                        checked: cfg_OverrideMenuRise
                        onToggled: {
                            cfg_OverrideMenuRise = checked;
                            writeLive("overrideMenuRise", checked);
                        }
                    }
                    QQC2.SpinBox {
                        id: riseSpin
                        from: 0
                        to: 64
                        enabled: cfg_OverrideMenuRise
                        value: cfg_MenuRiseDistance
                        onValueModified: {
                            cfg_MenuRiseDistance = value;
                            writeLive("menuRiseDistance", value);
                        }
                        textFromValue: (v) => v + " px"
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    opacity: 0.6
                    wrapMode: Text.WordWrap
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: root.tr("Distance between the menu and the panel or screen edge.")
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            // ---- Icon sizes ----
            QQC2.Label {
                text: root.tr("Override icon size")
                font.bold: true
            }
            QQC2.Label {
                Layout.fillWidth: true
                opacity: 0.65
                wrapMode: Text.WordWrap
                text: root.tr("Override icon size for various menu items.")
            }

            Kirigami.FormLayout {
                Layout.fillWidth: true

                IconOverrideRow {
                    label: root.tr("Grid menu items:")
                    hint: root.tr("Applications, pinned apps, shortcuts and grid search results (non-traditional layouts).")
                    level: cfg_IconSizeGrid
                    onLevelEdited: (v) => {
                        cfg_IconSizeGrid = v;
                        writeLive("iconSizeGrid", v);
                    }
                }
                IconOverrideRow {
                    label: root.tr("Applications:")
                    hint: root.tr("Applications, pinned apps, items in categories, and list search results.")
                    level: cfg_IconSizeApps
                    onLevelEdited: (v) => {
                        cfg_IconSizeApps = v;
                        writeLive("iconSizeApps", v);
                    }
                }
                IconOverrideRow {
                    label: root.tr("Shortcuts:")
                    hint: root.tr("Directories, application shortcuts, and the power menu.")
                    level: cfg_IconSizeShortcuts
                    onLevelEdited: (v) => {
                        cfg_IconSizeShortcuts = v;
                        writeLive("iconSizeShortcuts", v);
                    }
                }
                IconOverrideRow {
                    label: root.tr("Application categories:")
                    hint: root.tr("Category list.")
                    level: cfg_IconSizeCategories
                    onLevelEdited: (v) => {
                        cfg_IconSizeCategories = v;
                        writeLive("iconSizeCategories", v);
                    }
                }
                IconOverrideRow {
                    label: root.tr("Button widgets:")
                    hint: root.tr("Power buttons, Unity-style bottom bar, and Mint-style sidebar buttons.")
                    level: cfg_IconSizeButtons
                    onLevelEdited: (v) => {
                        cfg_IconSizeButtons = v;
                        writeLive("iconSizeButtons", v);
                    }
                }
                IconOverrideRow {
                    label: root.tr("Other:")
                    hint: root.tr("User avatar, search icon, and navigation icons.")
                    level: cfg_IconSizeOther
                    onLevelEdited: (v) => {
                        cfg_IconSizeOther = v;
                        writeLive("iconSizeOther", v);
                    }
                }
            }

            QQC2.Button {
                text: root.tr("Reset to defaults")
                onClicked: {
                    cfg_MenuHeight = 540;
                    cfg_LeftPanelWidth = 380;
                    cfg_RightPanelWidth = 220;
                    cfg_WidthOffset = 0;
                    cfg_OverrideMenuPosition = "off";
                    cfg_OverrideMenuRise = false;
                    cfg_MenuRiseDistance = 6;
                    cfg_IconSizeGrid = -1;
                    cfg_IconSizeApps = -1;
                    cfg_IconSizeShortcuts = -1;
                    cfg_IconSizeCategories = -1;
                    cfg_IconSizeButtons = -1;
                    cfg_IconSizeOther = -1;
                    heightSpin.value = 540;
                    leftSpin.value = 380;
                    rightSpin.value = 220;
                    offsetSpin.value = 0;
                    riseSwitch.checked = false;
                    riseSpin.value = 6;
                    posCombo.currentIndex = 0;
                    syncWidthFromPanels();
                    writeLive("menuHeight", 540);
                    writeLive("overrideMenuPosition", "off");
                    writeLive("overrideMenuRise", false);
                    writeLive("menuRiseDistance", 6);
                    writeLive("iconSizeGrid", -1);
                    writeLive("iconSizeApps", -1);
                    writeLive("iconSizeShortcuts", -1);
                    writeLive("iconSizeCategories", -1);
                    writeLive("iconSizeButtons", -1);
                    writeLive("iconSizeOther", -1);
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
        }
    }

    Connections {
        target: plasmoid.configuration
        function onMenuHeightChanged() {
            var v = plasmoid.configuration.menuHeight;
            if (heightSpin.value !== v) heightSpin.value = v;
            cfg_MenuHeight = v;
        }
        function onLeftPanelWidthChanged() {
            var v = plasmoid.configuration.leftPanelWidth;
            if (leftSpin.value !== v) leftSpin.value = v;
            cfg_LeftPanelWidth = v;
        }
        function onRightPanelWidthChanged() {
            var v = plasmoid.configuration.rightPanelWidth;
            if (rightSpin.value !== v) rightSpin.value = v;
            cfg_RightPanelWidth = v;
        }
        function onSidebarWidthChanged() {
            var v = plasmoid.configuration.sidebarWidth;
            if (rightSpin.value !== v) {
                rightSpin.value = v;
                cfg_RightPanelWidth = v;
            }
        }
    }

    Component.onCompleted: {
        heightSpin.value = cfg_MenuHeight || 540;
        leftSpin.value = cfg_LeftPanelWidth || 380;
        rightSpin.value = cfg_RightPanelWidth || cfg_SidebarWidth || 220;
        offsetSpin.value = cfg_WidthOffset || 0;
        riseSpin.value = cfg_MenuRiseDistance >= 0 ? cfg_MenuRiseDistance : 6;
        if (!cfg_LeftPanelWidth)
            cfg_LeftPanelWidth = 380;
        if (!cfg_RightPanelWidth)
            cfg_RightPanelWidth = cfg_SidebarWidth || 220;
    }
}
