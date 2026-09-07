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

const removed = [];
const model = {
    enabled: true,
    count: 1,
    maxFavorites: -1,
    isFavorite: function (id) { return id.indexOf("kate") >= 0; },
    removeFavorite: function (id) { removed.push(id); },
    addFavorite: function () {}
};

const actions = tools.createFavoriteActions(function (s) { return s; }, model,
    "applications:org.kde.kate.desktop");
assert(actions && actions[0].actionId === "_kicker_favorite_remove",
    "createFavoriteActions uses Kickoff remove id");
assert(actions[0].actionArgument.favoriteId === "applications:org.kde.kate.desktop",
    "createFavoriteActions preserves the exact favoriteId");
assert(actions[0].actionArgument.favoriteModel === model,
    "createFavoriteActions carries the live favoriteModel like Kickoff");

tools.triggerAction(null, -1, "_kicker_favorite_remove", actions[0].actionArgument);
assert(removed[0] === "applications:org.kde.kate.desktop",
    "triggerAction removes through actionArgument.favoriteModel");

let triggered = null;
const appModel = {
    trigger: function (index, actionId, argument) {
        triggered = { index, actionId, argument };
        return true;
    }
};
assert(tools.triggerAction(appModel, 3, "new-window", { x: 1 }) === true,
    "normal model action returns Kickoff's close request");
assert(triggered.index === 3 && triggered.actionId === "new-window",
    "normal model action uses the originating row");

const native = [
    { text: "New Window", actionId: "new-window" },
    { text: "Add to Desktop", actionId: "addToDesktop" }
];
const merged = tools.insertFavoriteActions(native, actions);
assert(merged[1].actionId === "_kicker_favorite_remove",
    "favorite action is inserted before addToDesktop like Kickoff");

console.log("KickoffTools favorite helpers passed.");
