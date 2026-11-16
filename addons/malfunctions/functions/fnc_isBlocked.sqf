#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the unit's trigger does nothing right now: the weapon in the unit's hands is jammed and its own muzzle is selected (a
 * grenade launcher under it still fires). The condition of the fire block (fnc_jam).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Blocked <BOOL>
 *
 * Example:
 * [player] call mhwm_malfunctions_fnc_isBlocked;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

(weaponState _unit) params ["_weapon", "_muzzle"];

_weapon isNotEqualTo ""
&& {_weapon == _muzzle}
&& {EGVAR(main,enabled)}
&& {count ([_unit, _weapon] call FUNC(state)) > 0}
