#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const source = fs.readFileSync(
    path.join(__dirname, "../package/contents/code/GroupDrag.js"),
    "utf8"
).replace(/^\.pragma library\s*/, "");
const drag = {};
vm.createContext(drag);
vm.runInContext(source, drag);

function assertEqual(actual, expected, msg) {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a !== e)
        throw new Error(`${msg}: ${a} !== ${e}`);
}

const unit = 54;
const top = 100;
const grab = 20;
const count = 6;

// slotForPosition: finger at press point keeps the original slot
assertEqual(drag.slotForPosition(top + grab, grab, unit, top, count), 0, "no movement keeps slot 0");
// dragging down half a row still counts as the next slot boundary
assertEqual(drag.slotForPosition(top + grab + 0.4 * unit, grab, unit, top, count), 0, "below half row stays");
assertEqual(drag.slotForPosition(top + grab + 0.6 * unit, grab, unit, top, count), 1, "past half row moves to slot 1");
assertEqual(drag.slotForPosition(top + grab + 2.4 * unit, grab, unit, top, count), 2, "2.4 rows down lands on slot 2");
assertEqual(drag.slotForPosition(top + grab + 2.6 * unit, grab, unit, top, count), 3, "2.6 rows down lands on slot 3");
// clamping beyond both ends
assertEqual(drag.slotForPosition(top + grab + 99 * unit, grab, unit, top, count), count - 1, "bottom clamp");
assertEqual(drag.slotForPosition(-9999, grab, unit, top, count), 0, "top clamp");
// degenerate inputs stay safe
assertEqual(drag.slotForPosition(top + grab, grab, 0, top, count), 0, "zero unit height");
assertEqual(drag.slotForPosition(top + grab, grab, unit, top, 1), 0, "single row");
// a list that does not start at y=0 (type groups sit below other rows)
assertEqual(drag.slotForPosition(400 + grab + 1.4 * unit, grab, unit, 400, count), 1, "non-zero list top");

// shiftForRow: dragging row 0 down to slot 2 pushes rows 1-2 up, rest stay
assertEqual(drag.shiftForRow(0, 0, 2, unit), 0, "dragged row is not shifted");
assertEqual(drag.shiftForRow(1, 0, 2, unit), -unit, "row between slides up");
assertEqual(drag.shiftForRow(2, 0, 2, unit), -unit, "target slot row slides up");
assertEqual(drag.shiftForRow(3, 0, 2, unit), 0, "rows after target stay");
// dragging row 4 up to slot 1 pushes rows 1-3 down
assertEqual(drag.shiftForRow(0, 4, 1, unit), 0, "rows before target stay");
assertEqual(drag.shiftForRow(1, 4, 1, unit), unit, "target slot row slides down");
assertEqual(drag.shiftForRow(3, 4, 1, unit), unit, "row before origin slides down");
assertEqual(drag.shiftForRow(4, 4, 1, unit), 0, "dragged row is not shifted (up)");
assertEqual(drag.shiftForRow(5, 4, 1, unit), 0, "rows after origin stay");
// idle state never shifts
assertEqual(drag.shiftForRow(2, -1, -1, unit), 0, "no drag, no shift");
assertEqual(drag.shiftForRow(2, 3, 3, unit), 0, "same slot, no shift");

// liftForRow: dragged row top follows the pointer exactly
assertEqual(drag.liftForRow(top + grab, grab, top), 0, "press point lifts nothing");
assertEqual(drag.liftForRow(top + grab + 100, grab, top), 100, "pointer delta is the lift");

console.log("test_group_drag: all assertions passed");
