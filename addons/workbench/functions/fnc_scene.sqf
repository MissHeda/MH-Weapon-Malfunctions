#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The workbench's 3D scene, far off any map: a dark sphere, the weapon's own model as a simple object (so its bolt can be
 * animated and its magazine shown apart from it), the magazine's model, three lights (key, fill, rim) and a camera that
 * films into SCENE_TARGET. Where the bolt, the magazine, the ejection port and the muzzle sit is read from the model once it
 * has loaded (fnc_points, asked every frame until then).
 *
 * GVAR(wb) get "scene":
 *   camera, objects (everything made), weapon (the model), mag (the magazine's model or objNull), case (a spent case for a
 *   stovepipe or objNull), base (ASL of the weapon's origin), target (what the camera looks at), az, pitch, dist, near, far,
 *   pip (the player's own PiP view distance), points (fnc_points, once known)
 *
 * Arguments:
 * 0: "start" or "stop" <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_mode", "", [""]]];

if (isNil QGVAR(wb)) exitWith {};

if (_mode == "stop") exitWith {
    private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];
    private _camera = _scene getOrDefault ["camera", objNull];

    if (!isNull _camera) then {
        _camera cameraEffect ["Terminate", "Back", SCENE_TARGET];
        camDestroy _camera;
    };

    {deleteVehicle _x} forEach (_scene getOrDefault ["objects", []]);

    if ("pip" in _scene) then {
        setPiPViewDistance (_scene get "pip");
    };

    GVAR(wb) set ["scene", createHashMap];
};

if (_mode != "start") exitWith {};

private _unit = GVAR(wb) get "unit";
private _weapon = GVAR(wb) get "weapon";
private _config = configFile >> "CfgWeapons" >> _weapon;
private _scene = createHashMap;
private _objects = [];

GVAR(wb) set ["scene", _scene];
_scene set ["objects", _objects];
_scene set ["pip", getPiPViewDistance];
setPiPViewDistance SCENE_PIP_DISTANCE;

private _ground = SCENE_PLACE + [((getTerrainHeightASL SCENE_PLACE) max 0) + 300];

// The sphere round it all: dark, so only the lights show the weapon.
private _sphere = "Sphere_3DEN" createVehicleLocal [0, 0, 0];
_sphere setPosASL _ground;
{_sphere setObjectTexture [_x, SCENE_SPHERE_COLOR]} forEach [0, 1];
_objects pushBack _sphere;

private _base = _ground vectorAdd [0, 0, 100];
_scene set ["base", _base];

// The weapon's own model, upright, its origin at the base.
private _model = getText (_config >> "model");

if (_model select [0, 1] == "\") then {_model = _model select [1]};
if (_model != "" && {!(".p3d" in toLowerANSI _model)}) then {_model = _model + ".p3d"};

private _object = if (_model isEqualTo "") then {objNull} else {createSimpleObject [_model, _base, true]};

if (!isNull _object) then {
    _object setPosWorld _base;
    _object setVectorDirAndUp [[0, 1, 0], [0, 0, 1]];
    _objects pushBack _object;
};

_scene set ["weapon", _object];

// The magazine in it, as the model a weapon shows it with (modelSpecial), else none: then only the hotspot marks it.
private _magClass = (_unit weaponState _weapon) param [3, ""];

if (_magClass isEqualTo "") then {
    _magClass = ([primaryWeaponMagazine _unit, handgunMagazine _unit] select (_weapon == handgunWeapon _unit)) param [0, ""];
};

private _magModel = getText (configFile >> "CfgMagazines" >> _magClass >> "modelSpecial");

if (_magModel select [0, 1] == "\") then {_magModel = _magModel select [1]};
if (_magModel != "" && {!(".p3d" in toLowerANSI _magModel)}) then {_magModel = _magModel + ".p3d"};

private _mag = if (_magModel isEqualTo "") then {objNull} else {createSimpleObject [_magModel, _base, true]};

if (!isNull _mag) then {
    _mag hideObject true;
    _objects pushBack _mag;
};

_scene set ["mag", _mag];

// A spent case for a stovepipe: the round's own cartridge model.
private _ammo = getText (configFile >> "CfgMagazines" >> _magClass >> "ammo");
private _cartridge = getText (configFile >> "CfgAmmo" >> _ammo >> "cartridge");
private _caseModel = getText (configFile >> "CfgVehicles" >> _cartridge >> "model");

if (_caseModel select [0, 1] == "\") then {_caseModel = _caseModel select [1]};
if (_caseModel != "" && {!(".p3d" in toLowerANSI _caseModel)}) then {_caseModel = _caseModel + ".p3d"};

private _case = if (_caseModel isEqualTo "") then {objNull} else {createSimpleObject [_caseModel, _base, true]};

if (!isNull _case) then {
    _case hideObject true;
    _objects pushBack _case;
};

_scene set ["case", _case];

// The lights, with the camera: key, fill, rim. Without falloff up to 30 m (AIO: with a constant falloff they lit nothing).
private _lights = [[1, [1, 0.96, 0.92]], [0.4, [0.75, 0.8, 0.95]], [0.7, [0.9, 0.92, 1]]] apply {
    _x params ["_share", "_colour"];

    private _light = "#lightpoint" createVehicleLocal [0, 0, 0];
    _light setPosASL _base;
    _light setLightIntensity (SCENE_LIGHT * _share);
    _light setLightAmbient _colour;
    _light setLightColor _colour;
    _light setLightUseFlare false;
    _light setLightDayLight true;
    _light setLightAttenuation SCENE_LIGHT_REACH;
    _objects pushBack _light;
    _light
};

_scene set ["lights", _lights];

// The camera: right side of the weapon first (where the ejection port mostly is), a little from above.
_scene set ["target", _base];
_scene set ["az", 90];
_scene set ["pitch", 12];
_scene set ["dist", 1];
_scene set ["near", 0.25];
_scene set ["far", 3];

private _camera = "camera" camCreate (ASLToAGL (_base vectorAdd [1, 0, 0]));
_camera cameraEffect ["Internal", "Back", SCENE_TARGET];
_camera camSetFov SCENE_FOV;
_camera camSetFocus [-1, -1];
_scene set ["camera", _camera];

call FUNC(camera);
