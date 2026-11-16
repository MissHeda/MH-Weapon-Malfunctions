#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The panel anew: what is seen on the weapon (mhwm_malfunctions_fnc_describe), what the last hand movement did, and what
 * the hands can do - by mouse, or the buttons.
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
private _state = [GVAR(wb) get "unit", GVAR(wb) get "weapon"] call EFUNC(malfunctions,state);

// What is seen.
private _lines = ([_state] call EFUNC(malfunctions,describe)) apply {
    _x params ["_text", "_problem"];

    format [
        "<t color='%1' size='1.1'>%2</t>  <t color='%3'>%4</t>",
        [HEX_DIM, HEX_RED] select _problem,
        ["·", "■"] select _problem,
        HEX_TEXT,
        _text
    ]
};

(_ctrls get "see") ctrlSetStructuredText parseText (_lines joinString "<br/>");

// The last hand movement.
private _result = GVAR(wb) getOrDefault ["result", ""];
private _text = switch (true) do {
    case (_result isEqualTo ""): {format ["<t color='%1'>%2</t>", HEX_DIM, LLSTRING(Last_None)]};
    case (_result == "WB_Cleared"): {format ["<t font='PuristaBold' size='1.2' color='#6bd98c'>%1</t>", LLSTRING(WB_Cleared)]};
    case (_result select [0, 3] == "WB_"): {localize format ["STR_mhwm_workbench_%1", _result]};
    default {localize format ["STR_mhwm_malfunctions_%1", _result]};
};

(_ctrls get "last") ctrlSetStructuredText parseText _text;

// What the hands can do.
(_ctrls get "hands") ctrlSetStructuredText parseText (
    [LLSTRING(Hands_Help), LLSTRING(Hands_Buttons)] select (GVAR(wb) get "buttons")
);
