import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.TextField {
    id: root

    property string placeholder: i18n("Search applications…")
    property bool searching: text.length > 0

    placeholderText: placeholder
    clearButtonShown: true
    Accessible.name: i18n("Search")
    Accessible.role: Accessible.EditableText
    focus: true

    Keys.onEscapePressed: (event) => {
        if (text.length > 0) {
            text = "";
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    Keys.onDownPressed: (event) => {
        event.accepted = false;
    }
}
