#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The field manual over the workbench: one page drawn like an old army maintenance comic (tools/manual/make_manual.py ->
 * ui\manual_co.paa) that shows how every minigame is played. A click anywhere closes it; while it is up the 3D view takes
 * no mouse (fnc_onMouse). It comes up by itself the first time a player opens the workbench (profile).
 *
 * Arguments:
 * 0: Show <BOOL> (default: the other way round)
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_show", isNil {GVAR(wb) get "manual"}, [true]]];

if (isNil QGVAR(wb)) exitWith {};

private _display = GVAR(wb) get "display";

{ctrlDelete _x} forEach (GVAR(wb) getOrDefault ["manual", []]);
GVAR(wb) deleteAt "manual";

if (!_show) exitWith {};

profileNamespace setVariable [QGVAR(manualSeen), true];

private _controls = [];

private _dim = _display ctrlCreate [QGVAR(rect), -1];
_dim ctrlSetPosition [safeZoneX, safeZoneY, safeZoneW, safeZoneH];
_dim ctrlSetBackgroundColor [0, 0, 0, 0.72];
_dim ctrlCommit 0;
_controls pushBack _dim;

// The page is 2:1 in pixels: as large as fits, with room for the line under it.
private _h = 0.86 * safeZoneH;
private _w = 2 * (_h / pixelH) * pixelW;

if (_w > 0.94 * safeZoneW) then {
    _w = 0.94 * safeZoneW;
    _h = ((_w / pixelW) / 2) * pixelH;
};

private _x = safeZoneX + (safeZoneW - _w) / 2;
private _y = safeZoneY + (safeZoneH - _h) / 2 - 0.02 * safeZoneH;

// A shadow under the paper.
private _shadow = _display ctrlCreate [QGVAR(rect), -1];
_shadow ctrlSetPosition [_x + 6 * pixelW, _y + 6 * pixelH, _w, _h];
_shadow ctrlSetBackgroundColor [0, 0, 0, 0.6];
_shadow ctrlCommit 0;
_controls pushBack _shadow;

private _page = _display ctrlCreate [QGVAR(picture), -1];
_page ctrlSetPosition [_x, _y, _w, _h];
_page ctrlSetText QPATHTOF(ui\manual_co.paa);
_page ctrlCommit 0;
_controls pushBack _page;

private _theme = GVAR(wb) get "theme";
private _note = _display ctrlCreate [QGVAR(structured), -1];
_note ctrlSetPosition [_x, _y + _h + 0.008 * safeZoneH, _w, 0.03 * safeZoneH];
_note ctrlSetStructuredText parseText format [
    "<t align='center' font='%1' size='0.75' color='%2'>%3</t>",
    _theme get "fontMono", (_theme get "muted") call BIS_fnc_colorRGBAtoHTML, toUpperANSI LLSTRING(Manual_Close)
];
_note ctrlCommit 0;
_controls pushBack _note;

// The whole screen closes it.
private _click = _display ctrlCreate [QGVAR(click), -1];
_click ctrlSetPosition [safeZoneX, safeZoneY, safeZoneW, safeZoneH];
_click ctrlCommit 0;
_click ctrlAddEventHandler ["ButtonClick", {[false] call FUNC(manual)}];
ctrlSetFocus _click;
_controls pushBack _click;

GVAR(wb) set ["manual", _controls];
