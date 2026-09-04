.pragma library

// Pure helpers for handle-drag row reordering in config lists.
// All positions are in the row container's coordinate space.

// Slot under the dragged row's center, clamped to [0, count - 1].
function slotForPosition(containerMouseY, grabOffsetY, unitHeight, listTop, count) {
    if (count <= 1 || unitHeight <= 0)
        return 0;
    var center = containerMouseY - grabOffsetY + unitHeight / 2;
    var slot = Math.floor((center - listTop) / unitHeight);
    if (slot < 0)
        slot = 0;
    if (slot > count - 1)
        slot = count - 1;
    return slot;
}

// Visual displacement (px) for a resting row while another row is dragged:
// rows between the drag origin and the target slot slide out of the way.
function shiftForRow(index, fromIndex, targetIndex, unitHeight) {
    if (fromIndex < 0 || targetIndex < 0 || index === fromIndex)
        return 0;
    if (fromIndex < targetIndex && index > fromIndex && index <= targetIndex)
        return -unitHeight;
    if (targetIndex < fromIndex && index >= targetIndex && index < fromIndex)
        return unitHeight;
    return 0;
}

// Lift offset so the dragged row follows the pointer.
function liftForRow(containerMouseY, grabOffsetY, rowY) {
    return containerMouseY - grabOffsetY - rowY;
}
