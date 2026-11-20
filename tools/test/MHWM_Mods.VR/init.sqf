// Unattended check of mod and DLC weapons in the 3D view (tools/test/run_auto.ps1 -Mission MHWM_Mods -Workshop ...):
// each weapon that is loaded, jammed (double feed: magazine and bolt both marked), its points logged, a picture each.
if (!hasInterface) exitWith {};

MHWMT_log = {diag_log text format ["MHWMTEST %1", _this]};

[] spawn {
    waitUntil {!isNull player && {time > 1}};
    disableUserInput true;
    player setPosATL [4096, 4096, 0];
    player allowDamage false;
    profileNamespace setVariable ["mhwm_workbench_manualSeen", true];

    {
        private _weapon = _x;
        if (!isClass (configFile >> "CfgWeapons" >> _weapon)) then {format ["skip %1", _weapon] call MHWMT_log; continue};
        private _mag = (compatibleMagazines _weapon) param [0, ""];
        player setUnitLoadout [[_weapon, "", "", "", [_mag, 30], [], ""], [], [], ["U_B_CombatUniform_mcam", []], [], [], "", "", [], ["", "", "", "", "", ""]];
        sleep 1;
        player selectWeapon primaryWeapon player;
        sleep 0.5;
        [player, currentWeapon player, true] call mhwm_malfunctions_fnc_clear;
        [player, currentWeapon player, "double"] call mhwm_malfunctions_fnc_jam;
        [] call mhwm_workbench_fnc_open;
        sleep 4;
        private _scene = mhwm_workbench_wb get "scene";
        private _p = _scene getOrDefault ["points", createHashMap];
        private _o = _scene getOrDefault ["weapon", objNull];
        format ["%1 model %2 box %3", _weapon, getText (configFile >> "CfgWeapons" >> _weapon >> "model"), 0 boundingBoxReal _o] call MHWMT_log;
        format ["%1 muzzle %2 port %3 mag %4 handle %5 centre %6 size %7 fwd %8", _weapon, _p get "muzzle", _p get "port", _p get "mag", _p get "handle", _p get "centre", _p get "size", _p get "fwd"] call MHWMT_log;
        format ["%1 magProxy %2 sceneMag %3 hidden %4 proxies %5", _weapon, _p get "magProxy", _scene getOrDefault ["mag", objNull], isObjectHidden (_scene getOrDefault ["mag", objNull]),
            (selectionNames _o) select {"proxy:" in toLowerANSI _x}] call MHWMT_log;
        format ["%1 spots %2", _weapon, mhwm_workbench_wb getOrDefault ["spotScreen", []]] call MHWMT_log;
        diag_log text format ["MHWMTEST SHOT %1", _weapon];
        sleep 3;
        closeDialog 0;
        sleep 1;
    } forEach ["MCC_HK433_11_CTR_BLK_556", "srifle_DMR_03_F", "arifle_MX_F"];

    disableUserInput false;
    "DONE" call MHWMT_log;
};
