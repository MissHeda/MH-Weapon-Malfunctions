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

_spots pushBack [
    "handle",
    (_points get "handle") call _fnc_world,
    switch (true) do {
        case (_bolt == "locked"): {LLSTRING(Spot_HandleLocked)};
        case (getNumber (configFile >> "CfgWeapons" >> (GVAR(wb) get "weapon") >> "type") == 2): {LLSTRING(Spot_Slide)};
        default {LLSTRING(Spot_Handle)};
    },
    _bolt != "closed" || {_chamber in ["empty", "dud"]}
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
    _mag != "in" || {_chamber == "double" && {_bolt == "locked"}}
];

if ((_state get "port") == "stovepipe") then {
    _spots pushBack ["port", ((_points get "port") call _fnc_world) vectorAdd ((_points get "right") vectorMultiply 0.02), LLSTRING(Spot_Port), true];
};

if (_bolt == "locked") then {
    _spots pushBack [
        "chamber",
        ((_points get "port") vectorAdd ((_points get "fwd") vectorMultiply 0.02)) call _fnc_world,
        LLSTRING(Spot_Chamber),
        _chamber in ["double", "case", "round", "dud"]
    ];
};

_spots
