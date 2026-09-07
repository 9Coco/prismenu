.pragma library

function moveItem(list, from, to) {
    if (from < 0 || from >= list.length || to < 0 || to >= list.length || from === to) {
        return list.slice();
    }
    var copy = list.slice();
    var item = copy.splice(from, 1)[0];
    copy.splice(to, 0, item);
    return copy;
}

function toggleFavorite(pinned, appId) {
    var copy = (pinned || []).slice();
    var idx = copy.indexOf(appId);
    if (idx >= 0) {
        copy.splice(idx, 1);
    } else {
        copy.push(appId);
    }
    return copy;
}

function isFavorite(pinned, appId) {
    return (pinned || []).indexOf(appId) >= 0;
}

function addFavorite(pinned, appId) {
    var copy = (pinned || []).slice();
    if (copy.indexOf(appId) < 0) {
        copy.push(appId);
    }
    return copy;
}

function removeFavorite(pinned, appId) {
    var copy = (pinned || []).slice();
    var idx = copy.indexOf(appId);
    if (idx >= 0) {
        copy.splice(idx, 1);
    }
    return copy;
}

function pushRecent(recent, appId, maxItems) {
    var copy = (recent || []).slice();
    var idx = copy.indexOf(appId);
    if (idx >= 0) {
        copy.splice(idx, 1);
    }
    copy.unshift(appId);
    var max = Math.max(1, Math.min(20, maxItems || 5));
    if (copy.length > max) {
        copy = copy.slice(0, max);
    }
    return copy;
}

function clearRecent() {
    return [];
}
