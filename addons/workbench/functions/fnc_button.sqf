#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A button as AIO draws one: a round-cornered film (fnc_panel) with its label, the film brighter under the mouse, and a
 * clear click area over it. A primary button is filled with the accent.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Rectangle [x, y, w, h] <ARRAY>
 * 2: Label <STRING>
 * 3: On click <CODE>
 * 4: Primary <BOOL> (default: false)
 * 5: On the paper panel <BOOL> (default: false) - a caption box of the field manual: light paper, an ink frame, ink
 *    letters, red under the mouse
 *
 * Return Value:
 * The click area <CONTROL>
 *
 * Public: No
 */

params ["_display", "_rect", "_label", "_code", ["_primary", false], ["_paper", false]];

private _theme = GVAR(wb) get "theme";
private _base = _theme get (["card", "accentSoft"] select _primary);
private _hover = _theme get (["cardHover", "accent"] select _primary);
private _ink = _theme get "text";
private _parts = [];

if (_paper) then {
    _base = _theme get "paperBox";
    _hover = _theme get "paperRed";
    _ink = _theme get "paperInk";

    _rect params ["_bx", "_by", "_bw", "_bh"];

    private _fill = _display ctrlCreate [QGVAR(rect), -1];
    _fill ctrlSetPosition _rect;
    _fill ctrlSetBackgroundColor _base;
    _fill ctrlCommit 0;
    _parts pushBack _fill;

    {
        private _line = _display ctrlCreate [QGVAR(rect), -1];
        _line ctrlSetPosition _x;
        _line ctrlSetBackgroundColor _ink;
        _line ctrlCommit 0;
    } forEach [
        [_bx, _by, _bw, 2 * pixelH],
        [_bx, _by + _bh - 2 * pixelH, _bw, 2 * pixelH],
        [_bx, _by, 2 * pixelW, _bh],
        [_bx + _bw - 2 * pixelW, _by, 2 * pixelW, _bh]
    ];
} else {
    _parts = [_display, _rect, _base] call FUNC(panel);
};

private _text = _display ctrlCreate [QGVAR(structured), -1];
_text ctrlSetPosition [_rect select 0, (_rect select 1) + ((_rect select 3) - 0.026 * safeZoneH) / 2, _rect select 2, 0.03 * safeZoneH];
_text ctrlSetStructuredText parseText format [
    "<t align='center' font='%1' size='0.9' color='%2'>%3</t>",
    _theme get "fontBold", _ink call BIS_fnc_colorRGBAtoHTML, toUpperANSI _label
];
_text ctrlCommit 0;

private _click = _display ctrlCreate [QGVAR(click), -1];
_click ctrlSetPosition _rect;
_click ctrlCommit 0;
_click setVariable [QGVAR(parts), _parts];
_click setVariable [QGVAR(colors), [_base, _hover]];
_click setVariable [QGVAR(code), _code];

private _fnc_tint = {
    params ["_click", "_over"];

    private _color = (_click getVariable [QGVAR(colors), [[], []]]) select ([0, 1] select _over);

    {
        if (ctrlType _x == 0 && {ctrlStyle _x == 48}) then {_x ctrlSetTextColor _color} else {_x ctrlSetBackgroundColor _color};
    } forEach (_click getVariable [QGVAR(parts), []]);
};

_click setVariable [QGVAR(tint), _fnc_tint];
_click ctrlAddEventHandler ["MouseEnter", {params ["_c"]; [_c, true] call (_c getVariable QGVAR(tint))}];
_click ctrlAddEventHandler ["MouseExit", {params ["_c"]; [_c, false] call (_c getVariable QGVAR(tint))}];
_click ctrlAddEventHandler ["ButtonClick", {params ["_c"]; call (_c getVariable [QGVAR(code), {}])}];

_click
