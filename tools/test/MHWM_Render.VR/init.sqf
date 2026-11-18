// Renders for the field manual (tools/manual/make_manual.py): the workbench's 3D view alone, no interface, the weapon in each
// state a manual panel shows. "MHWMTEST VIEW x y w h" gives the view's place on the screen (UI units), then a SHOT per state.
if (!hasInterface) exitWith {};

MHWMT_log = {diag_log text format ["MHWMTEST %1", _this]};
MHWMT_shot = {diag_log text format ["MHWMTEST SHOT %1", _this]; sleep 2.5};

// Only the 3D view: every other control hidden, the drag's marks too.
MHWMT_bare = {
    // The frame loop would show the marks again every frame.
    [mhwm_workbench_wb getOrDefault ["pfh", -1]] call CBA_fnc_removePerFrameHandler;
    private _display = findDisplay 79420;
    private _keep = [];
    {
        if (ctrlType _x == 15) then {_keep pushBack _x; _keep append (allControls _x)};
    } forEach allControls _display;
    {
        if !(_x in _keep) then {_x ctrlShow false};
    } forEach allControls _display;
};

// A state, a drag held, a camera: then a picture.
MHWMT_pose = {
    params ["_name", "_state", ["_kind", ""], ["_progress", 0], ["_zoom", 1], ["_focus", ""], ["_az", 0], ["_pitch", 0]];

    private _w = currentWeapon player;
    private _s = [player, _w] call mhwm_malfunctions_fnc_state;
    {_s set [_x select 0, _x select 1]} forEach _state;
    [player, _w, _s] call mhwm_malfunctions_fnc_state;

    mhwm_workbench_wb set ["drag", createHashMapFromArray [["kind", _kind], ["progress", _progress]]];

    private _scene = mhwm_workbench_wb get "scene";
    private _points = _scene get "points";
    private _origin = _scene get "origin";
    _scene set ["target", if (_focus isEqualTo "") then {+_origin} else {(_scene get "weapon") modelToWorldVisualWorld (_points get _focus)}];
    _scene set ["dist", ((_points get "size") * 2.3) * _zoom];
    _scene set ["az", ((_points get "right") select 0) atan2 ((_points get "right") select 1) + _az];
    _scene set ["pitch", 8 + _pitch];
    call mhwm_workbench_fnc_camera;
    call mhwm_workbench_fnc_sync;
    sleep 0.6;
    call MHWMT_bare;
    private _spots = (call mhwm_workbench_fnc_hotspots) apply {[_x select 0, [_x select 1] call mhwm_workbench_fnc_project]};
    format ["SPOTS %1 %2", _name, _spots] call MHWMT_log;
    _name call MHWMT_shot;
};

[] spawn {
    waitUntil {!isNull player && {time > 1}};
    disableUserInput true;

    player setPosATL [4096, 4096, 0];
    player allowDamage false;
    player setUnitLoadout [
        ["arifle_MX_F", "", "", "", ["30Rnd_65x39_caseless_mag", 30], [], ""],
        [],
        ["hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", 16], [], ""],
        ["U_B_CombatUniform_mcam", []], ["V_PlateCarrier1_rgr", []], [], "H_HelmetB", "", [],
        ["ItemMap", "", "", "", "", ""]
    ];
    mhwm_main_notify = false;
    sleep 2;

    private _w = primaryWeapon player;
    player selectWeapon _w;
    sleep 1;
    [player, _w, "feed"] call mhwm_malfunctions_fnc_jam;
    [] call mhwm_workbench_fnc_open;
    sleep 3;
    (mhwm_workbench_wb get "viewRect") params ["_x", "_y", "_ww", "_hh"];
    format ["VIEW %1 %2 %3 %4 %5 %6 %7 %8", _x, _y, _ww, _hh, safeZoneX, safeZoneY, safeZoneW, safeZoneH] call MHWMT_log;

    private _home = [["bolt", "closed"], ["chamber", "empty"], ["port", "clear"], ["mag", "in"]];

    ["r_rifle", _home] call MHWMT_pose;
    ["r_tap", _home + [["mag", "loose"]], "", 0, 0.55, "mag", 0, -4] call MHWMT_pose;
    ["r_rack", _home, "handle", 1, 0.55, "handle"] call MHWMT_pose;
    ["r_locked", _home + [["bolt", "locked"]], "", 0, 0.5, "port", -12, 6] call MHWMT_pose;
    ["r_magdrop", _home + [["bolt", "locked"]], "magPress", 0.75, 0.6, "mag", 0, -4] call MHWMT_pose;
    ["r_magout", _home + [["bolt", "locked"], ["mag", "out"]], "", 0, 0.65, "mag", 0, -4] call MHWMT_pose;
    ["r_chamber", _home + [["bolt", "locked"], ["chamber", "double"], ["mag", "out"]], "", 0, 0.32, "port", -20, 10] call MHWMT_pose;

    closeDialog 0;
    sleep 1;

    player selectWeapon handgunWeapon player;
    sleep 2;
    [player, handgunWeapon player, true] call mhwm_malfunctions_fnc_clear;
    [player, handgunWeapon player, "stovepipe"] call mhwm_malfunctions_fnc_jam;
    [] call mhwm_workbench_fnc_open;
    sleep 3;
    ["r_sweep", [["bolt", "short"], ["chamber", "empty"], ["port", "stovepipe"], ["mag", "in"]], "port", 0.35, 0.75, "port", -15, 12] call MHWMT_pose;
    ["r_pistol", [["bolt", "closed"], ["chamber", "round"], ["port", "clear"], ["mag", "in"]]] call MHWMT_pose;

    closeDialog 0;
    disableUserInput false;
    "DONE" call MHWMT_log;
};
