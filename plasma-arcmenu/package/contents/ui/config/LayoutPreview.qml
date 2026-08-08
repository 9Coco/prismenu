import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/**
 * Schematic layout preview (ArcMenu-style settings cards).
 * Uses filled white squares / lines as content placeholders so users can
 * tell where icons, labels, places, and search live — not empty wireframes.
 */
Item {
    id: root

    property string layoutId: "arcmenu"
    property color lineColor: Kirigami.Theme.textColor
    property real lineOpacity: 0.65

    readonly property color ink: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, lineOpacity)
    readonly property color inkSoft: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, lineOpacity * 0.55)

    readonly property string previewKind: {
        switch (layoutId) {
        case "arcmenu": return "arcmenu";
        case "brisk":
        case "budgie":
        case "gnome": return "sidebarTopSearch";
        case "mint":
        case "tognee": return "iconRail";
        case "whisker": return "whisker";
        case "elementary":
        case "chromebook":
        case "pop":
        case "plasma-dash":
        case "unity-dash": return "searchGrid";
        case "plasma":
        case "unity":
        case "kickoff": return "tallList";
        case "redmond":
        case "sleek": return "gridSidebar";
        case "eleven":
        case "az":
        case "insider": return "windowsHome";
        case "windows": return "windows";
        case "zest":
        case "enterprise": return "threeCol";
        case "raven": return "raven";
        case "kicker":
        case "simple":
        case "runner": return "runner";
        default: return "sidebarTopSearch";
        }
    }

    // Small solid icon block
    component IconBlock: Rectangle {
        property int size: 7
        width: size
        height: size
        radius: 1.5
        color: root.ink
    }

    // Horizontal text line
    component TextLine: Rectangle {
        property real lineWidth: parent ? parent.width : 20
        width: lineWidth
        height: 2
        radius: 1
        color: root.inkSoft
    }

    // One menu row: icon + 1–2 text lines
    component MenuRow: Row {
        property real rowWidth: 40
        property bool dualLine: true
        spacing: 3
        width: rowWidth
        height: dualLine ? 10 : 7

        IconBlock {
            size: dualLine ? 8 : 7
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: Math.max(4, rowWidth - 12)
            TextLine { lineWidth: parent.width * 0.95 }
            TextLine {
                visible: dualLine
                lineWidth: parent.width * 0.55
            }
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: Math.max(2, Math.round(Math.min(width, height) * 0.04))
        radius: 3
        color: "transparent"
        border.width: 1.5
        border.color: root.ink
        clip: true

        // ---- ArcMenu: left apps (icon+text), right places icons, search+session bottom ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "arcmenu"

            // Left: pinned / all apps list
            Column {
                id: arcLeft
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.22
                width: parent.width * 0.55
                spacing: Math.max(2, height / 28)

                Repeater {
                    model: 7
                    MenuRow {
                        rowWidth: arcLeft.width
                        dualLine: index > 1
                    }
                }
            }

            // Right: user + places (icon stack)
            Column {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.22
                width: parent.width * 0.36
                spacing: Math.max(3, height / 22)

                // user
                Row {
                    spacing: 3
                    width: parent.width
                    IconBlock { size: 9 }
                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        TextLine { lineWidth: Math.min(28, parent.parent.width * 0.55) }
                    }
                }

                Repeater {
                    model: 6
                    MenuRow {
                        rowWidth: parent.width
                        dualLine: false
                    }
                }
            }

            // Bottom search (left) + session dots (right)
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.16

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.55
                    height: parent.height
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.ink

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        spacing: 3
                        IconBlock { size: 6 }
                        TextLine { lineWidth: 18 }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: 3
                        IconBlock { size: 7 }
                    }
                }
            }
        }

        // ---- Brisk / Budgie / GNOME: search top, cats left, apps right ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "sidebarTopSearch"

            Rectangle {
                id: briskSearch
                height: parent.height * 0.14
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    spacing: 3
                    IconBlock { size: 6 }
                    TextLine { lineWidth: parent.parent.width * 0.45 }
                }
            }

            Column {
                id: briskCats
                anchors.left: parent.left
                anchors.top: briskSearch.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                width: parent.width * 0.38
                spacing: Math.max(2, height / 26)
                Repeater {
                    model: 6
                    MenuRow {
                        rowWidth: briskCats.width
                        dualLine: false
                    }
                }
            }

            Column {
                id: briskApps
                anchors.right: parent.right
                anchors.top: briskSearch.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                width: parent.width * 0.55
                spacing: Math.max(2, height / 22)
                Repeater {
                    model: 5
                    MenuRow {
                        rowWidth: briskApps.width
                        dualLine: true
                    }
                }
            }
        }

        // ---- Mint: icon rail + categories + content ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "iconRail"

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.14
                spacing: 4
                Repeater {
                    model: 6
                    IconBlock {
                        size: Math.max(6, parent.width * 0.7)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Column {
                id: mintCats
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.18
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.18
                anchors.bottom: parent.bottom
                width: parent.width * 0.32
                spacing: Math.max(2, height / 24)
                Repeater {
                    model: 6
                    MenuRow {
                        rowWidth: mintCats.width
                        dualLine: false
                    }
                }
            }

            Column {
                id: mintApps
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.18
                anchors.bottom: parent.bottom
                width: parent.width * 0.42
                spacing: Math.max(2, height / 20)
                Repeater {
                    model: 4
                    MenuRow {
                        rowWidth: mintApps.width
                        dualLine: true
                    }
                }
            }

            Rectangle {
                height: parent.height * 0.12
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.18
                anchors.right: parent.right
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    spacing: 3
                    IconBlock { size: 5 }
                    TextLine { lineWidth: 20 }
                }
            }
        }

        // ---- Whisker: user bar, cats + apps, search bottom ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "whisker"

            Row {
                id: whiskerUser
                anchors.top: parent.top
                width: parent.width
                height: parent.height * 0.16
                spacing: 4
                IconBlock {
                    size: Math.max(8, parent.height * 0.55)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    TextLine { lineWidth: 22 }
                }
                Item { width: Math.max(4, parent.width * 0.2); height: 1 }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Repeater {
                        model: 4
                        IconBlock { size: 6 }
                    }
                }
            }

            Rectangle {
                id: whiskerSearch
                height: parent.height * 0.12
                width: parent.width
                anchors.top: whiskerUser.bottom
                anchors.topMargin: 3
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    spacing: 3
                    IconBlock { size: 5 }
                    TextLine { lineWidth: 24 }
                }
            }

            Column {
                id: whiskerCats
                anchors.left: parent.left
                anchors.top: whiskerSearch.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                width: parent.width * 0.4
                spacing: Math.max(2, height / 24)
                Repeater {
                    model: 6
                    MenuRow {
                        rowWidth: whiskerCats.width
                        dualLine: false
                    }
                }
            }

            Column {
                id: whiskerApps
                anchors.right: parent.right
                anchors.top: whiskerSearch.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                width: parent.width * 0.52
                spacing: Math.max(2, height / 20)
                Repeater {
                    model: 5
                    MenuRow {
                        rowWidth: whiskerApps.width
                        dualLine: true
                    }
                }
            }
        }

        // ---- Search + icon grid (Pop / Dash / Elementary) ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "searchGrid"

            Rectangle {
                id: gridSearch
                height: parent.height * 0.14
                width: parent.width * 0.92
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    spacing: 3
                    IconBlock { size: 6 }
                    TextLine { lineWidth: 28 }
                }
            }

            Grid {
                anchors.top: gridSearch.bottom
                anchors.topMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                columns: 4
                rowSpacing: 5
                columnSpacing: 5
                Repeater {
                    model: 8
                    Column {
                        spacing: 2
                        width: Math.max(10, (frame.width - 30) / 4 - 4)
                        IconBlock {
                            size: Math.max(8, parent.width * 0.55)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.85
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Repeater {
                    model: 3
                    Rectangle {
                        width: 22
                        height: 10
                        radius: 2
                        color: index === 0 ? root.inkSoft : "transparent"
                        border.width: 1
                        border.color: root.ink
                    }
                }
            }
        }

        // ---- Tall list + bottom tabs (Plasma / Kickoff) ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "tallList"

            Row {
                id: plasmaHead
                anchors.top: parent.top
                width: parent.width
                height: parent.height * 0.16
                spacing: 4
                IconBlock {
                    size: Math.max(8, parent.height * 0.55)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: parent.width - 16
                    height: parent.height * 0.55
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.ink
                }
            }

            Column {
                id: plasmaList
                anchors.top: plasmaHead.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.18
                spacing: Math.max(2, height / 22)
                Repeater {
                    model: 5
                    MenuRow {
                        rowWidth: plasmaList.width
                        dualLine: true
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                Repeater {
                    model: 4
                    Column {
                        spacing: 2
                        IconBlock {
                            size: 7
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }

        // ---- Grid + right places (Redmond) ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "gridSidebar"

            Rectangle {
                id: redSearch
                height: parent.height * 0.12
                width: parent.width * 0.62
                anchors.left: parent.left
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    spacing: 3
                    IconBlock { size: 5 }
                    TextLine { lineWidth: 16 }
                }
            }

            Grid {
                anchors.left: parent.left
                anchors.top: redSearch.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                width: parent.width * 0.62
                columns: 3
                rowSpacing: 4
                columnSpacing: 4
                Repeater {
                    model: 9
                    Column {
                        spacing: 2
                        width: Math.max(8, (parent.parent.width * 0.62 - 8) / 3 - 2)
                        IconBlock {
                            size: Math.max(7, parent.width * 0.5)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.8
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Column {
                id: redSide
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                width: parent.width * 0.32
                spacing: Math.max(2, height / 26)

                MenuRow {
                    rowWidth: redSide.width
                    dualLine: false
                }
                Repeater {
                    model: 5
                    MenuRow {
                        rowWidth: redSide.width
                        dualLine: false
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: parent.width * 0.32
                spacing: 3
                Repeater {
                    model: 4
                    IconBlock { size: 6 }
                }
            }
        }

        // ---- Eleven / A-Z / Insider: centered avatar + grid ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "windowsHome"

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                spacing: 3
                IconBlock {
                    size: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                TextLine {
                    lineWidth: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                id: winSearch
                height: parent.height * 0.12
                width: parent.width * 0.85
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.28
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    spacing: 3
                    IconBlock { size: 5 }
                    TextLine { lineWidth: 20 }
                }
            }

            Grid {
                anchors.top: winSearch.bottom
                anchors.topMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                columns: 4
                rowSpacing: 4
                columnSpacing: 4
                Repeater {
                    model: 8
                    Column {
                        spacing: 2
                        width: Math.max(9, (frame.width - 28) / 4 - 3)
                        IconBlock {
                            size: Math.max(7, parent.width * 0.5)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.75
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }

        // ---- Windows rail ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "windows"

            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.12
                spacing: 4
                Repeater {
                    model: 5
                    IconBlock {
                        size: Math.max(6, parent.width * 0.55)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Column {
                id: winList
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.16
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                width: parent.width * 0.42
                spacing: Math.max(2, height / 22)
                Repeater {
                    model: 5
                    MenuRow {
                        rowWidth: winList.width
                        dualLine: true
                    }
                }
            }

            Grid {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                width: parent.width * 0.36
                columns: 2
                rowSpacing: 4
                columnSpacing: 3
                Repeater {
                    model: 6
                    IconBlock {
                        size: Math.max(8, (parent.parent.width * 0.36 - 3) / 2 - 2)
                    }
                }
            }
        }

        // ---- Enterprise three-col ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "threeCol"

            Row {
                id: entUser
                anchors.top: parent.top
                width: parent.width
                height: parent.height * 0.14
                spacing: 4
                IconBlock {
                    size: 9
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: parent.width * 0.7
                    height: parent.height * 0.55
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.ink
                }
            }

            Column {
                id: entCats
                anchors.left: parent.left
                anchors.top: entUser.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.12
                width: parent.width * 0.36
                spacing: Math.max(2, height / 24)
                Repeater {
                    model: 6
                    MenuRow {
                        rowWidth: entCats.width
                        dualLine: false
                    }
                }
            }

            Grid {
                anchors.right: parent.right
                anchors.top: entUser.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.12
                width: parent.width * 0.58
                columns: 3
                rowSpacing: 4
                columnSpacing: 3
                Repeater {
                    model: 6
                    Column {
                        spacing: 2
                        width: Math.max(8, (parent.parent.width * 0.58 - 6) / 3 - 1)
                        IconBlock {
                            size: Math.max(7, parent.width * 0.5)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.75
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 3
                Repeater {
                    model: 4
                    IconBlock { size: 6 }
                }
            }
        }

        // ---- Raven ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "raven"

            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.16
                spacing: 4
                Repeater {
                    model: 6
                    IconBlock {
                        size: Math.max(6, parent.width * 0.55)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Rectangle {
                id: ravenSearch
                height: parent.height * 0.12
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.2
                anchors.right: parent.right
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
            }

            Column {
                id: ravenList
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.2
                anchors.right: parent.right
                anchors.top: ravenSearch.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                spacing: Math.max(2, height / 18)
                Repeater {
                    model: 5
                    MenuRow {
                        rowWidth: ravenList.width
                        dualLine: true
                    }
                }
            }
        }

        // ---- Runner / Simple ----
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "runner"

            Rectangle {
                width: parent.width * 0.78
                height: parent.height * 0.72
                anchors.centerIn: parent
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: root.ink

                Column {
                    id: runnerCol
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 4

                    Rectangle {
                        width: parent.width
                        height: parent.height * 0.18
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.ink
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            spacing: 3
                            IconBlock { size: 5 }
                            TextLine { lineWidth: 22 }
                        }
                    }

                    Repeater {
                        model: 4
                        MenuRow {
                            rowWidth: runnerCol.width
                            dualLine: true
                        }
                    }
                }
            }
        }
    }
}
