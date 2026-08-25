import QtQuick

/** SearchField pre-wired to the shared LayoutBase contract. */
SearchField {
    id: root

    required property var layoutRoot

    menuData: layoutRoot ? layoutRoot.menuData : null
    placeholder: menuData ? menuData.searchPlaceholder : layoutRoot.tr("Search…")
    text: menuData ? menuData.searchQuery : ""

    Connections {
        target: root
        function onTextChanged() {
            if (root.menuData)
                root.menuData.setSearch(root.text);
        }
    }
}
