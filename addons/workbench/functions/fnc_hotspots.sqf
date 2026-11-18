#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The parts the hands can work on right now, as the weapon is:
 *   handle   the charging handle or slide: drag back (rack, right click at the end locks it), or click when locked (release)
 *   mag      the magazine: click to tap it home, drag down to drop it; out, drag it up into the well
 *   port     a stovepipe's case: swipe it out
 *   chamber  with the bolt locked: hold and wiggle to clear what is in it
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[id, point (ASL), label, needs attention], ...] <ARRAY>
 *
 * Public: No
 */

private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];
private _points = _scene getOrDefault ["points", createHashMap];
private _object = _scene getOrDefault ["weapon", objNull];

if (count _points == 0 || {isNull _object}) exitWith {[]};

private _state = [GVAR(wb) get "unit", GVAR(wb) get "weapon"] call EFUNC(malfunctions,state);

if (count _state == 0) exitWith {[]};

private _bolt = _state get "bolt";
private _mag = _state get "mag";
private _chamber = _state get "chamber";
private _fnc_world = {_object modelToWorldVisualWorld _this};
private _spots = [];

// Only the part of the step to do now asks for the hands (fnc_steps): it alone is marked red, with what to do as its label.
private _next = ([_state] call FUNC(steps)) param [0, ""];
private _nextPart = switch (_next) do {
    case "tap";
    case "drop";
    case "insert": {"mag"};
    case "rack";
    case "lock";
    case "release": {"handle"};
    case "sweep": {"port"};
    case "clear";
    case "pull": {"chamber"};
    case "wait": {"muzzle"};
    default {""};
};

_spots pushBack [
    "handle",
    (_points get "handle") call _fnc_world,
    switch (true) do {
        case (_bolt == "locked"): {LLSTRING(Spot_HandleLocked)};
        case (getNumber (configFile >> "CfgWeapons" >> (GVAR(wb) get "weapon") >> "type") == 2): {LLSTRING(Spot_Slide)};
        default {LLSTRING(Spot_Handle)};
    },
    _nextPart == "handle"
];

private _magAt = (_points get "mag") call _fnc_world;

if (_mag == "out") then {
    _magAt = _magAt vectorAdd ((_points get "down") vectorMultiply TRAVEL_MAG) vectorAdd ((_points get "right") vectorMultiply 0.04);
};

_spots pushBack [
    "mag",
    _magAt,
    switch (_mag) do {
        case "out": {LLSTRING(Spot_MagOut)};
        case "loose": {LLSTRING(Spot_MagLoose)};
        default {LLSTRING(Spot_Mag)};
    },
    _nextPart == "mag"
];

if ((_state get "port") == "stovepipe") then {
    _spots pushBack ["port", ((_points get "port") call _fnc_world) vectorAdd ((_points get "right") vectorMultiply 0.02), LLSTRING(Spot_Port), _nextPart == "port"];
};

if (_bolt == "locked") then {
    _spots pushBack [
        "chamber",
        ((_points get "port") vectorAdd ((_points get "fwd") vectorMultiply 0.02)) call _fnc_world,
        LLSTRING(Spot_Chamber),
        _nextPart == "chamber"
    ];
};

// A dud: the muzzle, held safe for a moment before the bolt comes back.
if (_state getOrDefault ["hang", false]) then {
    _spots pushBack ["muzzle", (_points get "muzzle") call _fnc_world, LLSTRING(Spot_Muzzle), _nextPart == "muzzle"];
};

// The marked part's label says what to do with it.
{
    if (_x select 3) then {_x set [2, localize format ["STR_mhwm_workbench_Spot_Do_%1", _next]]};
} forEach _spots;

_spots
