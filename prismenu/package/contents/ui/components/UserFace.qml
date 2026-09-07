import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents

/**
 * User avatar — same stack as Plasma Kickoff Header.qml:
 *   import org.kde.kirigamiaddons.components as KirigamiComponents
 *   KirigamiComponents.Avatar {
 *       source: kuser.faceIconUrl
 *       name: kuser.fullName
 *       cache: false
 *   }
 *
 * Important: do not put this under a parent with clip: true — Avatar's layer
 * effect then renders as a solid black circle.
 */
Item {
    id: root

    property string userIcon: ""
    property string userName: ""
    property color fallbackColor: Kirigami.Theme.textColor
    property bool showRing: true
    /** circle | square | rounded — Kickoff is always circular; square uses plain Image */
    property string shape: "circle"

    readonly property url faceUrl: {
        var s = String(root.userIcon || "").trim();
        if (!s || s === "user-identity")
            return "";
        if (s.indexOf("file:") === 0 || s.indexOf("image:") === 0 || s.indexOf("http") === 0)
            return s;
        if (s.indexOf("/") === 0)
            return "file://" + s;
        return "";
    }

    // Kickoff-style circular avatar (kirigami-addons)
    KirigamiComponents.Avatar {
        id: avatar
        anchors.fill: parent
        anchors.margins: root.showRing ? 1 : 0
        visible: root.shape !== "square"
        name: root.userName
        source: root.faceUrl
        cache: false
        asynchronous: true
    }

    // Optional ring (Kickoff Avatar already clips to a circle)
    Rectangle {
        anchors.fill: parent
        visible: root.showRing && root.shape !== "square"
        radius: width / 2
        color: "transparent"
        border.color: root.fallbackColor
        border.width: 1
        opacity: 0.35
        z: 2
    }

    // Square shape only (settings option) — no circular crop
    Image {
        anchors.fill: parent
        anchors.margins: root.showRing ? 1 : 0
        visible: root.shape === "square"
        source: root.faceUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        visible: root.showRing && root.shape === "square"
        radius: 0
        color: "transparent"
        border.color: root.fallbackColor
        border.width: 1
        opacity: 0.35
        z: 2
    }
}
