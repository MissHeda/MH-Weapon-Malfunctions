#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The open workbench: everything it shows and does (fnc_open), nil while closed.
GVAR(wb) = nil;

if (hasInterface) then {
    // Shift + R, where ACE has its "Clear jam" - ACE's jams become this mod's (fnc_onAceJammed).
    [CBA_SETTINGS_CAT, QGVAR(keyOpen), [LLSTRING(Key_Open), LLSTRING(Key_Open_Desc)], {
        [] call FUNC(open)
    }, {}, [19, [true, false, false]]] call CBA_fnc_addKeybind;
};

ADDON = true;
