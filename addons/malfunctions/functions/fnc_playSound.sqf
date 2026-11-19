#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A sound of a hand on the weapon, at the unit, heard by everyone near (playSound3D). The bolt is Arma's own, the magazine's
 * are recordings. Each player can switch them off for themselves.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Kind <STRING> - "bolt", "boltBack" (pulled to the rear), "boltHome" (let go, it snaps forward), "dry", "seat",
 *    "drop_1", "rattle", "click_1"
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "bolt"] call mhwm_malfunctions_fnc_playSound;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_kind", "", [""]]];

if (!EGVAR(main,sounds) || {isNull _unit}) exitWith {};

private _file = switch (_kind) do {
    case "bolt": {selectRandom [SOUND_BOLT, SOUND_BOLT_2]};
    case "boltBack": {SOUND_BOLT_BACK};
    case "boltHome": {selectRandom SOUND_BOLT_HOME};
    case "dry": {SOUND_DRY};
    case "seat": {SOUND_PATH(seat)};
    case "drop_1": {SOUND_PATH(drop_1)};
    case "rattle": {SOUND_PATH(rattle)};
    case "click_1": {SOUND_PATH(click_1)};
    default {""};
};

if (_file isEqualTo "") exitWith {};

playSound3D [_file, objNull, insideBuilding _unit >= 0.5, eyePos _unit, 1.4, 1, 20];
