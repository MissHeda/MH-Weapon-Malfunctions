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
 *   panel    a page of the field manual: the step to do now with its comic picture, every step in order, the last
 *            hand movement (fnc_steps, fnc_refresh) - and with the server's minigames off, or without
 *            Picture-in-Picture, a button for every hand movement. The "Field notes" check in the header hides
 *            the three cards for players who know the drill (profileNamespace mhwm_workbench_notesHidden): the view then
 *            takes the whole width, or with buttons the panel keeps only them.
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
    ["buttons", !EGVAR(main,minigames) || {!isPiPEnabled}],
    ["notes", !(profileNamespace getVariable [QGVAR(notesHidden), false])],
    ["done", []]
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
private _showPanel = (GVAR(wb) get "notes") || {GVAR(wb) get "buttons"};
private _panelW = [0, 0.28 * _fw] select _showPanel;
private _bodyY = _fy + _headH + _gap;
private _bodyH = _fh - _headH - _gap;
private _viewW = [_fw, _fw - _panelW - _gap] select _showPanel;
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

// The field notes check: off hides the side panel's cards; the bench is built anew with the other layout.
private _notesW = 0.1 * safeZoneW;
private _notesX = _chipX - 2 * _gap - _manualW - _notesW;
[_display, [_notesX, _chipY, _notesW, _chipH], "     " + LLSTRING(Notes), {
    profileNamespace setVariable [QGVAR(notesHidden), GVAR(wb) get "notes"];
    saveProfileNamespace;
    closeDialog 0;
    [{[] call FUNC(open)}] call CBA_fnc_execNextFrame;
}] call FUNC(button);

// The check box at the button's left: an accent frame, filled while the notes show.
private _boxH = _chipH * 0.42;
private _boxW = _boxH * pixelW / pixelH;
private _boxX = _notesX + _pad * pixelW / pixelH;
private _boxY = _chipY + (_chipH - _boxH) / 2;
{
    [_x, _theme get "accent"] call _fnc_line;
} forEach [
    [_boxX, _boxY, _boxW, 2 * pixelH],
    [_boxX, _boxY + _boxH - 2 * pixelH, _boxW, 2 * pixelH],
    [_boxX, _boxY, 2 * pixelW, _boxH],
    [_boxX + _boxW - 2 * pixelW, _boxY, 2 * pixelW, _boxH]
];
if (GVAR(wb) get "notes") then {
    [[_boxX + _boxW * 0.25, _boxY + _boxH * 0.25, _boxW * 0.5, _boxH * 0.5], _theme get "accent"] call _fnc_line;
};

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

// Over the view at the right: the weapon back where it started, turned and zoomed as it was.
private _resetW = 0.075 * safeZoneW;
[_display, [_bx1 - _insetW * 1.5 - _resetW, _by0 + _inset * 0.6, _resetW, 0.034 * safeZoneH], LLSTRING(ResetView), {
    private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];

    if ("home" in _scene && {"origin" in _scene}) then {
        (_scene get "home") params ["_az", "_pitch", "_dist"];
        _scene set ["az", _az];
        _scene set ["pitch", _pitch];
        _scene set ["dist", _dist];
        _scene set ["target", +(_scene get "origin")];
        call FUNC(camera);
    };
}] call FUNC(button);

// Under the view: how the mouse works.
private _hint = [QGVAR(text), [_vx, _vy + _vh + _gap * 0.5, _vw, _hintH]] call _fnc_make;
_ctrls set ["hint", _hint];

