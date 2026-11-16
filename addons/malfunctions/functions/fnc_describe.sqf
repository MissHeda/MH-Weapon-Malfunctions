#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the player sees and feels on the jammed weapon, line by line. With "Show what is wrong" off, only what anyone would
 * see at a glance - where the bolt and the magazine are - and the chamber only once the bolt is locked open and the player looks in.
 * A dud is known only after the trigger was pulled on it.
 *
 * Arguments:
 * 0: State <HASHMAP> (fnc_state)
 *
 * Return Value:
 * Lines: [text, is a problem] <ARRAY>
 *
 * Example:
 * [[player, primaryWeapon player] call mhwm_malfunctions_fnc_state] call mhwm_malfunctions_fnc_describe;
 *
 * Public: No
 */

params [["_state", createHashMap, [createHashMap]]];

if (count _state == 0) exitWith {[[LLSTRING(See_Works), false]]};

private _full = EGVAR(main,diagnosis);
private _bolt = _state get "bolt";
private _chamber = _state get "chamber";
private _lines = [];

_lines pushBack (switch (_bolt) do {
    case "short": {[LLSTRING(See_BoltShort), true]};
    case "locked": {[LLSTRING(See_BoltLocked), false]};
    default {[LLSTRING(See_BoltClosed), false]};
});

if ((_state get "port") == "stovepipe") then {
    _lines pushBack [LLSTRING(See_Stovepipe), true];
};

if (_full || {_bolt == "locked"}) then {
    _lines pushBack (switch (_chamber) do {
        case "round": {[LLSTRING(See_ChamberRound), false]};
        case "dud": {
            [[LLSTRING(See_ChamberRound), false], [LLSTRING(See_Dud), true]] select (_state getOrDefault ["tried", false] && {_bolt != "locked"})
        };
        case "double": {[LLSTRING(See_Double), true]};
        case "case": {[LLSTRING(See_Case), true]};
        default {[LLSTRING(See_ChamberEmpty), _bolt != "locked"]};
    });
};

_lines pushBack (switch (_state get "mag") do {
    case "loose": {[LLSTRING(See_MagLoose), true]};
    case "out": {[LLSTRING(See_MagOut), true]};
    default {[LLSTRING(See_MagIn), false]};
});

_lines
