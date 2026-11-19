#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the workbench for the jammed weapon in the player's hands, in the look of AIO's Glass (fnc_theme): round-cornered
 * near-black panes, the player's own Arma colour as the accent, Purista - with a military touch: the 3D
 * view framed by a sight's corner brackets with a readout over it, numbered sections in a monospace.
 *
 *   header   title, the weapon, field notes check, field manual, close
 *   view     the weapon in 3D (fnc_scene, filmed into a render target), its parts marked (fnc_hotspots) and worked by
 *            mouse (fnc_onMouse, fnc_onFrame); under it how the mouse works
 *   panel    a field notebook: a page per step with its comic picture taped in, every step in order, the last
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
    ["done", []],
    ["view", -1]
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

// The header's buttons at the right, in a row (the status chip is gone: Mia - "MALFUNCTION" up there said nothing).
private _closeW = 0.075 * safeZoneW;
private _chipX = _fx + _fw - _pad - _closeW + _gap;
private _chipY = _fy + _headH * 0.2;
private _chipH = _headH * 0.6;

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

// The check box at the button's left, round-cornered as the panes: an accent ring, filled while the notes show.
private _boxH = _chipH * 0.42;
private _boxW = _boxH * pixelW / pixelH;
private _boxX = _notesX + _pad * pixelW / pixelH;
private _boxY = _chipY + (_chipH - _boxH) / 2;
private _ring = 2;

[_display, [_boxX, _boxY, _boxW, _boxH], _theme get "accent", _boxH * 0.3] call FUNC(panel);
[_display, [_boxX + _ring * pixelW, _boxY + _ring * pixelH, _boxW - 2 * _ring * pixelW, _boxH - 2 * _ring * pixelH], [0.08, 0.08, 0.08, 1], _boxH * 0.22] call FUNC(panel);

