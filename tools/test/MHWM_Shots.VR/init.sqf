// Workshop pictures (tools/test/run_auto.ps1 -Mission MHWM_Shots): stills ("MHWMTEST SHOT <name>") and frame bursts for
// GIFs ("MHWMTEST BURST <name> <frames>") of the 3D view, the notebook, the field manual and the notice in the world.
if (!hasInterface) exitWith {};

MHWMT_log = {diag_log text format ["MHWMTEST %1", _this]};
MHWMT_shot = {diag_log text format ["MHWMTEST SHOT %1", _this]; sleep 2.5};
MHWMT_burst = {params ["_name", "_frames"]; diag_log text format ["MHWMTEST BURST %1 %2", _name, _frames]; sleep 0.8};
MHWMT_spot = {
    private _spots = mhwm_workbench_wb getOrDefault ["spotScreen", []];
    private _i = _spots findIf {(_x select 0) == _this};
    if (_i < 0) exitWith {[]};
    (_spots select _i) select 1
};
MHWMT_bench = {
    params ["_cause", ["_acts", []]];
    if (!isNil "mhwm_workbench_wb") then {closeDialog 0; sleep 0.8};
    [player, currentWeapon player, true] call mhwm_malfunctions_fnc_clear;
    [player, currentWeapon player, _cause] call mhwm_malfunctions_fnc_jam;
    [] call mhwm_workbench_fnc_open;
    sleep 3.5;
    {[_x] call mhwm_workbench_fnc_act; sleep 0.4} forEach _acts;
    mhwm_workbench_wb set ["view", -1];
    call mhwm_workbench_fnc_refresh;
    sleep 1.2;
};
// A slow drag along a part's line: the GIF's motion.
MHWMT_drag = {
    params ["_id", "_fraction", "_seconds"];
    private _p = _id call MHWMT_spot;
    if (_p isEqualTo []) exitWith {format ["no spot %1", _id] call MHWMT_log};
    mhwm_workbench_testMouse = _p;
    sleep 0.3;
    ["down", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
    sleep 0.1;
    private _vec = (mhwm_workbench_wb get "drag") getOrDefault ["vec", [0, 0]];
    private _steps = round (_seconds / 0.05);
    for "_i" from 1 to _steps do {
        mhwm_workbench_testMouse = [(_p select 0) + (_vec select 0) * _fraction * _i / _steps, (_p select 1) + (_vec select 1) * _fraction * _i / _steps];
        sleep 0.05;
    };
    sleep 0.4;
    ["up", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
    mhwm_workbench_testMouse = [-1, -1];
};

[] spawn {
    waitUntil {!isNull player && {time > 1}};
    disableUserInput true;
    player setPosATL [4096, 4096, 0];
    player setDir 0;
    player allowDamage false;
    player setUnitLoadout [
        ["arifle_MX_F", "", "", "optic_Holosight", ["30Rnd_65x39_caseless_mag", 30], [], ""],
        [], ["hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", 16], [], ""],
        ["U_B_CombatUniform_mcam", [["16Rnd_9x21_Mag", 2, 16]]], ["V_PlateCarrier1_rgr", [["30Rnd_65x39_caseless_mag", 4, 30]]],
        [], "H_HelmetB", "", [], ["ItemMap", "", "ItemRadio", "ItemCompass", "ItemWatch", ""]
    ];
    profileNamespace setVariable ["mhwm_workbench_manualSeen", true];
    // The brand's red as the UI accent for the pictures (the test profile's default is orange).
    {profileNamespace setVariable [format ["GUI_BCG_RGB_%1", _x select 0], _x select 1]} forEach [["R", 0.878], ["G", 0.157], ["B", 0.247]];
    profileNamespace setVariable ["mhwm_workbench_notesHidden", false];
    sleep 2;

    // 1. Double feed, halfway: bolt locked, magazine out, the notebook on "remove the double feed".
    ["double", ["lock", "drop"]] call MHWMT_bench;
    "01_double" call MHWMT_shot;

    // 2. GIF: a stuck case wiggled free.
    ["extract", ["lock", "drop"]] call MHWMT_bench;
    ["gif_wiggle", 40] call MHWMT_burst;
    private _p = "chamber" call MHWMT_spot;
    if (_p isNotEqualTo []) then {
        mhwm_workbench_testMouse = _p;
        sleep 0.2;
        ["down", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
        for "_i" from 1 to 16 do {
            if (((mhwm_workbench_wb get "drag") getOrDefault ["kind", ""]) != "chamber") exitWith {};
            mhwm_workbench_testMouse = [(_p select 0) + ([-1, 1] select (_i % 2)) * 0.025 * safeZoneW, _p select 1];
            sleep 0.18;
        };
        ["up", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
        mhwm_workbench_testMouse = [-1, -1];
    };
    sleep 2;

    // 3. GIF: the charging handle racked on a loose magazine, after the tap.
    ["feed", ["tap"]] call MHWMT_bench;
    ["gif_rack", 36] call MHWMT_burst;
    ["handle", 1, 2] call MHWMT_drag;
    sleep 1.5;
    "02_cleared" call MHWMT_shot;

    // 4. The field manual.
    ["stovepipe"] call MHWMT_bench;
    [true] call mhwm_workbench_fnc_manual;
    sleep 1.5;
    "03_manual" call MHWMT_shot;
    [false] call mhwm_workbench_fnc_manual;
    sleep 0.5;

    // 5. Pistol dud: waiting out a hangfire at the muzzle (GIF of the bar).
    closeDialog 0;
    sleep 0.5;
    player selectWeapon handgunWeapon player;
    sleep 1.5;
    ["dud"] call MHWMT_bench;
    "04_pistol" call MHWMT_shot;
    ["gif_wait", 30] call MHWMT_burst;
    private _m = "muzzle" call MHWMT_spot;
    if (_m isNotEqualTo []) then {
        mhwm_workbench_testMouse = _m;
        sleep 0.2;
        ["down", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
        sleep 2.6;
        ["up", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
        mhwm_workbench_testMouse = [-1, -1];
    };
    sleep 1.5;

    // 6. The notice in the world, first person with the rifle.
    closeDialog 0;
    sleep 0.5;
    player selectWeapon primaryWeapon player;
    sleep 2;
    player switchCamera "INTERNAL";
    [player, currentWeapon player, true] call mhwm_malfunctions_fnc_clear;
    [player, currentWeapon player, "feed"] call mhwm_malfunctions_fnc_jam;
    sleep 0.6;
    "05_notice" call MHWMT_shot;

    disableUserInput false;
    "DONE" call MHWMT_log;
};
