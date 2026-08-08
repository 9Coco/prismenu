import QtQuick
import org.kde.kirigami as Kirigami

/**
 * Circular user avatar — supports theme icon names and file:// face images.
 */
Item {
    id: root

    property string userIcon: "user-identity"
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
        var s = String(root.userIcon || "");
        if (!s || s === "user-identity")
            return "";
        if (s.indexOf("file:") === 0 || s.indexOf("image:") === 0)
            return s;
        if (s.indexOf("/") === 0)
            return "file://" + s;
        return "";
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
        color: "transparent"

        Image {
            id: faceImg
            anchors.fill: parent
            source: root.faceSrc
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
            cache: false
        }

        Kirigami.Icon {
            anchors.fill: parent
            anchors.margins: Math.max(2, width * 0.12)
            visible: !faceImg.visible
            source: root.faceSrc.length
                ? "user-identity"
                : (root.userIcon || "user-identity")
            color: root.fallbackColor
        }
    }
}
