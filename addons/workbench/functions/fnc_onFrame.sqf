#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Every frame while the workbench is open: closes it when the player can no longer work on the weapon; reads the model's
 * points until it has loaded (fnc_points); follows the drag - the camera's turn, how far a part is moved along its line and
 * how far the mouse strayed from it, the chamber's wiggle; shows the parts on the screen with their marks and labels, the
 * drag's track of dots, the tap's pulsing ring and the wiggle's bar; keeps the scene as the weapon is (fnc_sync).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

if (isNil QGVAR(wb)) exitWith {};

private _unit = GVAR(wb) get "unit";
private _display = GVAR(wb) get "display";

if (isNull _display || {!alive _unit} || {currentWeapon _unit != (GVAR(wb) get "weapon")} || {!isNull objectParent _unit}) exitWith {
    if (!isNull _display) then {closeDialog 0};
};

private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];
private _ctrls = GVAR(wb) get "ctrls";
private _drag = GVAR(wb) get "drag";
private _kind = _drag getOrDefault ["kind", ""];
private _mouse = MOUSE_POS;
private _theme = GVAR(wb) get "theme";

if ("weapon" in _scene && {!("points" in _scene)}) then {
    call FUNC(points);
};

// ----- The middle button, held: moving the weapon -----
// Also read from the mouse itself (inputMouse: 2 click and hold, 4 double click and hold): the display's press did not
// always reach the bench (Mia: "holding the middle button does nothing"). A move begun so ends when the button is up.
private _middle = inputMouse 2;

if (_kind == "" && {_middle in [2, 4]} && {!("manual" in GVAR(wb))}) then {
    (GVAR(wb) get "viewRect") params ["_vx", "_vy", "_vw", "_vh"];
    _mouse params ["_mx", "_my"];

    if (_mx >= _vx && {_mx <= _vx + _vw} && {_my >= _vy} && {_my <= _vy + _vh}) then {
        _drag = createHashMapFromArray [["kind", "pan"], ["last", _mouse], ["button", 2], ["polled", true]];
        GVAR(wb) set ["drag", _drag];
        _kind = "pan";
    };
};

if (_kind == "pan" && {_drag getOrDefault ["polled", false]} && {_middle == 0}) then {
    _drag = createHashMap;
    GVAR(wb) set ["drag", _drag];
    _kind = "";
};

