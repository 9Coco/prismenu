#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const source = fs.readFileSync(
    path.join(__dirname, "../package/contents/code/AppsModel.js"),
    "utf8"
).replace(/^\.pragma library\s*/, "");
const model = {};
vm.createContext(model);
vm.runInContext(source, model);

function assertEqual(actual, expected, msg) {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a !== e)
        throw new Error(`${msg}: ${a} !== ${e}`);
}

assertEqual(model.canonicalGroupId("all"), "all-apps", "all drills share the all-apps key");
assertEqual(model.canonicalGroupId("favorites"), "pinned", "favorites alias pinned");
assertEqual(model.canonicalGroupId("Development"), "Development", "system categories keep their id");

assertEqual(model.canReorderGroup("pinned"), true, "pinned is reorderable");
assertEqual(model.canReorderGroup("all"), true, "all-apps is reorderable");
assertEqual(model.canReorderGroup("Development"), true, "system categories are reorderable");
assertEqual(model.canReorderGroup("qgrp-ai"), true, "custom groups are reorderable");
assertEqual(model.canReorderGroup("frequent"), false, "recent apps stay recency-ordered");
assertEqual(model.canReorderGroup("recent-files"), false, "recent files are not reorderable");
assertEqual(model.canReorderGroup("bookmarks"), false, "places lists are not reorderable");
assertEqual(model.canReorderGroup(""), false, "empty group is not reorderable");

assertEqual(model.isSectionId("__az_section_A"), true, "A-Z header id");
assertEqual(model.itemsHaveSections([
    { id: "__az_section_A", isSection: true },
    { id: "a.desktop", name: "A" }
]), true, "AZ rows trip the section guard");
assertEqual(model.itemsHaveSections([{ id: "a.desktop", name: "A" }]), false,
    "flat app lists have no sections");

const apps = [
    { id: "c", name: "C" },
    { id: "a", name: "A" },
    { id: "b", name: "B" }
];
assertEqual(model.applyAppListOrder(apps, []).map((x) => x.id), ["c", "a", "b"],
    "empty stored order keeps the incoming list");
assertEqual(model.applyAppListOrder(apps, ["b", "a"]).map((x) => x.id), ["b", "a", "c"],
    "stored ids lead; newcomers append in incoming order");
assertEqual(model.applyAppListOrder(apps, ["gone", "a", "b", "c"]).map((x) => x.id),
    ["a", "b", "c"], "uninstalled ids are dropped");

console.log("AppsModel group-order helpers passed.");
