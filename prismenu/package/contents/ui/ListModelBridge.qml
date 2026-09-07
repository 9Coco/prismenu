import QtQuick

/**
 * Converts a JS array of objects into a ListModel for ListView/GridView.
 *
 * wrapApp: expose only the source object's stable id under `appId`.  Do not
 * put the complete Kicker object in ListModel: it may contain QIcon and other
 * native values which ListModel coerces into unusable JS values.
 *
 * A pure reordering of the same id set is applied with move() so attached
 * views emit rowsMoved and animate the shift instead of rebuilding every
 * delegate (launcher-style drag preview).
 */
ListModel {
    id: root
    property var source: []
    property bool wrapApp: false
    /**
     * Kickoff-style live reorder freezes the source binding so a parent
     * JS-array rebuild cannot wipe in-flight move / moveDisplaced slides.
     */
    property bool freezeSource: false

    function _keyOf(item) {
        return (item && item.id !== undefined) ? String(item.id) : "";
    }

    function _appendOne(item) {
        if (wrapApp)
            append({ appId: _keyOf(item) });
        else
            append(item);
    }

    function appIdAt(row) {
        if (row < 0 || row >= count)
            return "";
        var cur = get(row);
        if (wrapApp)
            return String(cur.appId || "");
        return String((cur && (cur.id || cur.appId)) || "");
    }

    function freeze() {
        freezeSource = true;
    }

    function unfreeze() {
        if (!freezeSource)
            return;
        freezeSource = false;
        syncFromSource();
    }

    function rebuild() {
        clear();
        var arr = source || [];
        for (var i = 0; i < arr.length; ++i)
            _appendOne(arr[i]);
    }

    function _rowKey(row) {
        var cur = get(row);
        return wrapApp ? String(cur.appId || "") : _keyOf(cur);
    }

    function syncFromSource() {
        if (freezeSource)
            return;
        var arr = source || [];
        if (arr.length !== count) {
            rebuild();
            return;
        }
        var newKeys = [];
        var allKeyed = true;
        for (var i = 0; i < arr.length; ++i) {
            var nk = _keyOf(arr[i]);
            if (!nk) {
                allKeyed = false;
                break;
            }
            newKeys.push(nk);
        }
        var oldKeys = [];
        if (allKeyed) {
            for (var r = 0; r < count; ++r) {
                var k = _rowKey(r);
                if (!k) {
                    allKeyed = false;
                    break;
                }
                oldKeys.push(k);
            }
        }
        if (!allKeyed) {
            rebuild();
            return;
        }
        var sortedOld = oldKeys.slice().sort();
        var sortedNew = newKeys.slice().sort();
        var sameSet = true;
        for (var s = 0; s < sortedOld.length; ++s) {
            if (sortedOld[s] !== sortedNew[s]) {
                sameSet = false;
                break;
            }
        }
        if (!sameSet) {
            rebuild();
            return;
        }
        // Same id set, different order → walk the target order and move
        // displaced rows so the view receives rowsMoved (animated shift).
        var moved = false;
        for (var t = 0; t < newKeys.length; ++t) {
            if (_rowKey(t) === newKeys[t])
                continue;
            var fromIdx = -1;
            for (var f = t + 1; f < count; ++f) {
                if (_rowKey(f) === newKeys[t]) {
                    fromIdx = f;
                    break;
                }
            }
            if (fromIdx >= 0) {
                move(fromIdx, t, 1);
                moved = true;
            }
        }
        // wrapApp rows only store an id; set() would reset delegates and
        // cancel the move animation Kickoff relies on.
        if (wrapApp)
            return;
        if (!moved) {
            for (var u = 0; u < arr.length; ++u)
                set(u, arr[u]);
        }
    }

    onSourceChanged: {
        if (!freezeSource)
            syncFromSource();
    }
    Component.onCompleted: syncFromSource()
}
