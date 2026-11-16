#include "script_component.hpp"

if (!hasInterface) exitWith {};

// "Clear malfunction": ACE's self-interaction under Equipment, else the action menu - shown only while the weapon in the
// hands is jammed.
if (HAS_ACE) then {
    private _action = [
        QGVAR(open),
        LLSTRING(Action_Open),
        "\A3\ui_f\data\igui\cfg\actions\reload_ca.paa",
        {[] call FUNC(open)},
        {[_player] call EFUNC(malfunctions,isBlocked)}
    ] call ace_interact_menu_fnc_createAction;

    ["CAManBase", 1, ["ACE_SelfActions", "ACE_Equipment"], _action, true] call ace_interact_menu_fnc_addActionToClass;
} else {
    GVAR(addAction) = {
        params ["_unit"];

        if (isNull _unit || {_unit getVariable [QGVAR(actionAdded), false]}) exitWith {};

        _unit setVariable [QGVAR(actionAdded), true];
        _unit addAction [
            format ["<t color='%1'>%2</t>", HEX_RED, LLSTRING(Action_Open)],
            {[] call FUNC(open)},
            nil,
            6,
            true,
            true,
            "",
            "_this == _target && {[_this] call mhwm_malfunctions_fnc_isBlocked}"
        ];
    };

    // Retroactive: the unit the player has now gets it at once.
    ["unit", {[_this select 0] call GVAR(addAction)}, true] call CBA_fnc_addPlayerEventHandler;
};
