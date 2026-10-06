.pragma library

/*
 * SPDX-FileCopyrightText: 2013 Aurélien Gâteau <agateau@kde.org>
 * SPDX-FileCopyrightText: 2013-2015 Eike Hein <hein@kde.org>
 * SPDX-FileCopyrightText: 2017 Ivan Cukic <ivan.cukic@kde.org>
 * SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>
 * SPDX-FileCopyrightText: 2026 Prismenu Contributors
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Derived from Plasma Kickoff's ui/code/tools.js:
 * https://invent.kde.org/plasma/plasma-desktop/-/blob/Plasma/6.3/applets/kickoff/package/contents/ui/code/tools.js
 *
 * Prismenu adaptations: retain the favorite action API, use QML-compatible
 * string helpers and the catalog's activity list, and insert favorite actions
 * into the app context menu. Attribution restored on 2026-10-07.
 * See the package's THIRD_PARTY_NOTICES.md and COPYING for licensing details.
 */

function startsWith(value, prefix) {
    value = String(value || "");
    prefix = String(prefix || "");
    return value.substr(0, prefix.length) === prefix;
}

function createFavoriteActions(i18n, favoriteModel, favoriteId) {
    if (!favoriteModel || !favoriteId || !favoriteModel.enabled)
        return null;

    if (favoriteModel.activities === undefined
            || favoriteModel.activities.activities.length <= 1) {
        var action = {};
        if (favoriteModel.isFavorite(favoriteId)) {
            action.text = i18n("Remove from Favorites");
            action.icon = "bookmark-remove";
            action.actionId = "_kicker_favorite_remove";
        } else if (favoriteModel.maxFavorites === -1
                || favoriteModel.count < favoriteModel.maxFavorites) {
            action.text = i18n("Add to Favorites");
            action.icon = "bookmark-new";
            action.actionId = "_kicker_favorite_add";
        } else {
            return null;
        }
        action.actionArgument = {
            favoriteModel: favoriteModel,
            favoriteId: favoriteId
        };
        return [action];
    }

    var subActions = [];
    var linkedActivities = favoriteModel.linkedActivitiesFor(favoriteId);
    var activities = favoriteModel.activities.activities;
    var linkedToAllActivities = linkedActivities.indexOf(":global") !== -1;

    subActions.push({
        text: i18n("On All Activities"),
        checkable: true,
        actionId: linkedToAllActivities
            ? "_kicker_favorite_remove_from_activity"
            : "_kicker_favorite_set_to_activity",
        checked: linkedToAllActivities,
        actionArgument: {
            favoriteModel: favoriteModel,
            favoriteId: favoriteId,
            favoriteActivity: ""
        }
    });

    var addActivityItem = function (activityId, activityName) {
        var linkedToThisActivity = linkedActivities.indexOf(activityId) !== -1;
        subActions.push({
            text: activityName,
            checkable: true,
            checked: linkedToThisActivity && !linkedToAllActivities,
            actionId: linkedToAllActivities
                ? "_kicker_favorite_set_to_activity"
                : (linkedToThisActivity
                    ? "_kicker_favorite_remove_from_activity"
                    : "_kicker_favorite_add_to_activity"),
            actionArgument: {
                favoriteModel: favoriteModel,
                favoriteId: favoriteId,
                favoriteActivity: activityId
            }
        });
    };

    addActivityItem(favoriteModel.activities.currentActivity,
        i18n("On the Current Activity"));
    subActions.push({
        type: "separator",
        actionId: "_kicker_favorite_separator"
    });
    activities.forEach(function (activityId) {
        addActivityItem(activityId, favoriteModel.activityNameForId(activityId));
    });

    return [{
        text: i18n("Show in Favorites"),
        icon: "favorite",
        subActions: subActions
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

function triggerAction(model, index, actionId, actionArgument) {
    if (startsWith(actionId, "_kicker_favorite_")) {
        handleFavoriteAction(actionId, actionArgument);
        return;
    }
    var closeRequested = model.trigger(index, actionId, actionArgument);
    return closeRequested === true;
}

function handleFavoriteAction(actionId, actionArgument) {
    var favoriteId = actionArgument.favoriteId;
    var favoriteModel = actionArgument.favoriteModel;
    if (favoriteModel === null || favoriteId === null)
        return null;

    if (actionId === "_kicker_favorite_remove") {
        favoriteModel.removeFavorite(favoriteId);
    } else if (actionId === "_kicker_favorite_add") {
        favoriteModel.addFavorite(favoriteId);
    } else if (actionId === "_kicker_favorite_remove_from_activity") {
        favoriteModel.removeFavoriteFrom(favoriteId, actionArgument.favoriteActivity);
    } else if (actionId === "_kicker_favorite_add_to_activity") {
        favoriteModel.addFavoriteTo(favoriteId, actionArgument.favoriteActivity);
    } else if (actionId === "_kicker_favorite_set_to_activity") {
        favoriteModel.setFavoriteOn(favoriteId, actionArgument.favoriteActivity);
    }
}