// ----- The drag -----
switch (true) do {
    case (_kind == "orbit"): {
        private _last = _drag get "last";
        private _dx = (_mouse select 0) - (_last select 0);
        private _dy = (_mouse select 1) - (_last select 1);

        _drag set ["last", _mouse];

        if ("az" in _scene && {_dx != 0 || {_dy != 0}}) then {
            _scene set ["az", (_scene get "az") + _dx / safeZoneW * 300];
            _scene set ["pitch", (_scene get "pitch") + _dy / safeZoneH * 150];
            call FUNC(camera);
        };
    };

    // The weapon follows the mouse: the camera and its aim move the other way, by what a screen distance is at the
    // weapon's distance - at most twice the weapon's size away from where it started.
    case (_kind == "pan"): {
        private _last = _drag get "last";
        private _dx = (_mouse select 0) - (_last select 0);
        private _dy = (_mouse select 1) - (_last select 1);

        _drag set ["last", _mouse];

        if ("camRight" in _scene && {_dx != 0 || {_dy != 0}}) then {
            (GVAR(wb) get "picRect") params ["", "", "_pw", "_ph"];

            private _tanV = SCENE_TAN;
            private _dist = _scene get "dist";
            private _shift = ((_scene get "camRight") vectorMultiply (-_dx / _pw * 2 * _tanV * SCENE_ASPECT * _dist))
                vectorAdd ((_scene get "camUp") vectorMultiply (_dy / _ph * 2 * _tanV * _dist));
            private _target = (_scene get "target") vectorAdd _shift;
            private _origin = _scene getOrDefault ["origin", _target];
            private _limit = ((_scene getOrDefault ["points", createHashMap]) getOrDefault ["size", 1]) * 2;
            private _offset = _target vectorDiff _origin;

            if (vectorMagnitude _offset > _limit) then {
                _target = _origin vectorAdd ((vectorNormalized _offset) vectorMultiply _limit);
            };

            _scene set ["target", _target];
            call FUNC(camera);
        };
    };

    case (_kind == "chamber"): {
        private _mx = _mouse select 0;
        private _anchor = _drag get "anchor";
        private _step = 0.012 * safeZoneW;
        private _sign = _drag get "sign";

        // A back-and-forth counts once the mouse went the other way far enough.
        if (abs (_mx - _anchor) > _step) then {
            private _now = [-1, 1] select (_mx > _anchor);

            if (_now != _sign) then {
                _drag set ["sign", _now];
                _drag set ["count", (_drag get "count") + 1];
                [_unit, ["rattle", "click_1"] select ((_drag get "count") % 2)] call EFUNC(malfunctions,playSound);
            };

            _drag set ["anchor", _mx];
        };

        _drag set ["progress", ((_drag get "count") / (_drag get "needed")) min 1];

        if ((_drag get "count") >= (_drag get "needed")) then {
            GVAR(wb) set ["drag", createHashMap];
            [ACT_CLEAR] call FUNC(act);
        };
    };

    case ("vec" in _drag): {
        private _vec = _drag get "vec";
        private _start = _drag get "start";
        private _d = [(_mouse select 0) - (_start select 0), (_mouse select 1) - (_start select 1)];
        private _len2 = (_vec select 0) ^ 2 + (_vec select 1) ^ 2;
        private _along = ((_d select 0) * (_vec select 0) + (_d select 1) * (_vec select 1)) / _len2;
        private _across = abs ((_d select 0) * (_vec select 1) - (_d select 1) * (_vec select 0)) / _len2;

        _drag set ["progress", (_along max 0) min 1];
        _drag set ["maxDev", (_drag get "maxDev") max _across];

        // The bolt held all the way back: after a moment the catch locks it open.
        if (_kind == "handle") then {
            if ((_along max 0) >= RACK_FULL) then {
                if !("heldSince" in _drag) then {_drag set ["heldSince", diag_tickTime]};

                private _hold = (diag_tickTime - (_drag get "heldSince")) / LOCK_HOLD;
                _drag set ["hold", _hold min 1];

                if (_hold >= 1) then {
                    GVAR(wb) set ["drag", createHashMap];
                    [ACT_LOCK] call FUNC(act);
                };
            } else {
                _drag deleteAt "heldSince";
                _drag set ["hold", 0];
            };
        };
    };
};

call FUNC(sync);

// ----- The parts on the screen -----
private _spots = call FUNC(hotspots);
private _marks = _ctrls get "marks";
private _spotScreen = [];
private _hovered = "";
private _placed = [];

(GVAR(wb) get "viewRect") params ["_vx", "_vy", "_vw", "_vh"];

