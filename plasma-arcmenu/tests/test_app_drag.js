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

console.log("AppDrag Kickoff-style reorder helpers passed.");
