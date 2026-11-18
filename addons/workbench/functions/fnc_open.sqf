#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the workbench for the jammed weapon in the player's hands, in the look of AIO's Glass (fnc_theme): round-cornered
 * near-black panes, the player's own Arma colour as the accent, Purista - with a military touch: a status chip, the 3D
 * view framed by a sight's corner brackets with a readout over it, numbered sections in a monospace.
 *
 *   header   title, the weapon, status chip (MALFUNCTION / CLEAR), close
 *   view     the weapon in 3D (fnc_scene, filmed into a render target), its parts marked (fnc_hotspots) and worked by
 *            mouse (fnc_onMouse, fnc_onFrame); under it how the mouse works
 *   panel    01 Observation (fnc_describe), 02 Last action, 03 Procedure - and with the server's minigames off, or
 *            without Picture-in-Picture, a button for every hand movement
 *
 * GVAR(wb), while open:
 *   unit, weapon, display, theme, ctrls (hashmap of controls), viewRect / picRect [x, y, w, h] (screen),
 *   scene (fnc_scene), drag (the mouse's hold, fnc_onMouse), result (last stringtable key), pfh, closing, openTime, buttons
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

private _theme = call FUNC(theme);
GVAR(wb) set ["theme", _theme];

private _html = {_this call BIS_fnc_colorRGBAtoHTML};
private _accentHex = (_theme get "accent") call _html;
private _mutedHex = (_theme get "muted") call _html;
private _text2Hex = (_theme get "text2") call _html;

// ----- Layout -----
private _pad = 0.012 * safeZoneH;
private _gap = 0.008 * safeZoneH;
private _fx = safeZoneX + 0.06 * safeZoneW;
private _fy = safeZoneY + 0.07 * safeZoneH;
private _fw = 0.88 * safeZoneW;
private _fh = 0.86 * safeZoneH;
private _headH = 0.075 * safeZoneH;
private _hintH = 0.036 * safeZoneH;
private _panelW = 0.28 * _fw;
private _bodyY = _fy + _headH + _gap;
private _bodyH = _fh - _headH - _gap;
private _viewW = _fw - _panelW - _gap;
private _px = _fx + _viewW + _gap;

private _fnc_make = {
    params ["_class", "_pos", ["_group", controlNull]];

    private _ctrl = if (isNull _group) then {_display ctrlCreate [_class, -1]} else {_display ctrlCreate [_class, -1, _group]};

    _ctrl ctrlSetPosition _pos;
    _ctrl ctrlCommit 0;
    _ctrl
};

private _fnc_line = {
    params ["_pos", "_color"];

    private _ctrl = [QGVAR(rect), _pos] call _fnc_make;
    _ctrl ctrlSetBackgroundColor _color;
    _ctrl
};

// The world behind, dimmed.
[[safeZoneX, safeZoneY, safeZoneW, safeZoneH], _theme get "dim"] call _fnc_line;

// ----- Header -----
[_display, [_fx, _fy, _fw, _headH], _theme get "panel"] call FUNC(panel);

// A short accent bar at the left, as a unit marking.
[[_fx + _pad, _fy + _headH * 0.25, 0.0035 * safeZoneH * pixelW / pixelH, _headH * 0.5], _theme get "accent"] call _fnc_line;

// The weapon: its inventory picture, its name large, and under it what this is - so it is clear which weapon is open.
private _config = configFile >> "CfgWeapons" >> _weapon;
private _iconH = _headH * 0.8;
private _iconW = 2 * _iconH * pixelW / pixelH;
private _icon = [QGVAR(picture), [_fx + _pad * 2, _fy + _headH * 0.1, _iconW, _iconH]] call _fnc_make;
_icon ctrlSetText getText (_config >> "picture");

private _title = [QGVAR(structured), [_fx + _pad * 3 + _iconW, _fy + _headH * 0.06, _fw * 0.55, _headH * 0.55]] call _fnc_make;
_title ctrlSetStructuredText parseText format [
    "<t font='%1' size='1.35'>%2</t>",
    _theme get "fontBold", getText (_config >> "displayName")
];

private _subtitle = [QGVAR(structured), [_fx + _pad * 3 + _iconW, _fy + _headH * 0.58, _fw * 0.55, _headH * 0.4]] call _fnc_make;
_subtitle ctrlSetStructuredText parseText format [
    "<t font='%1' size='0.72' color='%2'>%3 // %4</t>",
    _theme get "fontMono", _mutedHex, toUpperANSI LLSTRING(Title), toUpperANSI _weapon
];

// The status chip: what the weapon is now (fnc_refresh fills it).
private _chipW = 0.11 * safeZoneW;
private _closeW = 0.075 * safeZoneW;
private _chipX = _fx + _fw - _pad - _closeW - _gap - _chipW;
private _chipY = _fy + _headH * 0.2;
private _chipH = _headH * 0.6;
private _chipParts = [_display, [_chipX, _chipY, _chipW, _chipH], _theme get "card"] call FUNC(panel);
private _chip = [QGVAR(structured), [_chipX, _chipY + (_chipH - 0.026 * safeZoneH) / 2, _chipW, 0.03 * safeZoneH]] call _fnc_make;

_ctrls set ["chip", _chip];
_ctrls set ["chipParts", _chipParts];

[_display, [_fx + _fw - _pad - _closeW, _chipY, _closeW, _chipH], LLSTRING(Close), {closeDialog 0}] call FUNC(button);

// The field manual: how the minigames are played (fnc_manual).
private _manualW = 0.1 * safeZoneW;
[_display, [_chipX - _gap - _manualW, _chipY, _manualW, _chipH], LLSTRING(Manual), {[] call FUNC(manual)}, true] call FUNC(button);

// ----- The 3D view -----
[_display, [_fx, _bodyY, _viewW, _bodyH], _theme get "panel"] call FUNC(panel);

private _vx = _fx + _pad;
private _vy = _bodyY + _pad;
private _vw = _viewW - 2 * _pad;
private _vh = _bodyH - 2 * _pad - _hintH;

private _view = [QGVAR(group), [_vx, _vy, _vw, _vh]] call _fnc_make;
private _viewBack = [QGVAR(rect), [0, 0, _vw, _vh], _view] call _fnc_make;
_viewBack ctrlSetBackgroundColor [0.025, 0.025, 0.028, 1];

// The picture has the screen's shape and covers the view; the group cuts it to size.
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

// The sight's corner brackets, in the accent.
private _arm = 0.035 * safeZoneH;
private _armW = _arm * pixelW / pixelH;
private _thick = 2 * pixelH;
private _thickW = 2 * pixelW;
private _inset = _pad;
private _insetW = _pad * pixelW / pixelH;
private _bx0 = _vx + _insetW;
private _by0 = _vy + _inset;
private _bx1 = _vx + _vw - _insetW;
private _by1 = _vy + _vh - _inset;

{
    _x params ["_cx", "_cy", "_dx", "_dy"];

    // Across, then up or down, from the corner inwards.
    [[[_cx, _cx - _armW] select (_dx < 0), [_cy, _cy - _thick] select (_dy < 0), _armW, _thick], _theme get "accent"] call _fnc_line;
    [[[_cx, _cx - _thickW] select (_dx < 0), [_cy, _cy - _arm] select (_dy < 0), _thickW, _arm], _theme get "accent"] call _fnc_line;
} forEach [
    [_bx0, _by0, 1, 1],
    [_bx1, _by0, -1, 1],
    [_bx0, _by1, 1, -1],
    [_bx1, _by1, -1, -1]
];

// The readout over the view, as on a sight: the magazine in the weapon and its rounds.
(_unit weaponState _weapon) params ["", "", "", ["_magClass", ""], ["_rounds", 0]];

private _readout = [QGVAR(structured), [_bx0 + _insetW * 1.5, _by0 + _inset * 0.6, _vw * 0.8, 0.03 * safeZoneH]] call _fnc_make;
_readout ctrlSetStructuredText parseText format [
    "<t font='%1' size='0.72' color='%2'>%3 // %4 // %5 %6</t>",
    _theme get "fontMono", _mutedHex, toUpperANSI LLSTRING(Readout),
    toUpperANSI getText (configFile >> "CfgMagazines" >> _magClass >> "displayName"),
    _rounds, toUpperANSI LLSTRING(Rounds)
];

// Under the view: how the mouse works.
private _hint = [QGVAR(structured), [_vx, _vy + _vh + _gap, _vw, _hintH]] call _fnc_make;
_ctrls set ["hint", _hint];

// ----- Panel: three cards -----
[_display, [_px, _bodyY, _panelW, _bodyH], _theme get "panel"] call FUNC(panel);

private _innerX = _px + _pad;
private _innerW = _panelW - 2 * _pad;
private _y = _bodyY + _pad;
private _buttonH = 0.042 * safeZoneH;
private _buttonsH = [0, 4 * (_buttonH + _gap) + _pad] select (GVAR(wb) get "buttons");
private _free = _bodyH - 2 * _pad - _buttonsH - 2 * _gap;

private _fnc_card = {
    params ["_number", "_name", "_height"];

    [_display, [_innerX, _y, _innerW, _height], _theme get "card"] call FUNC(panel);

    private _head = [QGVAR(structured), [_innerX + _pad, _y + _gap, _innerW - 2 * _pad, 0.026 * safeZoneH]] call _fnc_make;
    _head ctrlSetStructuredText parseText format [
        "<t font='%1' size='0.75' color='%2'>%3</t>  <t font='%1' size='0.75' color='%4'>%5</t>",
        _theme get "fontMono", _accentHex, _number, _mutedHex, toUpperANSI _name
    ];

    private _body = [QGVAR(structured), [_innerX + _pad, _y + _gap + 0.03 * safeZoneH, _innerW - 2 * _pad, _height - 0.03 * safeZoneH - 2 * _gap]] call _fnc_make;

    _y = _y + _height + _gap;
    _body
};

_ctrls set ["see", ["01", LLSTRING(Head_See), _free * 0.36] call _fnc_card];
_ctrls set ["last", ["02", LLSTRING(Head_Last), _free * 0.18] call _fnc_card];
_ctrls set ["hands", ["03", LLSTRING(Head_Hands), _free * 0.46] call _fnc_card];

// The buttons: every hand movement, for the server without minigames or a player without Picture-in-Picture.
if (GVAR(wb) get "buttons") then {
    private _bw = (_innerW - _gap) / 2;

    {
        _x params ["_act", "_label"];

        private _col = _forEachIndex % 2;
        private _row = floor (_forEachIndex / 2);
        private _click = [
            _display,
            [_innerX + _col * (_bw + _gap), _y + _row * (_buttonH + _gap), _bw, _buttonH],
            _label,
            {[_c getVariable [QGVAR(act), ""]] call FUNC(act)}
        ] call FUNC(button);

        _click setVariable [QGVAR(act), _act];
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

private _barBack = [QGVAR(rect), [0, 0, 0, 0]] call _fnc_make;
_barBack ctrlSetBackgroundColor [0, 0, 0, 0.6];
_ctrls set ["barBack", _barBack];

private _bar = [QGVAR(rect), [0, 0, 0, 0]] call _fnc_make;
_bar ctrlSetBackgroundColor (_theme get "accent");
_ctrls set ["bar", _bar];

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

// The first time a player opens the bench, the manual comes up by itself.
if !(profileNamespace getVariable [QGVAR(manualSeen), false]) then {
    [true] call FUNC(manual);
};

true
