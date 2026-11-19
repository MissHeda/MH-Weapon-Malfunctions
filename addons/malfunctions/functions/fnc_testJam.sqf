#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * For testing only, no key and no setting (Mia: it has no place in a release): the weapon in the player's hands
 * malfunctions at once, the next of the five causes each call, a malfunction there is now cleared first. Called by the
 * test missions or from the debug console; singleplayer, the editor's preview or a logged-in admin.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * call mhwm_malfunctions_fnc_testJam;
 *
 * Public: No
 */

private _unit = PLAYER_UNIT;
private _weapon = currentWeapon _unit;

if (!EGVAR(main,enabled) || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};
if !(_weapon in [primaryWeapon _unit, handgunWeapon _unit] && {_weapon isNotEqualTo ""}) exitWith {false};

private _allowed = !isMultiplayer || {is3DENPreview} || {serverCommandAvailable "#kick"};

if (!_allowed) exitWith {false};

private _index = (missionNamespace getVariable [QGVAR(testIndex), -1]) + 1;
private _cause = CAUSES select (_index % count CAUSES);

GVAR(testIndex) = _index;

[_unit, _weapon, true] call FUNC(clear);
[_unit, _weapon, _cause] call FUNC(jam);

[
    [LLSTRING(Test_Title), 1, COLOR_DIM],
    [localize format ["STR_mhwm_malfunctions_Cause_%1", [_cause select [0, 1], _cause select [1]] call {toUpperANSI (_this select 0) + (_this select 1)}]]
] call CBA_fnc_notify;

true
