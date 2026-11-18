#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The chance that this shot jams the weapon: the server's rate per 1000 rounds, times
 * - the weapon's own factor: the server's "Weapon reliability" list first, else mhwm_reliability in its config (1 without),
 * - subsonic magazines: slower than sound (initSpeed under 340 m/s) in a weapon whose fastest magazine is faster - a .45
 *   built for subsonic rounds does not jam more with them - or listed by the server,
 *
 * Both server lists take wildcards: "rhs_weap_ak*:0.5", "*_SD_*". An exact class wins over a wildcard.
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

// A list entry, lower case, made a full-match pattern when it holds a "*": [exact, pattern] - one of them "".
private _fnc_entry = {
    private _entry = toLowerANSI trim _this;

    if ("*" in _entry) then {
        ["", (_entry regexReplace ["[^a-z0-9_*]/g", ""]) regexReplace ["\*/g", ".*"]]
    } else {
        [_entry, ""]
    }
};

private _chance = EGVAR(main,rate) / 1000;

if (_chance <= 0) exitWith {0};

// The server's list, "class:factor, class:factor", read again whenever it changes (initSettings).
if (isNil QGVAR(weaponRateMap)) then {
    GVAR(weaponRateMap) = createHashMap;
    GVAR(weaponRateWild) = [];
    GVAR(weaponCache) = createHashMap;

    {
        private _pair = (_x splitString ":") apply {trim _x};

        if (count _pair == 2) then {
            ((_pair select 0) call _fnc_entry) params ["_exact", "_pattern"];
            private _factor = parseNumber (_pair select 1);

            if (_exact isEqualTo "") then {
                if (_pattern isNotEqualTo "") then {GVAR(weaponRateWild) pushBack [_pattern, _factor]};
            } else {
                GVAR(weaponRateMap) set [_exact, _factor];
            };
        };
    } forEach (EGVAR(main,weaponRates) splitString ",");
};

private _weaponFactor = GVAR(weaponCache) getOrDefaultCall [toLowerANSI _weapon, {
    private _lower = toLowerANSI _weapon;
    private _listed = GVAR(weaponRateMap) getOrDefault [_lower, -1];

    if (_listed < 0) then {
        private _index = GVAR(weaponRateWild) findIf {_lower regexMatch (_x select 0)};
        if (_index >= 0) then {_listed = GVAR(weaponRateWild) select _index select 1};
    };

    if (_listed >= 0) then {
        _listed
    } else {
        private _entry = configFile >> "CfgWeapons" >> _weapon >> "mhwm_reliability";

        [1, getNumber _entry] select (isNumber _entry)
    }
}, true];

_chance = _chance * _weaponFactor;

if (_chance <= 0 || {_magazine isEqualTo ""}) exitWith {_chance max 0};

// Subsonic: on the server's list, or slower than sound in a weapon made for faster rounds.
if (isNil QGVAR(subsonicCache)) then {
    GVAR(subsonicCache) = createHashMap;
    GVAR(subsonicList) = createHashMap;
    GVAR(subsonicWild) = [];

    {
        (_x call _fnc_entry) params ["_exact", "_pattern"];

        if (_exact isNotEqualTo "") then {GVAR(subsonicList) set [_exact, true]};
        if (_pattern isNotEqualTo "") then {GVAR(subsonicWild) pushBack _pattern};
    } forEach (EGVAR(main,subsonicMags) splitString ",");
};

private _magConfig = configFile >> "CfgMagazines" >> _magazine;

private _subsonic = GVAR(subsonicCache) getOrDefaultCall [toLowerANSI (_weapon + "|" + _magazine), {
    private _lower = toLowerANSI _magazine;

    if (_lower in GVAR(subsonicList) || {GVAR(subsonicWild) findIf {_lower regexMatch _x} >= 0}) exitWith {true};

    private _speed = getNumber (_magConfig >> "initSpeed");

    if (_speed <= 0 || {_speed >= 340}) exitWith {false};

    // The weapon's fastest magazine: a weapon only ever fed slow rounds is built for them.
    private _fastest = selectMax ((compatibleMagazines _weapon) apply {getNumber (configFile >> "CfgMagazines" >> _x >> "initSpeed")});

    !isNil "_fastest" && {_fastest >= 340}
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
