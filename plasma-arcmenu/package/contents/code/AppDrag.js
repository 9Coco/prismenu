.pragma library

/**
 * Drag & drop protocol shared by every application item in ArcMenu.
 *
 * text/uri-list — the same MIME current Plasma Kickoff emits when an entry
 * is dragged out of the menu.  The value is an array containing the
 * applications: URL, which the desktop containment can turn into a link.
 *
 * application/x-arcmenu-reorder — internal marker carrying the app id so
 * app lists can reorder entries (or pin a new entry on a pinned view).
 */
var LAUNCHER_MIME = "text/uri-list";
var REORDER_MIME = "application/x-arcmenu-reorder";

/** Virtual applications: URL the launcher entry resolves to (Kickoff shape). */
function launcherUrl(app) {
    if (!app)
        return "";
    var url = String(app.kickerUrl || app.entryPath || "");
    if (url)
        return url;
    var id = String(app.id || "");
    if (id && id.indexOf(".desktop") >= 0)
        return "applications:" + id;
    return "";
}

/** Only real .desktop applications can be turned into desktop launchers. */
function canDragOut(app) {
    return launcherUrl(app).length > 0;
}

/** Drag payload for an application item (see MIME notes above). */
function mimeDataFor(app) {
    var out = {};
    var url = launcherUrl(app);
    if (url)
        out[LAUNCHER_MIME] = [url];
    var id = app ? String(app.id || "") : "";
    if (id)
        out[REORDER_MIME] = id;
    return out;
}

/** Event API shim: Qt ≥6.10 DragEvent exposes formats/getDataAsString
 *  directly; older builds go through event.mimeData (hasFormat,
 *  getDataAsByteArray). */
function eventFormats(event) {
    if (!event)
        return [];
    if (event.formats !== undefined)
        return event.formats;
    var md = event.mimeData;
    var out = [];
    if (md) {
        if (md.hasFormat(REORDER_MIME))
            out.push(REORDER_MIME);
        if (md.hasFormat(LAUNCHER_MIME))
            out.push(LAUNCHER_MIME);
    }
    return out;
}

function eventDataAsString(event, format) {
    if (!event)
        return "";
    try {
        if (event.getDataAsString)
            return String(event.getDataAsString(format) || "");
    } catch (e) {
        // fall through to the legacy mimeData path
    }
    var md = event.mimeData;
    if (md && md.getDataAsByteArray) {
        try {
            return String(md.getDataAsByteArray(format) || "");
        } catch (e2) {
            return "";
        }
    }
    return "";
}

/** True when a drag carries something a pinned view can consume. */
function isPinDrag(event) {
    // Native Drag.Automatic on Wayland can preserve the QML source while its
    // custom MIME formats are not surfaced back to an in-process DropArea.
    // Treat our source marker as authoritative before checking foreign MIME.
    try {
        var source = event ? event.source : null;
        if (source && String(source.dragAppId || ""))
            return true;
    } catch (e) {
        // Continue with MIME detection for external/legacy drags.
    }
    var formats = eventFormats(event);
    return formats.indexOf(REORDER_MIME) >= 0
        || formats.indexOf(LAUNCHER_MIME) >= 0;
}

/** App id carried by an internal reorder drag ("" for foreign drags). */
function dropSourceId(event) {
    // For a drag started by one of our QML items, event.source is the most
    // reliable channel: Drag.Automatic may hand the payload to the platform
    // drag backend, where a custom MIME string is not guaranteed to round-trip
    // through getDataAsString() on every Plasma/Qt combination.
    try {
        var source = event ? event.source : null;
        if (source && source.dragAppId !== undefined) {
            var sourceId = String(source.dragAppId || "");
            if (sourceId)
                return sourceId;
        }
    } catch (e) {
        // Foreign drags do not necessarily expose a readable source object.
    }
    if (eventFormats(event).indexOf(REORDER_MIME) < 0)
        return "";
    return eventDataAsString(event, REORDER_MIME);
}

/**
 * Common drop handler for pinned/favorite views: reorder the dragged pin,
 * or pin a not-yet-pinned app next to the drop target.
 */
function handlePinnedDrop(menuData, event, targetId, after) {
    if (!menuData || !menuData.movePinnedItem)
        return false;
    var srcId = dropSourceId(event);
    if (!srcId)
        return false;
    if (menuData.pinnedPreviewSourceId === srcId
            && menuData.commitPinnedPreview) {
        _dropCommitted = !!menuData.commitPinnedPreview(srcId);
        return _dropCommitted;
    }
    _dropCommitted = true;
    return !!menuData.movePinnedItem(srcId, String(targetId || ""));
}

