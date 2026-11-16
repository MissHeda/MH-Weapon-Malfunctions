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

if ("weapon" in _scene && {!("points" in _scene)}) then {
    call FUNC(points);
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
    };
};

call FUNC(sync);

// ----- The parts on the screen -----
private _spots = call FUNC(hotspots);
private _marks = _ctrls get "marks";
private _spotScreen = [];
private _hovered = "";

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

        private _size = HOTSPOT_SIZE * ([1, 1.35] select (_over || _active));
        private _w = _size * pixelW / pixelH;

        _ring ctrlSetPosition [(_screen select 0) - _w / 2, (_screen select 1) - _size / 2, _w, _size];
        _ring ctrlSetTextColor ([[1, 1, 1, 0.75], COLOR_RED] select (_attention || _over || _active));
        _ring ctrlShow true;
        _ring ctrlCommit 0;

        _label ctrlSetPosition [(_screen select 0) + _w * 0.7, (_screen select 1) - 0.016 * safeZoneH, 0.16 * safeZoneW, 0.032 * safeZoneH];
        _label ctrlSetStructuredText parseText format [
            "<t font='PuristaMedium' size='0.85' color='%1' shadow='2'>%2</t>",
            [HEX_TEXT, HEX_RED] select (_attention || _over),
            _text
        ];
        _label ctrlShow true;
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
            case (_share <= _progress && {_progress >= _full}): {COLOR_GOOD};
            case (_share <= _progress): {COLOR_RED};
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

if ((_state getOrDefault ["mag", ""]) == "loose" && {_magScreen isNotEqualTo []} && {_kind in ["", "magPress"]} && {!(GVAR(wb) get "buttons")}) then {
    private _phase = ((diag_tickTime - (GVAR(wb) getOrDefault ["openTime", 0])) mod TAP_PERIOD) / TAP_PERIOD;
    private _size = HOTSPOT_SIZE * (1 + 2 * (1 - _phase));
    private _w = _size * pixelW / pixelH;
    private _good = _phase > 1 - TAP_WINDOW || {_phase < TAP_WINDOW / 3};

    (_magScreen select 1) params ["_sx", "_sy"];

    _pulse ctrlSetPosition [_sx - _w / 2, _sy - _size / 2, _w, _size];
    _pulse ctrlSetTextColor ([[1, 1, 1, 0.5], COLOR_GOOD] select _good);
    _pulse ctrlShow true;
    _pulse ctrlCommit 0;
} else {
    _pulse ctrlShow false;
};

// ----- The wiggle's bar, under the chamber -----
private _bar = _ctrls get "bar";
private _barBack = _ctrls get "barBack";
private _chamberScreen = _spotScreen param [_spotScreen findIf {(_x select 0) == "chamber"}, []];

if (_kind == "chamber" && {_chamberScreen isNotEqualTo []}) then {
    (_chamberScreen select 1) params ["_sx", "_sy"];

    private _bw = 0.1 * safeZoneW;
    private _bh = 0.008 * safeZoneH;
    private _by = _sy + HOTSPOT_SIZE;

    _barBack ctrlSetPosition [_sx - _bw / 2, _by, _bw, _bh];
    _bar ctrlSetPosition [_sx - _bw / 2, _by, _bw * (_drag getOrDefault ["progress", 0]), _bh];
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
    (_ctrls get "hint") ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensed' size='0.9' color='%1'>%2</t>",
        HEX_DIM,
        localize format ["STR_mhwm_workbench_%1", _hintKey]
    ];
};
