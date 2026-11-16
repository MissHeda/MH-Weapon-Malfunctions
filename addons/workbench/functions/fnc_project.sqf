#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a point of the scene shows on the screen: through the camera (fnc_camera) onto the picture, which has the screen's
 * shape. The camera's vertical half view is SCENE_TAN, the horizontal one that times the screen's shape.
 *
 * Arguments:
 * 0: Point <ARRAY> (ASL)
 *
 * Return Value:
 * [x, y] on the screen, [] behind the camera <ARRAY>
 *
 * Public: No
 */

params [["_point", [], [[]]]];

private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];

if !("camPos" in _scene) exitWith {[]};

private _d = _point vectorDiff (_scene get "camPos");
private _z = _d vectorDotProduct (_scene get "camFwd");

if (_z < 0.01) exitWith {[]};

private _tanV = SCENE_TAN;
private _tanH = _tanV * SCENE_ASPECT;
private _u = ((_d vectorDotProduct (_scene get "camRight")) / _z) / _tanH;
private _v = ((_d vectorDotProduct (_scene get "camUp")) / _z) / _tanV;

(GVAR(wb) get "picRect") params ["_px", "_py", "_pw", "_ph"];

[_px + _pw * (0.5 + _u / 2), _py + _ph * (0.5 - _v / 2)]
