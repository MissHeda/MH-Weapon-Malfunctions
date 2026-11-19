#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where the parts sit in the weapon's model, read once it has loaded (selectionPosition gives [0, 0, 0] before - asked every
 * frame by fnc_onFrame, at most ~2 s, then the gaps are filled from what is known):
 *   muzzle, breech    memory points of the barrel's ends (config muzzlePos / muzzleEnd)
 *   port              the ejection port: where cases fly from (config cartridgePos)
 *   mag               the magazine's proxy (weapon_slots\magazineslot) or a selection named for the magazine
 *   handle            a selection named bolt, charging handle, slide... else just behind the port
 *   fwd, up, right    the barrel's axis and the model's up; down = towards the magazine
 *   magDir, magUp     how the magazine proxy is turned
 *   boltTravel        how far the bolt comes back: by the weapon's length
 *   boltAnims         model.cfg animations that move the bolt (animationNames), driven 0..1
 *   magSelections     selections of a magazine built into the model, hidden while it is out
 * and the frame: target (the weapon's middle, ASL) and size, for the camera.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Done <BOOL>
 *
 * Public: No
 */

private _scene = GVAR(wb) getOrDefault ["scene", createHashMap];

if ("points" in _scene) exitWith {true};

private _object = _scene getOrDefault ["weapon", objNull];
private _weapon = GVAR(wb) get "weapon";
private _config = configFile >> "CfgWeapons" >> _weapon;
private _tries = (_scene getOrDefault ["pointTries", 0]) + 1;

_scene set ["pointTries", _tries];

private _fnc_memory = {
    params ["_name"];

    if (isNull _object || {_name isEqualTo ""}) exitWith {[]};

    private _at = _object selectionPosition [_name, "Memory"];

    [_at, []] select (_at isEqualTo [0, 0, 0])
};

private _muzzleName = getText (_config >> "muzzlePos");
private _breechName = getText (_config >> "muzzleEnd");
private _portName = getText (_config >> "cartridgePos");

if (_muzzleName isEqualTo "") then {_muzzleName = "usti hlavne"};
if (_breechName isEqualTo "") then {_breechName = "konec hlavne"};
if (_portName isEqualTo "") then {_portName = "nabojnicestart"};

private _muzzle = [_muzzleName] call _fnc_memory;
private _breech = [_breechName] call _fnc_memory;
private _port = [_portName] call _fnc_memory;

// Not loaded yet: again next frame, a while.
if ((_muzzle isEqualTo [] || {_port isEqualTo []}) && {_tries < 120} && {!isNull _object}) exitWith {false};

private _points = createHashMap;

// The barrel's axis; without both ends the model's own forward.
private _fwd = [0, 1, 0];

if (_muzzle isNotEqualTo [] && {_breech isNotEqualTo []} && {_muzzle distance _breech > 0.05}) then {
    _fwd = vectorNormalized (_muzzle vectorDiff _breech);
};

private _up = [0, 0, 1];
private _right = vectorNormalized (_fwd vectorCrossProduct _up);
_up = vectorNormalized (_right vectorCrossProduct _fwd);

private _names = if (isNull _object) then {[]} else {(selectionNames _object) apply {toLowerANSI _x}};

// The muzzle flash is part of the model: hidden (the first test showed it burning in front of the barrel).
{
    _object hideSelection [_x, true];
} forEach (_names select {!("proxy:" in _x) && {"zasleh" in _x || {"flash" in _x}}});

// The magazine: its proxy, else a selection of its own.
private _magProxy = _names param [_names findIf {"proxy:" in _x && {"magazine" in _x}}, ""];
private _mag = [];
private _magDir = _fwd;
private _magUp = _up;

if (_magProxy isNotEqualTo "") then {
    {
        private _at = _object selectionPosition [_magProxy, _x];

        if (_at isNotEqualTo [0, 0, 0]) exitWith {
            _mag = _at;
            // Only now, with the LOD loaded: selectionVectorDirAndUp on an unloaded LOD crashes the game (AIO 0.7.10).
            (_object selectionVectorDirAndUp [_magProxy, _x]) params [["_d", _fwd], ["_u", _up]];
            _magDir = _d;
            _magUp = _u;
        };
    } forEach [0, 1];
};

private _magSelections = _names select {!("proxy:" in _x) && {"magazine" in _x || {_x in ["mag", "zasobnik"]}}};

if (_mag isEqualTo [] && {_magSelections isNotEqualTo []}) then {
    private _at = _object selectionPosition [_magSelections select 0, 0];

    if (_at isNotEqualTo [0, 0, 0]) then {_mag = _at};
};

// The slots' stand-in models: a simple object draws them as orange placeholders (Mia: RHS's PKP showed an orange
// magazine and plate) - the real magazine is our own object (fnc_scene). Hidden only after the magazine is found: a
// hidden proxy has no position, and its mark fell back into the trigger guard (Mia, P07).
{
    _object hideSelection [_x, true];
} forEach (_names select {"proxy:" in _x && {"weapon_slots" in _x || {"slot" in _x} || {"magazine" in _x}}});

// No port: a little behind the middle of the barrel's breech end.
if (_port isEqualTo []) then {
    _port = if (_breech isNotEqualTo []) then {_breech vectorAdd (_fwd vectorMultiply -0.05)} else {[0, 0, 0]};
};

// No magazine proxy or selection (the P07): low in the grip, under the ejection port and a little behind it - the
// model's lowest point is the magazine's base there. Before, 8 cm under the port put the mark in the trigger guard (Mia).
if (_mag isEqualTo []) then {
    private _low = if (isNull _object) then {(_port select 2) - 0.08} else {((0 boundingBoxReal _object) select 0) select 2};
    _mag = _port vectorAdd (_fwd vectorMultiply -0.015);
    _mag set [2, _low + 0.025];
};

private _down = _mag vectorDiff _port;
_down = _down vectorDiff (_fwd vectorMultiply (_down vectorDotProduct _fwd));
_down = if (vectorMagnitude _down < 0.01) then {_up vectorMultiply -1} else {vectorNormalized _down};

// The bolt: a selection named for it, else behind the port.
private _handleName = _names param [_names findIf {
    private _name = _x;
    !("proxy:" in _name) && {["charging", "handle", "bolt", "slide", "cocking", "zaver", "zavor", "nabijeni"] findIf {_x in _name} >= 0}
}, ""];

private _handle = [];

if (_handleName isNotEqualTo "") then {
    private _at = _object selectionPosition [_handleName, 0];

    if (_at isNotEqualTo [0, 0, 0]) then {_handle = _at};
};

if (_handle isEqualTo []) then {
    // A rifle: at the ejection port, where the bolt shows when it moves (the MX's handle sits there; 6 cm behind it was on
    // bare receiver). A handgun: the slide's rear serrations, clear of the port's own mark.
    _handle = if (getNumber (_config >> "type") == 2) then {
        _port vectorAdd (_fwd vectorMultiply -0.05) vectorAdd (_up vectorMultiply 0.01)
    } else {
        _port vectorAdd (_up vectorMultiply 0.01)
    };
};

// The weapon's length gives the bolt's travel: a pistol's slide 3-4 cm, a rifle's bolt 8-10 cm.
private _length = if (_muzzle isNotEqualTo [] && {_breech isNotEqualTo []}) then {_muzzle distance _breech} else {0.5};

_points set ["boltTravel", ((_length * 0.18) max 0.03) min 0.11];

// The animations that move the bolt.
private _anims = if (isNull _object) then {[]} else {animationNames _object};

_points set ["boltAnims", _anims select {
    private _name = toLowerANSI _x;
    !("mag" in _name) && {["bolt", "charging", "handle", "slide", "cocking", "zaver", "carrier"] findIf {_x in _name} >= 0}
}];

_points set ["magSelections", _magSelections];
_points set ["muzzle", [_muzzle, _port vectorAdd (_fwd vectorMultiply 0.4)] select (_muzzle isEqualTo [])];
_points set ["port", _port];
_points set ["mag", _mag];
_points set ["magDir", _magDir];
_points set ["magUp", _magUp];
_points set ["handle", _handle];
_points set ["fwd", _fwd];
_points set ["up", _up];
_points set ["right", _right];
_points set ["down", _down];

// The frame: the visual box, which proxies blow up - so held to what the points say the weapon is.
private _box = if (isNull _object) then {[[-0.4, -0.4, -0.15], [0.4, 0.4, 0.15], 0.5]} else {0 boundingBoxReal _object};

_box params ["_min", "_max"];

private _centre = (_min vectorAdd _max) vectorMultiply 0.5;
private _size = selectMax ((_max vectorDiff _min) apply {abs _x});
private _known = [_points get "muzzle", _port, _mag, _handle];
private _knownCentre = [0, 0, 0];

{_knownCentre = _knownCentre vectorAdd _x} forEach _known;
_knownCentre = _knownCentre vectorMultiply (1 / count _known);

if (_centre distance _knownCentre > 0.4) then {_centre = _knownCentre};

// The barrel is about half to two thirds of a weapon; the box only where no barrel was found.
if (_muzzle isNotEqualTo [] && {_breech isNotEqualTo []}) then {
    _size = _length * 1.7;
};

_size = (_size max 0.25) min 1.6;

_points set ["centre", _centre];
_points set ["size", _size];
_scene set ["points", _points];

// The camera frames the weapon now.
if (!isNull _object) then {
    _scene set ["target", _object modelToWorldVisualWorld _centre];
    // Where moving with the middle button starts from, and where "Reset view" puts the weapon back.
    _scene set ["origin", _object modelToWorldVisualWorld _centre];
};

// Far enough that the whole weapon fits (1.35 cut the MX's stock and barrel off in the first test).
private _dist = _size * 2.3;

_scene set ["dist", _dist];
// From the weapon's right side, where the ejection port mostly is (compass bearing of "right").
_scene set ["az", (_right select 0) atan2 (_right select 1)];
_scene set ["near", _dist * 0.3];
_scene set ["far", _dist * 2.5];
_scene set ["home", [_scene get "az", _scene get "pitch", _dist]];

call FUNC(camera);
call FUNC(sync);

true
