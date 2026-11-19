#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Worked out once per class, on first use: weapon factors (fnc_chance), subsonic magazines.
GVAR(weaponCache) = createHashMap;
GVAR(subsonicCache) = nil;
GVAR(weaponRateMap) = nil;

// Two keys only (Mia: too many keybinds): the blind Tap-Rack and the test key. Everything else is done in the 3D view.
if (hasInterface) then {
    private _cat = CBA_SETTINGS_CAT;

    [_cat, QGVAR(keyTapRack), [LLSTRING(Key_TapRack), LLSTRING(Key_TapRack_Desc)], {
        ["tapRack"] call FUNC(quickAction)
    }, {}, [19, [false, true, false]]] call CBA_fnc_addKeybind; // Ctrl + R

    // Ctrl + Shift + J: a malfunction now, the next cause each press - for testing (fnc_testJam).
    [_cat, QGVAR(keyTest), [LLSTRING(Key_Test), LLSTRING(Key_Test_Desc)], {
        call FUNC(testJam)
    }, {}, [36, [true, true, false]]] call CBA_fnc_addKeybind;
};

ADDON = true;
