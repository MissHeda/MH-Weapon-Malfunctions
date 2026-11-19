#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Worked out once per class, on first use: weapon factors (fnc_chance), subsonic magazines.
GVAR(weaponCache) = createHashMap;
GVAR(subsonicCache) = nil;
GVAR(weaponRateMap) = nil;

// One key only (Mia: too many keybinds): the blind Tap-Rack. Everything else is done in the 3D view (Shift + R).
if (hasInterface) then {
    private _cat = CBA_SETTINGS_CAT;

    [_cat, QGVAR(keyTapRack), [LLSTRING(Key_TapRack), LLSTRING(Key_TapRack_Desc)], {
        ["tapRack"] call FUNC(quickAction)
    }, {}, [19, [false, false, true]]] call CBA_fnc_addKeybind; // Alt + R - Ctrl + R is ACE's "Check ammo"

};

ADDON = true;
