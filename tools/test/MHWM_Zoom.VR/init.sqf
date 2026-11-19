// Unattended check of the 3D view's marks against the picture at every zoom (tools/test/run_auto.ps1 -Mission MHWM_Zoom):
// a stovepipe on the MX, the bench open with and without the notebook, three distances each. Logs camera, picture rect and
// the marks' screen places; "MHWMTEST SHOT <name>" asks the runner for a picture.
if (!hasInterface) exitWith {};

MHWMT_log = {diag_log text format ["MHWMTEST %1", _this]};
MHWMT_shot = {diag_log text format ["MHWMTEST SHOT %1", _this]; sleep 3};

MHWMT_measure = {
    params ["_tag"];

    private _scene = mhwm_workbench_wb getOrDefault ["scene", createHashMap];
    format ["%1 dist %2 home %3 camPos %4 target %5 picRect %6 viewRect %7 res %8", _tag, _scene getOrDefault ["dist", -1],
        _scene getOrDefault ["home", []], _scene getOrDefault ["camPos", []], _scene getOrDefault ["target", []],
        mhwm_workbench_wb get "picRect", mhwm_workbench_wb get "viewRect", getResolution] call MHWMT_log;
    private _camera = _scene getOrDefault ["camera", objNull];
    format ["%1 camera real ASL %2 dir %3", _tag, getPosASL _camera, vectorDir _camera] call MHWMT_log;
    format ["%1 spots %2", _tag, mhwm_workbench_wb getOrDefault ["spotScreen", []]] call MHWMT_log;
    _tag call MHWMT_shot;
};

MHWMT_zooms = {
    params ["_tag"];

    private _scene = mhwm_workbench_wb get "scene";
    private _home = (_scene get "home") select 2;

    {
        _scene set ["dist", _home * _x];
        call mhwm_workbench_fnc_camera;
        sleep 1.5;
        [format ["%1_%2", _tag, _forEachIndex]] call MHWMT_measure;
    } forEach [1, 1.8, 2.5];
};

[] spawn {
    waitUntil {!isNull player && {time > 1}};
    disableUserInput true;

    player setPosATL [4096, 4096, 0];
    player allowDamage false;
    player setUnitLoadout [
        ["arifle_MX_F", "", "", "", ["30Rnd_65x39_caseless_mag", 30], [], ""],
        [], [], ["U_B_CombatUniform_mcam", []], [], [], "", "", [], ["", "", "", "", "", ""]
    ];
    sleep 2;

    // Run in a real player's profile too: what it holds is put back at the end.
    private _keep = ["mhwm_workbench_notesHidden", "mhwm_workbench_manualSeen"] apply {[_x, profileNamespace getVariable _x]};
    format ["profile %1 fovTop %2 fovLeft %3 uiScale %4", profileName, getResolution select 6, getResolution select 7, getResolution select 5] call MHWMT_log;

    {
        _x params ["_tag", "_hidden"];

        profileNamespace setVariable ["mhwm_workbench_notesHidden", _hidden];
        profileNamespace setVariable ["mhwm_workbench_manualSeen", true];
        [player, currentWeapon player, true] call mhwm_malfunctions_fnc_clear;
        [player, currentWeapon player, "stovepipe"] call mhwm_malfunctions_fnc_jam;
        [] call mhwm_workbench_fnc_open;
        sleep 4;
        [_tag] call MHWMT_zooms;

        // As a player does it: the wheel out all the way, then the weapon moved up with the middle button.
        private _scene = mhwm_workbench_wb get "scene";
        _scene set ["dist", (_scene get "home") select 2];
        call mhwm_workbench_fnc_camera;
        for "_i" from 1 to 12 do {["wheel", [displayNull, -1]] call mhwm_workbench_fnc_onMouse; sleep 0.05};
        sleep 1;
        [format ["%1_wheel", _tag]] call MHWMT_measure;
        (mhwm_workbench_wb get "viewRect") params ["_vx", "_vy", "_vw", "_vh"];
        mhwm_workbench_testMouse = [_vx + _vw / 2, _vy + _vh / 2];
        mhwm_workbench_wb set ["drag", createHashMapFromArray [["kind", "pan"], ["last", mhwm_workbench_testMouse], ["button", 2]]];
        for "_i" from 1 to 10 do {
            mhwm_workbench_testMouse = [_vx + _vw / 2 + 0.01 * _i, _vy + _vh / 2 - 0.02 * _i];
            sleep 0.05;
        };
        mhwm_workbench_wb set ["drag", createHashMap];
        sleep 1;
        [format ["%1_pan", _tag]] call MHWMT_measure;
        closeDialog 0;
        sleep 1;
    } forEach [["notes", false], ["wide", true]];

    {profileNamespace setVariable _x} forEach _keep;
    saveProfileNamespace;
    disableUserInput false;
    "DONE" call MHWMT_log;
};
