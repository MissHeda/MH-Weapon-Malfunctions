#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The panel anew: the status chip, and on the paper page the step to do now with its picture, every step in order
 * (fnc_steps; done ones from GVAR(wb) "done", ticked by fnc_act) and what the last hand movement did.
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

// Without the field notes there is no page to fill.
if !("now" in _ctrls) exitWith {};

private _steps = [_state] call FUNC(steps);
private _done = GVAR(wb) get "done";
private _total = count _done + count _steps;
private _slide = getNumber (configFile >> "CfgWeapons" >> (GVAR(wb) get "weapon") >> "type") == 2;
private _fnc_title = {localize format ["STR_mhwm_workbench_Step_%1", [_this, "rackSlide"] select (_this == "rack" && _slide)]};
private _pictures = createHashMapFromArray [
    ["tap", "tap"], ["rack", "rack"], ["lock", "locked"], ["release", "locked"], ["drop", "magout"], ["insert", "magout"],
    ["clear", "chamber"], ["sweep", "sweep"], ["look", "chamber"]
];

// The count over the page.
(_ctrls get "progress") ctrlSetStructuredText parseText format [
    "<t font='%1' size='0.72' color='%2'>%3</t>",
    _theme get "fontMono", "paperInk" call _hex,
    toUpperANSI ([format [LLSTRING(Progress), (count _done + 1) min _total, _total], LLSTRING(Progress_Done)] select _cleared)
];

// The step now: picture, number, what and how.
private _pic = _ctrls get "nowPic";
private _frameColor = _theme get (["paperRed", "paperGood"] select _cleared);

{_x ctrlSetBackgroundColor _frameColor} forEach (_ctrls get "nowFrame");

if (_cleared) then {
    _pic ctrlShow false;
    (_ctrls get "now") ctrlSetStructuredText parseText format [
        "<t font='%1' size='1.5' color='%2'>%3</t><br/><t size='0.9' color='%4'>%5</t>",
        _theme get "fontBold", "paperGood" call _hex, toUpperANSI LLSTRING(WB_Cleared), "paperInk" call _hex, LLSTRING(Step_Cleared_How)
    ];
} else {
    private _step = _steps select 0;

    _pic ctrlShow true;
    _pic ctrlSetText format [QPATHTOF(ui\step_%1_co.paa), _pictures get _step];
    (_ctrls get "now") ctrlSetStructuredText parseText format [
        "<t font='%1' size='1.15' color='%2'>%3. %4</t><br/><t size='0.85' color='%5'>%6</t>",
        _theme get "fontBold", "paperRed" call _hex, count _done + 1, toUpperANSI (_step call _fnc_title),
        "paperInk" call _hex, localize format ["STR_mhwm_workbench_Step_%1_How", _step]
    ];
};

// Every step: done ones ticked and greyed, the one now in red, the rest in ink.
private _rows = [];

{
    _rows pushBack format [
        "<t font='%1' color='%2'>OK</t>  <t color='%3'>%4. %5</t>",
        _theme get "fontBold", "paperGood" call _hex, "paperMuted" call _hex, _forEachIndex + 1, _x call _fnc_title
    ];
} forEach _done;

{
    _rows pushBack ([
        format ["<t color='%1'>%2. %3</t>", "paperInk" call _hex, count _done + _forEachIndex + 1, _x call _fnc_title],
        format ["<t font='%1' color='%2'>&gt;&gt;  %3. %4</t>", _theme get "fontBold", "paperRed" call _hex, count _done + 1, _x call _fnc_title]
    ] select (_forEachIndex == 0));
} forEach _steps;

(_ctrls get "list") ctrlSetStructuredText parseText format [
    "<t font='%1' size='0.72' color='%2'>%3</t><br/><t size='0.9'>%4</t>",
    _theme get "fontMono", "paperMuted" call _hex, toUpperANSI LLSTRING(Head_Steps), _rows joinString "<br/>"
];

// What the last hand movement did.
private _result = GVAR(wb) getOrDefault ["result", ""];
private _text = switch (true) do {
    case (_result isEqualTo "" || {_result == "WB_Cleared"}): {""};
    case (_result select [0, 3] == "WB_"): {localize format ["STR_mhwm_workbench_%1", _result]};
    default {localize format ["STR_mhwm_malfunctions_%1", _result]};
};

(_ctrls get "last") ctrlSetStructuredText parseText format [
    "<t font='%1' size='0.72' color='%2'>%3</t><br/><t size='0.85' color='%4'>%5</t>",
    _theme get "fontMono", "paperMuted" call _hex, toUpperANSI LLSTRING(Head_Last), "paperInk" call _hex,
    [_text, LLSTRING(Last_None)] select (_text isEqualTo "")
];
