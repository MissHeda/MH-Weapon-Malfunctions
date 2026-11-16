// Warnings and errors go straight to the RPT rather than through CBA_fnc_log.
#define DEBUG_SYNCHRONOUS
#include "\x\cba\addons\main\script_macros_common.hpp"
#include "\x\cba\addons\xeh\script_xeh.hpp"

// Functions are compiled through CBA, which caches them and lets them be recompiled while testing with file patching.
#undef PREP
#define PREP(fncName) [QPATHTOF(functions\DOUBLES(fnc,fncName).sqf), QFUNC(fncName)] call CBA_fnc_compileFunction

// The unit the player controls, a unit taken over in Zeus included.
#define PLAYER_UNIT (missionNamespace getVariable ["ACE_player", player])

// ACE is optional; only ACE Overheating jams weapons.
#define HAS_ACE (isClass (configFile >> "CfgPatches" >> "ace_common"))
#define HAS_ACE_OVERHEATING (isClass (configFile >> "CfgPatches" >> "ace_overheating"))

// The settings' category in CBA's Addon Options.
#define CBA_SETTINGS_CAT "MH Weapon Malfunctions"

// ----- A malfunction's state (a hashmap per weapon class, kept on the unit, fnc_state) -----
// "cause"   what went wrong first, one of the CAUSE_* below
// "bolt"    "closed" | "short" (not fully forward) | "locked" (held open by the bolt catch)
// "chamber" "empty" | "round" | "dud" | "double" (two rounds wedged) | "case" (spent case stuck)
// "port"    "clear" | "stovepipe" (spent case caught in the ejection port)
// "mag"     "in" | "loose" (not seated) | "out"
// "tried"   the trigger was pulled on it at least once - a dud is only known after that
#define CAUSE_FEED "feed"
#define CAUSE_DUD "dud"
#define CAUSE_STOVEPIPE "stovepipe"
#define CAUSE_DOUBLE "double"
#define CAUSE_EXTRACT "extract"
#define CAUSES [CAUSE_FEED, CAUSE_DUD, CAUSE_STOVEPIPE, CAUSE_DOUBLE, CAUSE_EXTRACT]

// ----- What a hand does to the weapon (fnc_act) -----
#define ACT_TAP "tap"
#define ACT_RACK "rack"
#define ACT_SHORT "short"
#define ACT_LOCK "lock"
#define ACT_RELEASE "release"
#define ACT_DROP "drop"
#define ACT_INSERT "insert"
#define ACT_INSERT_LOOSE "insertLoose"
#define ACT_CLEAR "clear"
#define ACT_SWEEP "sweep"

// Raised locally whenever a unit's malfunction changed: [unit, weapon, state or nil when cleared].
#define EVENT_CHANGED "mhwm_malfunctions_changed"

// ----- The look: MH | Workshop -----
#define COLOR_BASE [0.043, 0.027, 0.031, 0.94]
#define COLOR_PANEL [0.075, 0.045, 0.05, 0.96]
#define COLOR_RED [0.878, 0.157, 0.247, 1]
#define COLOR_RED_SOFT [0.878, 0.157, 0.247, 0.35]
#define COLOR_TEXT [0.863, 0.863, 0.875, 1]
#define COLOR_DIM [0.863, 0.863, 0.875, 0.55]
#define COLOR_GOOD [0.42, 0.85, 0.55, 1]
#define HEX_RED "#e0283f"
#define HEX_TEXT "#dcdcdf"
#define HEX_DIM "#8c8b90"

// A sound of the mod near the unit.
// playSound3D wants an addon's path without the leading backslash.
#define SOUND_PATH(name) QUOTE(z\mhwm\addons\malfunctions\sounds\name.ogg)
#define SOUND_BOLT "A3\Sounds_F_Arsenal\weapons\LongRangeRifles\M320\M320_bolt_01.wss"
#define SOUND_BOLT_2 "A3\Sounds_F_Arsenal\weapons\LongRangeRifles\M320\M320_bolt_02.wss"
#define SOUND_DRY "A3\Sounds_F_Arsenal\weapons\Rifles\Mk20\dry_Mk20.wss"