/* ------------------------------------------------------------------ */
/* Kickoff-style live reorder.                                         */
/*                                                                     */
/* Official KickoffDropArea does not preview through a JS array: it    */
/* calls ListModel.move(sourceIndex, targetIndex, 1) on the view while */
/* the pointer is over a cell, waits for move / moveDisplaced to       */
/* finish, then hops again. Mid-list items therefore slide out of the  */
/* way (the travelling hole) instead of jumping after mouse-up.        */
/*                                                                     */
/* The ListModel is frozen against its source binding for the drag so  */
/* a parent JS-array rebuild cannot wipe the in-flight animation.      */
/* Drop commits the model order; a cancelled / external drop unfreezes */
/* and the stored order walks back into place.                         */
/* ------------------------------------------------------------------ */

var _liveTarget = "\u0001"; // sentinel: no hover recorded yet
var _dropCommitted = false;
var _frozenModel = null;

function _transitionRunning(transition) {
    try {
        return !!(transition && transition.running);
    } catch (e) {
        return false;
    }
}

/** True while GridView/ListView is still sliding rows into place. */
function viewIsAnimating(view) {
    if (!view)
        return false;
    return _transitionRunning(view.move) || _transitionRunning(view.moveDisplaced);
}

function freezeModel(model) {
    if (!model || _frozenModel === model)
        return;
    if (_frozenModel && _frozenModel.unfreeze)
        _frozenModel.unfreeze();
    _frozenModel = model;
    if (model.freeze)
        model.freeze();
}

function unfreezeModel() {
    if (_frozenModel && _frozenModel.unfreeze)
        _frozenModel.unfreeze();
    _frozenModel = null;
}

function idAtModel(model, index) {
    if (!model || index < 0)
        return "";
    try {
        if (model.appIdAt)
            return String(model.appIdAt(index) || "");
    } catch (e) {
        // fall through to get()
    }
    if (index >= (model.count || 0) || !model.get)
        return "";
    var row = model.get(index);
    if (!row)
        return "";
    return String(row.appId || row.id || "");
}

function indexOfId(model, appId) {
    appId = String(appId || "");
    if (!model || !appId)
        return -1;
    var n = model.count || 0;
    for (var i = 0; i < n; ++i) {
        if (idAtModel(model, i) === appId)
            return i;
    }
    return -1;
}

function isSectionId(id) {
    id = String(id || "");
    return id.indexOf("__az_section_") === 0 || id.indexOf("__section_") === 0;
}

function modelIds(model) {
    var out = [];
    if (!model)
        return out;
    var n = model.count || 0;
    for (var i = 0; i < n; ++i) {
        var id = idAtModel(model, i);
        if (id && !isSectionId(id))
            out.push(id);
    }
    return out;
}

function viewGroupId(view) {
    try {
        if (view && view.reorderGroupId !== undefined)
            return String(view.reorderGroupId || "");
    } catch (e) {
        // Views without the property are treated as legacy pinned grids.
    }
    return "";
}

/** Empty group id keeps Kickoff drop-to-pin on older pinned-only views. */
function isPinnedGroupId(groupId) {
    groupId = String(groupId || "");
    return !groupId || groupId === "pinned" || groupId === "favorites";
}

/** True when this drag should hop rows inside `view` while the pointer moves. */
function isLiveReorderSource(view, menuData, srcId) {
    srcId = String(srcId || "");
    if (!srcId)
        return false;
    if (isPinnedGroupId(viewGroupId(view)))
        return isPinnedSource(menuData, srcId);
    if (!view || !view.model)
        return false;
    return indexOfId(view.model, srcId) >= 0;
}

/**
 * Kickoff moveRow(): take the hovered cell's index. Items between the
 * source and that cell are displaced by ListView/GridView's move
 * transitions. Returns the clamped destination, or -1 if nothing to do.
 */
function clampMoveIndex(model, menuData, srcId, from, to, groupId) {
    if (!model || from < 0 || to < 0 || from === to)
        return -1;
    var n = model.count || 0;
    if (to >= n)
        to = n - 1;
    if (to < 0 || from >= n)
        return -1;
    if (!isPinnedGroupId(groupId)) {
        var hopped = to;
        if (isSectionId(idAtModel(model, hopped))) {
            var step = from < hopped ? -1 : 1;
            while (hopped >= 0 && hopped < n && isSectionId(idAtModel(model, hopped)))
                hopped += step;
            if (hopped < 0 || hopped >= n || hopped === from)
                return -1;
            to = hopped;
        }
        return to;
    }
    if (!menuData || !menuData.isArcMenuOnlyPinId)
        return to;
    // Plasma favorites and ArcMenu-only shortcuts live in different
    // backing stores, so a live drag stays inside its own section.
    var fromLocal = menuData.isArcMenuOnlyPinId(srcId);
    var toId = idAtModel(model, to);
    if (!toId || menuData.isArcMenuOnlyPinId(toId) === fromLocal)
        return to;
    var i;
    if (fromLocal) {
        for (i = 0; i < n; ++i) {
            if (menuData.isArcMenuOnlyPinId(idAtModel(model, i)))
                return from === i ? -1 : i;
        }
        return from === n - 1 ? -1 : n - 1;
    }
    var lastGlobal = -1;
    for (i = 0; i < n; ++i) {
        if (!menuData.isArcMenuOnlyPinId(idAtModel(model, i)))
            lastGlobal = i;
    }
    if (lastGlobal < 0)
        return -1;
    return from === lastGlobal ? -1 : lastGlobal;
}

