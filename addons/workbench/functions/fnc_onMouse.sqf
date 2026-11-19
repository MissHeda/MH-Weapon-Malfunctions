#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The mouse on the workbench. A left press on a part (fnc_hotspots, placed on the screen by fnc_onFrame) takes hold of it;
 * the drag itself is followed every frame (fnc_onFrame), the release decides what the hand did:
 *   handle        back past RACK_FULL: rack; past RACK_SHORT: a short stroke; less: let go gently, nothing.
 *                 Held all the way back for LOCK_HOLD (fnc_onFrame), or a right click there: the bolt locks open.
 *   handleLocked  a click on the locked bolt: released, it runs forward
 *   magPress      dragged down most of the way: the magazine drops; a click: a tap
 *   magInsert     up into the well all the way: in - seated if the hand kept to the well's line (INSERT_TOLERANCE),
 *                 else in but not seated
 *   port          swiped most of the way: the stovepipe is swept out
 *   chamber       a stuck case: wiggled until done (fnc_onFrame); a double feed with the magazine out: each round
 *                 dragged out of the port on its own (pull); let go before, nothing
 *   muzzle        a dud: held still, muzzle safe, until the bar is full (WAIT_HOLD, fnc_onFrame)
 * Anywhere else, or with the right button, the drag turns the camera; the wheel zooms.
 *
 * Arguments:
 * 0: "down", "up" or "wheel" <STRING>
 * 1: The display event's arguments <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_event", "_args"];

if (isNil QGVAR(wb) || {GVAR(wb) get "closing"}) exitWith {};

// The manual lies over the bench: its own click closes it, nothing reaches the weapon.
if ("manual" in GVAR(wb)) exitWith {};

private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];
private _drag = GVAR(wb) get "drag";
private _mouse = MOUSE_POS;

if (_event == "wheel") exitWith {
    _args params ["", "_scroll"];

    if !("dist" in _scene) exitWith {};

    _scene set ["dist", (_scene get "dist") * (1 - (_scroll max -3 min 3) * 0.08)];
    call FUNC(camera);
};

_args params ["", "_button"];

private _state = [GVAR(wb) get "unit", GVAR(wb) get "weapon"] call EFUNC(malfunctions,state);
private _points = _scene getOrDefault ["points", createHashMap];
private _object = _scene getOrDefault ["weapon", objNull];

private _fnc_end = {
    GVAR(wb) set ["drag", createHashMap];
    call FUNC(sync);
};

