// Checks the test mission's menu (.hemtt/missions/MHWM_Test.VR, copied here as menu.sqf by the runner's caller): every
// entry is run once, the result logged - and pictures of the bench with the paper panel.
if (!hasInterface) exitWith {};
call compile preprocessFileLineNumbers "menu.sqf";

[] spawn {
    waitUntil {!isNull player && {time > 3}};
    disableUserInput true;
    profileNamespace setVariable ["mhwm_workbench_manualSeen", true];
    sleep 2;
    diag_log text format ["MHWMTEST actions on player: %1, ACE root: %2", count actionIDs player, !isNil "ace_interact_menu_fnc_createAction"];
    {
        _x params ["_label", "_code", "_group"];
        if (_group != "AI" && {_label != "Open the 3D bench"}) then {
            call _code;
            sleep 0.3;
            private _s = [player, currentWeapon player] call mhwm_malfunctions_fnc_state;
            diag_log text format ["MHWMTEST entry '%1': weapon %2, state %3", _label, currentWeapon player, if (count _s == 0) then {"none"} else {[_s get "cause", _s get "mag"]}];
        };
    } forEach MHWMT_entries;

    player selectWeapon primaryWeapon player;
    sleep 1;
    ["double"] call MHWMT_jam;
    [] call mhwm_workbench_fnc_open;
    sleep 3;
    diag_log text format ["MHWMTEST first open: dialog %1, manual %2", !isNull findDisplay 79420, "manual" in mhwm_workbench_wb];
    diag_log text "MHWMTEST SHOT paper_double";
    sleep 3;
    closeDialog 0;
    sleep 0.5;
    diag_log text format ["MHWMTEST after close: dialog %1, wb nil %2", !isNull findDisplay 79420, isNil "mhwm_workbench_wb"];
    mhwm_main_minigames = false;
    ["extract"] call MHWMT_jam;
    private _opened = [] call mhwm_workbench_fnc_open;
    diag_log text format ["MHWMTEST second open: %1, blocked %2, busy %3, weapon %4 muzzle %5", _opened, [player] call mhwm_malfunctions_fnc_isBlocked, player getVariable ["mhwm_malfunctions_busy", false], currentWeapon player, currentMuzzle player];
    sleep 3;
    diag_log text "MHWMTEST SHOT paper_buttons";
    sleep 3;
    closeDialog 0;
    ["AI: rifleman who jams (watch him clear)", MHWMT_entries select (count MHWMT_entries - 1) select 1] params ["", "_ai"];
    call _ai;
    sleep 25;
    disableUserInput false;
    diag_log text "MHWMTEST DONE";
};
