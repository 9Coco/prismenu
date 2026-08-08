import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale

/**
 * Fine-tuning — ArcMenu-style behavior toggles (微调).
 */
Item {
    id: root

    property bool cfg_ShowCategorySubmenus
    property bool cfg_ShowAppDescriptions
    property bool cfg_ShowGenericNames
    property bool cfg_ShowHiddenRecentFiles
    property bool cfg_MultiLineLabels
    property bool cfg_ShowTooltips
    property bool cfg_GroupAppsAlphabeticallyList
    property bool cfg_GroupAppsAlphabeticallyGrid
    property bool cfg_ActivateExistingWindow
    property bool cfg_KeepOpenOnCtrlClick
    property bool cfg_ScrollviewFadeEffects
    property bool cfg_ShowScrollbars
    property bool cfg_OverlayScrollbars
    property string cfg_CategoryIconType
    property string cfg_ShortcutIconType

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

    component ToggleRow: RowLayout {
        id: trow
        property string label: ""
        property string hint: ""
        property bool checked: false
        property bool rowEnabled: true
        signal toggled(bool on)

        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing
        opacity: rowEnabled ? 1 : 0.45

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            QQC2.Label {
                text: trow.label
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            QQC2.Label {
                visible: trow.hint.length > 0
                text: trow.hint
                opacity: 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
        QQC2.Switch {
            checked: trow.checked
            enabled: trow.rowEnabled
            onToggled: trow.toggled(checked)
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

            // ---- General ----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: generalCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: generalCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    ToggleRow {
                        label: root.tr("Show category submenus")
                        checked: cfg_ShowCategorySubmenus
                        onToggled: (on) => { cfg_ShowCategorySubmenus = on; writeLive("showCategorySubmenus", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Show application descriptions")
                        checked: cfg_ShowAppDescriptions
                        onToggled: (on) => { cfg_ShowAppDescriptions = on; writeLive("showAppDescriptions", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Show generic application names")
                        checked: cfg_ShowGenericNames
                        onToggled: (on) => { cfg_ShowGenericNames = on; writeLive("showGenericNames", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Show hidden recent files")
                        checked: cfg_ShowHiddenRecentFiles
                        onToggled: (on) => { cfg_ShowHiddenRecentFiles = on; writeLive("showHiddenRecentFiles", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Show multi-lined labels")
                        hint: root.tr("Allows application labels to span multiple lines on grid-style layouts.")
                        checked: cfg_MultiLineLabels
                        onToggled: (on) => { cfg_MultiLineLabels = on; writeLive("multiLineLabels", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Show tooltips")
                        checked: cfg_ShowTooltips
                        onToggled: (on) => { cfg_ShowTooltips = on; writeLive("showTooltips", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Group apps alphabetically on list views")
                        hint: root.tr("For All Apps sections.")
                        checked: cfg_GroupAppsAlphabeticallyList
                        onToggled: (on) => { cfg_GroupAppsAlphabeticallyList = on; writeLive("groupAppsAlphabeticallyList", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Group apps alphabetically on grid views")
                        hint: root.tr("For All Apps sections.")
                        checked: cfg_GroupAppsAlphabeticallyGrid
                        onToggled: (on) => { cfg_GroupAppsAlphabeticallyGrid = on; writeLive("groupAppsAlphabeticallyGrid", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Activate app window on launch")
                        hint: root.tr("Launching an app activates its existing window if one is open; otherwise, it launches a new instance. Hold Ctrl while launching or middle-click to open a new window.")
                        checked: cfg_ActivateExistingWindow
                        onToggled: (on) => { cfg_ActivateExistingWindow = on; writeLive("activateExistingWindow", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Keep ArcMenu open on Ctrl+Click")
                        hint: root.tr("Prevents the menu from closing when activating items while holding Ctrl.")
                        checked: cfg_KeepOpenOnCtrlClick
                        onToggled: (on) => { cfg_KeepOpenOnCtrlClick = on; writeLive("keepOpenOnCtrlClick", on); }
                    }
                }
            }

            // ---- Scrollview ----
            QQC2.Label {
                text: root.tr("Scrollview options")
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: scrollCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: scrollCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    ToggleRow {
                        label: root.tr("Scrollview fade effects")
                        checked: cfg_ScrollviewFadeEffects
                        onToggled: (on) => { cfg_ScrollviewFadeEffects = on; writeLive("scrollviewFadeEffects", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Show scrollbars")
                        checked: cfg_ShowScrollbars
                        onToggled: (on) => { cfg_ShowScrollbars = on; writeLive("showScrollbars", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Overlay scrollbars")
                        checked: cfg_OverlayScrollbars
                        rowEnabled: cfg_ShowScrollbars
                        onToggled: (on) => { cfg_OverlayScrollbars = on; writeLive("overlayScrollbars", on); }
                    }
                }
            }

            // ---- Icon style ----
            QQC2.Label {
                text: root.tr("Icon style")
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: iconCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: iconCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            QQC2.Label { text: root.tr("Category icon type"); Layout.fillWidth: true }
                            QQC2.Label {
                                text: root.tr("Some icon themes may not include the selected icon type.")
                                opacity: 0.6
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                        QQC2.ComboBox {
                            model: [root.tr("Full Color"), root.tr("Symbolic")]
                            Component.onCompleted: currentIndex = cfg_CategoryIconType === "fullcolor" ? 0 : 1
                            onActivated: {
                                cfg_CategoryIconType = currentIndex === 0 ? "fullcolor" : "symbolic";
                                writeLive("categoryIconType", cfg_CategoryIconType);
                            }
                        }
                    }

                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            text: root.tr("Shortcut icon type")
                            Layout.fillWidth: true
                        }
                        QQC2.ComboBox {
                            model: [root.tr("Full Color"), root.tr("Symbolic")]
                            Component.onCompleted: currentIndex = cfg_ShortcutIconType === "fullcolor" ? 0 : 1
                            onActivated: {
                                cfg_ShortcutIconType = currentIndex === 0 ? "fullcolor" : "symbolic";
                                writeLive("shortcutIconType", cfg_ShortcutIconType);
                            }
                        }
                    }
                }
            }

            QQC2.Button {
                text: root.tr("Reset to defaults")
                onClicked: {
                    cfg_ShowCategorySubmenus = false;
                    cfg_ShowAppDescriptions = false;
                    cfg_ShowGenericNames = false;
                    cfg_ShowHiddenRecentFiles = false;
                    cfg_MultiLineLabels = true;
                    cfg_ShowTooltips = true;
                    cfg_GroupAppsAlphabeticallyList = true;
                    cfg_GroupAppsAlphabeticallyGrid = false;
                    cfg_ActivateExistingWindow = false;
                    cfg_KeepOpenOnCtrlClick = true;
                    cfg_ScrollviewFadeEffects = true;
                    cfg_ShowScrollbars = true;
                    cfg_OverlayScrollbars = true;
                    cfg_CategoryIconType = "symbolic";
                    cfg_ShortcutIconType = "symbolic";
                    writeLive("showCategorySubmenus", false);
                    writeLive("showAppDescriptions", false);
                    writeLive("showGenericNames", false);
                    writeLive("showHiddenRecentFiles", false);
                    writeLive("multiLineLabels", true);
                    writeLive("showTooltips", true);
                    writeLive("groupAppsAlphabeticallyList", true);
                    writeLive("groupAppsAlphabeticallyGrid", false);
                    writeLive("activateExistingWindow", false);
                    writeLive("keepOpenOnCtrlClick", true);
                    writeLive("scrollviewFadeEffects", true);
                    writeLive("showScrollbars", true);
                    writeLive("overlayScrollbars", true);
                    writeLive("categoryIconType", "symbolic");
                    writeLive("shortcutIconType", "symbolic");
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
        }
    }
}
