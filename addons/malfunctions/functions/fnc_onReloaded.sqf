#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A jammed weapon was reloaded the normal way: a fresh magazine is in and seated, the rest stays as it was - a double feed or
 * a stuck case does not go away by changing magazines, and an empty chamber still needs the bolt racked.
 *
 * An AI unit that reloads while its weapon is jammed (fnc_aiClear) gets the rounds of the magazine it took out back as a
 * magazine of their own, minus the round the jam cost.
 *
 * Arguments:
 * Reloaded event handler arguments
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_unit", "_weapon", "_muzzle", "", "_oldMagazine"];

if (!local _unit || {_weapon != _muzzle}) exitWith {};

private _aiJam = _unit getVariable [QGVAR(aiJam), []];

if (_aiJam isNotEqualTo [] && {(_aiJam select 0) == _weapon}) exitWith {
    _unit setVariable [QGVAR(aiJam), nil];
    [_unit, _weapon, true] call FUNC(clear);

    _oldMagazine params [["_class", ""]];

    private _rounds = (_aiJam select 1) - 1;

    if (_class isNotEqualTo "" && {_rounds > 0}) then {
        _unit addMagazine [_class, _rounds];
    };
};

private _state = [_unit, _weapon] call FUNC(state);

if (count _state == 0) exitWith {};

_state set ["mag", "in"];

[_unit, _weapon, _state] call FUNC(state);
