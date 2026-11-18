#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The panel anew: the status chip, what is seen on the weapon (mhwm_malfunctions_fnc_describe), what the last hand
 * movement did, and what the hands can do - by mouse, or the buttons. Problems in the theme's warning red, everything
 * else in white and grey; the accent marks the parts' names in the procedure.
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

private _ctrls = GVAR(wb) get "ctrls";
private _theme = GVAR(wb) get "theme";
private _state = [GVAR(wb) get "unit", GVAR(wb) get "weapon"] call EFUNC(malfunctions,state);
private _hex = {(_theme get _this) call BIS_fnc_colorRGBAtoHTML};
private _cleared = count _state == 0;

// The status chip: a red film while jammed, a green one when clear.
private _chipColor = +(_theme get (["warn", "good"] select _cleared));
_chipColor set [3, 0.22];

{
    if (ctrlType _x == 0 && {ctrlStyle _x == 48}) then {_x ctrlSetTextColor _chipColor} else {_x ctrlSetBackgroundColor _chipColor};
} forEach (_ctrls get "chipParts");

(_ctrls get "chip") ctrlSetStructuredText parseText format [
    "<t align='center' font='%1' size='0.85' color='%2'>%3</t>",
    _theme get "fontMono",
    (["warn", "good"] select _cleared) call _hex,
    toUpperANSI ([LLSTRING(Status_Jammed), LLSTRING(Status_Clear)] select _cleared)
];

// What is seen.
private _lines = ([_state] call EFUNC(malfunctions,describe)) apply {
    _x params ["_text", "_problem"];

    format [
        "<t font='%1' color='%2'>%3</t>  <t color='%4'>%5</t>",
        _theme get "fontMono",
        (["muted", "warn"] select _problem) call _hex,
        [">", "!"] select _problem,
        (["text2", "text"] select _problem) call _hex,
        _text
    ]
};

(_ctrls get "see") ctrlSetStructuredText parseText format ["<t size='0.95'>%1</t>", _lines joinString "<br/>"];

// The last hand movement.
private _result = GVAR(wb) getOrDefault ["result", ""];
private _text = switch (true) do {
    case (_result isEqualTo ""): {format ["<t color='%1'>%2</t>", "muted" call _hex, LLSTRING(Last_None)]};
    case (_result == "WB_Cleared"): {format ["<t font='%1' size='1.15' color='%2'>%3</t>", _theme get "fontBold", "good" call _hex, LLSTRING(WB_Cleared)]};
    case (_result select [0, 3] == "WB_"): {localize format ["STR_mhwm_workbench_%1", _result]};
    default {localize format ["STR_mhwm_malfunctions_%1", _result]};
};

(_ctrls get "last") ctrlSetStructuredText parseText format ["<t size='0.95'>%1</t>", _text];

// What the hands can do: the parts' names in the accent.
(_ctrls get "hands") ctrlSetStructuredText parseText format [
    "<t size='0.82' color='%2'>%1</t>",
    ([LLSTRING(Hands_Help), LLSTRING(Hands_Buttons)] select (GVAR(wb) get "buttons")) regexReplace ["#ACCENT#/g", "accent" call _hex],
    "text2" call _hex
];
