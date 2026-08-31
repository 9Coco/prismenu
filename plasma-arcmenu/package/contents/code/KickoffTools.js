.pragma library

/**
 * Kickoff's code/tools.js favorite helpers.
 *
 * Official Kickoff builds "Add/Remove from Favorites" with
 * Tools.createFavoriteActions(i18n, view.model.favoritesModel, model.favoriteId)
 * and runs them through Tools.triggerAction(), which calls
 * favoritesModel.removeFavorite(actionArgument.favoriteId).
 *
 * actionArgument is an object `{ favoriteId }`, not a bare string.
 */

function startsWith(value, prefix) {
    value = String(value || "");
    prefix = String(prefix || "");
    return value.substr(0, prefix.length) === prefix;
}

function createFavoriteActions(i18n, favoriteModel, favoriteId) {
    if (!favoriteId || !favoriteModel)
        return null;

    var isFav = false;
    try { isFav = !!favoriteModel.isFavorite(favoriteId); } catch (e) {}
    if (!isFav) {
        try {
            if (favoriteModel.linkedActivitiesFor) {
                var linked = favoriteModel.linkedActivitiesFor(favoriteId);
                isFav = !!(linked && linked.length);
            }
        } catch (e2) {}
    }

    var argument = { favoriteId: favoriteId };
    if (isFav) {
        return [{
            type: "kickoff-favorite",
            text: i18n("Remove from Favorites"),
            icon: "bookmark-remove",
            actionId: "_kicker_favorite_remove",
            actionArgument: argument
        }];
    }
    return [{
        type: "kickoff-favorite",
        text: i18n("Add to Favorites"),
        icon: "bookmark-new",
        actionId: "_kicker_favorite_add",
        actionArgument: argument
    }];
}

function insertFavoriteActions(actionList, favoriteActions) {
    var actions = (actionList && actionList.length) ? actionList.slice() : [];
    if (!favoriteActions || !favoriteActions.length)
        return actions;
    if (!actions.length)
        return favoriteActions.slice();
    var firstAddTo = -1;
    for (var i = 0; i < actions.length; ++i) {
        var id = actions[i] ? String(actions[i].actionId || "") : "";
        if (id === "addToDesktop" || id === "addToTaskManager" || id === "addToPanel") {
            firstAddTo = i;
            break;
        }
    }
    if (firstAddTo >= 0) {
        for (var f = favoriteActions.length - 1; f >= 0; --f)
            actions.splice(firstAddTo, 0, favoriteActions[f]);
    } else {
        if (!actions[actions.length - 1] || !actions[actions.length - 1].separator)
            actions.push({ type: "separator", separator: true });
        for (var a = 0; a < favoriteActions.length; ++a)
            actions.push(favoriteActions[a]);
    }
    return actions;
}

function dropFavoriteActions(actionList) {
    var out = [];
    for (var i = 0; i < (actionList || []).length; ++i) {
        var id = String((actionList[i] && actionList[i].actionId) || "").toLowerCase();
        if (id.indexOf("favorite") >= 0)
            continue;
        out.push(actionList[i]);
    }
    return out;
}

function favoriteIdFromArgument(actionArgument) {
    if (actionArgument && typeof actionArgument === "object") {
        if (actionArgument.favoriteId)
            return String(actionArgument.favoriteId);
    }
    if (actionArgument === undefined || actionArgument === null)
        return "";
    var asString = String(actionArgument);
    if (asString === "[object Object]")
        return "";
    return asString;
}

function handleFavoriteAction(actionId, actionArgument, favoriteModel) {
    if (!favoriteModel)
        return false;
    var favoriteId = favoriteIdFromArgument(actionArgument);
    if (!favoriteId)
        return false;
    try {
        if (actionId === "_kicker_favorite_remove") {
            favoriteModel.removeFavorite(favoriteId);
            return true;
        }
        if (actionId === "_kicker_favorite_add") {
            favoriteModel.addFavorite(favoriteId);
            return true;
        }
        if (actionId === "_kicker_favorite_add_to_activity" && favoriteModel.addFavoriteTo) {
            favoriteModel.addFavoriteTo(favoriteId, actionArgument.activityId);
            return true;
        }
        if (actionId === "_kicker_favorite_remove_from_activity" && favoriteModel.removeFavoriteFrom) {
            favoriteModel.removeFavoriteFrom(favoriteId, actionArgument.activityId);
            return true;
        }
        if (actionId === "_kicker_favorite_set_on_activity" && favoriteModel.setFavoriteOn) {
            favoriteModel.setFavoriteOn(favoriteId, actionArgument.activityId);
            return true;
        }
        if (startsWith(actionId, "_kicker_favorite_") && String(actionId).indexOf("remove") >= 0) {
            favoriteModel.removeFavorite(favoriteId);
            return true;
        }
        if (startsWith(actionId, "_kicker_favorite_")) {
            favoriteModel.addFavorite(favoriteId);
            return true;
        }
    } catch (e) {
        return false;
    }
    return false;
}

function triggerAction(model, index, actionId, actionArgument, favoriteModel) {
    if (startsWith(actionId, "_kicker_favorite_")) {
        var fm = favoriteModel;
        if (!fm && model && model.favoritesModel)
            fm = model.favoritesModel;
        return handleFavoriteAction(actionId, actionArgument, fm);
    }
    if (!model || !model.trigger)
        return false;
    try {
        return !!model.trigger(index, String(actionId || ""), actionArgument);
    } catch (e) {
        return false;
    }
}
