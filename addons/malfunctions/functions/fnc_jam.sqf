#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The weapon malfunctions. Picks the cause by the server's weights unless one is given, sets up how the weapon looks now and
 * stops the burst. A player's trigger is blocked from now on (an action on DefaultAction, as ACE does it - the magazine keeps
 * its rounds, a reload stays an honest reload); an AI unit clears its weapon by itself (fnc_aiClear).
 *
 * How each cause leaves the weapon (bolt / chamber / ejection port / magazine):
 *   feed       closed / empty  / clear     / loose (most times) or in
 *   dud        closed / dud    / clear     / in
 *   stovepipe  short  / empty  / stovepipe / in
 *   double     short  / double / clear     / in
 *   extract    short  / case   / clear     / in
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 * 2: Cause <STRING> (default: "" - picked by the weights)
 *
 * Return Value:
 * Jammed <BOOL>
 *
 * Example:
 * [player, primaryWeapon player, "double"] call mhwm_malfunctions_fnc_jam;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_cause", "", [""]], ["_stopBurst", true, [true]]];

if (isNull _unit || {_weapon isEqualTo ""} || {!local _unit}) exitWith {false};
if (count ([_unit, _weapon] call FUNC(state)) > 0) exitWith {false};

if !(_cause in CAUSES) then {
    private _weights = [];

    {
        _weights append [_x, missionNamespace getVariable [format ["mhwm_main_weight_%1", _x], 1]];
    } forEach CAUSES;

    _cause = if ((_weights select {_x isEqualType 0}) findIf {_x > 0} < 0) then {""} else {selectRandomWeighted _weights};
};

if (_cause isEqualTo "") exitWith {false};

private _state = createHashMapFromArray [["cause", _cause], ["tried", false], ["port", "clear"], ["mag", "in"]];

switch (_cause) do {
    case CAUSE_FEED: {
        _state set ["bolt", "closed"];
        _state set ["chamber", "empty"];
        _state set ["mag", ["in", "loose"] select (random 1 < 0.6)];
        // Seated and still nothing fed: the magazine's spring is weak - only a fresh magazine feeds.
        _state set ["weakMag", (_state get "mag") == "in"];
    };
    case CAUSE_DUD: {
        _state set ["bolt", "closed"];
        _state set ["chamber", "dud"];
        // It might yet be a hang fire: wait a moment, muzzle safe, before the bolt comes back.
        _state set ["hang", true];
    };
    case CAUSE_STOVEPIPE: {
        _state set ["bolt", "short"];
        _state set ["chamber", "empty"];
        _state set ["port", "stovepipe"];
    };
    case CAUSE_DOUBLE: {
        _state set ["bolt", "short"];
        _state set ["chamber", "double"];
        // Two rounds, pulled out one at a time.
        _state set ["stuck", 2];
    };
    case CAUSE_EXTRACT: {
        _state set ["bolt", "short"];
        _state set ["chamber", "case"];
    };
};

[_unit, _weapon, _state] call FUNC(state);

private _isPlayer = isPlayer _unit || {_unit == PLAYER_UNIT};

// AI: no rounds until it has cleared the weapon by itself.
if (!_isPlayer) exitWith {
    [_unit, _weapon] call FUNC(aiClear);
    true
};

// Stop the burst: no rounds for a frame, then the magazine as it was. ACE's jam did that already - and its rounds are
// at 0 for this frame, so taking them now would empty the magazine (seen in the ACE test).
if (_stopBurst) then {
    private _ammo = _unit ammo _weapon;

    _unit setAmmo [_weapon, 0];

    [{
        params ["_unit", "_weapon", "_ammo"];

        if (alive _unit && {_weapon in [primaryWeapon _unit, handgunWeapon _unit]}) then {
            _unit setAmmo [_weapon, _ammo];
        };
    }, [_unit, _weapon, _ammo]] call CBA_fnc_execNextFrame;
};

// The trigger does nothing while the weapon in the hands is jammed (fnc_isBlocked) - one action per unit, as ACE adds it.
if ((_unit getVariable [QGVAR(blockUnit), objNull]) != _unit) then {
    private _id = _unit addAction [
        "",
        {
            if (inputAction "DefaultAction" == 0) exitWith {};

            [{[_this select 1] call FUNC(onDryFire)}, _this] call CBA_fnc_directCall;
        },
        nil,
        -1,
        false,
        true,
        "DefaultAction",
        "_this == (missionNamespace getVariable ['ACE_player', player]) && {[_this] call mhwm_malfunctions_fnc_isBlocked}"
    ];

    _unit setVariable [QGVAR(blockId), _id];
    _unit setVariable [QGVAR(blockUnit), _unit];
};

// The notice with the keys: each player may switch it off (Mia).
if (EGVAR(main,jamNotice) && {_unit == PLAYER_UNIT}) then {
    [
        [LLSTRING(Jammed), 1.2, COLOR_RED],
        [LLSTRING(Jammed_Hint)]
    ] call CBA_fnc_notify;
};

true