{
    _x params ["_ring", "_label"];

    private _spot = _spots param [_forEachIndex, []];
    private _screen = if (_spot isEqualTo []) then {[]} else {[_spot select 1] call FUNC(project)};

    if (_screen isEqualTo [] || {(_screen select 0) < _vx} || {(_screen select 0) > _vx + _vw} || {(_screen select 1) < _vy} || {(_screen select 1) > _vy + _vh}) then {
        _ring ctrlShow false;
        _label ctrlShow false;
    } else {
        _spot params ["_id", "", "_text", "_attention"];

        _spotScreen pushBack [_id, _screen];

        private _over = (_mouse distance2D _screen) < HOTSPOT_RADIUS && {_kind == ""};
        private _active = switch (_id) do {
            case "handle": {_kind in ["handle", "handleLocked"]};
            case "mag": {_kind in ["magPress", "magInsert"]};
            default {_kind == _id};
        };

        if (_over) then {_hovered = _id};

        private _size = HOTSPOT_SIZE * (switch (true) do {
            case (_over || _active): {1.35};
            case (_attention): {1.2 + 0.15 * sin (diag_tickTime * 360)};
            default {0.6};
        });
        private _w = _size * pixelW / pixelH;

        _ring ctrlSetPosition [(_screen select 0) - _w / 2, (_screen select 1) - _size / 2, _w, _size];
        // A part that needs the hands: the warning red; under the mouse or held: the player's accent; else quiet white.
        _ring ctrlSetTextColor (switch (true) do {
            case (_over || _active): {_theme get "accent"};
            case (_attention): {_theme get "warn"};
            default {[1, 1, 1, 0.6]};
        });
        _ring ctrlShow true;
        _ring ctrlCommit 0;

        // Labels of parts close together kept apart (the first test had "Bolt (locked)" across "Chamber"): right of the
        // ring, else left of it (right-aligned), else above or below it - never further, pushing them down only put
        // "Chamber" two labels below its ring. Each label takes about the first 60 % of its box.
        private _lw = 0.16 * safeZoneW;
        private _lh = 0.032 * safeZoneH;
        private _used = _lw * 0.6;

        // The step's label is one line on a dark plate as wide as its words: red on the tan MX was cut and hard to read.
        if (_attention) then {
            private _measure = _ctrls get "measure";
            _measure ctrlSetFontHeight (0.03 * safeZoneH * 0.85);
            _measure ctrlSetText toUpperANSI _text;
            _lw = ctrlTextWidth _measure + 0.012 * safeZoneW;
            _used = _lw;
        };
        private _sx = _screen select 0;
        private _cy = (_screen select 1) - _lh / 2;
        private _candidates = [
            [_sx + _w * 0.7, _cy, "left", _sx + _w * 0.7],
            [_sx - _w * 0.7 - _lw, _cy, "right", _sx - _w * 0.7 - _used],
            [_sx + _w * 0.7, _cy - _lh, "left", _sx + _w * 0.7],
            [_sx + _w * 0.7, _cy + _lh, "left", _sx + _w * 0.7]
        ];
        private _pick = _candidates findIf {
            _x params ["", "_ty", "", "_tx"];
            _placed findIf {
                _x params ["_ox", "_oy"];
                _tx < _ox + _used && {_ox < _tx + _used} && {abs (_ty - _oy) < _lh}
            } < 0
        };

        (_candidates select (_pick max 0)) params ["_lx", "_ly", "_align", "_occupied"];

        _placed pushBack [_occupied, _ly];

        _label ctrlSetPosition [_lx, _ly, _lw, _lh];
        _label ctrlSetBackgroundColor ([[0, 0, 0, 0], [0.04, 0.04, 0.04, 0.8]] select _attention);
        _label ctrlSetStructuredText parseText format [
            "<t font='%4' size='%5' color='%1' shadow='2' align='%3'>%2</t>",
            (switch (true) do {
                case (_over || _active): {_theme get "accent"};
                case (_attention): {_theme get "warn"};
                default {_theme get "text2"};
            }) call BIS_fnc_colorRGBAtoHTML,
            toUpperANSI _text,
            [_align, "center"] select _attention,
            _theme get "fontMono",
            [0.72, 0.85] select _attention
        ];
        // Quiet parts keep their names to themselves until the mouse is on them: only the step now speaks.
        _label ctrlShow (_attention || {_over} || {_active});
        _label ctrlCommit 0;
    };
} forEach _marks;

GVAR(wb) set ["spotScreen", _spotScreen];

// ----- The drag's track: dots along the line, filled as far as the part has come -----
private _track = _ctrls get "track";

if ("vec" in _drag) then {
    private _from = _drag get "from";
    private _vec = _drag get "vec";
    private _progress = _drag get "progress";
    private _dot = 0.012 * safeZoneH;
    private _full = switch (_kind) do {
        case "handle": {RACK_FULL};
        case "magInsert": {0.9};
        default {0.8};
    };

    {
        private _share = (_forEachIndex + 1) / TRACK_DOTS;
        private _at = [(_from select 0) + (_vec select 0) * _share, (_from select 1) + (_vec select 1) * _share];
        private _colour = switch (true) do {
            case (_share <= _progress && {_progress >= _full}): {_theme get "good"};
            case (_share <= _progress): {_theme get "accent"};
            default {[1, 1, 1, 0.3]};
        };

        _x ctrlSetPosition [(_at select 0) - _dot * pixelW / pixelH / 2, (_at select 1) - _dot / 2, _dot * pixelW / pixelH, _dot];
        _x ctrlSetTextColor _colour;
        _x ctrlShow true;
        _x ctrlCommit 0;
    } forEach _track;
} else {
    {_x ctrlShow false} forEach _track;
};

// ----- The tap's ring: it closes in on a loose magazine's mark, again and again -----
private _pulse = _ctrls get "pulse";
private _state = [_unit, GVAR(wb) get "weapon"] call EFUNC(malfunctions,state);
private _magScreen = _spotScreen param [_spotScreen findIf {(_x select 0) == "mag"}, []];

