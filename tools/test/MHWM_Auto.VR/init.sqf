// Unattended test of MH Weapon Malfunctions (tools/test/run_auto.ps1): every malfunction is made and cleared the way a
// player would - by the fired event, the quick keys, ACE Overheating, and the workbench's minigames with a stand-in mouse
// (mhwm_workbench_testMouse). Results go to the RPT as "MHWMTEST" lines, "MHWMTEST SHOT <name>" asks the runner for a
// picture of the window.
if (!hasInterface) exitWith {};

MHWMT_log = {diag_log text format ["MHWMTEST %1", _this]};
MHWMT_shot = {diag_log text format ["MHWMTEST SHOT %1", _this]; sleep 3};
MHWMT_state = {
    private _s = [player, currentWeapon player] call mhwm_malfunctions_fnc_state;
    if (count _s == 0) exitWith {"CLEARED"};
    format ["bolt=%1 chamber=%2 port=%3 mag=%4", _s get "bolt", _s get "chamber", _s get "port", _s get "mag"]
};
MHWMT_spot = {
    private _spots = mhwm_workbench_wb getOrDefault ["spotScreen", []];
    private _i = _spots findIf {(_x select 0) == _this};
    if (_i < 0) exitWith {[]};
    (_spots select _i) select 1
};
// Press on a part, move along its line by a fraction (plus a sideways offset), then let go - or right click at the end.
MHWMT_drag = {
    params ["_id", "_fraction", ["_rightClick", false], ["_offset", [0, 0]]];

    private _p = _id call MHWMT_spot;
    if (_p isEqualTo []) exitWith {format ["  no spot %1 (spots %2)", _id, mhwm_workbench_wb getOrDefault ["spotScreen", []]] call MHWMT_log};

    mhwm_workbench_testMouse = _p;
    sleep 0.1;
    ["down", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
    sleep 0.1;

    private _vec = (mhwm_workbench_wb get "drag") getOrDefault ["vec", [0, 0]];

    for "_i" from 1 to 10 do {
        mhwm_workbench_testMouse = [
            (_p select 0) + (_vec select 0) * _fraction * _i / 10 + (_offset select 0) * _i / 10,
            (_p select 1) + (_vec select 1) * _fraction * _i / 10 + (_offset select 1) * _i / 10
        ];
        sleep 0.05;
    };

    sleep 0.2;
    format ["  %1 held: progress %2 dev %3", _id, (mhwm_workbench_wb get "drag") getOrDefault ["progress", -1], (mhwm_workbench_wb get "drag") getOrDefault ["maxDev", -1]] call MHWMT_log;

    if (_rightClick) then {
        ["down", [displayNull, 1]] call mhwm_workbench_fnc_onMouse;
        sleep 0.1;
        ["up", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
    } else {
        ["up", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
    };

    sleep 0.4;
    format ["  after %1: %2 | last: %3", _id, call MHWMT_state, mhwm_workbench_wb getOrDefault ["result", "-"]] call MHWMT_log;
};
MHWMT_click = {
    private _p = _this call MHWMT_spot;
    if (_p isEqualTo []) exitWith {format ["  no spot %1", _this] call MHWMT_log};
    mhwm_workbench_testMouse = _p;
    sleep 0.1;
    ["down", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
    sleep 0.05;
    ["up", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
    sleep 0.4;
    format ["  after click %1: %2 | last: %3", _this, call MHWMT_state, mhwm_workbench_wb getOrDefault ["result", "-"]] call MHWMT_log;
};
MHWMT_wiggle = {
    private _p = "chamber" call MHWMT_spot;
    if (_p isEqualTo []) exitWith {"  no spot chamber" call MHWMT_log};
    mhwm_workbench_testMouse = _p;
    sleep 0.1;
    ["down", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;

    for "_i" from 1 to 14 do {
        if (isNil "mhwm_workbench_wb" || {((mhwm_workbench_wb get "drag") getOrDefault ["kind", ""]) != "chamber"}) exitWith {};
        mhwm_workbench_testMouse = [(_p select 0) + ([-1, 1] select (_i % 2)) * 0.03 * safeZoneW, _p select 1];
        sleep 0.12;
    };

    ["up", [displayNull, 0]] call mhwm_workbench_fnc_onMouse;
    sleep 0.4;
    format ["  after wiggle: %1 | last: %2", call MHWMT_state, mhwm_workbench_wb getOrDefault ["result", "-"]] call MHWMT_log;
};
MHWMT_open = {
    params ["_cause"];

    [player, currentWeapon player, true] call mhwm_malfunctions_fnc_clear;
    [player, currentWeapon player, _cause] call mhwm_malfunctions_fnc_jam;
    format ["== %1 on %2: %3", _cause, currentWeapon player, call MHWMT_state] call MHWMT_log;
    private _opened = [] call mhwm_workbench_fnc_open;
    sleep 3;
    private _scene = mhwm_workbench_wb getOrDefault ["scene", createHashMap];
    private _points = _scene getOrDefault ["points", createHashMap];
    format ["  open %1 points %2 tries %3 anims %4 magSel %5 mag %6 case %7", _opened, count _points, _scene getOrDefault ["pointTries", -1],
        _points getOrDefault ["boltAnims", []], _points getOrDefault ["magSelections", []],
        !isNull (_scene getOrDefault ["mag", objNull]), !isNull (_scene getOrDefault ["case", objNull])] call MHWMT_log;
    format ["  spots %1", mhwm_workbench_wb getOrDefault ["spotScreen", []]] call MHWMT_log;
};
MHWMT_close = {
    sleep 2;
    format ["  dialog open after: %1", !isNull findDisplay 79420] call MHWMT_log;
    if (!isNull findDisplay 79420) then {closeDialog 0; sleep 0.5};
};

[] spawn {
    waitUntil {!isNull player && {time > 1}};
    disableUserInput true;

    player setPosATL [4096, 4096, 0];
    player setDir 0;
    player allowDamage false;
    player setUnitLoadout [
        ["arifle_MX_F", "", "", "optic_Aco", ["30Rnd_65x39_caseless_mag", 30], [], ""],
        [],
        ["hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", 16], [], ""],
        ["U_B_CombatUniform_mcam", [["16Rnd_9x21_Mag", 2, 16]]],
        ["V_PlateCarrier1_rgr", [["30Rnd_65x39_caseless_mag", 6, 30]]],
        [], "H_HelmetB", "", [],
        ["ItemMap", "", "ItemRadio", "ItemCompass", "ItemWatch", ""]
    ];
    sleep 2;

    format ["start ace=%1 aceOverheating=%2 pip=%3 res=%4", isClass (configFile >> "CfgPatches" >> "ace_main"), isClass (configFile >> "CfgPatches" >> "ace_overheating"), isPiPEnabled, getResolution] call MHWMT_log;

    mhwm_main_fumble = 0;
    private _w = primaryWeapon player;
    player selectWeapon _w;
    sleep 1;

    // ----- 1. A shot jams it (rate 1000 per 1000) -----
    mhwm_main_rate = 1000;
    private _ammo = player ammo _w;
    player forceWeaponFire [_w, "Single"];
    sleep 0.5;
    mhwm_main_rate = 0;
    format ["1 fired: %1 | ammo %2 -> %3 | blocked %4", call MHWMT_state, _ammo, player ammo _w, [player] call mhwm_malfunctions_fnc_isBlocked] call MHWMT_log;
    _ammo = player ammo _w;
    player forceWeaponFire [_w, "Single"];
    sleep 0.5;
    format ["1 fired again while jammed: ammo %1 -> %2", _ammo, player ammo _w] call MHWMT_log;

    // ----- 2. Quick keys: tap-rack on a failure to feed -----
    [player, _w, true] call mhwm_malfunctions_fnc_clear;
    [player, _w, "feed"] call mhwm_malfunctions_fnc_jam;
    format ["2 feed: %1", call MHWMT_state] call MHWMT_log;
    ["tapRack"] call mhwm_malfunctions_fnc_quickAction;
    sleep 3;
    format ["2 after tapRack: %1", call MHWMT_state] call MHWMT_log;

    // ----- 3. ACE Overheating -----
    if (isClass (configFile >> "CfgPatches" >> "ace_overheating")) then {
        [player, _w, true] call mhwm_malfunctions_fnc_clear;
        mhwm_main_aceMode = 1;
        private _before = player ammo _w;
        [player, _w, "eject"] call ace_overheating_fnc_jamWeapon;
        sleep 0.5;
        format ["3 ACE decides, ACE eject: %1 | ACE list %2 | ammo %3 -> %4", call MHWMT_state, player getVariable ["ace_overheating_jammedWeapons", []], _before, player ammo _w] call MHWMT_log;
        [player, _w, true] call mhwm_malfunctions_fnc_clear;
        mhwm_main_aceMode = 0;
        [player, _w, "feed"] call ace_overheating_fnc_jamWeapon;
        sleep 0.5;
        format ["3 mod decides, ACE feed: %1 | ACE list %2", call MHWMT_state, player getVariable ["ace_overheating_jammedWeapons", []]] call MHWMT_log;
    };

    // ----- 4. Workbench: double feed, the full drill -----
    ["double"] call MHWMT_open;
    "wb_double_open" call MHWMT_shot;
    ["handle", 1, true] call MHWMT_drag;
    "wb_double_locked" call MHWMT_shot;
    ["mag", 1] call MHWMT_drag;
    "wb_double_magout" call MHWMT_shot;
    call MHWMT_wiggle;
    ["mag", 1] call MHWMT_drag;
    "handle" call MHWMT_click;
    "wb_double_done" call MHWMT_shot;
    call MHWMT_close;

    // ----- 5. Extraction failure, with a crooked insert first -----
    ["extract"] call MHWMT_open;
    ["handle", 0.5] call MHWMT_drag;
    ["handle", 1] call MHWMT_drag;
    ["handle", 1, true] call MHWMT_drag;
    call MHWMT_wiggle;
    ["mag", 1] call MHWMT_drag;
    call MHWMT_wiggle;
    ["mag", 1, false, [0.08 * safeZoneW, 0]] call MHWMT_drag;
    "wb_extract_loose" call MHWMT_shot;
    "handle" call MHWMT_click;
    ["handle", 1] call MHWMT_drag;
    call MHWMT_close;

    // ----- 6. Feed failure with a loose magazine: the tap's beat -----
    ["feed"] call MHWMT_open;
    private _state = [player, _w] call mhwm_malfunctions_fnc_state;
    _state set ["mag", "loose"];
    [player, _w, _state] call mhwm_malfunctions_fnc_state;
    "wb_feed_loose" call MHWMT_shot;
    waitUntil {(((diag_tickTime - (mhwm_workbench_wb get "openTime")) mod 1.1) / 1.1) > 0.5 && {(((diag_tickTime - (mhwm_workbench_wb get "openTime")) mod 1.1) / 1.1) < 0.6}};
    "mag" call MHWMT_click;
    waitUntil {(((diag_tickTime - (mhwm_workbench_wb get "openTime")) mod 1.1) / 1.1) > 0.9};
    "mag" call MHWMT_click;
    ["handle", 1] call MHWMT_drag;
    call MHWMT_close;

    // ----- 7. Dud -----
    ["dud"] call MHWMT_open;
    ["handle", 1] call MHWMT_drag;
    call MHWMT_close;

    // ----- 8. Handgun stovepipe: sweep -----
    player selectWeapon handgunWeapon player;
    sleep 2;
    ["stovepipe"] call MHWMT_open;
    "wb_pistol_stovepipe" call MHWMT_shot;
    ["port", 1] call MHWMT_drag;
    call MHWMT_close;

    // ----- 9. Rifle seen from other angles -----
    player selectWeapon _w;
    sleep 2;
    ["stovepipe"] call MHWMT_open;
    "wb_rifle_stovepipe" call MHWMT_shot;
    (mhwm_workbench_wb get "scene") set ["az", ((mhwm_workbench_wb get "scene") get "az") + 40];
    (mhwm_workbench_wb get "scene") set ["pitch", 25];
    call mhwm_workbench_fnc_camera;
    sleep 0.5;
    "wb_rifle_turned" call MHWMT_shot;
    ["handle", 1] call MHWMT_drag;
    call MHWMT_close;

    // ----- 10. Buttons instead of minigames -----
    mhwm_main_minigames = false;
    ["extract"] call MHWMT_open;
    "wb_buttons" call MHWMT_shot;
    {
        [_x] call mhwm_workbench_fnc_act;
        sleep 0.3;
        format ["  button %1: %2 | last: %3", _x, call MHWMT_state, if (isNil "mhwm_workbench_wb") then {"-"} else {mhwm_workbench_wb get "result"}] call MHWMT_log;
    } forEach ["lock", "drop", "clear", "insert", "release"];
    call MHWMT_close;
    mhwm_main_minigames = true;

    disableUserInput false;
    "DONE" call MHWMT_log;
};
