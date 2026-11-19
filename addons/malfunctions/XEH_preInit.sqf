#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Worked out once per class, on first use: weapon factors (fnc_chance), subsonic magazines.
GVAR(weaponCache) = createHashMap;
GVAR(subsonicCache) = nil;
GVAR(weaponRateMap) = nil;

ADDON = true;
