#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A local unit fired: maybe this shot jams the weapon (fnc_chance, fnc_jam). Only a primary weapon or a handgun, only its
 * own muzzle (no grenade launcher), never from a vehicle. With ACE Overheating deciding (setting "With ACE Overheating"),
 * this mod rolls nothing itself: ACE's jams become its malfunctions (fnc_onAceJammed).
 *
 * Arguments:
 * Fired event handler arguments
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_unit", "_weapon", "_muzzle", "", "", "_magazine"];

if (!local _unit || {!EGVAR(main,enabled)} || {_weapon != _muzzle}) exitWith {};
if (HAS_ACE_OVERHEATING && {EGVAR(main,aceMode) == 1} && {missionNamespace getVariable ["ace_overheating_enabled", false]}) exitWith {};

private _isPlayer = isPlayer _unit || {_unit == PLAYER_UNIT};

if (!_isPlayer && {!EGVAR(main,ai)}) exitWith {};
if !(_weapon == primaryWeapon _unit || {EGVAR(main,handguns) && {_weapon == handgunWeapon _unit}}) exitWith {};

// Nothing left to feed: the weapon is simply empty.
if (_unit ammo _weapon < 1) exitWith {};

if (random 1 >= [_unit, _weapon, _magazine] call FUNC(chance)) exitWith {};

[_unit, _weapon] call FUNC(jam);
