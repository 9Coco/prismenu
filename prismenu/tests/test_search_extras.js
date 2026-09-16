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
      description: "sftp://host/home", group: "Locations" },
    { id: "runner:file", name: "example.txt", provider: "runner",
      description: "~/Desktop/example.txt" }
], [
    { id: "place", name: "android phone", provider: "kfileplaces",
      kickerUrl: "sftp://host/home" }
], [
    { id: "file", name: "example.txt", provider: "recent-files",
      kickerUrl: "file:///home/user/Desktop/example.txt" }
], [], [], "a", 20, value => value);

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
], [], [], [], "a", 1, value => value);
if (!capped.some(row => row.sectionId === "places"))
    throw new Error("Application cap incorrectly hid the Places section");

if (search.classifySearchItem({ provider: "runner", group: "常用位置",
        name: "Quark", kickerUrl: "sftp://host/" }) !== "places")
    throw new Error("Locations runner group was not classified as places");
if (search.classifySearchItem({ provider: "runner", group: "窗口",
        name: "Clash Verge" }) !== "windows")
    throw new Error("Windows runner group was not classified as windows");
if (search.classifySearchItem({ provider: "runner", group: "书签",
        name: "Hanime1", kickerUrl: "https://hanime1.me" }) !== "bookmarks")
    throw new Error("Bookmarks runner group was not classified as bookmarks");
if (search.classifySearchItem({ provider: "runner",
        name: "android phone", kickerUrl: "sftp://host/home" }) !== "places")
    throw new Error("Remote sftp URL was not classified as places");
if (search.classifySearchItem({ provider: "runner",
        name: "Notes", kickerUrl: "file:///home/user/Notes" }) !== "places")
    throw new Error("Directory file URL was not classified as places");
if (search.classifySearchItem({ provider: "runner",
        name: "readme.md", kickerUrl: "file:///home/user/readme.md" }) !== "files")
    throw new Error("Document file URL was not classified as files");

const kickoffLike = search.composeSearchResults([
    { id: "runner:app", name: "Clash Verge", provider: "runner", group: "Applications" },
    { id: "runner:win", name: "Clash Verge", provider: "runner", group: "Windows" },
    { id: "runner:loc", name: "android phone", provider: "runner", group: "Locations",
      kickerUrl: "sftp://phone/" },
    { id: "runner:bm", name: "Hanime1", provider: "runner", group: "Bookmarks",
      kickerUrl: "https://hanime1.me" }
], [], [], [
    { id: "window:0:Clash Verge", name: "Clash Verge", provider: "windows" }
], [
    { id: "bookmark:https://hanime1.me", name: "Hanime1", provider: "bookmarks",
      kickerUrl: "https://hanime1.me" }
], "a", 20, value => value);
const kickoffSections = kickoffLike.filter(row => row.isSection).map(row => row.sectionId);
if (kickoffSections.join(",") !== "applications,places,windows,bookmarks")
    throw new Error(`Kickoff-like sections: ${kickoffSections.join(",")}`);
const clashHits = kickoffLike.filter(row => !row.isSection && row.name === "Clash Verge");
if (clashHits.length !== 2)
    throw new Error("App and window with the same name must both appear");

const compat = search.composeSearchResults([
    { id: "app:1", name: "AList", provider: "runner" }
], [], [], [], "a", 20, value => value);
if (!compat.some(row => row.name === "AList"))
    throw new Error("Legacy composeSearchResults signature broke");

if (search.resultIconSource({ icon: "bookmarks" }) !== "bookmarks")
    throw new Error("resultIconSource ignored theme icon name");
if (search.resultIconSource({ decoration: "folder-remote", icon: "x" }) !== "folder-remote")
    throw new Error("resultIconSource should prefer decoration");

const nativeIcon = { kind: "native-icon" };
const changedIcon = { kind: "changed-native-icon" };
const holder = { decoration: nativeIcon };
const nativePlace = { icon: "folder", decoration: "folder-music", iconHolder: holder };
if (search.resultIconSource(nativePlace) !== nativeIcon)
    throw new Error("resultIconSource must preserve live native icons without string conversion");
holder.decoration = changedIcon;
if (search.resultIconSource(nativePlace) !== changedIcon)
    throw new Error("resultIconSource did not follow a changed native decoration");
for (const empty of [null, undefined, ""]) {
    holder.decoration = empty;
    if (search.resultIconSource(nativePlace) !== "folder-music")
        throw new Error("Missing live decoration should fall back to the snapshot");
    if (search.resultIconSource({ decoration: empty, icon: "folder" }) !== "folder")
        throw new Error("Missing native decoration should fall back to the theme name");
}
if (search.resultIconSource({ decoration: nativeIcon, icon: "folder" }) !== nativeIcon)
    throw new Error("resultIconSource must preserve native snapshot icons");
if (search.resultIconSource({ decoration: { isNull: true }, icon: "folder" }) !== "folder")
    throw new Error("A null decoration should fall back to the theme name");
if (search.resultIconSource({ icon: "/tmp/custom-place.svg" }) !== "/tmp/custom-place.svg")
    throw new Error("Custom icon paths should be preserved");
if (search.resultIconSource(null) !== "application-x-executable")
    throw new Error("Missing entries should retain the generic fallback");

console.log("SearchExtras provider tests passed.");
