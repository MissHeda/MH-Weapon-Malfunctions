#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A pane with round corners, as AIO draws them (its fnc_uiPanel): a middle bar and two side bars, and in the corners
 * a quarter circle texture tinted the pane's colour. Snapped to whole pixels so no seam shows.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Rectangle [x, y, w, h] <ARRAY> (screen)
 * 2: Colour <ARRAY>
 * 3: Corner radius <NUMBER> (default: the theme's)
 *
 * Return Value:
 * The controls made <ARRAY>
 *
 * Public: No
 */

params ["_display", "_rect", "_color", ["_radius", -1]];
_rect params ["_left", "_top", "_width", "_height"];

if (_radius < 0) then {_radius = (GVAR(wb) get "theme") get "radius"};

private _x0 = safeZoneX + round ((_left - safeZoneX) / pixelW) * pixelW;
private _y0 = safeZoneY + round ((_top - safeZoneY) / pixelH) * pixelH;
private _x1 = safeZoneX + round ((_left + _width - safeZoneX) / pixelW) * pixelW;
private _y1 = safeZoneY + round ((_top + _height - safeZoneY) / pixelH) * pixelH;
private _corner = floor (_radius / pixelH) min floor (round ((_x1 - _x0) / pixelW) / 2) min floor (round ((_y1 - _y0) / pixelH) / 2);
private _controls = [];

private _fnc_rect = {
    private _ctrl = _display ctrlCreate [QGVAR(rect), -1];
    _ctrl ctrlSetPosition _this;
    _ctrl ctrlSetBackgroundColor _color;
    _ctrl ctrlCommit 0;
    _controls pushBack _ctrl;
};

if (_corner < 1) exitWith {
    [_x0, _y0, _x1 - _x0, _y1 - _y0] call _fnc_rect;
    _controls
};

private _cap = _corner * pixelW;
private _rise = _corner * pixelH;

{
    if (_x select 3 > 0) then {_x call _fnc_rect};
} forEach [
    [_x0 + _cap, _y0, _x1 - _x0 - 2 * _cap, _y1 - _y0],
    [_x0, _y0 + _rise, _cap, _y1 - _y0 - 2 * _rise],
    [_x1 - _cap, _y0 + _rise, _cap, _y1 - _y0 - 2 * _rise]
];

{
    _x params ["_texture", "_cornerRect"];

    private _ctrl = _display ctrlCreate [QGVAR(corner), -1];
    _ctrl ctrlSetPosition _cornerRect;
    _ctrl ctrlSetText _texture;
    _ctrl ctrlSetTextColor _color;
    _ctrl ctrlCommit 0;
    _controls pushBack _ctrl;
} forEach [
    [QPATHTOF(ui\corner_tl_ca.paa), [_x0, _y0, _cap, _rise]],
    [QPATHTOF(ui\corner_tr_ca.paa), [_x1 - _cap, _y0, _cap, _rise]],
    [QPATHTOF(ui\corner_bl_ca.paa), [_x0, _y1 - _rise, _cap, _rise]],
    [QPATHTOF(ui\corner_br_ca.paa), [_x1 - _cap, _y1 - _rise, _cap, _rise]]
];

_controls
