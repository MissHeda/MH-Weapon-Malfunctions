#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the hands still have to do, in order, worked out from the weapon as it is now: the side panel shows the first one
 * large with its picture and the rest as a list (fnc_refresh), the 3D view marks the first one's part (fnc_hotspots).
 *
 * The weapon is played through on a copy of its state, one step at a time, until it would work again. Without "Show what
 * is wrong" the chamber is hidden while the bolt is closed: then the list stops after locking the bolt open with "look".
 *
 * Steps: tap, rack, lock, release, drop, insert, clear, sweep, look
 *
 * Arguments:
 * 0: State <HASHMAP> (default: the open bench's weapon)
 *
 * Return Value:
 * Steps <ARRAY of STRING>, empty when the weapon works
 *
 * Example:
 * [] call mhwm_workbench_fnc_steps;
 *
 * Public: No
 */

params [["_state", createHashMap]];

if (count _state == 0 && {!isNil QGVAR(wb)}) then {
    _state = [GVAR(wb) get "unit", GVAR(wb) get "weapon"] call EFUNC(malfunctions,state);
};

if (count _state == 0) exitWith {[]};

private _s = +_state;
private _steps = [];
private _hidden = !EGVAR(main,diagnosis) && {(_s get "bolt") != "locked"};

for "_i" from 1 to 10 do {
    private _bolt = _s get "bolt";
    private _chamber = _s get "chamber";
    private _mag = _s get "mag";

    private _step = switch (true) do {
        case ((_s get "port") == "stovepipe"): {"sweep"};
        case (_chamber in ["double", "case"]): {
            switch (true) do {
                case (_bolt != "locked"): {"lock"};
                case (_mag != "out"): {"drop"};
                default {"clear"};
            }
        };
        case (_bolt == "locked"): {["release", "insert"] select (_mag == "out")};
        case (_mag == "out"): {"insert"};
        case (_mag == "loose"): {"tap"};
        case (_bolt != "closed" || {_chamber in ["empty", "dud"]}): {"rack"};
        default {""};
    };

    if (_step isEqualTo "") exitWith {};

    _steps pushBack _step;

    // A closed bolt hides the chamber: a short bolt is opened and looked into first.
    if (_hidden && {_step == "lock"}) exitWith {_steps pushBack "look"};

    switch (_step) do {
        case "sweep": {_s set ["port", "clear"]; _s set ["bolt", "closed"]; _s set ["chamber", "round"]};
        case "lock": {
            _s set ["bolt", "locked"];
            if (_chamber in ["round", "dud"]) then {_s set ["chamber", "empty"]};
        };
        case "drop": {_s set ["mag", "out"]};
        case "clear": {_s set ["chamber", "empty"]};
        case "insert": {_s set ["mag", "in"]};
        case "tap": {_s set ["mag", "in"]};
        case "release";
        case "rack": {_s set ["bolt", "closed"]; _s set ["chamber", "round"]};
    };
};

_steps
