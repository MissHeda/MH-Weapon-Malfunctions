#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The trigger pulled on the jammed weapon (the fire block, fnc_jam). With the bolt closed the hammer falls with a click -
 * now the player knows a dud for one; with the bolt out of battery the trigger is dead.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _weapon = currentWeapon _unit;
private _state = [_unit, _weapon] call FUNC(state);

if (count _state == 0) exitWith {};

if ((_state get "bolt") == "closed") then {
    [_unit, "dry"] call FUNC(playSound);
};

if !(_state getOrDefault ["tried", false]) then {
    _state set ["tried", true];
    [_unit, _weapon, _state] call FUNC(state);
};
