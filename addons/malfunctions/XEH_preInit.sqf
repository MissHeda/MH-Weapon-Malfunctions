#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Worked out once per class, on first use: weapon factors (fnc_chance), subsonic magazines.
GVAR(weaponCache) = createHashMap;
GVAR(subsonicCache) = nil;
GVAR(weaponRateMap) = nil;

// The quick keys: blind clearing without the 3D view (fnc_quickAction). Unbound but the immediate action drill.
if (hasInterface) then {
    private _cat = CBA_SETTINGS_CAT;

    [_cat, QGVAR(keyTapRack), [LLSTRING(Key_TapRack), LLSTRING(Key_TapRack_Desc)], {
        ["tapRack"] call FUNC(quickAction)
    }, {}, [19, [false, true, false]]] call CBA_fnc_addKeybind; // Ctrl + R

    [_cat, QGVAR(keyTap), [LLSTRING(Key_Tap), LLSTRING(Key_Tap_Desc)], {
        [ACT_TAP] call FUNC(quickAction)
    }, {}, [0, [false, false, false]]] call CBA_fnc_addKeybind;

    [_cat, QGVAR(keyRack), [LLSTRING(Key_Rack), LLSTRING(Key_Rack_Desc)], {
        [ACT_RACK] call FUNC(quickAction)
    }, {}, [0, [false, false, false]]] call CBA_fnc_addKeybind;

    [_cat, QGVAR(keyLock), [LLSTRING(Key_Lock), LLSTRING(Key_Lock_Desc)], {
        ["lockToggle"] call FUNC(quickAction)
    }, {}, [0, [false, false, false]]] call CBA_fnc_addKeybind;

    [_cat, QGVAR(keyMag), [LLSTRING(Key_Mag), LLSTRING(Key_Mag_Desc)], {
        ["magToggle"] call FUNC(quickAction)
    }, {}, [0, [false, false, false]]] call CBA_fnc_addKeybind;

    // Ctrl + Shift + J: a malfunction now, the next cause each press - for testing (fnc_testJam).
    [_cat, QGVAR(keyTest), [LLSTRING(Key_Test), LLSTRING(Key_Test_Desc)], {
        call FUNC(testJam)
    }, {}, [36, [true, true, false]]] call CBA_fnc_addKeybind;

    [_cat, QGVAR(keyClear), [LLSTRING(Key_Clear), LLSTRING(Key_Clear_Desc)], {
        [ACT_CLEAR] call FUNC(quickAction)
    }, {}, [0, [false, false, false]]] call CBA_fnc_addKeybind;
};

ADDON = true;
