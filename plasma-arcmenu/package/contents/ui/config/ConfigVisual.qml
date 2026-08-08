import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/IconSizes.js" as IconSizes

/**
 * Menu Visual Appearance — row layout matches GNOME ArcMenu Adw.ActionRow:
 * title (+ subtitle) on the left, control(s) on the right — no lone hint lines.
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

    function tr(msgid) { return Locale.tr(msgid, uiLang); }
    function writeLive(key, value) { try { plasmoid.configuration[key] = value; } catch (e) {} }

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

    /** Adw.ActionRow-style: title/subtitle left, trailing controls right */
    component SettingRow: RowLayout {
        id: srow
        property string title: ""
        property string subtitle: ""
        default property alias trailing: trail.data

        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 8
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            QQC2.Label {
                text: srow.title
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
            }
            QQC2.Label {
                visible: srow.subtitle.length > 0
                text: srow.subtitle
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        RowLayout {
            id: trail
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: Kirigami.Units.smallSpacing
        }
    }

    component GroupCard: Rectangle {
        id: card
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.smallSpacing
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing
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

            QQC2.Label { text: root.tr("Menu size"); font.bold: true }

            GroupCard {
                SettingRow {
                    title: root.tr("Height")
                    QQC2.SpinBox {
                        id: heightSpin
                        from: 400; to: 800; stepSize: 10
                        value: cfg_MenuHeight
                        onValueModified: {
                            cfg_MenuHeight = value;
                            writeLive("menuHeight", value);
                        }
                        textFromValue: (v) => v + " px"
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Left panel width")
                    subtitle: root.tr("Traditional layouts")
                    QQC2.SpinBox {
                        id: leftSpin
                        from: 180; to: 600; stepSize: 5
                        value: cfg_LeftPanelWidth
                        onValueModified: {
                            cfg_LeftPanelWidth = value;
                            root.syncWidthFromPanels();
                        }
                        textFromValue: (v) => v + " px"
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Right panel width")
                    subtitle: root.tr("Traditional layouts")
                    QQC2.SpinBox {
                        id: rightSpin
                        from: 160; to: 360; stepSize: 5
                        value: cfg_RightPanelWidth
                        onValueModified: {
                            cfg_RightPanelWidth = value;
                            root.syncWidthFromPanels();
                        }
                        textFromValue: (v) => v + " px"
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Width offset")
                    subtitle: root.tr("Non-traditional layouts")
                    QQC2.SpinBox {
                        id: offsetSpin
                        from: -200; to: 400; stepSize: 10
                        value: cfg_WidthOffset
                        onValueModified: {
                            cfg_WidthOffset = value;
                            root.syncWidthFromPanels();
                        }
                        textFromValue: (v) => v + " px"
                    }
                }
            }

            QQC2.Label { text: root.tr("Menu position"); font.bold: true }

            GroupCard {
                SettingRow {
                    title: root.tr("Override menu position")
                    QQC2.ComboBox {
                        id: posCombo
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
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
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Override menu rise")
                    subtitle: root.tr("Distance between the menu and the panel or screen edge.")
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
                        from: 0; to: 64
                        enabled: cfg_OverrideMenuRise
                        value: cfg_MenuRiseDistance
                        onValueModified: {
                            cfg_MenuRiseDistance = value;
                            writeLive("menuRiseDistance", value);
                        }
                        textFromValue: (v) => v + " px"
                    }
                }
            }

            QQC2.Label { text: root.tr("Override icon size"); font.bold: true }
            QQC2.Label {
                Layout.fillWidth: true
                opacity: 0.65
                wrapMode: Text.WordWrap
                text: root.tr("Override icon size for various menu items.")
            }

            GroupCard {
                SettingRow {
                    title: root.tr("Grid menu items")
                    subtitle: root.tr("Applications, pinned apps, shortcuts and grid search results (non-traditional layouts).")
                    QQC2.ComboBox {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        model: root.iconLevelModel
                        currentIndex: root.levelToIndex(cfg_IconSizeGrid)
                        onActivated: {
                            cfg_IconSizeGrid = root.indexToLevel(currentIndex);
                            writeLive("iconSizeGrid", cfg_IconSizeGrid);
                        }
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Applications")
                    subtitle: root.tr("Applications, pinned apps, items in categories, and list search results.")
                    QQC2.ComboBox {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        model: root.iconLevelModel
                        currentIndex: root.levelToIndex(cfg_IconSizeApps)
                        onActivated: {
                            cfg_IconSizeApps = root.indexToLevel(currentIndex);
                            writeLive("iconSizeApps", cfg_IconSizeApps);
                        }
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Shortcuts")
                    subtitle: root.tr("Directories, application shortcuts, and the power menu.")
                    QQC2.ComboBox {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        model: root.iconLevelModel
                        currentIndex: root.levelToIndex(cfg_IconSizeShortcuts)
                        onActivated: {
                            cfg_IconSizeShortcuts = root.indexToLevel(currentIndex);
                            writeLive("iconSizeShortcuts", cfg_IconSizeShortcuts);
                        }
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Application categories")
                    subtitle: root.tr("Category list.")
                    QQC2.ComboBox {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        model: root.iconLevelModel
                        currentIndex: root.levelToIndex(cfg_IconSizeCategories)
                        onActivated: {
                            cfg_IconSizeCategories = root.indexToLevel(currentIndex);
                            writeLive("iconSizeCategories", cfg_IconSizeCategories);
                        }
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Button widgets")
                    subtitle: root.tr("Power buttons, Unity-style bottom bar, and Mint-style sidebar buttons.")
                    QQC2.ComboBox {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        model: root.iconLevelModel
                        currentIndex: root.levelToIndex(cfg_IconSizeButtons)
                        onActivated: {
                            cfg_IconSizeButtons = root.indexToLevel(currentIndex);
                            writeLive("iconSizeButtons", cfg_IconSizeButtons);
                        }
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Other")
                    subtitle: root.tr("User avatar, search icon, and navigation icons.")
                    QQC2.ComboBox {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        model: root.iconLevelModel
                        currentIndex: root.levelToIndex(cfg_IconSizeOther)
                        onActivated: {
                            cfg_IconSizeOther = root.indexToLevel(currentIndex);
                            writeLive("iconSizeOther", cfg_IconSizeOther);
                        }
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
