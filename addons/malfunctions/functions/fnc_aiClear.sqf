#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * An AI unit clears its jammed weapon by itself: no rounds for a few seconds (a double feed or a stuck case takes longer),
 * the reload gesture and the bolt, then the magazine back less the round the jam cost. Should it reload meanwhile,
 * fnc_onReloaded hands the rounds back as a magazine.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]]];

private _ammo = _unit ammo _weapon;
private _cause = ([_unit, _weapon] call FUNC(state)) getOrDefault ["cause", CAUSE_FEED];
private _time = [2 + random 2, 5 + random 4] select (_cause in [CAUSE_DOUBLE, CAUSE_EXTRACT]);

_unit setVariable [QGVAR(aiJam), [_weapon, _ammo]];
_unit setAmmo [_weapon, 0];

[{
    params ["_unit", "_weapon"];

    private _reload = getText (configFile >> "CfgWeapons" >> _weapon >> "reloadAction");

    if (alive _unit && {_reload isNotEqualTo ""}) then {
        _unit playActionNow _reload;
    };
}, [_unit, _weapon], 0.5] call CBA_fnc_waitAndExecute;

[{
    params ["_unit", "_weapon"];

    private _aiJam = _unit getVariable [QGVAR(aiJam), []];

    // Reloaded meanwhile (fnc_onReloaded) or dead: nothing left to do.
    if (_aiJam isEqualTo [] || {!alive _unit} || {(_aiJam select 0) != _weapon}) exitWith {};

    _unit setVariable [QGVAR(aiJam), nil];
    [_unit, _weapon, true] call FUNC(clear);
    [_unit, "bolt"] call FUNC(playSound);

    if (_weapon in [primaryWeapon _unit, handgunWeapon _unit]) then {
        _unit setAmmo [_weapon, ((_aiJam select 1) - 1) max 0];
    };
}, [_unit, _weapon], _time] call CBA_fnc_waitAndExecute;