if (_event == "down") exitWith {
    private _kind = _drag getOrDefault ["kind", ""];

    // The right button while the bolt is held all the way back: the catch locks it.
    if (_button == 1 && {_kind == "handle"}) exitWith {
        if ((_drag getOrDefault ["progress", 0]) >= RACK_FULL) then {
            call _fnc_end;
            [ACT_LOCK] call FUNC(act);
        };
    };

    if (_kind != "") exitWith {};

    (GVAR(wb) get "viewRect") params ["_vx", "_vy", "_vw", "_vh"];
    _mouse params ["_mx", "_my"];

    if (_mx < _vx || {_mx > _vx + _vw} || {_my < _vy} || {_my > _vy + _vh}) exitWith {};

    // The part under the mouse, the nearest within reach.
    private _spot = "";
    private _best = HOTSPOT_RADIUS * ((GVAR(wb) getOrDefault ["zoom", 1]) max 0.5);

    if (_button == 0 && {!(GVAR(wb) get "buttons")}) then {
        {
            _x params ["_id", "_screen"];

            private _distance = _mouse distance2D _screen;

            if (_distance < _best) then {
                _best = _distance;
                _spot = _id;
            };
        } forEach (GVAR(wb) getOrDefault ["spotScreen", []]);
    };

    // The middle button held moves the weapon across the view, as in AIO's 3D view ("Reset view" puts it back).
    if (_button == 2) exitWith {
        GVAR(wb) set ["drag", createHashMapFromArray [["kind", "pan"], ["last", _mouse], ["button", _button]]];
    };

    if (_spot isEqualTo "" || {count _points == 0} || {count _state == 0}) exitWith {
        GVAR(wb) set ["drag", createHashMapFromArray [["kind", "orbit"], ["last", _mouse], ["button", _button]]];
    };

    private _fnc_world = {_object modelToWorldVisualWorld _this};
    private _new = createHashMapFromArray [["start", _mouse], ["time", diag_tickTime], ["progress", 0], ["maxDev", 0], ["button", 0]];

    // The drag's line on the screen: from where the part is to where the hand takes it.
    private _fnc_line = {
        params ["_from", "_to"];

        private _s0 = [_from] call FUNC(project);
        private _s1 = [_to] call FUNC(project);

        if (_s0 isEqualTo [] || {_s1 isEqualTo []}) exitWith {false};

        private _vec = [(_s1 select 0) - (_s0 select 0), (_s1 select 1) - (_s0 select 1)];

        // Looked at end on, the line is too short to drag along: then straight down the screen.
        if (vectorMagnitude (_vec + [0]) < 0.02) then {
            _vec = [0, 0.08 * safeZoneH];
        };

        _new set ["from", _s0];
        _new set ["vec", _vec];
        true
    };

    switch (_spot) do {
        case "handle": {
            if ((_state get "bolt") == "locked") exitWith {
                _new set ["kind", "handleLocked"];
            };

            private _at = (_points get "handle") call _fnc_world;
            private _back = _at vectorAdd ((_object vectorModelToWorldVisual (_points get "fwd")) vectorMultiply -(_points get "boltTravel"));

            _new set ["kind", "handle"];
            [_at, _back] call _fnc_line;
        };

        case "mag": {
            private _seated = (_points get "mag") call _fnc_world;
            private _down = _object vectorModelToWorldVisual (_points get "down");
            private _right = _object vectorModelToWorldVisual (_points get "right");
            private _outAt = _seated vectorAdd (_down vectorMultiply TRAVEL_MAG) vectorAdd (_right vectorMultiply 0.04);

            if ((_state get "mag") == "out") then {
                _new set ["kind", "magInsert"];
                [_outAt, _seated] call _fnc_line;
            } else {
                _new set ["kind", "magPress"];
                [_seated, _outAt] call _fnc_line;
            };
        };

        case "port": {
            private _at = (_points get "port") call _fnc_world;
            private _out = vectorNormalized ((_object vectorModelToWorldVisual (_points get "right")) vectorAdd (_object vectorModelToWorldVisual (_points get "up")));

            _new set ["kind", "port"];
            [_at, _at vectorAdd (_out vectorMultiply (TRAVEL_SWEEP * 1.5))] call _fnc_line;
        };

        case "muzzle": {
            _new set ["kind", "muzzle"];
            _new set ["since", diag_tickTime];
        };

        case "chamber": {
            private _chamber = _state get "chamber";

            // Nothing to wiggle free: the hand finds out at once.
            if (_chamber == "empty" || {_chamber == "double" && {(_state get "mag") != "out"}}) exitWith {
                [ACT_CLEAR] call FUNC(act);
            };

            // A double feed: the rounds come out one by one, each dragged up and out of the port.
            if (_chamber == "double") exitWith {
                private _at = ((_points get "port") vectorAdd ((_points get "fwd") vectorMultiply 0.02)) call _fnc_world;
                private _out = vectorNormalized ((_object vectorModelToWorldVisual (_points get "right")) vectorAdd (_object vectorModelToWorldVisual (_points get "up")));

                _new set ["kind", "pull"];
                [_at, _at vectorAdd (_out vectorMultiply (TRAVEL_SWEEP * 1.5))] call _fnc_line;
            };

            _new set ["kind", "chamber"];
            _new set ["needed", switch (_chamber) do {
                case "double": {WIGGLE_DOUBLE};
                case "case": {WIGGLE_CASE};
                default {WIGGLE_ROUND};
            }];
            _new set ["count", 0];
            _new set ["sign", 0];
            _new set ["anchor", _mouse select 0];
        };
    };

    if ("kind" in _new) then {
        GVAR(wb) set ["drag", _new];
    };
};

// ----- Released -----
if (_button != (_drag getOrDefault ["button", -1])) exitWith {};

private _kind = _drag getOrDefault ["kind", ""];
private _progress = _drag getOrDefault ["progress", 0];

call _fnc_end;

switch (_kind) do {
    case "handle": {
        if (_progress >= RACK_FULL) exitWith {[ACT_RACK] call FUNC(act)};
        if (_progress >= RACK_SHORT) exitWith {[ACT_SHORT] call FUNC(act)};
    };

    case "handleLocked": {
        [ACT_RELEASE] call FUNC(act);
    };

    case "magPress": {
        if (_progress >= 0.8) exitWith {[ACT_DROP] call FUNC(act)};

        // A click, not a drag: the tap.
        if (_progress < 0.2) then {[ACT_TAP] call FUNC(act)};
    };

    case "magInsert": {
        if (_progress >= 0.9) then {
            [[ACT_INSERT_LOOSE, ACT_INSERT] select ((_drag getOrDefault ["maxDev", 1]) < INSERT_TOLERANCE)] call FUNC(act);
        };
    };

    case "port": {
        if (_progress >= 0.8) then {[ACT_SWEEP] call FUNC(act)};
    };

    case "pull": {
        if (_progress >= 0.8) then {[ACT_CLEAR] call FUNC(act)};
    };
};
