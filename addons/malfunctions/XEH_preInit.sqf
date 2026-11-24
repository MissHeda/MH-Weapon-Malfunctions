#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Worked out once per class, on first use: weapon factors (fnc_chance), subsonic magazines.
GVAR(weaponCache) = createHashMap;
GVAR(subsonicCache) = nil;
GVAR(weaponRateMap) = nil;

// A malfunction on purpose, to practise: no key by default (Mia), set one in CBA's keybinds.
if (hasInterface) then {
    [CBA_SETTINGS_CAT, QGVAR(keyTest), [LLSTRING(Key_Test), LLSTRING(Key_Test_Desc)], {
        call FUNC(testJam)
    }, {}, [0, [false, false, false]]] call CBA_fnc_addKeybind;
};

ADDON = true;
