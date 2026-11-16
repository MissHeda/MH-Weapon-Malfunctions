#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * One hand movement on a jammed weapon, as it would go on a real one. The weapon's ammo counts the rounds in the magazine
 * and a round in the chamber; a round thrown out is lost (setAmmo - 1). The weapon works again once the bolt is closed on a
 * round, the ejection port is clear and the magazine is in - or it is simply empty.
 *
 *   tap         a loose magazine seats
 *   rack        the bolt all the way back and let go: clears a stovepipe, throws out the round in the chamber, feeds the
 *               next - stuck on a double feed with the magazine in, the extractor slips over a stuck case
 *   short       the bolt only part way back: nothing changes
 *   lock        the bolt back and caught open: the chamber's round falls out, a stovepipe case drops
 *   release     the bolt catch let go: the bolt runs forward and feeds
 *   drop        the magazine out
 *   insert      the magazine in, seated; insertLoose: in, not seated
 *   clear       fingers or a tool in the chamber, bolt locked: rounds of a double feed come out once the magazine is out, a
 *               stuck case is pried out
 *   sweep       a stovepipe case swept out of the port: the bolt runs forward and feeds
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon class <STRING>
 * 2: Action <STRING>
 *
 * Return Value:
 * [what happened as a stringtable key without its STR_mhwm_malfunctions_ prefix <STRING>, weapon works again <BOOL>]
 *
 * Example:
 * [player, primaryWeapon player, "rack"] call mhwm_malfunctions_fnc_act;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_action", "", [""]]];

private _state = [_unit, _weapon] call FUNC(state);

if (count _state == 0) exitWith {["", true]};

private _bolt = _state get "bolt";
private _chamber = _state get "chamber";
private _port = _state get "port";
private _mag = _state get "mag";
private _ammo = _unit ammo _weapon;
private _result = "";
private _sound = "";

private _fnc_loseRound = {
    if (_ammo > 0) then {
        _ammo = _ammo - 1;
        _unit setAmmo [_weapon, _ammo];
    };
};

// The bolt runs forward: it stops on whatever is wedged in the chamber, else it closes and takes a round along.
private _fnc_forward = {
    if (_chamber in ["double", "case"] || {_port == "stovepipe"}) exitWith {
        _bolt = "short";
    };

    if (_chamber == "empty" && {_mag == "in"} && {_ammo > 0}) then {
        _chamber = "round";
    };

    _bolt = "closed";
};

switch (_action) do {
    case ACT_TAP: {
        _sound = "seat";
        _result = switch (_mag) do {
            case "loose": {_mag = "in"; "Act_TapSeated"};
            case "out": {_sound = ""; "Act_TapNoMag"};
            default {"Act_TapNothing"};
        };
    };

    case ACT_RACK: {
        _sound = "bolt";

        if (_bolt == "locked") exitWith {
            call _fnc_forward;
            _result = ["Act_ReleaseStuck", "Act_Release"] select (_bolt == "closed");
        };

        if (_chamber == "double") exitWith {
            if (_mag == "out") then {
                call _fnc_loseRound;
                _chamber = "empty";
                call _fnc_forward;
                _result = "Act_DoubleShaken";
            } else {
                _result = "Act_RackStuck";
            };
        };

        if (_chamber == "case") exitWith {
            _result = "Act_RackSlips";
        };

        _result = "Act_Rack";

        if (_port == "stovepipe") then {
            _port = "clear";
            _result = "Act_RackStovepipe";
        };

        if (_chamber in ["round", "dud"]) then {
            if (_chamber == "dud") then {_result = "Act_RackDud"};
            call _fnc_loseRound;
            _chamber = "empty";
        };

        call _fnc_forward;

        if (_bolt == "closed" && {_chamber == "empty"}) then {
            _result = ["Act_RackEmpty", "Act_RackNoFeed"] select (_mag != "in" && {_ammo > 0});
        };
    };

    case ACT_SHORT: {
        _sound = "bolt";
        _result = "Act_Short";
    };

    case ACT_LOCK: {
        _sound = "bolt";

        if (_bolt == "locked") exitWith {
            _result = "Act_AlreadyLocked";
        };

        if (_chamber in ["round", "dud"]) then {
            call _fnc_loseRound;
            _chamber = "empty";
        };

        if (_chamber == "double" && {_mag == "out"}) then {
            call _fnc_loseRound;
            _chamber = "empty";
        };

        _port = "clear";
        _bolt = "locked";
        _result = ["Act_Lock", "Act_LockCase"] select (_chamber == "case");
    };

    case ACT_RELEASE: {
        _sound = "bolt";

        if (_bolt != "locked") exitWith {
            _sound = "";
            _result = "Act_NotLocked";
        };

        call _fnc_forward;
        _result = ["Act_ReleaseStuck", "Act_Release"] select (_bolt == "closed");
    };

    case ACT_DROP: {
        if (_mag == "out") exitWith {_result = "Act_NoMag"};

        _mag = "out";
        _sound = "drop_1";
        _result = "Act_Drop";
    };

    case ACT_INSERT;
    case ACT_INSERT_LOOSE: {
        if (_mag != "out") exitWith {_result = "Act_MagThere"};

        _mag = ["in", "loose"] select (_action == ACT_INSERT_LOOSE);
        _sound = "seat";
        _result = ["Act_Insert", "Act_InsertLoose"] select (_action == ACT_INSERT_LOOSE);
    };

    case ACT_CLEAR: {
        if (_bolt != "locked") exitWith {_result = "Act_ClearNeedsLock"};

        _sound = "rattle";

        switch (_chamber) do {
            case "double": {
                if (_mag == "out") then {
                    call _fnc_loseRound;
                    _chamber = "empty";
                    _result = "Act_ClearDouble";
                } else {
                    _sound = "";
                    _result = "Act_ClearMagHolds";
                };
            };
            case "case": {
                _chamber = "empty";
                _result = "Act_ClearCase";
            };
            case "round";
            case "dud": {
                call _fnc_loseRound;
                _chamber = "empty";
                _result = "Act_ClearRound";
            };
            default {
                _sound = "";
                _result = "Act_ClearNothing";
            };
        };
    };

    case ACT_SWEEP: {
        if (_port != "stovepipe") exitWith {_result = "Act_SweepNothing"};

        _port = "clear";
        _sound = "click_1";

        if (_bolt == "short") then {
            call _fnc_forward;
        };

        _result = "Act_Sweep";
    };
};

_state set ["bolt", _bolt];
_state set ["chamber", _chamber];
_state set ["port", _port];
_state set ["mag", _mag];

if (_sound isNotEqualTo "") then {
    [_unit, _sound] call FUNC(playSound);
};

private _works = _bolt == "closed" && {_port == "clear"} && {_mag == "in"} && {_chamber == "round" || {_chamber == "empty" && {_ammo == 0}}};

if (_works) then {
    [_unit, _weapon] call FUNC(clear);
} else {
    [_unit, _weapon, _state] call FUNC(state);
};

[_result, _works]
