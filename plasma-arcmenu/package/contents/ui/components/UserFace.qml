import QtQuick
import org.kde.kirigami as Kirigami

/**
 * Circular user avatar — loads staged file:// PNG (see AppsBackend.refreshUserMeta).
 * Kirigami.Avatar is not available in all Plasma plasmoid Kirigami builds.
 */
Item {
    id: root

    property string userIcon: "user-identity"
    property string userName: ""
    property color fallbackColor: Kirigami.Theme.textColor
    property bool showRing: true
    /** circle | square | rounded */
    property string shape: "circle"

    property int _faceRev: 0

    readonly property real faceRadius: {
        if (shape === "square")
            return 0;
        if (shape === "rounded")
            return Math.min(width, height) * 0.22;
        return width / 2;
    }

    readonly property string facePath: {
        var s = String(root.userIcon || "").trim();
        if (!s || s === "user-identity")
            return "";
        if (s.indexOf("file:") === 0) {
            // strip query if present
            var q = s.indexOf("?");
            return q >= 0 ? s.substring(0, q) : s;
        }
        if (s.indexOf("/") === 0)
            return "file://" + s;
        return "";
    }

    // Kickoff-style cache bust so Image reloads when the face file changes
    readonly property string faceSrc: facePath.length
        ? (facePath + "?rev=" + _faceRev)
        : ""

    readonly property string initials: {
        var n = String(root.userName || "").trim();
        if (!n.length)
            return "";
        return n.charAt(0).toUpperCase();
    }

    readonly property bool faceReady: faceImg.status === Image.Ready
    readonly property bool faceFailed: facePath.length > 0
        && (faceImg.status === Image.Error || faceImg.status === Image.Null)

    onUserIconChanged: _faceRev++
    onFacePathChanged: {
        if (facePath.length)
            console.log("ArcMenu UserFace path:", facePath);
    }

    Rectangle {
        anchors.fill: parent
        visible: root.showRing
        radius: root.faceRadius
        color: "transparent"
        border.color: root.fallbackColor
        border.width: 1
        opacity: 0.35
        z: 2
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
            // Local faces: sync load avoids stuck Loading state in plasmoid
            asynchronous: false
            cache: true
            smooth: true
            mipmap: true
            visible: status === Image.Ready
            onStatusChanged: {
                if (status === Image.Error)
                    console.warn("ArcMenu UserFace decode error:", root.facePath);
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.faceReady && root.initials.length > 0
            text: root.initials
            color: Kirigami.Theme.highlightedTextColor
            font.pixelSize: Math.max(10, Math.round(root.height * 0.42))
            font.bold: true
            z: 1
        }

        Kirigami.Icon {
            anchors.fill: parent
            anchors.margins: Math.max(2, width * 0.12)
            visible: !root.faceReady && root.initials.length === 0
            source: "user-identity"
            color: root.fallbackColor
        }
    }
}
