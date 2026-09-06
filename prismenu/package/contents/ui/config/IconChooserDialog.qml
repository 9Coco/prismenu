import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import "../../code/Distro.js" as Distro
import "../../code/PresetIcons.js" as PresetIcons
import "../../code/Locale.js" as Locale

/**
 * ArcMenu-style icon picker: search, type/category filters, preset grid, browse files.
 */
QQC2.Dialog {
    id: root

    property string uiLang: "zh_CN"
    /** Current selection id (preset name, theme name) or empty while browsing */
    property string selectedIconId: ""
    /** Absolute path when user picked a file */
    property string selectedFilePath: ""
    /** "preset" | "theme" | "file" | "" */
    property string selectedKind: ""

    signal iconChosen(string iconId, string kind, string filePath)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    title: root.tr("Select an Icon")
    modal: true
    standardButtons: QQC2.Dialog.NoButton
    width: 540
    height: 620
    closePolicy: QQC2.Popup.CloseOnEscape
    padding: Kirigami.Units.largeSpacing
    // Overlay is null in QWidget-hosted config windows; fall back to the
    // default parent (window contentItem) instead of crashing (2026-08).
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    property string searchQuery: ""
    property string filterType: "all"      // all | symbolic | fullcolor
    property string filterGroup: "all"     // all | extension | distro | system

    function buildAllEntries() {
        var out = [];
        var ids = PresetIcons.allIds();
        var i;
        for (i = 0; i < ids.length; ++i) {
            var pid = ids[i];
            out.push({
                id: pid,
                displayName: pid,
                group: PresetIcons.groupOf(pid),
                sourceKind: "preset",
                symbolic: PresetIcons.isSymbolic(pid)
            });
        }
        var sys = Distro.systemIconNames();
        for (i = 0; i < sys.length; ++i) {
            var sid = sys[i];
            out.push({
                id: sid,
                displayName: sid,
                group: "system",
                sourceKind: "theme",
                symbolic: String(sid).indexOf("-symbolic") >= 0
            });
        }
        return out;
    }

    property var allEntries: []

    function matchesFilters(entry) {
        if (!entry)
            return false;
        if (filterGroup !== "all" && entry.group !== filterGroup)
            return false;
        var name = String(entry.displayName || "").toLowerCase();
        if (filterType === "symbolic" && name.indexOf("-symbolic") < 0)
            return false;
        if (filterType === "fullcolor" && name.indexOf("-symbolic") >= 0)
            return false;
        if (searchQuery.length > 0 && name.indexOf(searchQuery) < 0)
            return false;
        return true;
    }

    function rebuildModel() {
        if (!allEntries || allEntries.length === 0)
            allEntries = buildAllEntries();
        filteredModel.clear();
        var list = allEntries;
        for (var i = 0; i < list.length; ++i) {
            var e = list[i];
            if (!matchesFilters(e))
                continue;
            filteredModel.append({
                iconId: e.id,
                displayName: e.displayName,
                group: e.group,
                sourceKind: e.sourceKind,
                symbolic: e.symbolic ? 1 : 0
            });
        }
    }

    function selectEntry(entry) {
        if (!entry)
            return;
        selectedIconId = entry.iconId || entry.id;
        selectedKind = entry.sourceKind;
        selectedFilePath = "";
        selectBtn.enabled = true;
    }

    function applySelection() {
        if (selectedKind === "file" && selectedFilePath) {
            iconChosen("", "file", selectedFilePath);
        } else if (selectedIconId) {
            iconChosen(selectedIconId, selectedKind || "theme", "");
        } else {
            return;
        }
        close();
    }

    function openFor(currentId) {
        selectedIconId = currentId || "";
        selectedFilePath = "";
        if (PresetIcons.isPreset(currentId) || Distro.isPresetIcon(currentId))
            selectedKind = "preset";
        else if (currentId === "custom" || currentId === "auto-distro" || !currentId)
            selectedKind = "";
        else
            selectedKind = "theme";
        searchQuery = "";
        searchField.text = "";
        filterType = "all";
        filterGroup = "all";
        allEntries = buildAllEntries();
        rebuildModel();
        selectBtn.enabled = PresetIcons.isPreset(currentId) || Distro.isPresetIcon(currentId)
            || (!!currentId && currentId !== "custom" && currentId !== "auto-distro");
        open();
    }

    Component.onCompleted: {
        allEntries = buildAllEntries();
        if (QQC2.Overlay.overlay)
            parent = QQC2.Overlay.overlay;
    }
    onOpened: rebuildModel()

    ListModel { id: filteredModel }

    header: RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        QQC2.Button {
            text: root.tr("Cancel")
            flat: true
            onClicked: root.reject()
        }
        Item { Layout.fillWidth: true }
        QQC2.Label {
            text: root.title
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }
        Item { Layout.fillWidth: true }
        QQC2.Button {
            id: selectBtn
            text: root.tr("Select")
            enabled: false
            highlighted: true
            onClicked: root.applySelection()
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: root.tr("Search icons…")
                leftPadding: Kirigami.Units.largeSpacing * 2
                onTextChanged: {
                    root.searchQuery = text.trim().toLowerCase();
                    root.rebuildModel();
                }
                Kirigami.Icon {
                    anchors.left: parent.left
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    source: "edit-find-symbolic"
                    opacity: 0.6
                }
            }

            QQC2.ToolButton {
                id: filterBtn
                icon.name: "open-menu-symbolic"
                QQC2.ToolTip.text: root.tr("Filter")
                QQC2.ToolTip.visible: hovered
                onClicked: filterMenu.popup(filterBtn)
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 64
            cellHeight: 64
            model: filteredModel
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: QQC2.ItemDelegate {
                required property string iconId
                required property string displayName
                required property string group
                required property string sourceKind
                required property int symbolic

                width: grid.cellWidth - 4
                height: grid.cellHeight - 4
                highlighted: iconId === root.selectedIconId && root.selectedKind !== "file"
                QQC2.ToolTip.text: displayName
                QQC2.ToolTip.visible: hovered
                onClicked: {
                    root.selectEntry({
                        iconId: iconId,
                        displayName: displayName,
                        group: group,
                        sourceKind: sourceKind,
                        symbolic: symbolic
                    });
                }
                onDoubleClicked: {
                    root.selectEntry({
                        iconId: iconId,
                        displayName: displayName,
                        group: group,
                        sourceKind: sourceKind,
                        symbolic: symbolic
                    });
                    root.applySelection();
                }

                contentItem: Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: Kirigami.Units.iconSizes.medium
                    source: sourceKind === "preset"
                        ? Qt.resolvedUrl("../../icons/menu-button/" + iconId + ".svg")
                        : iconId
                    isMask: symbolic === 1
                    color: Kirigami.Theme.textColor
                }

                background: Rectangle {
                    radius: Kirigami.Units.smallSpacing
                    color: parent.highlighted
                        ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.35)
                        : (parent.hovered
                            ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                            : "transparent")
                }
            }
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: root.tr("Browse Files...")
            onClicked: fileDialog.open()
        }
    }

    QQC2.Menu {
        id: filterMenu
        QQC2.Menu {
            title: root.tr("Type")
            QQC2.MenuItem {
                text: root.tr("All"); checkable: true
                checked: root.filterType === "all"
                onTriggered: { root.filterType = "all"; root.rebuildModel(); }
            }
            QQC2.MenuItem {
                text: root.tr("Symbolic"); checkable: true
                checked: root.filterType === "symbolic"
                onTriggered: { root.filterType = "symbolic"; root.rebuildModel(); }
            }
            QQC2.MenuItem {
                text: root.tr("Full Color"); checkable: true
                checked: root.filterType === "fullcolor"
                onTriggered: { root.filterType = "fullcolor"; root.rebuildModel(); }
            }
        }
        QQC2.Menu {
            title: root.tr("Category")
            QQC2.MenuItem {
                text: root.tr("All"); checkable: true
                checked: root.filterGroup === "all"
                onTriggered: { root.filterGroup = "all"; root.rebuildModel(); }
            }
            QQC2.MenuItem {
                text: root.tr("Extension"); checkable: true
                checked: root.filterGroup === "extension"
                onTriggered: { root.filterGroup = "extension"; root.rebuildModel(); }
            }
            QQC2.MenuItem {
                text: root.tr("Distros"); checkable: true
                checked: root.filterGroup === "distro"
                onTriggered: { root.filterGroup = "distro"; root.rebuildModel(); }
            }
            QQC2.MenuItem {
                text: root.tr("System"); checkable: true
                checked: root.filterGroup === "system"
                onTriggered: { root.filterGroup = "system"; root.rebuildModel(); }
            }
        }
    }

    Dialogs.FileDialog {
        id: fileDialog
        title: root.tr("Select an Icon")
        nameFilters: [root.tr("Images (*.png *.svg *.jpg *.jpeg *.webp)"), root.tr("All files (*)")]
        onAccepted: {
            var path = selectedFile.toString().replace("file://", "");
            root.selectedFilePath = path;
            root.selectedKind = "file";
            root.selectedIconId = "";
            root.selectBtn.enabled = true;
            root.applySelection();
        }
    }
}
