#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the workbench for the jammed weapon in the player's hands: the weapon in 3D on the left (fnc_scene, filmed into a
 * render target), what is seen on it and what the last hand movement did on the right (fnc_refresh). The parts the hands
 * can work on are marked on the weapon (fnc_hotspots) and worked by mouse (fnc_onMouse, fnc_onFrame); with the server's
 * minigames off, or without Picture-in-Picture, buttons do the same.
 *
 * GVAR(wb), while open:
 *   unit, weapon, display, ctrls (hashmap of controls), viewRect / picRect [x, y, w, h] (screen),
 *   scene (fnc_scene), drag (the mouse's hold, fnc_onMouse), result (last stringtable key), pfh, closing
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [] call mhwm_workbench_fnc_open;
 *
 * Public: Yes
 */

if (!isNil QGVAR(wb)) exitWith {true};

private _unit = PLAYER_UNIT;

if (!alive _unit || {!([_unit] call EFUNC(malfunctions,isBlocked))}) exitWith {false};
if (_unit getVariable [QEGVAR(malfunctions,busy), false]) exitWith {false};

private _weapon = currentWeapon _unit;

if !(createDialog QGVAR(dialog)) exitWith {false};

private _display = findDisplay IDD_WORKBENCH;
private _ctrls = createHashMap;

GVAR(wb) = createHashMapFromArray [
    ["unit", _unit],
    ["weapon", _weapon],
    ["display", _display],
    ["ctrls", _ctrls],
    ["drag", createHashMap],
    ["result", ""],
    ["closing", false],
    ["openTime", diag_tickTime],
    ["buttons", !EGVAR(main,minigames) || {!isPiPEnabled}]
];

// ----- Layout -----
private _pad = 0.012 * safeZoneH;
private _fx = safeZoneX + 0.05 * safeZoneW;
private _fy = safeZoneY + 0.07 * safeZoneH;
private _fw = 0.9 * safeZoneW;
private _fh = 0.86 * safeZoneH;
private _headH = 0.055 * safeZoneH;
private _hintH = 0.04 * safeZoneH;
private _panelW = 0.3 * _fw;
private _vx = _fx + _pad;
private _vy = _fy + _headH + _pad;
private _vw = _fw - _panelW - 3 * _pad;
private _vh = _fh - _headH - _hintH - 3 * _pad;
private _px = _vx + _vw + _pad;

private _fnc_make = {
    params ["_class", "_pos", ["_group", controlNull]];

    private _ctrl = if (isNull _group) then {_display ctrlCreate [_class, -1]} else {_display ctrlCreate [_class, -1, _group]};

    _ctrl ctrlSetPosition _pos;
    _ctrl ctrlCommit 0;
    _ctrl
};

// The world behind, dimmed; the frame.
private _dim = [QGVAR(box), [safeZoneX, safeZoneY, safeZoneW, safeZoneH]] call _fnc_make;
_dim ctrlSetBackgroundColor [0, 0, 0, 0.55];

private _frame = [QGVAR(box), [_fx, _fy, _fw, _fh]] call _fnc_make;
_frame ctrlSetBackgroundColor COLOR_BASE;

// Header: a red line, the title, the weapon, close.
private _accent = [QGVAR(box), [_fx, _fy, _fw, 0.004 * safeZoneH]] call _fnc_make;
_accent ctrlSetBackgroundColor COLOR_RED;

private _title = [QGVAR(structured), [_fx + _pad, _fy + 0.008 * safeZoneH, _fw - 0.2 * _fw, _headH - 0.008 * safeZoneH]] call _fnc_make;
_title ctrlSetStructuredText parseText format [
    "<t font='PuristaBold' size='1.25' color='%1'>WEAPON MALFUNCTION</t>  <t font='PuristaMedium' size='1.1' color='%2'>%3</t>",
    HEX_RED, HEX_TEXT, getText (configFile >> "CfgWeapons" >> _weapon >> "displayName")
];

private _close = [QGVAR(button), [_fx + _fw - _pad - 0.09 * safeZoneW, _fy + 0.012 * safeZoneH, 0.09 * safeZoneW, _headH - 0.02 * safeZoneH]] call _fnc_make;
_close ctrlSetText LLSTRING(Close);
_close ctrlAddEventHandler ["ButtonClick", {closeDialog 0}];

// The 3D view: a group the size of the view, the picture inside it with the screen's shape, covering it.
private _view = [QGVAR(group), [_vx, _vy, _vw, _vh]] call _fnc_make;
private _viewBack = [QGVAR(box), [0, 0, _vw, _vh], _view] call _fnc_make;
_viewBack ctrlSetBackgroundColor [0.03, 0.02, 0.022, 1];

private _picH = _vh;
private _picW = SCENE_ASPECT * (_picH / pixelH) * pixelW;

if (_picW < _vw) then {
    _picW = _vw;
    _picH = ((_picW / pixelW) / SCENE_ASPECT) * pixelH;
};

private _picX = (_vw - _picW) / 2;
private _picY = (_vh - _picH) / 2;
private _picture = [QGVAR(picture), [_picX, _picY, _picW, _picH], _view] call _fnc_make;

_picture ctrlSetText SCENE_TEXTURE;

GVAR(wb) set ["viewRect", [_vx, _vy, _vw, _vh]];
GVAR(wb) set ["picRect", [_vx + _picX, _vy + _picY, _picW, _picH]];

// A thin red frame round the view.
{
    private _line = [QGVAR(box), _x] call _fnc_make;
    _line ctrlSetBackgroundColor COLOR_RED_SOFT;
} forEach [
    [_vx, _vy, _vw, pixelH],
    [_vx, _vy + _vh - pixelH, _vw, pixelH],
    [_vx, _vy, pixelW, _vh],
    [_vx + _vw - pixelW, _vy, pixelW, _vh]
];

// Under the view: how the mouse works.
private _hint = [QGVAR(structured), [_vx, _vy + _vh + _pad / 2, _vw, _hintH]] call _fnc_make;
_ctrls set ["hint", _hint];

// ----- Panel -----
private _panelBack = [QGVAR(box), [_px, _vy, _panelW, _vh + _hintH + _pad / 2]] call _fnc_make;
_panelBack ctrlSetBackgroundColor COLOR_PANEL;

private _y = _vy + _pad;
private _innerW = _panelW - 2 * _pad;

private _fnc_heading = {
    params ["_text"];

    private _ctrl = [QGVAR(structured), [_px + _pad, _y, _innerW, 0.03 * safeZoneH]] call _fnc_make;
    _ctrl ctrlSetStructuredText parseText format ["<t font='PuristaBold' size='0.9' color='%1'>%2</t>", HEX_RED, _text];
    _y = _y + 0.032 * safeZoneH;

    private _line = [QGVAR(box), [_px + _pad, _y, _innerW, pixelH]] call _fnc_make;
    _line ctrlSetBackgroundColor COLOR_RED_SOFT;
    _y = _y + _pad / 2;
};

[LLSTRING(Head_See)] call _fnc_heading;
private _see = [QGVAR(structured), [_px + _pad, _y, _innerW, 0.2 * safeZoneH]] call _fnc_make;
_ctrls set ["see", _see];
_y = _y + 0.2 * safeZoneH + _pad;

[LLSTRING(Head_Last)] call _fnc_heading;
private _last = [QGVAR(structured), [_px + _pad, _y, _innerW, 0.08 * safeZoneH]] call _fnc_make;
_ctrls set ["last", _last];
_y = _y + 0.08 * safeZoneH + _pad;

[LLSTRING(Head_Hands)] call _fnc_heading;
private _hands = [QGVAR(structured), [_px + _pad, _y, _innerW, 0.2 * safeZoneH]] call _fnc_make;
_ctrls set ["hands", _hands];
_y = _y + 0.2 * safeZoneH + _pad;

// The buttons: every hand movement, for the server without minigames or a player without Picture-in-Picture.
if (GVAR(wb) get "buttons") then {
    private _bw = (_innerW - _pad) / 2;
    private _bh = 0.04 * safeZoneH;
    private _buttons = [];

    {
        _x params ["_act", "_label"];

        private _col = _forEachIndex % 2;
        private _row = floor (_forEachIndex / 2);
        private _button = [QGVAR(button), [_px + _pad + _col * (_bw + _pad), _y + _row * (_bh + _pad / 2), _bw, _bh]] call _fnc_make;

        _button ctrlSetText _label;
        _button setVariable [QGVAR(act), _act];
        _button ctrlAddEventHandler ["ButtonClick", {
            params ["_button"];

            [_button getVariable [QGVAR(act), ""]] call FUNC(act);
        }];
        _buttons pushBack _button;
    } forEach [
        [ACT_TAP, LLSTRING(Btn_Tap)],
        [ACT_RACK, LLSTRING(Btn_Rack)],
        [ACT_LOCK, LLSTRING(Btn_Lock)],
        [ACT_RELEASE, LLSTRING(Btn_Release)],
        [ACT_DROP, LLSTRING(Btn_Drop)],
        [ACT_INSERT, LLSTRING(Btn_Insert)],
        [ACT_CLEAR, LLSTRING(Btn_Clear)],
        [ACT_SWEEP, LLSTRING(Btn_Sweep)]
    ];

    _ctrls set ["buttons", _buttons];
};

// Hotspot marks and the drag's track, made once and moved every frame (fnc_onFrame).
private _marks = [];

for "_i" from 0 to 5 do {
    private _ring = [QGVAR(picture), [0, 0, 0, 0]] call _fnc_make;
    _ring ctrlSetText TEX_CIRCLE;

    private _label = [QGVAR(structured), [0, 0, 0, 0]] call _fnc_make;

    _marks pushBack [_ring, _label];
};

_ctrls set ["marks", _marks];

private _track = [];

for "_i" from 0 to (TRACK_DOTS - 1) do {
    private _dot = [QGVAR(picture), [0, 0, 0, 0]] call _fnc_make;
    _dot ctrlSetText TEX_DOT;
    _track pushBack _dot;
};

_ctrls set ["track", _track];

private _pulse = [QGVAR(picture), [0, 0, 0, 0]] call _fnc_make;
_pulse ctrlSetText TEX_CIRCLE;
_ctrls set ["pulse", _pulse];

private _bar = [QGVAR(box), [0, 0, 0, 0]] call _fnc_make;
_bar ctrlSetBackgroundColor COLOR_RED;
_ctrls set ["bar", _bar];

private _barBack = [QGVAR(box), [0, 0, 0, 0]] call _fnc_make;
_barBack ctrlSetBackgroundColor [0, 0, 0, 0.6];
_ctrls set ["barBack", _barBack];

// The mouse: buttons and wheel on the display, movement polled each frame.
_display displayAddEventHandler ["MouseButtonDown", {["down", _this] call FUNC(onMouse); false}];
_display displayAddEventHandler ["MouseButtonUp", {["up", _this] call FUNC(onMouse); false}];
_display displayAddEventHandler ["MouseZChanged", {["wheel", _this] call FUNC(onMouse); false}];

// The scene and the frame loop.
if (isPiPEnabled) then {
    ["start"] call FUNC(scene);
};

GVAR(wb) set ["pfh", [{call FUNC(onFrame)}, 0] call CBA_fnc_addPerFrameHandler];

call FUNC(refresh);

true
