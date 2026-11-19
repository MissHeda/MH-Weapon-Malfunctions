#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The blind Tap-Rack key: clearing without the 3D view. Its time comes from the server, one setting per malfunction
 * (main_blindTime_<cause>); the weapon's reload gesture plays for the bigger movements and what the hand felt shows as a
 * note (CBA's notification).
 *
 * The server says, for each malfunction, whether Tap-Rack clears it (main_blindFix_<cause>, Mia). If it does, the key
 * plays the whole remedy of the workbench's notebook (workbench_fnc_steps) blind - a double feed or a stuck case too,
 * only slower. If not, it is the plain drill - tap, (wait out a dud,) rack - and fails with a note of what the hands felt:
 * that one needs the 3D view.
 *
 * Arguments:
 * 0: Action <STRING> - "tapRack"
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * ["tapRack"] call mhwm_malfunctions_fnc_quickAction;
 *
 * Public: No
 */

params [["_action", "tapRack", [""]]];

private _unit = PLAYER_UNIT;
private _weapon = currentWeapon _unit;

if (!EGVAR(main,enabled) || {!EGVAR(main,quickKeys)} || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};
if (_unit getVariable [QGVAR(busy), false]) exitWith {true};

private _state = [_unit, _weapon] call FUNC(state);

if (count _state == 0) exitWith {false};

// How long each hand movement takes by itself; scaled so the whole drill takes the server's time for this malfunction.
private _base = createHashMapFromArray [
    [ACT_TAP, 0.5], [ACT_RACK, 0.9], [ACT_WAIT, 1.5], [ACT_LOCK, 1.2], [ACT_RELEASE, 0.5], [ACT_DROP, 0.7],
    [ACT_INSERT, 1.4], [ACT_CLEAR, 2.5], [ACT_SWEEP, 1]
];

private _cause = _state getOrDefault ["cause", CAUSE_FEED];
private _fixes = missionNamespace getVariable [format ["mhwm_main_blindFix_%1", _cause], false];

private _acts = if (_fixes) then {
    // The notebook's steps, as hand movements: a pulled round of a double feed is one clearing each.
    private _map = createHashMapFromArray [
        ["wait", ACT_WAIT], ["tap", ACT_TAP], ["rack", ACT_RACK], ["lock", ACT_LOCK], ["release", ACT_RELEASE],
        ["drop", ACT_DROP], ["insert", ACT_INSERT], ["clear", ACT_CLEAR], ["pull", ACT_CLEAR], ["sweep", ACT_SWEEP]
    ];
    (([_state] call EFUNC(workbench,steps)) select {_x in _map}) apply {_map get _x}
} else {
    // Blind, a dud is waited out too before the rack.
    [[ACT_TAP, ACT_RACK], [ACT_TAP, ACT_WAIT, ACT_RACK]] select (_state getOrDefault ["hang", false])
};

if (_acts isEqualTo []) exitWith {false};

// The server's time for this malfunction; a weak magazine is swapped as well, so it takes twice the feed time.
private _total = missionNamespace getVariable [format ["mhwm_main_blindTime_%1", _cause], 2];

if (_cause == CAUSE_FEED && {_state getOrDefault ["weakMag", false]} && {_fixes}) then {_total = _total * 2};

private _sum = 0;
{_sum = _sum + (_base getOrDefault [_x, 1])} forEach _acts;

private _steps = _acts apply {[_x, (_base getOrDefault [_x, 1]) * _total / (_sum max 0.1), ["", ACT_SHORT] select (_x == ACT_RACK)]};

_unit setVariable [QGVAR(busy), true];

private _gesture = getText (configFile >> "CfgWeapons" >> _weapon >> "reloadAction");

if (_gesture isNotEqualTo "" && {_acts findIf {_x in [ACT_RACK, ACT_LOCK, ACT_INSERT, ACT_CLEAR]} >= 0}) then {
    _unit playActionNow _gesture;
};

// One step after the other; the next waits for the one before.
private _fnc_step = {
    params ["_unit", "_weapon", "_steps", "_fnc_step", "_fixes"];

    if (_steps isEqualTo [] || {!alive _unit} || {currentWeapon _unit != _weapon}) exitWith {
        _unit setVariable [QGVAR(busy), false];
    };

    (_steps deleteAt 0) params ["_act", "_seconds", "_fumbled"];

    [{
        params ["_unit", "_weapon", "_steps", "_fnc_step", "_act", "_fumbled", "_fixes"];

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

        // Along the whole remedy only the last note counts - a note for every step was a flood.
        if (_note isNotEqualTo "" && {EGVAR(main,notify)} && {!_fixes || {_steps isEqualTo []}}) then {
            [localize format ["STR_mhwm_malfunctions_%1", _note]] call CBA_fnc_notify;
        };

        [_unit, _weapon, _steps, _fnc_step, _fixes] call _fnc_step;
    }, [_unit, _weapon, _steps, _fnc_step, _act, _fumbled, _fixes], _seconds] call CBA_fnc_waitAndExecute;
};

[_unit, _weapon, _steps, _fnc_step, _fixes] call _fnc_step;

true