function sourceIndex(view, event, srcId) {
    try {
        var source = event ? event.source : null;
        if (source && source.dragView === view && source.dragIndex >= 0)
            return source.dragIndex;
    } catch (e) {
        // Wayland may omit event.source; fall through to an id lookup.
    }
    return indexOfId(view ? view.model : null, srcId);
}

/** Call when a drag session starts (drag ghost went active). */
function resetLiveReorder() {
    _liveTarget = "\u0001";
    _dropCommitted = false;
}

/** Restore the stored order after cancellation or an external desktop drop. */
function finishDrag(menuData) {
    if (!_dropCommitted && menuData && menuData.cancelPinnedPreview)
        menuData.cancelPinnedPreview();
    unfreezeModel();
    _liveTarget = "\u0001";
    _dropCommitted = false;
}

/** True when the dragged id is already part of the pinned list. */
function isPinnedSource(menuData, srcId) {
    if (!menuData || !menuData.effectivePinnedIds || !srcId)
        return false;
    return menuData.effectivePinnedIds().indexOf(String(srcId)) >= 0;
}

/**
 * Hover-time reorder. Only pinned sources shift live (dragging an
 * unpinned app over the pin list keeps the drop-to-pin behavior on
 * release). Throttled per hovered target: after a move the dragged
 * entry occupies the target slot, so further hover events either hit
 * the same target (no-op) or a new one.
 */
function handlePinnedDragMove(menuData, event, targetId, after) {
    if (!menuData || !menuData.previewPinnedItem)
        return false;
    targetId = String(targetId || "");
    var targetKey = targetId + (after ? ":after" : ":before");
    if (!targetId || targetKey === _liveTarget)
        return false;
    var srcId = dropSourceId(event);
    if (!srcId || !isPinnedSource(menuData, srcId))
        return false;
    _liveTarget = targetKey;
    var moved = false;
    try {
        moved = !!menuData.previewPinnedItem(srcId, targetId, !!after);
    } catch (e) {
        moved = false;
    }
    if (!moved)
        _liveTarget = "\u0001";
    return moved;
}

/**
 * KickoffDropArea.onPositionChanged: move the dragged row onto the cell
 * under the pointer. No-ops while the previous slide is still running so
 * displaced tiles finish making way before the next hop.
 */
function movePinnedInView(view, menuData, event, targetIndex) {
    if (!view || !view.model || !view.model.move || targetIndex < 0)
        return false;
    if (viewIsAnimating(view))
        return false;
    var srcId = dropSourceId(event);
    if (!srcId || !isLiveReorderSource(view, menuData, srcId))
        return false;
    var model = view.model;
    freezeModel(model);
    var from = sourceIndex(view, event, srcId);
    var to = clampMoveIndex(model, menuData, srcId, from, targetIndex,
        viewGroupId(view));
    if (to < 0 || to === from)
        return false;
    var key = srcId + ":" + to;
    if (key === _liveTarget)
        return false;
    try {
        model.move(from, to, 1);
    } catch (e) {
        return false;
    }
    _liveTarget = key;
    return true;
}

/** Persist the view's live order, or pin a foreign app at the hovered cell. */
function dropPinnedInView(view, menuData, event, targetIndex) {
    if (!menuData)
        return false;
    var srcId = dropSourceId(event);
    if (!srcId)
        return false;
    var groupId = viewGroupId(view);
    if (isPinnedGroupId(groupId) && isPinnedSource(menuData, srcId)
            && view && view.model && view.model.move) {
        var ids = modelIds(view.model);
        if (menuData.commitPinnedOrder)
            _dropCommitted = !!menuData.commitPinnedOrder(ids);
        else if (menuData.commitPinnedPreview)
            _dropCommitted = !!menuData.commitPinnedPreview(srcId);
        else
            _dropCommitted = false;
        return _dropCommitted;
    }
    if (isPinnedGroupId(groupId)) {
        var targetId = "";
        if (view && view.model && targetIndex >= 0)
            targetId = idAtModel(view.model, targetIndex);
        _dropCommitted = !!menuData.movePinnedItem(srcId, targetId);
        return _dropCommitted;
    }
    if (isLiveReorderSource(view, menuData, srcId)
            && view && view.model && view.model.move
            && menuData.commitGroupOrder) {
        _dropCommitted = !!menuData.commitGroupOrder(groupId, modelIds(view.model));
        return _dropCommitted;
    }
    return false;
}
