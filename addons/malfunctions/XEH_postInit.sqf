#include "script_component.hpp"

// Every shot of a local unit may be the one that jams (fnc_onFired); reloading keeps the malfunction (fnc_onReloaded).
["CAManBase", "Fired", {call FUNC(onFired)}] call CBA_fnc_addClassEventHandler;
["CAManBase", "Reloaded", {call FUNC(onReloaded)}] call CBA_fnc_addClassEventHandler;

// ACE Overheating jams weapons on its own: taken over or cleared at once (fnc_onAceJammed).
["ace_weaponJammed", {call FUNC(onAceJammed)}] call CBA_fnc_addEventHandler;

// Switched off: every weapon jammed now works again.
["CBA_SettingChanged", {
    params ["_setting", "_value"];

    if (_setting != QEGVAR(main,enabled) || {_value}) exitWith {};

    {
        private _unit = _x;

        {
            [_unit, _x, true] call FUNC(clear);
        } forEach keys (_unit getVariable [QGVAR(states), createHashMap]);
    } forEach (allUnits select {local _x});
}] call CBA_fnc_addEventHandler;
