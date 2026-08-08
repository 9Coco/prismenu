import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale

/**
 * Search Options — ArcMenu-style search settings.
 */
Item {
    id: root

    property var cfg_Providers: ["applications"]
    property string cfg_Placeholder
    property bool cfg_ShowDescription
    property int cfg_MaxResults
    property bool cfg_HideSearchBar
    property bool cfg_HighlightSearchTerms
    property bool cfg_SearchBoxRadiusEnabled
    property int cfg_SearchBoxRadius
    property bool cfg_SearchWindows
    property bool cfg_SearchRecentFiles

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }
    function writeLive(key, value) {
        try {
            plasmoid.configuration[key] = value;
            try { plasmoid.configuration.writeConfig(); } catch (e2) {}
        } catch (e) {}
    }

    component ToggleRow: RowLayout {
        id: trow
        property string label: ""
        property string hint: ""
        property bool checked: false
        signal toggled(bool on)
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            QQC2.Label { text: trow.label; Layout.fillWidth: true; wrapMode: Text.WordWrap }
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
            onToggled: trow.toggled(checked)
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label { text: root.tr("Search Options"); font.bold: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: optCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: optCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    ToggleRow {
                        label: root.tr("Hide Search Bar")
                        hint: root.tr("The search bar hides when empty and appears when typing.")
                        checked: cfg_HideSearchBar
                        onToggled: (on) => { cfg_HideSearchBar = on; writeLive("hideSearchBar", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    ToggleRow {
                        label: root.tr("Show search result descriptions")
                        checked: cfg_ShowDescription
                        onToggled: (on) => { cfg_ShowDescription = on; writeLive("showDescription", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    ToggleRow {
                        label: root.tr("Highlight search result terms")
                        checked: cfg_HighlightSearchTerms
                        onToggled: (on) => { cfg_HighlightSearchTerms = on; writeLive("highlightSearchTerms", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Maximum search results"); Layout.fillWidth: true }
                        QQC2.SpinBox {
                            from: 1; to: 100
                            value: cfg_MaxResults > 0 ? cfg_MaxResults : 5
                            onValueModified: { cfg_MaxResults = value; writeLive("maxResults", value); }
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Search box border radius"); Layout.fillWidth: true }
                        QQC2.Switch {
                            checked: cfg_SearchBoxRadiusEnabled
                            onToggled: { cfg_SearchBoxRadiusEnabled = checked; writeLive("searchBoxRadiusEnabled", checked); }
                        }
                        QQC2.SpinBox {
                            from: 0; to: 48
                            enabled: cfg_SearchBoxRadiusEnabled
                            value: cfg_SearchBoxRadius
                            onValueModified: { cfg_SearchBoxRadius = value; writeLive("searchBoxRadius", value); }
                        }
                    }
                }
            }

            QQC2.Label { text: root.tr("Additional Search Providers"); font.bold: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: provCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: provCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    ToggleRow {
                        label: root.tr("Search windows open in all workspaces")
                        checked: cfg_SearchWindows
                        onToggled: (on) => { cfg_SearchWindows = on; writeLive("searchWindows", on); }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    ToggleRow {
                        label: root.tr("Search recent files")
                        checked: cfg_SearchRecentFiles
                        onToggled: (on) => { cfg_SearchRecentFiles = on; writeLive("searchRecentFiles", on); }
                    }
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
        }
    }

    Component.onCompleted: {
        if (!cfg_MaxResults) cfg_MaxResults = 5;
        if (cfg_SearchBoxRadius === undefined || cfg_SearchBoxRadius === null)
            cfg_SearchBoxRadius = 25;
    }
}
