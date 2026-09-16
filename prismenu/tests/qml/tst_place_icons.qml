import QtQuick
import QtTest
import org.kde.kirigami as Kirigami
import "../../package/contents/ui" as Menu
import "../../package/contents/ui/components" as Components
import "../../package/contents/ui/config" as Config
import "../../package/contents/ui/layouts" as Layouts

TestCase {
    id: testCase
    name: "PlaceIcons"
    when: windowShown
    visible: true
    width: 480
    height: 320

    Menu.PlasmaNative { id: backend }
    Menu.MenuData { id: layoutData }
    Layouts.LayoutBase {
        id: layoutBase
        themeStyle: ({ activeBg: "#3daee9", activeFg: "#ffffff" })
    }
    QtObject { id: liveHolder; property var decoration: null }

    Config.ConfigSettingRow {
        id: settingsRow
        x: 220
        y: 60
        width: 240
        height: implicitHeight
        iconName: "folder"
    }

    QtObject {
        id: sidebarData
        property string uiLang: "en_US"
        property bool showUserAvatar: false
        property string userName: "Test"
        property var placeSections: []
    }

    Components.PlacesSidebar {
        id: sidebar
        width: 200
        height: 240
        menuData: sidebarData
        showSystemShortcuts: false
        fg: "#ff0000"
    }

    Components.ResolvedIcon {
        id: standalone
        x: 220
        width: 22
        height: 22
        animated: false
        iconName: "folder"
        tintColor: sidebar.fg
        preferSymbolic: sidebar.preferSymbolic
    }

    Kirigami.Icon {
        id: reference
        x: 260
        width: standalone.width
        height: standalone.height
        animated: false
        color: standalone.color
        isMask: standalone.isMask
    }

    function initTestCase() {
        tryVerify(() => backend.placesEntries.length > 0);
        verify(backend.placesEntries.some(item => typeof item.decoration !== "string"),
               "The KDE Places fixture must supply native QIcons, not just icon names");
    }

    function init() {
        sidebar.preferSymbolic = true;
        sidebarData.placeSections = [];
        liveHolder.decoration = null;
        standalone.iconItem = null;
        standalone.iconName = "folder";
        settingsRow.iconItem = null;
        settingsRow.iconName = "folder";
    }

    function nativePlaces() {
        return backend.placesEntries.filter(item => typeof item.decoration !== "string");
    }

    function resolvedIcons(item) {
        let icons = [];
        if (item.iconName !== undefined && item.valid !== undefined)
            icons.push(item);
        for (const child of item.children || [])
            icons = icons.concat(resolvedIcons(child));
        return icons;
    }

    function sidebarIcon(item) {
        sidebarData.placeSections = [{ id: "system", items: [item] }];
        tryVerify(() => resolvedIcons(sidebar).length === 1);
        const icon = resolvedIcons(sidebar)[0];
        icon.animated = false;
        return icon;
    }

    function imageOf(icon) {
        tryCompare(icon, "valid", true);
        wait(30);
        return grabImage(icon);
    }

    function compareWithNative(icon, decoration) {
        compare(icon.source, decoration, "Place icon must preserve the native decoration");
        compare(icon.isMask, sidebar.preferSymbolic);
        standalone.iconItem = icon.iconItem;
        reference.source = decoration;
        verify(imageOf(standalone).equals(imageOf(reference)),
               "Native decoration must render identically to Kirigami.Icon");
    }

    function test_nativeSidebar_data() {
        const rows = [];
        for (let i = 0; i < backend.placesEntries.length; ++i) {
            const item = backend.placesEntries[i];
            if (typeof item.decoration === "string")
                continue;
            rows.push({ tag: "place-" + i + "-symbolic", item: item, symbolic: true });
            rows.push({ tag: "place-" + i + "-color", item: item, symbolic: false });
        }
        return rows;
    }

    function test_nativeSidebar(row) {
        sidebar.preferSymbolic = row.symbolic;
        compareWithNative(sidebarIcon(row.item), row.item.iconHolder.decoration);
    }

    function test_snapshotDecoration() {
        const decoration = nativePlaces()[0].decoration;
        compareWithNative(sidebarIcon({ name: "Place", icon: "folder", decoration: decoration }), decoration);
    }

    function test_liveDecorationUpdates() {
        const places = nativePlaces();
        verify(places.length >= 2);
        liveHolder.decoration = places[0].decoration;
        const icon = sidebarIcon({ name: "Place", icon: "folder", iconHolder: liveHolder });
        compareWithNative(icon, liveHolder.decoration);
        liveHolder.decoration = places[1].decoration;
        compareWithNative(icon, liveHolder.decoration);
        liveHolder.decoration = null;
        compare(icon.source, "folder-symbolic");
    }

    function test_settingsDecoration() {
        const place = nativePlaces()[0];
        settingsRow.iconName = "";
        settingsRow.iconItem = place;
        const icons = resolvedIcons(settingsRow);
        compare(icons.length, 1);
        verify(icons[0].visible, "A native-only icon must not hide the settings badge");
        compare(icons[0].source, place.iconHolder.decoration);
        compare(icons[0].isMask, false);
    }

    function test_railDecorationUpdates() {
        const places = nativePlaces();
        liveHolder.decoration = places[0].decoration;
        const rails = layoutBase.asRailItems([{
            id: "test-place", name: "Place", icon: "folder",
            decoration: places[0].decoration, iconHolder: liveHolder,
            kickerUrl: "file:///example"
        }]);
        compare(rails.length, 1);
        compare(rails[0].iconHolder, liveHolder);
        compare(rails[0].decoration, places[0].decoration);
        compare(rails[0].kickerUrl, "file:///example");
        standalone.iconItem = rails[0];
        compare(standalone.source, liveHolder.decoration);
        liveHolder.decoration = places[1].decoration;
        compare(standalone.source, liveHolder.decoration);
    }

    function test_layoutConsumers_data() {
        return ["Redmond", "Windows", "Sleek", "Zest", "Unity", "Tognee"].map(name => ({ tag: name }));
    }

    function test_layoutConsumers(row) {
        const place = nativePlaces()[0];
        layoutData.plasmaPlaces = [place];
        const component = Qt.createComponent("../../package/contents/ui/layouts/Layout" + row.tag + ".qml");
        tryCompare(component, "status", Component.Ready);
        const layout = createTemporaryObject(component, testCase, {
            width: 760, height: 600, visible: false, menuData: layoutData,
            themeStyle: { activeBg: "#3daee9", activeFg: "#ffffff" }
        });
        verify(layout !== null, component.errorString());
        const icons = resolvedIcons(layout).filter(icon => icon.iconItem && icon.iconItem.id === place.id);
        compare(icons.length, 1, row.tag + " must forward the place entry to the shared icon renderer");
        compare(icons[0].source, place.iconHolder.decoration);
        tryCompare(icons[0], "valid", true);
        component.destroy();
    }

    function test_stringSources_data() {
        const customPath = String(Qt.resolvedUrl("../../package/contents/icons/categories/prismenu-cat-tools-build.svg")).replace(/^file:\/\//, "");
        return [
            { tag: "plain-folder", item: { icon: "folder" }, symbolic: false, source: "folder" },
            { tag: "symbolic-folder", item: { icon: "folder" }, symbolic: true, source: "folder-symbolic" },
            { tag: "string-decoration", item: { icon: "folder", decoration: "folder-music" }, symbolic: false, source: "folder-music" },
            { tag: "missing-decoration", item: { icon: "folder", decoration: null }, symbolic: false, source: "folder" },
            { tag: "custom-file", item: { icon: customPath }, symbolic: true, source: "file://" + customPath },
            { tag: "empty-item", item: null, symbolic: false, source: "folder" }
        ];
    }

    function test_stringSources(row) {
        standalone.iconItem = row.item;
        sidebar.preferSymbolic = row.symbolic;
        compare(standalone.source, row.source);
        tryCompare(standalone, "valid", true);
    }

    function test_bundledItemIcons() {
        standalone.iconItem = { icon: "prismenu-cat-tools-build" };
        verify(standalone.bundled);
        verify(standalone.isMask);
        tryCompare(standalone, "valid", true);
        sidebar.preferSymbolic = false;
        standalone.iconItem = { icon: "distro-ubuntu" };
        verify(standalone.preset);
        verify(!standalone.isMask);
        tryCompare(standalone, "valid", true);
    }
}
