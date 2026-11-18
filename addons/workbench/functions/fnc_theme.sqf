#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The workbench's colours, in the look of AIO's Glass: near-black panes with round corners, faint light films on them,
 * white text with grey for the second line, Purista - and the accent is the player's own active element colour from
 * Arma's Options > Game > Colors (orange without one), brightened where it would sink into the dark panes. Warnings are
 * a fixed red, a cleared weapon a fixed green: they mean something, whatever the player's colour.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Theme <HASHMAP>: accent, accentSoft, accentHover, onAccent, panel, card, cardHover, line, text, text2, muted, warn, good,
 * dim, radius, font, fontBold, fontMono
 *
 * Example:
 * call mhwm_workbench_fnc_theme;
 *
 * Public: No
 */

private _fnc_luma = {
    params ["_c"];
    0.2126 * ((_c select 0) ^ 2.2) + 0.7152 * ((_c select 1) ^ 2.2) + 0.0722 * ((_c select 2) ^ 2.2)
};

// The profile's colour; a channel it does not hold reads as -1.
private _rgb = ["R", "G", "B"] apply {profileNamespace getVariable [format ["GUI_BCG_RGB_%1", _x], -1]};

if (!(_rgb isEqualTypeAll 0) || {_rgb findIf {!(_x >= 0 && {_x <= 1})} >= 0}) then {
    _rgb = ACCENT_FALLBACK;
};

// Brightened until it stands out from the panes: a pure dark blue would sink into them.
for "_i" from 1 to 40 do {
    if (([_rgb] call _fnc_luma) >= ACCENT_MIN_LUMA) exitWith {};

    private _top = selectMax _rgb;

    _rgb = if (_top >= 0.1 && {_top < 1}) then {
        _rgb apply {(_x * 1.12) min 1}
    } else {
        _rgb apply {_x + (1 - _x) * 0.08}
    };
};

// Text on the accent: dark on a light accent, white on a dark one.
private _fill = ([_rgb] call _fnc_luma) + 0.05;
private _onAccent = [[1, 1, 1, 1], [0.05, 0.05, 0.05, 1]] select (_fill / (0.003 + 0.05) >= 1.05 / _fill);

createHashMapFromArray [
    ["accent", _rgb + [1]],
    ["accentSoft", _rgb + [0.2]],
    ["accentHover", (_rgb apply {_x + (1 - _x) * 0.25}) + [1]],
    ["onAccent", _onAccent],
    ["panel", [0.05, 0.05, 0.05, 0.92]],
    ["card", [1, 1, 1, 0.045]],
    ["cardHover", [1, 1, 1, 0.09]],
    ["line", [1, 1, 1, 0.08]],
    ["text", [1, 1, 1, 1]],
    ["text2", [0.78, 0.78, 0.78, 1]],
    ["muted", [0.56, 0.56, 0.56, 1]],
    ["warn", [0.93, 0.33, 0.27, 1]],
    ["good", [0.42, 0.85, 0.55, 1]],
    ["dim", [0, 0, 0, 0.5]],
    ["radius", 0.012 * safeZoneH],
    ["font", "PuristaMedium"],
    ["fontBold", "PuristaSemibold"],
    ["fontMono", "EtelkaMonospacePro"]
]
