#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The workbench closed (the dialog's onUnload): the frame loop stops, the scene goes, the player's PiP view distance comes
 * back.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

if (isNil QGVAR(wb)) exitWith {};

[GVAR(wb) getOrDefault ["pfh", -1]] call CBA_fnc_removePerFrameHandler;
["stop"] call FUNC(scene);

GVAR(wb) = nil;
