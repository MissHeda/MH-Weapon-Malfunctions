#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The weapon works again: its malfunction is gone. The fire block (fnc_jam) stays on the unit and asks fnc_isBlocked, which
 * says no now.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 * 2: Silent <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, primaryWeapon player] call mhwm_malfunctions_fnc_clear;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_silent", false, [false]]];

private _states = _unit getVariable [QGVAR(states), createHashMap];

if !(toLowerANSI _weapon in _states) exitWith {};

[_unit, _weapon, createHashMap] call FUNC(state);

if (!_silent && {_unit == PLAYER_UNIT} && {EGVAR(main,notify)}) then {
    [[LLSTRING(Cleared), 1.2, COLOR_GOOD]] call CBA_fnc_notify;
};
