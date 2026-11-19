#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The panel anew: the status chip, and the notebook's page - the step shown with its picture, every step in order as
 * a checklist (fnc_steps; done ones from GVAR(wb) "done", ticked by fnc_act) and what the last hand movement did. When
 * the page shown changes, the old one turns up over the spiral.
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
private _all = _done + _steps;
private _total = count _all;
private _current = count _done;
private _view = GVAR(wb) get "view";
private _shown = [_view, _current] select (_view < 0 || {_view >= _total});
private _final = _cleared && {_view < 0};
private _slide = getNumber (configFile >> "CfgWeapons" >> (GVAR(wb) get "weapon") >> "type") == 2;
private _fnc_title = {localize format ["STR_mhwm_workbench_Step_%1", [_this, "rackSlide"] select (_this == "rack" && _slide)]};
private _pictures = createHashMapFromArray [
    ["tap", "tap"], ["rack", "rack"], ["lock", "locked"], ["release", "locked"], ["drop", "magout"], ["insert", "magout"],
    ["clear", "chamber"], ["sweep", "sweep"], ["look", "chamber"], ["wait", "wait"], ["pull", "pull"]
];

// A new page: the old one turns up over the spiral and away.
private _page = [_shown, -1] select _final;

if (_page != (GVAR(wb) getOrDefault ["pageShown", _page])) then {
    private _flip = _ctrls get "flip";
    (GVAR(wb) get "pageRect") params ["_fx", "_fy", "_fw", "_fh"];

    _flip ctrlSetPosition [_fx, _fy, _fw, _fh];
    _flip ctrlCommit 0;
    _flip ctrlSetPosition [_fx, _fy, _fw, 0];
    _flip ctrlCommit 0.22;
};

GVAR(wb) set ["pageShown", _page];

// The head of the page: the drill's name, the page count between the tabs.
(_ctrls get "head") ctrlSetStructuredText parseText format [
    "<t font='%1' size='1' color='%2'>%3</t>", _theme get "fontBold", "paperRed" call _hex, toUpperANSI LLSTRING(Paper_Title)
];
(_ctrls get "progress") ctrlSetStructuredText parseText format [
    "<t align='center' font='%1' size='0.85' color='%2'>%3</t>",
    _theme get "fontBold", "paperInk" call _hex,
    [format ["%1/%2", (_shown + 1) min _total, _total], LLSTRING(Progress_Done)] select _final
];

// The page: its picture, the step's name - red for the step now, green when done, ink for one to come - what to do in
// the words of a drill card, written in pen, and how the bench does it.
private _pic = _ctrls get "nowPic";
private _tone = switch (true) do {
    case (_final): {"paperGood"};
    case (_shown < _current): {"paperGood"};
    case (_shown > _current): {"paperInk"};
    default {"paperRed"};
};

if (_final) then {
    _pic ctrlSetText QPATHTOF(ui\step_cleared_co.paa);
    (_ctrls get "nowTitle") ctrlSetStructuredText parseText format [
        "<t font='%1' size='1.05' color='%2'>%3</t>", _theme get "fontBold", "paperGood" call _hex, toUpperANSI LLSTRING(WB_Cleared)
    ];
    (_ctrls get "now") ctrlSetStructuredText parseText format [
        "<t size='0.88' color='%1'>%2</t>", "pen" call _hex, LLSTRING(Step_Cleared_How)
    ];
    (_ctrls get "nowHow") ctrlSetStructuredText parseText "";
} else {
    private _step = _all select _shown;
    private _note = switch (true) do {
        case (_shown < _current): {format ["  <t size='0.72' color='%1'>%2</t>", "paperGood" call _hex, toUpperANSI LLSTRING(Tag_Done)]};
        case (_shown > _current): {format ["  <t size='0.72' color='%1'>%2</t>", "paperMuted" call _hex, toUpperANSI LLSTRING(Tag_Later)]};
        default {""};
    };
    private _benchKey = format ["STR_mhwm_workbench_Spot_Do_%1", _step];

    _pic ctrlSetText format [QPATHTOF(ui\step_%1_co.paa), _pictures get _step];
    (_ctrls get "nowTitle") ctrlSetStructuredText parseText format [
        "<t font='%1' size='1.05' color='%2'>%3. %4</t>%5",
        _theme get "fontBold", _tone call _hex, _shown + 1, toUpperANSI (_step call _fnc_title), _note
    ];
    (_ctrls get "now") ctrlSetStructuredText parseText format [
        "<t size='0.88' color='%1'>%2</t>", "pen" call _hex, localize format ["STR_mhwm_workbench_Step_%1_How", _step]
    ];
    (_ctrls get "nowHow") ctrlSetStructuredText parseText (if (isLocalized _benchKey && {!(GVAR(wb) get "buttons")}) then {
        format [
            "<t font='%1' size='0.74' color='%2'>%3  </t><t font='%1' size='0.74' color='%4'>%5</t>",
            _theme get "fontBold", "paperMuted" call _hex, toUpperANSI LLSTRING(Bench), "paperRed" call _hex, toUpperANSI localize _benchKey
        ]
    } else {""});
};

// The sequence: a check box a step - ticked in pen when done, red for the step now - the page shown marked over with a
// highlighter.
{
    _x params ["_box", "_row", "_click"];

    if (_forEachIndex >= _total) then {
        {_x ctrlShow false} forEach [_box, _row, _click];
    } else {
        private _step = _all select _forEachIndex;
        private _isDone = _forEachIndex < _current;
        private _isNow = _forEachIndex == _current && {!_cleared};

        _box ctrlSetText ([QPATHTOF(ui\box_ca.paa), QPATHTOF(ui\tick_ca.paa)] select _isDone);
        _box ctrlSetTextColor (_theme get (switch (true) do {
            case (_isDone): {"pen"};
            case (_isNow): {"paperRed"};
            default {"paperMuted"};
        }));

        _row ctrlSetStructuredText parseText format [
            "<t font='%1' size='0.86' color='%2'>%3. %4</t>",
            _theme get (["font", "fontBold"] select _isNow),
            (switch (true) do {
                case (_isDone): {"paperMuted"};
                case (_isNow): {"paperRed"};
                default {"paperInk"};
            }) call _hex,
            _forEachIndex + 1, _step call _fnc_title
        ];
        _row ctrlSetBackgroundColor ([[0, 0, 0, 0], [1, 0.92, 0.3, 0.38]] select (_forEachIndex == _shown && {!_final}));

        {_x ctrlShow true} forEach [_box, _row, _click];
    };
} forEach (_ctrls get "rows");

// What the last hand movement did: a note at the foot of the page.
private _result = GVAR(wb) getOrDefault ["result", ""];
private _text = switch (true) do {
    case (_result isEqualTo "" || {_result == "WB_Cleared"}): {""};
    case (_result select [0, 3] == "WB_"): {localize format ["STR_mhwm_workbench_%1", _result]};
    default {localize format ["STR_mhwm_malfunctions_%1", _result]};
};

(_ctrls get "last") ctrlSetStructuredText parseText format [
    "<t font='%1' size='0.74' color='%2'>%3  </t><t size='0.86' color='%4'>%5</t>",
    _theme get "fontBold", "paperMuted" call _hex, toUpperANSI LLSTRING(Head_Last), "pen" call _hex,
    [_text, LLSTRING(Last_None)] select (_text isEqualTo "")
];
