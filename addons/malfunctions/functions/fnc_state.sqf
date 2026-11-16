#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A weapon's malfunction on a unit: its state (see script_macros.hpp, "A malfunction's state"), kept per weapon class in
 * the unit's GVAR(states). A weapon the unit no longer carries has none: its state goes with it.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 * 2: New state <HASHMAP> (optional; an empty hashmap removes it)
 *
 * Return Value:
 * The state, an empty hashmap when the weapon works <HASHMAP>
 *
 * Example:
 * [player, primaryWeapon player] call mhwm_malfunctions_fnc_state;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], "_new"];

private _states = _unit getVariable [QGVAR(states), createHashMap];
private _key = toLowerANSI _weapon;

if (!isNil "_new") exitWith {
    if (count _new == 0) then {
        _states deleteAt _key;
    } else {
        _states set [_key, _new];
    };

    _unit setVariable [QGVAR(states), _states];
    [EVENT_CHANGED, [_unit, _weapon, _new]] call CBA_fnc_localEvent;
    _new
};

private _state = _states getOrDefault [_key, createHashMap];

// Dropped, handed over, swapped in the arsenal: the malfunction went with the weapon.
if (count _state > 0 && {!(_weapon in [primaryWeapon _unit, handgunWeapon _unit])}) exitWith {
    _states deleteAt _key;
    createHashMap
};

_state