// Off: a tap is a plain click now (Mia: too complicated). The ring stays for a later "hard" mode.
if (false && {(_state getOrDefault ["mag", ""]) == "loose"} && {_magScreen isNotEqualTo []} && {_kind in ["", "magPress"]}) then {
    private _phase = ((diag_tickTime - (GVAR(wb) getOrDefault ["openTime", 0])) mod TAP_PERIOD) / TAP_PERIOD;
    private _size = HOTSPOT_SIZE * (1 + 2 * (1 - _phase));
    private _w = _size * pixelW / pixelH;
    private _good = _phase > 1 - TAP_WINDOW || {_phase < TAP_WINDOW / 3};

    (_magScreen select 1) params ["_sx", "_sy"];

    _pulse ctrlSetPosition [_sx - _w / 2, _sy - _size / 2, _w, _size];
    _pulse ctrlSetTextColor ([[1, 1, 1, 0.5], _theme get "good"] select _good);
    _pulse ctrlShow true;
    _pulse ctrlCommit 0;
} else {
    _pulse ctrlShow false;
};

// ----- The wiggle's bar, under the chamber -----
private _bar = _ctrls get "bar";
private _barBack = _ctrls get "barBack";
private _chamberScreen = _spotScreen param [_spotScreen findIf {(_x select 0) == "chamber"}, []];

private _handleScreen = _spotScreen param [_spotScreen findIf {(_x select 0) == "handle"}, []];
private _barAt = switch (true) do {
    case (_kind == "chamber" && {_chamberScreen isNotEqualTo []}): {[_chamberScreen select 1, _drag getOrDefault ["progress", 0]]};
    case (_kind == "handle" && {(_drag getOrDefault ["hold", 0]) > 0} && {_handleScreen isNotEqualTo []}): {[_handleScreen select 1, _drag get "hold"]};
    default {[]};
};

if (_barAt isNotEqualTo []) then {
    _barAt params ["_at", "_fill"];
    _at params ["_sx", "_sy"];

    private _bw = 0.1 * safeZoneW;
    private _bh = 0.008 * safeZoneH;
    private _by = _sy + HOTSPOT_SIZE;

    _barBack ctrlSetPosition [_sx - _bw / 2, _by, _bw, _bh];
    _bar ctrlSetPosition [_sx - _bw / 2, _by, _bw * _fill, _bh];
    {_x ctrlShow true; _x ctrlCommit 0} forEach [_barBack, _bar];
} else {
    {_x ctrlShow false} forEach [_barBack, _bar];
};

// ----- How the mouse works, for what is under it or held -----
private _hintKey = switch (true) do {
    case (GVAR(wb) get "buttons"): {"Hint_Buttons"};
    case (!("points" in _scene)): {"Hint_Loading"};
    case (_kind == "handle"): {"Hint_HandleHeld"};
    case (_kind == "magPress"): {"Hint_MagHeld"};
    case (_kind == "magInsert"): {"Hint_MagInsertHeld"};
    case (_kind == "port"): {"Hint_PortHeld"};
    case (_kind == "chamber"): {"Hint_ChamberHeld"};
    case (_hovered == "handle"): {["Hint_Handle", "Hint_HandleLocked"] select ((_state getOrDefault ["bolt", ""]) == "locked")};
    case (_hovered == "mag"): {["Hint_Mag", "Hint_MagOut"] select ((_state getOrDefault ["mag", ""]) == "out")};
    case (_hovered == "port"): {"Hint_Port"};
    case (_hovered == "chamber"): {"Hint_Chamber"};
    default {"Hint_Default"};
};

if (_hintKey != (GVAR(wb) getOrDefault ["hintKey", ""])) then {
    GVAR(wb) set ["hintKey", _hintKey];
    // One line, never wrapped (the long default line broke onto a second one, cut off by the frame): set at its size,
    // then smaller step by step until it fits the view's width.
    private _hint = _ctrls get "hint";
    private _fit = (ctrlPosition _hint) select 2;
    private _size = 0.024 * safeZoneH;

    _hint ctrlSetText toUpperANSI localize format ["STR_mhwm_workbench_%1", _hintKey];
    _hint ctrlSetFont (_theme get "fontMono");
    _hint ctrlSetTextColor (_theme get "muted");
    _hint ctrlSetFontHeight _size;

    while {ctrlTextWidth _hint > _fit && {_size > 0.012 * safeZoneH}} do {
        _size = _size * 0.92;
        _hint ctrlSetFontHeight _size;
    };
};
