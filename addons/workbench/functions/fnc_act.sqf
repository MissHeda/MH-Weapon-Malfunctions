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

([GVAR(wb) get "unit", GVAR(wb) get "weapon", _action] call EFUNC(malfunctions,act)) params ["_result", "_works"];

GVAR(wb) set ["result", _result];

if (_works) then {
    GVAR(wb) set ["closing", true];
    GVAR(wb) set ["result", "WB_Cleared"];

    [{
        if (!isNil QGVAR(wb)) then {closeDialog 0};
    }, [], 1.4] call CBA_fnc_waitAndExecute;
};

call FUNC(sync);
call FUNC(refresh);
