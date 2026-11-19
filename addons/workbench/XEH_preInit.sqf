#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The open workbench: everything it shows and does (fnc_open), nil while closed.
GVAR(wb) = nil;

// When the key went down (diag_tickTime), -1 while it is up or already used.
GVAR(keyDown) = -1;

if (hasInterface) then {
    // One key for a malfunction, ACE's own "Unjam weapon" key (Shift + R): tapped, the blind Tap-Rack; held, the 3D view.
    // ACE's handler on it only acts on ACE's jams, and those become this mod's at once (fnc_onAceJammed) - so the two
    // never both fire. Ctrl + R is ACE's "Check ammo", and CBA runs every handler of a key, none can go first (Mia).
    [CBA_SETTINGS_CAT, QGVAR(keyOpen), [LLSTRING(Key_Open), LLSTRING(Key_Open_Desc)], {
        private _down = diag_tickTime;
        GVAR(keyDown) = _down;

        [{
            params ["_down"];

            if (GVAR(keyDown) isEqualTo _down) then {
                GVAR(keyDown) = -1;
                [] call FUNC(open);
            };
        }, [_down], KEY_HOLD_OPEN] call CBA_fnc_waitAndExecute;

        false
    }, {
        if (GVAR(keyDown) < 0) exitWith {false};

        GVAR(keyDown) = -1;

        // Tap-Rack off on this server: a tap opens the 3D view as well.
        if !(["tapRack"] call EFUNC(malfunctions,quickAction)) then {[] call FUNC(open)};

        false
    }, [19, [true, false, false]]] call CBA_fnc_addKeybind;
};

ADDON = true;
