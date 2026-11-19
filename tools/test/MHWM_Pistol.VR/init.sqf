// Unattended check of a handgun's marks (tools/test/run_auto.ps1 -Mission MHWM_Pistol): P07 with each malfunction that
// shows the magazine, its points logged, a picture each.
if (!hasInterface) exitWith {};

MHWMT_log = {diag_log text format ["MHWMTEST %1", _this]};

[] spawn {
    waitUntil {!isNull player && {time > 1}};
    disableUserInput true;
    player setPosATL [4096, 4096, 0];
    player allowDamage false;
    player setUnitLoadout [[], [], ["hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", 16], [], ""], ["U_B_CombatUniform_mcam", []], [], [], "", "", [], ["", "", "", "", "", ""]];
    sleep 1;
    player selectWeapon handgunWeapon player;
    sleep 1;
    profileNamespace setVariable ["mhwm_workbench_manualSeen", true];

    {
        [player, currentWeapon player, true] call mhwm_malfunctions_fnc_clear;
        [player, currentWeapon player, _x] call mhwm_malfunctions_fnc_jam;
        [] call mhwm_workbench_fnc_open;
        sleep 4;
        private _points = (mhwm_workbench_wb get "scene") getOrDefault ["points", createHashMap];
        format ["%1 port %2 mag %3 handle %4 muzzle %5 size %6", _x, _points get "port", _points get "mag", _points get "handle", _points get "muzzle", _points get "size"] call MHWMT_log;
        format ["%1 spots %2", _x, mhwm_workbench_wb getOrDefault ["spotScreen", []]] call MHWMT_log;
        diag_log text format ["MHWMTEST SHOT pistol_%1", _x];
        sleep 3;
        closeDialog 0;
        sleep 1;
    } forEach ["feed", "dud"];

    disableUserInput false;
    "DONE" call MHWMT_log;
};
