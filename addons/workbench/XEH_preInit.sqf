#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The open workbench: everything it shows and does (fnc_open), nil while closed.
GVAR(wb) = nil;

if (hasInterface) then {
    // The 3D view on a key of its own (Mia: not by holding Shift + R): Ctrl + Shift + R.
    [CBA_SETTINGS_CAT, QGVAR(keyOpen), [LLSTRING(Key_Open), LLSTRING(Key_Open_Desc)], {
        [] call FUNC(open);
        false
    }, {}, [19, [true, true, false]]] call CBA_fnc_addKeybind;

    // Tap-Rack on Ctrl + R (Mia). That is ACE's "Check ammo" too, and CBA runs every handler of a key - none can go first.
    // ACE's check plays the reload gesture (fits the Tap-Rack) and shows its ammo hint a second later: while the weapon is
    // jammed that hint is taken down again as it comes up. With Tap-Rack off on the server it opens the 3D view instead.
    [CBA_SETTINGS_CAT, QEGVAR(malfunctions,keyTapRack), [LLSTRING(Key_TapRack), LLSTRING(Key_TapRack_Desc)], {
        private _unit = PLAYER_UNIT;

        if (count ([_unit, currentWeapon _unit] call EFUNC(malfunctions,state)) == 0) exitWith {false};

        if !(["tapRack"] call EFUNC(malfunctions,quickAction)) then {[] call FUNC(open)};

        if (!isNil "ace_reload_fnc_checkAmmo") then {
            [{
                ctrlShown (uiNamespace getVariable ["ACE_ctrlHint", controlNull])
            }, {
                ("ACE_RscHint" call BIS_fnc_rscLayer) cutText ["", "PLAIN"];
            }, [], 2] call CBA_fnc_waitUntilAndExecute;
        };

        true
    }, {}, [19, [false, true, false]]] call CBA_fnc_addKeybind;
};

ADDON = true;
