#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const source = fs.readFileSync(
    path.join(__dirname, "../package/contents/code/AppDrag.js"),
    "utf8"
).replace(/^\.pragma library\s*/, "");
const drag = {};
vm.createContext(drag);
vm.runInContext(source, drag);

function mockModel(ids) {
    return {
        count: ids.length,
        get: function (i) {
            return { id: ids[i] };
        }
    };
}

function assertEqual(actual, expected, msg) {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a !== e)
        throw new Error(`${msg}: ${a} !== ${e}`);
}

const app = { id: "org.kde.kate.desktop", kickerUrl: "applications:org.kde.kate.desktop" };
assertEqual(drag.launcherUrl(app), "applications:org.kde.kate.desktop", "launcherUrl prefers kickerUrl");
assertEqual(drag.canDragOut(app), true, "desktop apps can drag out");
assertEqual(drag.mimeDataFor(app)[drag.LAUNCHER_MIME], ["applications:org.kde.kate.desktop"], "uri-list payload");
assertEqual(drag.mimeDataFor(app)[drag.REORDER_MIME], "org.kde.kate.desktop", "reorder payload");

const srcEvent = { source: { dragAppId: "org.kde.kate.desktop" } };
assertEqual(drag.isPinDrag(srcEvent), true, "in-process source is a pin drag");
assertEqual(drag.dropSourceId(srcEvent), "org.kde.kate.desktop", "source id from drag ghost");

const model = mockModel(["a", "b", "c", "d"]);
assertEqual(drag.idAtModel(model, 2), "c", "idAtModel");
assertEqual(drag.indexOfId(model, "b"), 1, "indexOfId");
assertEqual(drag.modelIds(model), ["a", "b", "c", "d"], "modelIds");

const menu = {
    isArcMenuOnlyPinId: function (id) {
        return String(id || "").indexOf("shortcut-") === 0;
    }
};

assertEqual(drag.clampMoveIndex(model, menu, "a", 0, 2), 2,
    "Kickoff hop: source takes the hovered cell");
assertEqual(drag.clampMoveIndex(model, menu, "a", 0, 0), -1,
    "no-op when already on the hovered cell");

const mixed = mockModel(["a", "b", "shortcut-1", "shortcut-2"]);
assertEqual(drag.clampMoveIndex(mixed, menu, "a", 0, 3), 1,
    "global favorite cannot enter the ArcMenu-only section");
assertEqual(drag.clampMoveIndex(mixed, menu, "shortcut-2", 3, 0), 2,
    "ArcMenu-only pin stays in its section");

assertEqual(drag.viewIsAnimating({ move: { running: true }, moveDisplaced: { running: false } }), true,
    "wait for move transition like KickoffDropArea");
assertEqual(drag.viewIsAnimating({ move: { running: false }, moveDisplaced: { running: false } }), false,
    "idle view can hop again");

const azModel = mockModel(["a", "__az_section_B", "b", "c"]);
assertEqual(drag.clampMoveIndex(azModel, menu, "a", 0, 1, "Development"), -1,
    "hopping onto a section that collapses back to the source is a no-op");
assertEqual(drag.clampMoveIndex(azModel, menu, "c", 3, 1, "Development"), 2,
    "generic lists skip A-Z section headers");
assertEqual(drag.modelIds(azModel), ["a", "b", "c"],
    "modelIds omits section header rows");

const catView = { reorderGroupId: "Development", model: model };
assertEqual(drag.isLiveReorderSource(catView, menu, "a"), true,
    "category views live-reorder any row in the model");
assertEqual(drag.isLiveReorderSource(catView, menu, "missing"), false,
    "foreign ids do not hop a category list");
assertEqual(drag.isPinnedGroupId("Development"), false, "category is not a pin group");
assertEqual(drag.isPinnedGroupId(""), true, "empty group id keeps legacy pin drop");
assertEqual(drag.isPinnedGroupId("pinned"), true, "pinned group id");

let moved = null;
const liveModel = {
    count: 4,
    get: function (i) { return { id: ["a", "b", "c", "d"][i] }; },
    move: function (from, to) { moved = [from, to]; }
};
const liveView = {
    reorderGroupId: "Development",
    model: liveModel,
    move: { running: false },
    moveDisplaced: { running: false }
};
drag.resetLiveReorder();
assertEqual(drag.movePinnedInView(liveView, menu, srcEvent, 2), false,
    "kate is not in the Development model so it does not hop");
const catEvent = { source: { dragAppId: "a", dragView: liveView, dragIndex: 0 } };
assertEqual(drag.movePinnedInView(liveView, menu, catEvent, 2), true,
    "category drag hops onto the hovered cell");
assertEqual(moved, [0, 2], "ListModel.move follows Kickoff indexAt");

let committed = null;
const menuCommit = {
    isArcMenuOnlyPinId: menu.isArcMenuOnlyPinId,
    commitGroupOrder: function (groupId, ids) {
        committed = { groupId: groupId, ids: ids };
        return true;
    }
};
assertEqual(drag.dropPinnedInView(liveView, menuCommit, catEvent, 2), true,
    "category drop commits the live model order");
assertEqual(committed, { groupId: "Development", ids: ["a", "b", "c", "d"] },
    "commitGroupOrder receives the view group and model ids");

console.log("AppDrag Kickoff-style reorder helpers passed.");
