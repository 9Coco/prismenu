import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/LayoutRegistry.js" as LayoutRegistry

/**
 * Schematic layout preview matching each real menu layout.
 * - Filled squares = app icons
 * - Lines = labels
 * - Real symbolic icons for user / search / places / session (not generic squares)
 */
Item {
    id: root

    property string layoutId: "arcmenu"
    property color lineColor: Kirigami.Theme.textColor
    property real lineOpacity: 0.7

    readonly property color ink: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, lineOpacity)
    readonly property color inkSoft: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, lineOpacity * 0.5)

    readonly property var layoutInfo: LayoutRegistry.getLayout(layoutId)
    readonly property string previewKind: (layoutInfo && layoutInfo.previewKind)
        ? layoutInfo.previewKind : "brisk"

    component InkIcon: Kirigami.Icon {
        property int size: 8
        width: size
        height: size
        color: root.ink
        isMask: true
    }

    component SolidSquare: Rectangle {
        property int size: 7
        width: size
        height: size
        radius: 1.5
        color: root.ink
    }

    component HollowSquare: Rectangle {
        property int size: 7
        width: size
        height: size
        radius: 1.5
        color: "transparent"
        border.width: 1.2
        border.color: root.ink
    }

    component TextLine: Rectangle {
        property real lineWidth: 20
        width: lineWidth
        height: 1.8
        radius: 0.9
        color: root.inkSoft
    }

    // App list row: solid icon + label line(s)
    component AppRow: Row {
        property real rowWidth: 40
        property bool dual: false
        width: rowWidth
        height: dual ? 9 : 7
        spacing: 3

        SolidSquare {
            size: dual ? 7 : 6
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1.5
            width: Math.max(4, rowWidth - 11)
            TextLine { lineWidth: parent.width * 0.92 }
            TextLine {
                visible: dual
                lineWidth: parent.width * 0.5
            }
        }
    }

    // Category row: hollow icon + label
    component CatRow: Row {
        property real rowWidth: 40
        width: rowWidth
        height: 7
        spacing: 3

        HollowSquare {
            size: 6
            anchors.verticalCenter: parent.verticalCenter
        }
        TextLine {
            anchors.verticalCenter: parent.verticalCenter
            lineWidth: Math.max(4, rowWidth - 11)
        }
    }

    // Place row: symbolic icon + short label
    component PlaceRow: Row {
        property real rowWidth: 36
        property string iconName: "folder"
        width: rowWidth
        height: 8
        spacing: 3

        InkIcon {
            source: iconName
            size: 7
            anchors.verticalCenter: parent.verticalCenter
        }
        TextLine {
            anchors.verticalCenter: parent.verticalCenter
            lineWidth: Math.max(4, rowWidth - 12)
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        // Do not derive margins from this item's own layout-managed size.
        // That feeds width/height back into ColumnLayout and produced one
        // binding loop per preview card while switching layouts.
        anchors.margins: Math.max(2, Kirigami.Units.smallSpacing / 2)
        radius: 3
        color: "transparent"
        border.width: 1.5
        border.color: root.ink
        clip: true

        // ===================== Prismenu =====================
        // Left: pinned apps (solid icons + lines)
        // Right: user + places icons + session circles
        // Bottom: search (magnifier) under left column
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "arcmenu"

            Column {
                id: arcApps
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.2
                width: parent.width * 0.52
                spacing: Math.max(2, height / 30)
                Repeater {
                    model: 7
                    AppRow {
                        rowWidth: arcApps.width
                        dual: false
                    }
                }
            }

            Column {
                id: arcPlaces
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                width: parent.width * 0.4
                spacing: Math.max(2, height / 28)

                PlaceRow {
                    rowWidth: arcPlaces.width
                    iconName: "user-identity"
                }
                PlaceRow { rowWidth: arcPlaces.width; iconName: "user-home" }
                PlaceRow { rowWidth: arcPlaces.width; iconName: "folder-documents" }
                PlaceRow { rowWidth: arcPlaces.width; iconName: "folder-download" }
                PlaceRow { rowWidth: arcPlaces.width; iconName: "folder-music" }
                PlaceRow { rowWidth: arcPlaces.width; iconName: "folder-pictures" }
                PlaceRow { rowWidth: arcPlaces.width; iconName: "preferences-system" }
            }

            // Search under left
            Item {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * 0.52
                height: parent.height * 0.16

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.ink
                }
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 7
                }
            }

            // Session: logout / lock / power
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 4
                InkIcon { source: "system-log-out"; size: 8 }
                InkIcon { source: "system-lock-screen"; size: 8 }
                InkIcon { source: "system-shutdown"; size: 8 }
            }
        }

        // ===================== Brisk =====================
        // Search top | cats left (+ software/settings) | apps right | session bottom
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "brisk"

            Rectangle {
                id: briskSearch
                height: parent.height * 0.13
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 7
                }
            }

            Column {
                id: briskCats
                anchors.left: parent.left
                anchors.top: briskSearch.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.2
                width: parent.width * 0.36
                spacing: Math.max(2, height / 32)
                Repeater {
                    model: 5
                    CatRow { rowWidth: briskCats.width }
                }
                // Software + Settings (solid)
                Item { height: 2; width: 1 }
                AppRow { rowWidth: briskCats.width; dual: false }
                AppRow { rowWidth: briskCats.width; dual: false }
            }

            Column {
                id: briskApps
                anchors.right: parent.right
                anchors.top: briskSearch.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                width: parent.width * 0.58
                spacing: Math.max(2, height / 24)
                Repeater {
                    model: 6
                    AppRow {
                        rowWidth: briskApps.width
                        dual: true
                    }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 4
                InkIcon { source: "system-log-out"; size: 8 }
                InkIcon { source: "system-lock-screen"; size: 8 }
                InkIcon { source: "system-reboot"; size: 8 }
                InkIcon { source: "system-shutdown"; size: 8 }
            }
        }

        // ===================== Budgie =====================
        // Like Brisk but no software/settings extras, no session bar
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "budgie"

            Rectangle {
                id: budgieSearch
                height: parent.height * 0.13
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 7
                }
            }

            Column {
                id: budgieCats
                anchors.left: parent.left
                anchors.top: budgieSearch.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                width: parent.width * 0.38
                spacing: Math.max(2, height / 28)
                Repeater {
                    model: 7
                    CatRow { rowWidth: budgieCats.width }
                }
            }

            Column {
                id: budgieApps
                anchors.right: parent.right
                anchors.top: budgieSearch.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                width: parent.width * 0.56
                spacing: Math.max(2, height / 24)
                Repeater {
                    model: 6
                    AppRow {
                        rowWidth: budgieApps.width
                        dual: true
                    }
                }
            }
        }

        // ===================== Mint =====================
        // Left icon rail (settings/software/files + session) | search + cats | content
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "mint"

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.14
                spacing: 5
                InkIcon { source: "preferences-system"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
                InkIcon { source: "plasmadiscover"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
                InkIcon { source: "system-file-manager"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
                Item { height: 4; width: 1 }
                InkIcon { source: "system-log-out"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
                InkIcon { source: "system-lock-screen"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
                InkIcon { source: "system-shutdown"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
            }

            Rectangle {
                id: mintSearch
                height: parent.height * 0.12
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.18
                anchors.right: parent.right
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 6
                }
            }

            Column {
                id: mintCats
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.18
                anchors.top: mintSearch.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                width: parent.width * 0.34
                spacing: Math.max(2, height / 28)
                Repeater {
                    model: 6
                    CatRow { rowWidth: mintCats.width }
                }
            }

            Column {
                id: mintApps
                anchors.right: parent.right
                anchors.top: mintSearch.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                width: parent.width * 0.42
                spacing: Math.max(2, height / 22)
                Repeater {
                    model: 5
                    AppRow {
                        rowWidth: mintApps.width
                        dual: true
                    }
                }
            }
        }

        // ===================== Whisker =====================
        // Search | user + session | cats | apps
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "whisker"

            Rectangle {
                id: whiskerSearch
                height: parent.height * 0.12
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 6
                }
            }

            Item {
                id: whiskerUser
                anchors.top: whiskerSearch.bottom
                anchors.topMargin: 3
                width: parent.width
                height: parent.height * 0.14

                InkIcon {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    source: "user-identity"
                    size: 10
                }
                TextLine {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    lineWidth: 16
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    InkIcon { source: "preferences-system"; size: 7 }
                    InkIcon { source: "system-log-out"; size: 7 }
                    InkIcon { source: "system-lock-screen"; size: 7 }
                    InkIcon { source: "system-reboot"; size: 7 }
                    InkIcon { source: "system-shutdown"; size: 7 }
                }
            }

            Column {
                id: whiskerCats
                anchors.left: parent.left
                anchors.top: whiskerUser.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                width: parent.width * 0.4
                spacing: Math.max(2, height / 26)
                Repeater {
                    model: 6
                    CatRow { rowWidth: whiskerCats.width }
                }
            }

            Column {
                id: whiskerApps
                anchors.right: parent.right
                anchors.top: whiskerUser.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                width: parent.width * 0.54
                spacing: Math.max(2, height / 22)
                Repeater {
                    model: 5
                    AppRow {
                        rowWidth: whiskerApps.width
                        dual: true
                    }
                }
            }
        }

        // ===================== Pop =====================
        // Search | 6-col grid | bottom category tabs
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "pop"

            Rectangle {
                id: popSearch
                height: parent.height * 0.12
                width: parent.width * 0.92
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 6
                }
            }

            Grid {
                anchors.top: popSearch.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.16
                columns: 4
                rowSpacing: 4
                columnSpacing: 4
                Repeater {
                    model: 8
                    Column {
                        spacing: 2
                        width: Math.max(10, (frame.width - 28) / 4 - 3)
                        SolidSquare {
                            size: Math.max(8, parent.width * 0.5)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.8
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
                    Column {
                        required property int index
                        readonly property var icons: ["user-home", "applications-system", "applications-utilities"]
                        spacing: 2
                        InkIcon {
                            source: parent.icons[parent.index]
                            size: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }

        // ===================== searchGrid (Elementary / Dash) =====================
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "searchGrid"

            Rectangle {
                id: sgSearch
                height: parent.height * 0.14
                width: parent.width * 0.9
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 6
                }
            }

            Grid {
                anchors.top: sgSearch.bottom
                anchors.topMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                columns: 4
                rowSpacing: 5
                columnSpacing: 4
                Repeater {
                    model: 8
                    Column {
                        spacing: 2
                        width: Math.max(10, (frame.width - 28) / 4 - 3)
                        SolidSquare {
                            size: Math.max(8, parent.width * 0.5)
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

        // ===================== Plasma =====================
        // User+search header | list | bottom tabs (Pinned/Apps/Computer/Leave)
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "plasma"

            Row {
                id: plasmaHead
                anchors.top: parent.top
                width: parent.width
                height: parent.height * 0.16
                spacing: 4
                InkIcon {
                    source: "user-identity"
                    size: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: parent.width - 18
                    height: parent.height * 0.55
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.ink
                    InkIcon {
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.verticalCenter: parent.verticalCenter
                        source: "search"
                        size: 6
                    }
                }
            }

            Column {
                id: plasmaList
                anchors.top: plasmaHead.bottom
                anchors.topMargin: 3
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.18
                spacing: Math.max(2, height / 24)
                Repeater {
                    model: 5
                    AppRow {
                        rowWidth: plasmaList.width
                        dual: true
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Repeater {
                    model: 4
                    Column {
                        required property int index
                        readonly property var icons: [
                            "preferences-system-windows",
                            "view-app-grid-symbolic",
                            "computer",
                            "system-shutdown"
                        ]
                        spacing: 2
                        InkIcon {
                            source: parent.icons[parent.index]
                            size: 8
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

        // ===================== Redmond =====================
        // Left: search + app grid | Right: user + places + shortcuts + session
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "redmond"

            Rectangle {
                id: redSearch
                height: parent.height * 0.12
                width: parent.width * 0.6
                anchors.left: parent.left
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 6
                }
            }

            Grid {
                anchors.left: parent.left
                anchors.top: redSearch.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                width: parent.width * 0.6
                columns: 3
                rowSpacing: 4
                columnSpacing: 3
                Repeater {
                    model: 9
                    Column {
                        spacing: 2
                        width: Math.max(8, (parent.parent.width * 0.6 - 6) / 3 - 2)
                        SolidSquare {
                            size: Math.max(7, parent.width * 0.45)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.75
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
                width: parent.width * 0.34
                spacing: Math.max(2, height / 30)

                PlaceRow { rowWidth: redSide.width; iconName: "user-identity" }
                PlaceRow { rowWidth: redSide.width; iconName: "user-home" }
                PlaceRow { rowWidth: redSide.width; iconName: "folder-documents" }
                PlaceRow { rowWidth: redSide.width; iconName: "folder-download" }
                PlaceRow { rowWidth: redSide.width; iconName: "folder-music" }
                PlaceRow { rowWidth: redSide.width; iconName: "plasmadiscover" }
                PlaceRow { rowWidth: redSide.width; iconName: "preferences-system" }
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 3
                InkIcon { source: "system-log-out"; size: 7 }
                InkIcon { source: "system-lock-screen"; size: 7 }
                InkIcon { source: "system-reboot"; size: 7 }
                InkIcon { source: "system-shutdown"; size: 7 }
            }
        }

        // ===================== Eleven =====================
        // Search | pinned grid | frequent list | footer user + files/settings/power
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "eleven"

            Rectangle {
                id: elSearch
                height: parent.height * 0.12
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 6
                }
            }

            Grid {
                id: elGrid
                anchors.top: elSearch.bottom
                anchors.topMargin: 3
                anchors.left: parent.left
                width: parent.width
                columns: 4
                rowSpacing: 3
                columnSpacing: 3
                Repeater {
                    model: 4
                    Column {
                        spacing: 1
                        width: Math.max(8, (frame.width - 24) / 4 - 2)
                        SolidSquare {
                            size: Math.max(7, parent.width * 0.45)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.7
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Column {
                id: elFreq
                anchors.top: elGrid.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.16
                spacing: Math.max(2, height / 16)
                Repeater {
                    model: 3
                    AppRow {
                        rowWidth: elFreq.width * 0.48
                    }
                }
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.14

                InkIcon {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    source: "user-identity"
                    size: 9
                }
                TextLine {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    lineWidth: 14
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    InkIcon { source: "system-file-manager"; size: 8 }
                    InkIcon { source: "preferences-system"; size: 8 }
                    InkIcon { source: "system-shutdown"; size: 8 }
                }
            }
        }

        // ===================== A-Z =====================
        // Like Eleven but no frequent section
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "az"

            Rectangle {
                id: azSearch
                height: parent.height * 0.12
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 6
                }
            }

            Grid {
                anchors.top: azSearch.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.16
                columns: 4
                rowSpacing: 4
                columnSpacing: 3
                Repeater {
                    model: 8
                    Column {
                        spacing: 2
                        width: Math.max(8, (frame.width - 24) / 4 - 2)
                        SolidSquare {
                            size: Math.max(7, parent.width * 0.45)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.7
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.14
                InkIcon {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    source: "user-identity"
                    size: 9
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    InkIcon { source: "system-file-manager"; size: 8 }
                    InkIcon { source: "preferences-system"; size: 8 }
                    InkIcon { source: "system-shutdown"; size: 8 }
                }
            }
        }

        // ===================== Insider =====================
        // Left rail (menu/files/settings/power) | avatar + search + grid
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "insider"

            Item {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.14

                InkIcon {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "application-menu"
                    size: 8
                }
                Column {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    InkIcon { source: "system-file-manager"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
                    InkIcon { source: "preferences-system"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
                    InkIcon { source: "system-shutdown"; size: 8; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.18
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 4

                InkIcon {
                    source: "user-identity"
                    size: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                TextLine {
                    lineWidth: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle {
                    height: Math.max(10, parent.height * 0.12)
                    width: parent.width
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.ink
                    InkIcon {
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.verticalCenter: parent.verticalCenter
                        source: "search"
                        size: 6
                    }
                }
                Grid {
                    width: parent.width
                    columns: 4
                    rowSpacing: 3
                    columnSpacing: 3
                    Repeater {
                        model: 8
                        Column {
                            spacing: 1
                            width: Math.max(8, (frame.width * 0.78 - 12) / 4 - 2)
                            SolidSquare {
                                size: Math.max(7, parent.width * 0.45)
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            TextLine {
                                lineWidth: parent.width * 0.7
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }

        // ===================== Enterprise =====================
        // Header user|search | cats left + session | content grid right
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "enterprise"

            Row {
                id: entHead
                anchors.top: parent.top
                width: parent.width
                height: parent.height * 0.14
                spacing: 4
                InkIcon {
                    source: "user-identity"
                    size: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextLine {
                    anchors.verticalCenter: parent.verticalCenter
                    lineWidth: 12
                }
                Rectangle {
                    width: parent.width * 0.55
                    height: parent.height * 0.55
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.ink
                    InkIcon {
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        source: "search"
                        size: 5
                    }
                }
            }

            Column {
                id: entCats
                anchors.left: parent.left
                anchors.top: entHead.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                width: parent.width * 0.38
                spacing: Math.max(2, height / 28)
                Repeater {
                    model: 6
                    CatRow { rowWidth: entCats.width }
                }
            }

            Grid {
                anchors.right: parent.right
                anchors.top: entHead.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.05
                width: parent.width * 0.56
                columns: 3
                rowSpacing: 3
                columnSpacing: 3
                Repeater {
                    model: 6
                    Column {
                        spacing: 1
                        width: Math.max(8, (parent.parent.width * 0.56 - 6) / 3 - 1)
                        SolidSquare {
                            size: Math.max(7, parent.width * 0.45)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        TextLine {
                            lineWidth: parent.width * 0.7
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 3
                InkIcon { source: "system-log-out"; size: 7 }
                InkIcon { source: "system-lock-screen"; size: 7 }
                InkIcon { source: "system-reboot"; size: 7 }
                InkIcon { source: "system-shutdown"; size: 7 }
            }
        }

        // ===================== Windows rail =====================
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
                    InkIcon {
                        required property int index
                        readonly property var icons: ["user-home", "folder", "preferences-system", "system-log-out", "system-shutdown"]
                        source: icons[index]
                        size: 8
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
                anchors.bottomMargin: parent.height * 0.12
                width: parent.width * 0.42
                spacing: Math.max(2, height / 24)
                Repeater {
                    model: 5
                    AppRow {
                        rowWidth: winList.width
                        dual: true
                    }
                }
            }

            Grid {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.12
                width: parent.width * 0.36
                columns: 2
                rowSpacing: 4
                columnSpacing: 3
                Repeater {
                    model: 6
                    SolidSquare {
                        size: Math.max(8, (parent.parent.width * 0.36 - 3) / 2 - 2)
                    }
                }
            }
        }

        // ===================== Plasma 6 Kickoff =====================
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "kickoff6"

            Row {
                id: kickoffHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height * 0.14
                spacing: 3

                InkIcon { source: "user-identity"; size: kickoffHeader.height * 0.72 }
                TextLine { lineWidth: parent.width * 0.12; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    width: parent.width * 0.58
                    height: parent.height * 0.8
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.ink
                    InkIcon {
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.verticalCenter: parent.verticalCenter
                        source: "search"
                        size: 6
                    }
                }
                InkIcon { source: "configure"; size: kickoffHeader.height * 0.65 }
                InkIcon { source: "window-pin"; size: kickoffHeader.height * 0.65 }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: kickoffHeader.bottom
                height: 1
                color: root.inkSoft
            }

            Column {
                id: kickoffNav
                anchors.left: parent.left
                anchors.top: kickoffHeader.bottom
                anchors.topMargin: 3
                anchors.bottom: kickoffFooter.top
                width: parent.width * 0.25
                spacing: 3
                Repeater {
                    model: 8
                    CatRow { rowWidth: kickoffNav.width }
                }
            }

            Rectangle {
                anchors.left: kickoffNav.right
                anchors.top: kickoffHeader.bottom
                anchors.bottom: kickoffFooter.top
                width: 1
                color: root.inkSoft
            }

            Grid {
                anchors.left: kickoffNav.right
                anchors.leftMargin: 6
                anchors.right: parent.right
                anchors.top: kickoffHeader.bottom
                anchors.topMargin: 6
                anchors.bottom: kickoffFooter.top
                columns: 5
                rowSpacing: 4
                columnSpacing: 5
                Repeater {
                    model: 20
                    SolidSquare { size: Math.max(6, (parent.parent.width * 0.68 - 24) / 5) }
                }
            }

            Row {
                id: kickoffFooter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.13
                spacing: 5
                InkIcon { source: "view-app-grid-symbolic"; size: kickoffFooter.height * 0.65 }
                TextLine { lineWidth: parent.width * 0.12; anchors.verticalCenter: parent.verticalCenter }
                InkIcon { source: "compass"; size: kickoffFooter.height * 0.65 }
                Item { width: parent.width * 0.28; height: 1 }
                InkIcon { source: "system-suspend"; size: kickoffFooter.height * 0.65 }
                InkIcon { source: "system-reboot"; size: kickoffFooter.height * 0.65 }
                InkIcon { source: "system-shutdown"; size: kickoffFooter.height * 0.65 }
                InkIcon { source: "system-log-out"; size: kickoffFooter.height * 0.65 }
            }
        }

        // ===================== Raven =====================
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
                    model: 5
                    InkIcon {
                        required property int index
                        readonly property var icons: ["view-app-grid-symbolic", "folder", "preferences-system", "system-log-out", "system-shutdown"]
                        source: icons[index]
                        size: 8
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
                InkIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    source: "search"
                    size: 6
                }
            }

            Column {
                id: ravenList
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.2
                anchors.right: parent.right
                anchors.top: ravenSearch.bottom
                anchors.topMargin: 3
                anchors.bottom: parent.bottom
                spacing: Math.max(2, height / 20)
                Repeater {
                    model: 5
                    AppRow {
                        rowWidth: ravenList.width
                        dual: true
                    }
                }
            }
        }

        // ===================== Runner / Simple =====================
        Item {
            anchors.fill: parent
            anchors.margins: 5
            visible: root.previewKind === "runner"

            Rectangle {
                width: parent.width * 0.8
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
                        InkIcon {
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            source: "search"
                            size: 6
                        }
                    }

                    Repeater {
                        model: 4
                        AppRow {
                            rowWidth: runnerCol.width
                            dual: true
                        }
                    }
                }
            }
        }
    }
}
