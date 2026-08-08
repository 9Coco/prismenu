import QtQuick
import org.kde.kirigami as Kirigami

/**
 * Circular user avatar — file:// face images (prefer staged *.png cache) or theme icon.
 * Note: Kirigami.Avatar is unavailable in some Plasma plasmoid Kirigami builds.
 */
Item {
    id: root

    property string userIcon: "user-identity"
    property string userName: ""
    property color fallbackColor: Kirigami.Theme.textColor
    property bool showRing: true
    /** circle | square | rounded */
    property string shape: "circle"

    readonly property real faceRadius: {
        if (shape === "square")
            return 0;
        if (shape === "rounded")
            return Math.min(width, height) * 0.22;
        return width / 2;
    }

    readonly property string faceSrc: {
        var s = String(root.userIcon || "").trim();
        if (!s || s === "user-identity")
            return "";
        if (s.indexOf("file:") === 0 || s.indexOf("image:") === 0)
            return s;
        if (s.indexOf("/") === 0)
            return "file://" + s;
        return "";
    }

    readonly property string initials: {
        var n = String(root.userName || "").trim();
        if (!n.length)
            return "";
        return n.charAt(0).toUpperCase();
    }

    Rectangle {
        anchors.fill: parent
        visible: root.showRing
        radius: root.faceRadius
        color: "transparent"
        border.color: root.fallbackColor
        border.width: 1
        opacity: 0.35
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.showRing ? 1 : 0
        radius: root.faceRadius
        clip: true
        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.35)

        Image {
            id: faceImg
            anchors.fill: parent
            source: root.faceSrc
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
            cache: false
        }

        Text {
            anchors.centerIn: parent
            visible: !faceImg.visible && root.initials.length > 0
            text: root.initials
            color: Kirigami.Theme.highlightedTextColor
            font.pixelSize: Math.max(10, Math.round(root.height * 0.42))
            font.bold: true
        }

        Kirigami.Icon {
            anchors.fill: parent
            anchors.margins: Math.max(2, width * 0.12)
            visible: !faceImg.visible && root.initials.length === 0
            source: "user-identity"
            color: root.fallbackColor
        }
    }
}