if (GVAR(wb) get "notes") then {
    _ring = 4;
    [_display, [_boxX + _ring * pixelW, _boxY + _ring * pixelH, _boxW - 2 * _ring * pixelW, _boxH - 2 * _ring * pixelH], _theme get "accent", _boxH * 0.16] call FUNC(panel);
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

// ----- Panel: a field notebook lying open beside the weapon -----
// Mia: "als ob man da wirklich ein notebook nebenbei offen hat". A spiral pad (ui\notebook_ca.paa, make_notebook.py):
// ruled lines and a red margin drawn here on the text rows, one page per step - its picture taped in, what to do in the
// words of a drill card, the whole sequence ticked off below - paged with the tabs at the top, the page turning up over
// the spiral (fnc_refresh). With the server's minigames off, or without Picture-in-Picture, a button for every hand
// movement at the bottom of the page.
if (_showPanel) then {
    private _paperInk = _theme get "paperInk";

    // The pad: its texture has the shadowless round corners, nothing behind it (Mia: the dark block showed).
    private _notebook = [QGVAR(picture), [_px, _bodyY, _panelW, _bodyH]] call _fnc_make;
    _notebook ctrlSetText QPATHTOF(ui\notebook_ca.paa);

    // The top page on the texture: left 0.035, top 0.075, right 0.945, bottom 0.965.
    private _pgL = _px + 0.035 * _panelW;
    private _pgR = _px + 0.945 * _panelW;
    private _pgT = _bodyY + 0.075 * _bodyH;
    private _pgB = _bodyY + 0.965 * _bodyH;
    private _rowH = 0.029 * safeZoneH;
    // Below the spiral's holes (Mia: the head ran into the wire).
    private _lineTop = _bodyY + 0.155 * _bodyH;
    private _marginX = _pgL + 0.1 * (_pgR - _pgL);
    private _innerX = _marginX + _gap;
    private _innerW = _pgR - _gap * 1.2 - _innerX;

    GVAR(wb) set ["pageRect", [_pgL, _pgT + 0.03 * _bodyH, _pgR - _pgL, _pgB - _pgT - 0.03 * _bodyH]];

    // Ruled lines across the page, the red margin down it.
    private _lines = floor ((_pgB - _lineTop) / _rowH);
    for "_k" from 0 to _lines do {
        [[_pgL, _lineTop + _k * _rowH, _pgR - _pgL, pixelH], [0.4, 0.56, 0.74, 0.45]] call _fnc_line;
    };
    [[_marginX, _pgT + 0.035 * _bodyH, pixelW * 1.5, _pgB - _pgT - 0.045 * _bodyH], [0.82, 0.3, 0.25, 0.6]] call _fnc_line;

    // A row of text sits on its line: row 0 above the first line.
    private _fnc_row = {_lineTop + (_this - 1) * _rowH + _rowH * 0.08};

    private _buttonH = 0.042 * safeZoneH;
    private _buttonsH = [0, 5 * (_buttonH + _gap) + _gap] select (GVAR(wb) get "buttons");
    private _rowsFree = floor ((_pgB - _buttonsH - _lineTop) / _rowH);

    if (GVAR(wb) get "notes") then {
        // The head: the drill's name.
        _ctrls set ["head", [QGVAR(structured), [_innerX, 0 call _fnc_row, _innerW, _rowH]] call _fnc_make];

        // At the foot of the page: the tabs to page with, the page count between them - a click on the count goes back to
        // the step now (Mia: the buttons at the bottom).
        private _tabW = 0.017 * safeZoneW;
        private _tabH = _rowH * 0.9;
        private _countW = 0.04 * safeZoneW;
        private _ty = (_rowsFree call _fnc_row) - _rowH * 0.05;
        private _left = _innerX + (_innerW - 2 * _tabW - _countW) / 2;

        [_display, [_left, _ty, _tabW, _tabH], "<", {[-1] call FUNC(page)}, false, true] call FUNC(button);
        [_display, [_left + _tabW + _countW, _ty, _tabW, _tabH], ">", {[1] call FUNC(page)}, false, true] call FUNC(button);

        private _count = [QGVAR(structured), [_left + _tabW, _ty + _rowH * 0.06, _countW, _tabH]] call _fnc_make;
        _ctrls set ["progress", _count];
        private _countClick = [QGVAR(click), [_left + _tabW, _ty, _countW, _tabH]] call _fnc_make;
        _countClick ctrlAddEventHandler ["ButtonClick", {[0] call FUNC(page)}];

        // The rows the page has: the head, the step's title, three of words, the bench's hint, the sequence's head and
        // seven steps, the last action's two, the tabs - the picture takes what is left.
        private _picRows = ((_rowsFree - 17) min 11) max 4;
        private _picH = _picRows * _rowH - _rowH * 0.5;
        private _picW = (_picH / pixelH) * (446 / 300) * pixelW;

        if (_picW > _innerW * 0.94) then {
            _picW = _innerW * 0.94;
            _picH = (_picW / pixelW) * (300 / 446) * pixelH;
        };

        private _picX = _innerX + (_innerW - _picW) / 2;
        private _picY = (1 call _fnc_row) + _rowH * 0.15;

        // The picture taped in: its shadow, the print, two strips of tape over its top corners.
        [[_picX + 4 * pixelW, _picY + 5 * pixelH, _picW, _picH], [0, 0, 0, 0.22]] call _fnc_line;
        _ctrls set ["nowPic", [QGVAR(picture), [_picX, _picY, _picW, _picH]] call _fnc_make];

        private _tapeW = _picW * 0.16;
        private _tapeH = _rowH * 0.55;
        {
            [[_x - _tapeW / 2, _picY - _tapeH * 0.45, _tapeW, _tapeH], [0.93, 0.9, 0.76, 0.78]] call _fnc_line;
        } forEach [_picX + _picW * 0.08, _picX + _picW * 0.92];

        private _r = 1 + _picRows;
        _ctrls set ["nowTitle", [QGVAR(structured), [_innerX, _r call _fnc_row, _innerW, _rowH]] call _fnc_make];
        _ctrls set ["now", [QGVAR(structured), [_innerX, (_r + 1) call _fnc_row, _innerW, 3 * _rowH]] call _fnc_make];
        _ctrls set ["nowHow", [QGVAR(structured), [_innerX, (_r + 4) call _fnc_row, _innerW, _rowH]] call _fnc_make];

        // The whole sequence, a check box each - a click on one turns to its page (fnc_page).
        _r = _r + 5;
        private _head = [QGVAR(structured), [_innerX, _r call _fnc_row, _innerW, _rowH]] call _fnc_make;
        _head ctrlSetStructuredText parseText format [
            "<t font='%1' size='0.78' color='%2'>%3</t>", _theme get "fontBold", (_theme get "paperMuted") call BIS_fnc_colorRGBAtoHTML,
            toUpperANSI LLSTRING(Head_Steps)
        ];

        private _rows = [];
        private _boxS = _rowH * 0.72;

        for "_i" from 0 to 6 do {
            private _y = (_r + 1 + _i) call _fnc_row;
            private _box = [QGVAR(picture), [_innerX, _y + _rowH * 0.02, _boxS * pixelW / pixelH, _boxS]] call _fnc_make;
            private _row = [QGVAR(structured), [_innerX + _boxS * pixelW / pixelH + _gap * 0.6, _y, _innerW, _rowH]] call _fnc_make;
            private _click = [QGVAR(click), [_innerX, _y, _innerW, _rowH]] call _fnc_make;

            _click setVariable [QGVAR(row), _i];
            _click ctrlAddEventHandler ["ButtonClick", {params ["_c"]; [_c getVariable QGVAR(row), true] call FUNC(page)}];
            _rows pushBack [_box, _row, _click];
        };

        _ctrls set ["rows", _rows];

        // What the last hand movement did, as a note over the tabs.
        _r = _rowsFree - 2;
        _ctrls set ["last", [QGVAR(structured), [_innerX, _r call _fnc_row, _innerW, 2 * _rowH]] call _fnc_make];
    };

    // The buttons: every hand movement, for the server without minigames or a player without Picture-in-Picture.
    if (GVAR(wb) get "buttons") then {
        private _bw = (_innerW - _gap) / 2;
        private _y = _pgB - _buttonsH + _gap * 0.5;

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
            [ACT_SWEEP, LLSTRING(Btn_Sweep)],
            [ACT_WAIT, LLSTRING(Btn_Wait)]
        ];
    };

    // The page that turns up over the spiral when the notebook is paged: made last, so it lies over the page.
    if (GVAR(wb) get "notes") then {
        private _flip = [QGVAR(picture), [0, 0, 0, 0]] call _fnc_make;
        _flip ctrlSetText QPATHTOF(ui\flip_co.paa);
        _ctrls set ["flip", _flip];
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

// Out of sight: measures how wide a label's words are (fnc_onFrame).
private _measure = [QGVAR(text), [-10, -10, 0.5, 0.05]] call _fnc_make;
_measure ctrlSetFont (_theme get "fontMono");
_ctrls set ["measure", _measure];

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
