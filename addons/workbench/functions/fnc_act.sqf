#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A hand movement from the workbench (a minigame or a button): done on the weapon (mhwm_malfunctions_fnc_act), shown in the
 * panel. Once the weapon works again the workbench says so and closes a moment later.
 *
 * Arguments:
 * 0: Action <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_action", "", [""]]];

if (isNil QGVAR(wb) || {GVAR(wb) get "closing"}) exitWith {};

private _before = [] call FUNC(steps);

([GVAR(wb) get "unit", GVAR(wb) get "weapon", _action] call EFUNC(malfunctions,act)) params ["_result", "_works"];

// The step that was up is done when the hands did it and the list moved on (the side panel ticks it off).
private _after = [] call FUNC(steps);
private _did = switch (_action) do {
    case ACT_INSERT_LOOSE: {ACT_INSERT};
    case ACT_CLEAR: {["clear", "pull"] select ((_before param [0, ""]) == "pull")};
    default {_action};
};

if ((_before param [0, ""]) == _did && {_works || {_after isNotEqualTo _before}}) then {
    (GVAR(wb) get "done") pushBack (_before select 0);
};

GVAR(wb) set ["result", _result];
GVAR(wb) set ["view", -1];

if (_works) then {
    GVAR(wb) set ["closing", true];
    GVAR(wb) set ["result", "WB_Cleared"];

    [{
        if (!isNil QGVAR(wb)) then {closeDialog 0};
    }, [], 1.4] call CBA_fnc_waitAndExecute;
};

call FUNC(sync);
call FUNC(refresh);
