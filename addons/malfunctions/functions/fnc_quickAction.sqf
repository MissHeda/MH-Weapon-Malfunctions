#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A quick key: one hand movement blind, without the 3D view. It takes its time (times the server's "Quick key time"), plays
 * the weapon's reload gesture for the bigger movements, and fumbles at the server's chance: a short stroke instead of a
 * rack, a magazine not seated, a tap or a clearing that misses. What the hand felt shows as a note.
 *
 *   tapRack     the immediate action drill: tap, then rack
 *   lockToggle  lock the bolt open, or let it go when it is locked
 *   magToggle   drop the magazine, or insert it when it is out
 *   clear       clear the chamber - or sweep a stovepipe out of the port
 *
 * Arguments:
 * 0: Action <STRING> - tap, rack, tapRack, lockToggle, magToggle, clear
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * ["tapRack"] call mhwm_malfunctions_fnc_quickAction;
 *
 * Public: No
 */

params [["_action", "", [""]]];

private _unit = PLAYER_UNIT;
private _weapon = currentWeapon _unit;

if (!EGVAR(main,enabled) || {!EGVAR(main,quickKeys)} || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};
if (_unit getVariable [QGVAR(busy), false]) exitWith {true};

private _state = [_unit, _weapon] call FUNC(state);

if (count _state == 0) exitWith {false};

// The movements in order, each [action, seconds, fumbled action or "" for a miss].
private _steps = switch (_action) do {
    case ACT_TAP: {[[ACT_TAP, 0.5, ""]]};
    case ACT_RACK: {[[ACT_RACK, 0.9, ACT_SHORT]]};
    case "tapRack": {[[ACT_TAP, 0.5, ""], [ACT_RACK, 0.9, ACT_SHORT]]};
    case "lockToggle": {
        [[[ACT_LOCK, 1.2, ACT_SHORT]], [[ACT_RELEASE, 0.5, ""]]] select ((_state get "bolt") == "locked")
    };
    case "magToggle": {
        [[[ACT_DROP, 0.7, ""]], [[ACT_INSERT, 1.4, ACT_INSERT_LOOSE]]] select ((_state get "mag") == "out")
    };
    case ACT_CLEAR: {
        [[[ACT_CLEAR, 2.5, ""]], [[ACT_SWEEP, 1, ""]]] select ((_state get "port") == "stovepipe" && {(_state get "bolt") != "locked"})
    };
    default {[]};
};

if (_steps isEqualTo []) exitWith {false};

_unit setVariable [QGVAR(busy), true];

private _gesture = getText (configFile >> "CfgWeapons" >> _weapon >> "reloadAction");

if (_gesture isNotEqualTo "" && {_steps findIf {(_x select 0) in [ACT_RACK, ACT_LOCK, ACT_INSERT, ACT_CLEAR]} >= 0}) then {
    _unit playActionNow _gesture;
};

// One step after the other; the next waits for the one before.
private _fnc_step = {
    params ["_unit", "_weapon", "_steps", "_fnc_step"];

    if (_steps isEqualTo [] || {!alive _unit} || {currentWeapon _unit != _weapon}) exitWith {
        _unit setVariable [QGVAR(busy), false];
    };

    (_steps deleteAt 0) params ["_act", "_seconds", "_fumbled"];

    [{
        params ["_unit", "_weapon", "_steps", "_fnc_step", "_act", "_fumbled"];

        if (!alive _unit || {currentWeapon _unit != _weapon}) exitWith {
            _unit setVariable [QGVAR(busy), false];
        };

        private _note = "";
        private _works = false;

        if (random 1 < EGVAR(main,fumble)) then {
            if (_fumbled isEqualTo "") then {
                _note = "Act_Fumbled";
            } else {
                ([_unit, _weapon, _fumbled] call FUNC(act)) params ["_result", "_done"];
                _note = _result;
                _works = _done;
            };
        } else {
            ([_unit, _weapon, _act] call FUNC(act)) params ["_result", "_done"];
            _note = _result;
            _works = _done;
        };

        // Cleared: whatever steps are left are not needed. The note of "cleared" comes from fnc_clear.
        if (_works) exitWith {
            _unit setVariable [QGVAR(busy), false];
        };

        if (_note isNotEqualTo "" && {EGVAR(main,notify)}) then {
            [localize format ["STR_mhwm_malfunctions_%1", _note]] call CBA_fnc_notify;
        };

        [_unit, _weapon, _steps, _fnc_step] call _fnc_step;
    }, [_unit, _weapon, _steps, _fnc_step, _act, _fumbled], _seconds * EGVAR(main,quickTime)] call CBA_fnc_waitAndExecute;
};

[_unit, _weapon, _steps, _fnc_step] call _fnc_step;

true
