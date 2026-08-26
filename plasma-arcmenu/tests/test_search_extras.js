#!/usr/bin/env node

const fs = require("fs");
const vm = require("vm");

const source = fs.readFileSync("package/contents/code/SearchExtras.js", "utf8")
    .replace(/^\.pragma library\s*/, "");
const search = {};
vm.createContext(search);
vm.runInContext(source, search);

const rows = search.composeSearchResults([
    { id: "runner:app", name: "AList", provider: "runner" },
    { id: "runner:place", name: "android phone", provider: "runner",
      description: "sftp://host/home" },
    { id: "runner:file", name: "example.txt", provider: "runner",
      description: "~/Desktop/example.txt" }
], [
    { id: "place", name: "android phone", provider: "kfileplaces",
      kickerUrl: "sftp://host/home" }
], [
    { id: "file", name: "example.txt", provider: "recent-files",
      kickerUrl: "file:///home/user/Desktop/example.txt" }
], [], "a", 20, value => value);

const sections = rows.filter(row => row.isSection).map(row => row.sectionId);
if (sections.join(",") !== "applications,places,files")
    throw new Error(`Unexpected provider sections: ${sections.join(",")}`);
if (rows.filter(row => !row.isSection).length !== 3)
    throw new Error("Native provider duplicates were not removed");

const capped = search.composeSearchResults([
    { id: "app:1", name: "Alpha", provider: "applications" },
    { id: "app:2", name: "Alpine", provider: "applications" }
], [
    { id: "place:1", name: "Archive", provider: "kfileplaces" }
], [], [], "a", 1, value => value);
if (!capped.some(row => row.sectionId === "places"))
    throw new Error("Application cap incorrectly hid the Places section");

console.log("SearchExtras provider tests passed.");
