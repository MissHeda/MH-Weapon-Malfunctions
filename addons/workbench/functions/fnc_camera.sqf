#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the scene's camera where its turn (az, compass degrees), pitch and distance say, looking at the target. Kept for the
 * projection (fnc_project): camPos (ASL) and the camera's forward, right and up.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];
private _camera = _scene getOrDefault ["camera", objNull];

if (isNull _camera) exitWith {};

private _target = _scene get "target";
private _az = _scene get "az";
private _pitch = ((_scene get "pitch") max -75) min 75;
private _dist = ((_scene get "dist") max (_scene get "near")) min (_scene get "far");

_scene set ["pitch", _pitch];
_scene set ["dist", _dist];

private _pos = _target vectorAdd ([cos _pitch * sin _az, cos _pitch * cos _az, sin _pitch] vectorMultiply _dist);

_camera camSetPos (ASLToAGL _pos);
_camera camSetTarget (ASLToAGL _target);
_camera camCommit 0;

private _fwd = vectorNormalized (_target vectorDiff _pos);
private _right = vectorNormalized (_fwd vectorCrossProduct [0, 0, 1]);

_scene set ["camPos", _pos];
_scene set ["camFwd", _fwd];
_scene set ["camRight", _right];
_scene set ["camUp", _right vectorCrossProduct _fwd];

// The lights stand with the camera: key from above left, fill from the right, rim from behind.
private _lights = _scene getOrDefault ["lights", []];

if (count _lights == 3) then {
    private _up = [0, 0, 1];

    (_lights select 0) setPosASL (_pos vectorAdd (_right vectorMultiply (-0.6 * _dist)) vectorAdd (_up vectorMultiply (0.6 * _dist)));
    (_lights select 1) setPosASL (_pos vectorAdd (_right vectorMultiply (0.8 * _dist)));
    (_lights select 2) setPosASL (_target vectorAdd (_fwd vectorMultiply (0.9 * _dist)) vectorAdd (_up vectorMultiply (0.5 * _dist)));
};
