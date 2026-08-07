import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/**
 * Simplified wireframe preview of a menu layout (ArcMenu-style settings cards).
 */
Item {
    id: root

    property string layoutId: "arcmenu"
    property color lineColor: Kirigami.Theme.textColor
    property real lineOpacity: 0.55

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
        case "sleek":
        case "eleven":
        case "insider": return "gridSidebar";
        case "windows": return "windows";
        case "zest":
        case "enterprise": return "threeCol";
        case "raven": return "raven";
        case "az":
        case "kicker":
        case "simple": return "runner";
        default: return "sidebarTopSearch";
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: Math.max(2, Math.round(Math.min(width, height) * 0.04))
        radius: 3
        color: "transparent"
        border.width: 1.5
        border.color: root.lineColor
        opacity: root.lineOpacity
        clip: true

        // ---- templates (only one visible) ----

        // ArcMenu: left pinned + right places, search bottom-left
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "arcmenu"

            Rectangle {
                width: parent.width * 0.55
                height: parent.height * 0.72
                anchors.left: parent.left
                anchors.top: parent.top
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                width: parent.width * 0.38
                height: parent.height * 0.72
                anchors.right: parent.right
                anchors.top: parent.top
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                width: parent.width * 0.55
                height: parent.height * 0.18
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
        }

        // Brisk / Budgie / GNOME: search top, sidebar left, list right
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "sidebarTopSearch"

            Rectangle {
                height: parent.height * 0.16
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                width: parent.width * 0.32
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.22
                anchors.bottom: parent.bottom
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Column {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.22
                anchors.bottom: parent.bottom
                width: parent.width * 0.62
                spacing: 3
                Repeater {
                    model: 5
                    Rectangle {
                        width: parent.width
                        height: Math.max(3, (parent.height - 12) / 5)
                        radius: 1
                        color: "transparent"
                        border.width: 1
                        border.color: root.lineColor
                    }
                }
            }
        }

        // Mint / Tognee: icon rail + content
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "iconRail"

            Rectangle {
                width: parent.width * 0.16
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                width: parent.width * 0.28
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.2
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.2
                width: parent.width * 0.48
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                height: parent.height * 0.14
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.2
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
        }

        // Whisker: user bar top, cats + apps, search bottom
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "whisker"

            Rectangle {
                height: parent.height * 0.2
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                width: parent.width * 0.36
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.26
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.18
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                width: parent.width * 0.58
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.26
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.18
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                height: parent.height * 0.14
                width: parent.width
                anchors.bottom: parent.bottom
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
        }

        // Search + app grid (Elementary / Chromebook / Pop / Dash)
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "searchGrid"

            Rectangle {
                height: parent.height * 0.16
                width: parent.width * 0.9
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Grid {
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.24
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 4
                rowSpacing: 4
                columnSpacing: 4
                Repeater {
                    model: 12
                    Rectangle {
                        width: Math.max(6, (frame.width - 24) / 4 - 4)
                        height: width
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.lineColor
                    }
                }
            }
        }

        // Tall list (Plasma / Unity / Kickoff)
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "tallList"

            Rectangle {
                height: parent.height * 0.18
                width: parent.width
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Column {
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.24
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.16
                spacing: 3
                Repeater {
                    model: 6
                    Rectangle {
                        width: parent.width
                        height: Math.max(3, (parent.height - 15) / 6)
                        radius: 1
                        color: "transparent"
                        border.width: 1
                        border.color: root.lineColor
                    }
                }
            }
            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Repeater {
                    model: 4
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.lineColor
                    }
                }
            }
        }

        // Grid + right sidebar (Redmond / Sleek / Eleven / Insider)
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "gridSidebar"

            Grid {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                width: parent.width * 0.68
                columns: 3
                rowSpacing: 3
                columnSpacing: 3
                Repeater {
                    model: 9
                    Rectangle {
                        width: Math.max(6, (parent.width - 6) / 3 - 2)
                        height: width * 0.75
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.lineColor
                    }
                }
            }
            Rectangle {
                width: parent.width * 0.26
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.14
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                height: parent.height * 0.1
                width: parent.width
                anchors.bottom: parent.bottom
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
        }

        // Windows: rail + list + pinned
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "windows"

            Rectangle {
                width: parent.width * 0.12
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                width: parent.width * 0.42
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.16
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.16
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Grid {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.16
                width: parent.width * 0.36
                columns: 2
                rowSpacing: 3
                columnSpacing: 3
                Repeater {
                    model: 6
                    Rectangle {
                        width: Math.max(5, (parent.width - 3) / 2 - 1)
                        height: width
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.lineColor
                    }
                }
            }
            Rectangle {
                height: parent.height * 0.12
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.16
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
        }

        // Three columns (Zest / Enterprise)
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "threeCol"

            Row {
                anchors.fill: parent
                anchors.bottomMargin: parent.height * 0.16
                spacing: 3
                Rectangle {
                    width: parent.width * 0.28
                    height: parent.height
                    color: "transparent"
                    border.width: 1
                    border.color: root.lineColor
                }
                Rectangle {
                    width: parent.width * 0.28
                    height: parent.height
                    color: "transparent"
                    border.width: 1
                    border.color: root.lineColor
                }
                Rectangle {
                    width: parent.width * 0.4 - 6
                    height: parent.height
                    color: "transparent"
                    border.width: 1
                    border.color: root.lineColor
                }
            }
            Rectangle {
                height: parent.height * 0.12
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.3
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
        }

        // Raven: tall left rail
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "raven"

            Rectangle {
                width: parent.width * 0.18
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Rectangle {
                height: parent.height * 0.14
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.22
                anchors.right: parent.right
                anchors.top: parent.top
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: root.lineColor
            }
            Column {
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.22
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.2
                anchors.bottom: parent.bottom
                spacing: 3
                Repeater {
                    model: 4
                    Rectangle {
                        width: parent.width
                        height: Math.max(4, (parent.height - 9) / 4)
                        radius: 1
                        color: "transparent"
                        border.width: 1
                        border.color: root.lineColor
                    }
                }
            }
        }

        // Runner / Simple / A-Z / Kicker: centered list
        Item {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.previewKind === "runner"

            Rectangle {
                width: parent.width * 0.7
                height: parent.height * 0.75
                anchors.centerIn: parent
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: root.lineColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 3
                    Rectangle {
                        width: parent.width
                        height: parent.height * 0.18
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.lineColor
                    }
                    Repeater {
                        model: 4
                        Rectangle {
                            width: parent.width
                            height: Math.max(3, (parent.height * 0.7) / 4 - 2)
                            radius: 1
                            color: "transparent"
                            border.width: 1
                            border.color: root.lineColor
                        }
                    }
                }
            }
        }
    }
}
