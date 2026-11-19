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

    // Tap-Rack on ACE's own "Unjam weapon" key (Shift + R): ACE's handler there only acts on ACE's jams, and those become
    // this mod's at once (fnc_onAceJammed) - the two never both fire. Ctrl + R is ACE's "Check ammo", and CBA runs every
    // handler of a key, none can go first. With Tap-Rack off on the server it opens the 3D view instead.
    [CBA_SETTINGS_CAT, QEGVAR(malfunctions,keyTapRack), [LLSTRING(Key_TapRack), LLSTRING(Key_TapRack_Desc)], {
        if !(["tapRack"] call EFUNC(malfunctions,quickAction)) then {[] call FUNC(open)};
        false
    }, {}, [19, [true, false, false]]] call CBA_fnc_addKeybind;
};

ADDON = true;
