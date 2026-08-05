import QtQuick

/**
 * Converts a JS array of objects into a ListModel for ListView/GridView.
 */
ListModel {
    id: root
    property var source: []

    function rebuild() {
        clear();
        var arr = source || [];
        for (var i = 0; i < arr.length; ++i) {
            append(arr[i]);
        }
    }

    onSourceChanged: rebuild()
    Component.onCompleted: rebuild()
}
