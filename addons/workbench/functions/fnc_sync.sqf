#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The scene shows the weapon as it is, and as the hand holds it right now:
 * - the bolt: back as far as it is dragged, else locked open, a little back when out of battery, or home
 * - the magazine: seated, a little low when loose, below the well when out - or as far as it is dragged
 * - a stovepipe's case sticking out of the port, swept out as far as it is dragged
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];
private _points = _scene getOrDefault ["points", createHashMap];
private _object = _scene getOrDefault ["weapon", objNull];

if (count _points == 0 || {isNull _object}) exitWith {};

private _state = [GVAR(wb) get "unit", GVAR(wb) get "weapon"] call EFUNC(malfunctions,state);
private _drag = GVAR(wb) get "drag";
private _kind = _drag getOrDefault ["kind", ""];
private _progress = _drag getOrDefault ["progress", 0];
private _bolt = _state getOrDefault ["bolt", "closed"];
private _mag = _state getOrDefault ["mag", "in"];
private _port = _state getOrDefault ["port", "clear"];

private _fwd = _points get "fwd";
private _up = _points get "up";
private _right = _points get "right";
private _down = _points get "down";

private _fnc_world = {_object modelToWorldVisualWorld _this};

// Places a simple object's model origin (not its centre) at a point.
private _fnc_place = {
    params ["_thing", "_at", "_dir", "_upVec"];

    _thing setVectorDirAndUp [_dir, _upVec];
    _thing setPosWorld (_at vectorAdd ((getPosWorld _thing) vectorDiff (_thing modelToWorldVisualWorld [0, 0, 0])));
};

// ----- The bolt -----
private _phase = switch (true) do {
    case (_kind == "handle"): {_progress};
    case (_bolt == "locked"): {1};
    case (_bolt == "short"): {0.25};
    default {0};
};

if (_phase != (_scene getOrDefault ["boltPhase", -1])) then {
    _scene set ["boltPhase", _phase];

    {
        _object animate [_x, _phase, true];
    } forEach (_points get "boltAnims");
};

// ----- The magazine -----
private _offset = switch (true) do {
    case (_kind == "magPress"): {([0, 0.012] select (_mag == "loose")) + _progress * TRAVEL_MAG};
    case (_kind == "magInsert"): {TRAVEL_MAG * (1 - _progress)};
    case (_mag == "out"): {TRAVEL_MAG};
    case (_mag == "loose"): {0.012};
    default {0};
};

private _magObject = _scene getOrDefault ["mag", objNull];

if (!isNull _magObject) then {
    private _seated = (_points get "mag") call _fnc_world;
    private _at = _seated vectorAdd (_down vectorMultiply _offset);

    // Out of the well, the magazine lies a little to the side, where the hand holds it.
    if (_offset > 0.05) then {
        _at = _at vectorAdd (_right vectorMultiply (0.04 * ((_offset - 0.05) / (TRAVEL_MAG - 0.05))));
    };

    [_magObject, _at, _points get "magDir", _points get "magUp"] call _fnc_place;
    _magObject hideObject false;
};

// A magazine built into the model: hidden while it is out.
private _magOut = _offset > 0.05;

if (_magOut != (_scene getOrDefault ["magHidden", false])) then {
    _scene set ["magHidden", _magOut];

    {
        _object hideSelection [_x, _magOut];
    } forEach (_points get "magSelections");
};

// ----- The stovepipe's case -----
private _case = _scene getOrDefault ["case", objNull];

if (!isNull _case) then {
    if (_port == "stovepipe") then {
        private _sweep = [0, _progress] select (_kind == "port");
        private _out = vectorNormalized (_right vectorAdd _up);
        private _at = ((_points get "port") call _fnc_world)
            vectorAdd (_right vectorMultiply 0.012)
            vectorAdd (_up vectorMultiply 0.008)
            vectorAdd (_out vectorMultiply (_sweep * TRAVEL_SWEEP));

        [_case, _at, _up, _fwd vectorMultiply -1] call _fnc_place;
        _case hideObject false;
    } else {
        _case hideObject true;
    };
};