// ----- Panel: what to do, as a page of the field manual -----
// Printed paper as the field manual (fnc_manual): the step to do now large, with its comic picture, and under it every
// step in order - done ones ticked off (fnc_steps, fnc_refresh). Mia: the field notes at the side, with the pictures,
// showing what comes first.
if (_showPanel) then {
    private _paperInk = _theme get "paperInk";
    private _inkHex = _paperInk call BIS_fnc_colorRGBAtoHTML;
    private _redHex = (_theme get "paperRed") call BIS_fnc_colorRGBAtoHTML;

    [[_px + 5 * pixelW, _bodyY + 5 * pixelH, _panelW, _bodyH], [0, 0, 0, 0.55]] call _fnc_line;

    private _paper = [QGVAR(picture), [_px, _bodyY, _panelW, _bodyH]] call _fnc_make;
    _paper ctrlSetText QPATHTOF(ui\paper_co.paa);

    private _innerX = _px + _pad * 1.4;
    private _innerW = _panelW - 2.8 * _pad;
    private _y = _bodyY + _pad;

    // The page's head: red stencil letters, the step count under them, a line of ink.
    private _pageHead = [QGVAR(structured), [_innerX, _y, _innerW, 0.05 * safeZoneH]] call _fnc_make;
    _pageHead ctrlSetStructuredText parseText format [
        "<t font='%1' size='1.45' color='%2'>%3</t>",
        _theme get "fontBold", _redHex, toUpperANSI LLSTRING(Paper_Title)
    ];
    _y = _y + 0.048 * safeZoneH;

    _ctrls set ["progress", [QGVAR(structured), [_innerX, _y, _innerW, 0.026 * safeZoneH]] call _fnc_make];
    _y = _y + 0.028 * safeZoneH;
    [[_innerX, _y, _innerW, 3 * pixelH], _paperInk] call _fnc_line;
    _y = _y + _gap * 1.5;

    private _buttonH = 0.042 * safeZoneH;
    private _buttonsH = [0, 4 * (_buttonH + _gap) + _pad] select (GVAR(wb) get "buttons");
    private _bottom = _bodyY + _bodyH - _pad - _buttonsH;

    if (GVAR(wb) get "notes") then {
        // The step now: its picture in the manual's shape (446 x 300), framed in red, its words under it.
        private _picW = _innerW;
        private _picH = (_picW / pixelW) * (300 / 446) * pixelH;
        private _maxH = (_bottom - _y) * 0.42;

        if (_picH > _maxH) then {
            _picH = _maxH;
            _picW = (_picH / pixelH) * (446 / 300) * pixelW;
        };

        private _picX = _innerX + (_innerW - _picW) / 2;
        private _nowH = 0.085 * safeZoneH;
        private _cardH = _picH + _nowH;

        [[_innerX, _y, _innerW, _cardH], _theme get "paperBox"] call _fnc_line;
        private _frame = [];
        {
            _frame pushBack ([_x, _theme get "paperRed"] call _fnc_line);
        } forEach [
            [_innerX, _y, _innerW, 4 * pixelH],
            [_innerX, _y + _cardH - 4 * pixelH, _innerW, 4 * pixelH],
            [_innerX, _y, 4 * pixelW, _cardH],
            [_innerX + _innerW - 4 * pixelW, _y, 4 * pixelW, _cardH]
        ];
        _ctrls set ["nowFrame", _frame];

        private _pic = [QGVAR(picture), [_picX, _y + 4 * pixelH, _picW, _picH - 4 * pixelH]] call _fnc_make;
        _ctrls set ["nowPic", _pic];

        _ctrls set ["now", [QGVAR(structured), [_innerX + _gap, _y + _picH + _gap * 0.4, _innerW - 2 * _gap, _nowH - _gap * 0.6]] call _fnc_make];
        _y = _y + _cardH + _gap * 1.5;

        // Every step in order.
        private _listH = (_bottom - _y) * 0.72;
        _ctrls set ["list", [QGVAR(structured), [_innerX, _y, _innerW, _listH]] call _fnc_make];
        _y = _y + _listH;

        // What the last hand movement did.
        [[_innerX, _y, _innerW, 2 * pixelH], _paperInk] call _fnc_line;
        _ctrls set ["last", [QGVAR(structured), [_innerX, _y + _gap * 0.5, _innerW, _bottom - _y - _gap]] call _fnc_make];
    };

    _y = _bottom + _gap;

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
                {[_c getVariable [QGVAR(act), ""]] call FUNC(act)},
                false,
                true
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
