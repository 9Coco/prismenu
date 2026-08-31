#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const source = fs.readFileSync(
    path.join(__dirname, "../package/contents/code/KickoffTools.js"),
    "utf8"
).replace(/^\.pragma library\s*/, "");
const tools = {};
vm.createContext(tools);
vm.runInContext(source, tools);

function assert(cond, msg) {
    if (!cond)
        throw new Error(msg);
}

const arg = { favoriteId: "applications:org.kde.kate.desktop" };
assert(tools.favoriteIdFromArgument(arg) === "applications:org.kde.kate.desktop",
    "Kickoff actionArgument.favoriteId");
assert(tools.favoriteIdFromArgument("applications:foo.desktop") === "applications:foo.desktop",
    "bare string argument still unwraps");

const removed = [];
const model = {
    enabled: true,
    isFavorite: function (id) { return id.indexOf("kate") >= 0; },
    removeFavorite: function (id) { removed.push(id); },
    addFavorite: function () {}
};

const actions = tools.createFavoriteActions(function (s) { return s; }, model,
    "applications:org.kde.kate.desktop");
assert(actions && actions[0].actionId === "_kicker_favorite_remove",
    "createFavoriteActions uses Kickoff remove id");
assert(actions[0].actionArgument.favoriteId === "applications:org.kde.kate.desktop",
    "createFavoriteActions argument is { favoriteId }");

assert(tools.handleFavoriteAction("_kicker_favorite_remove", actions[0].actionArgument, model),
    "handleFavoriteAction removes");
assert(removed[0] === "applications:org.kde.kate.desktop",
    "removeFavorite got Kickoff's exact id");

const native = [
    { text: "New Window", actionId: "new-window" },
    { text: "Add to Desktop", actionId: "addToDesktop" }
];
const merged = tools.insertFavoriteActions(native, actions);
assert(merged[1].actionId === "_kicker_favorite_remove",
    "favorite action is inserted before addToDesktop like Kickoff");

console.log("KickoffTools favorite helpers passed.");
