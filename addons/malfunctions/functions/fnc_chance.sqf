#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The chance that this shot jams the weapon: the server's rate per 1000 rounds, times
 * - the weapon's own factor: the server's "Weapon reliability" list first, else mhwm_reliability in its config (1 without),
 * - subsonic magazines (initSpeed under 340 m/s, or listed by the server),
 * - large magazines that are no belt,
 * - with ACE Overheating, the barrel's heat: 1 + heat factor * temperature / 500.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 * 2: Magazine class <STRING>
 *
 * Return Value:
 * Chance, 0 to 1 <NUMBER>
 *
 * Example:
 * [player, primaryWeapon player, currentMagazine player] call mhwm_malfunctions_fnc_chance;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_magazine", "", [""]]];

private _chance = EGVAR(main,rate) / 1000;

if (_chance <= 0) exitWith {0};

// The server's list, "class:factor, class:factor", read again whenever it changes (initSettings).
if (isNil QGVAR(weaponRateMap)) then {
    GVAR(weaponRateMap) = createHashMap;
    GVAR(weaponCache) = createHashMap;

    {
        private _pair = (_x splitString ":") apply {trim _x};

        if (count _pair == 2) then {
            GVAR(weaponRateMap) set [toLowerANSI (_pair select 0), parseNumber (_pair select 1)];
        };
    } forEach (EGVAR(main,weaponRates) splitString ",");
};

private _weaponFactor = GVAR(weaponCache) getOrDefaultCall [toLowerANSI _weapon, {
    private _listed = GVAR(weaponRateMap) getOrDefault [toLowerANSI _weapon, -1];

    if (_listed >= 0) then {
        _listed
    } else {
        private _entry = configFile >> "CfgWeapons" >> _weapon >> "mhwm_reliability";

        [1, getNumber _entry] select (isNumber _entry)
    }
}, true];

_chance = _chance * _weaponFactor;

if (_chance <= 0 || {_magazine isEqualTo ""}) exitWith {_chance max 0};

// Subsonic: slower than sound, or on the server's list.
if (isNil QGVAR(subsonicCache)) then {
    GVAR(subsonicCache) = createHashMap;

    {
        GVAR(subsonicCache) set [toLowerANSI trim _x, true];
    } forEach (EGVAR(main,subsonicMags) splitString ",");
};

private _magConfig = configFile >> "CfgMagazines" >> _magazine;

private _subsonic = GVAR(subsonicCache) getOrDefaultCall [toLowerANSI _magazine, {
    private _speed = getNumber (_magConfig >> "initSpeed");

    _speed > 0 && {_speed < 340}
}, true];

if (_subsonic) then {
    _chance = _chance * EGVAR(main,subsonicFactor);
};

// Large magazines: drums and casket magazines, not belts.
private _count = getNumber (_magConfig >> "count");

if (_count >= EGVAR(main,bigMagSize) && {!("belt" in toLowerANSI _magazine)} && {!("box" in toLowerANSI _magazine)}) then {
    _chance = _chance * EGVAR(main,bigMagFactor);
};

// ACE Overheating: the barrel's temperature.
if (HAS_ACE_OVERHEATING && {EGVAR(main,heatFactor) > 0}) then {
    private _temp = _unit getVariable [format ["ace_overheating_%1_temp", _weapon], 0];

    _chance = _chance * (1 + EGVAR(main,heatFactor) * ((_temp max 0) / 500));
};

(_chance max 0) min 1
