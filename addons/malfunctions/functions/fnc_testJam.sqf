#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The test key: the weapon in the player's hands malfunctions at once, without shooting a magazine empty. Each press
 * takes the next of the five causes in turn (feed, dud, stovepipe, double feed, extraction), a malfunction there is now
 * is cleared first. Works in singleplayer and the editor's preview, for a logged-in admin, or for everyone when the
 * server allows it ("Allow the test key").
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

private _allowed = !isMultiplayer || {is3DENPreview} || {serverCommandAvailable "#kick"} || {EGVAR(main,testKey)};

if (!_allowed) exitWith {
    [LLSTRING(Test_NotAllowed)] call CBA_fnc_notify;
    true
};

private _index = (missionNamespace getVariable [QGVAR(testIndex), -1]) + 1;
private _cause = CAUSES select (_index % count CAUSES);

GVAR(testIndex) = _index;

[_unit, _weapon, true] call FUNC(clear);
[_unit, _weapon, _cause] call FUNC(jam);

[
    [LLSTRING(Test_Title), 1, COLOR_DIM],
    [localize format ["STR_mhwm_main_Weight_%1", [_cause select [0, 1], _cause select [1]] call {toUpperANSI (_this select 0) + (_this select 1)}]]
] call CBA_fnc_notify;

true
