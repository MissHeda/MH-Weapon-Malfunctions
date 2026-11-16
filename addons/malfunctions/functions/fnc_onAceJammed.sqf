#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE Overheating jammed a weapon ("ace_weaponJammed"). Its jam is cleared at once, as its own successful clearing does
 * (no failed tries, no gesture) - so ACE's "Clear jam" never shows and its fire block lets go. Then:
 * - "ACE Overheating decides": the jam becomes this mod's malfunction, ACE's type mapped onto it,
 * - "This mod decides": nothing more, the rate set here is what counts.
 * Switched off, this mod leaves ACE's jams alone.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 * 2: ACE jam type <STRING> - "eject", "extract", "feed", "fire", "dud"
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_aceType", "", [""]]];

if (!local _unit || {!EGVAR(main,enabled)}) exitWith {};

// ACE's own state: this weapon is no longer in its list, and its fire block goes once nothing is jammed.
private _jammed = (_unit getVariable ["ace_overheating_jammedWeapons", []]) - [_weapon];

_unit setVariable ["ace_overheating_jammedWeapons", _jammed];
_unit setVariable [format ["ace_overheating_%1_jamType", _weapon], "None"];

if (_jammed isEqualTo []) then {
    private _id = _unit getVariable ["ace_overheating_JammingActionID", -1];

    if (_id != -1) then {
        [_unit, "DefaultAction", _id] call (missionNamespace getVariable ["ace_common_fnc_removeActionEventHandler", {}]);
        _unit setVariable ["ace_overheating_JammingActionID", -1];
    };
};

if (EGVAR(main,aceMode) != 1) exitWith {};

private _cause = switch (toLowerANSI _aceType) do {
    case "eject": {CAUSE_STOVEPIPE};
    case "extract": {CAUSE_EXTRACT};
    case "feed": {CAUSE_FEED};
    case "dud";
    case "fire": {CAUSE_DUD};
    default {""};
};

// A cause the server switched off (weight 0) is picked anew by the weights.
if (_cause isNotEqualTo "" && {(missionNamespace getVariable [format ["mhwm_main_weight_%1", _cause], 1]) <= 0}) then {
    _cause = "";
};

if !(_weapon in [primaryWeapon _unit, handgunWeapon _unit]) exitWith {};
if (_weapon == handgunWeapon _unit && {!EGVAR(main,handguns)}) exitWith {};

[_unit, _weapon, _cause] call FUNC(jam);
