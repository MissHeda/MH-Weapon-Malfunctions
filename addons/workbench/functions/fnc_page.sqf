#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Pages through the steps on the side panel: the large card shows another step than the one now - done ones and those
 * still to come - so the whole drill can be clicked through (Mia). GVAR(wb) "view" is the step shown, -1 the step now;
 * the next hand movement puts it back (fnc_act).
 *
 * Arguments:
 * 0: Step <NUMBER>: with 1 = true its place in the list, else -1 back, 1 on, 0 back to the step now
 * 1: Absolute <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_value", 0, [0]], ["_absolute", false, [false]]];

if (isNil QGVAR(wb)) exitWith {};

private _count = count (GVAR(wb) get "done") + count ([] call FUNC(steps));
private _now = count (GVAR(wb) get "done");

if (_count == 0) exitWith {};

private _shown = switch (true) do {
    case (_absolute): {_value};
    case (_value == 0): {_now};
    default {([GVAR(wb) get "view", _now] select ((GVAR(wb) get "view") < 0)) + _value};
};

if (_shown < 0 || {_shown >= _count}) exitWith {};

GVAR(wb) set ["view", [_shown, -1] select (_shown == _now)];

call FUNC(refresh);
