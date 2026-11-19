// Test mission for MH Weapon Malfunctions (hemtt launch test, then "Play Scenario"): a firing range on VR, and every
// variant one click away - in the action menu (mouse wheel) and, with ACE, under Self-Interaction > MHWM Test.
//
// It also listens to the clipboard for the unattended runs: "MHWMCMD:<id>|<code>" runs once, the result comes back as
// "MHWMRES:<id>|<result>".
if (!hasInterface) exitWith {};

MHWMT_say = {systemChat format ["[MHWM Test] %1", _this]};

// A malfunction of the given cause on the weapon in the hands, the old one cleared first; then the bench opens.
MHWMT_jam = {
    params ["_cause", ["_mag", ""]];

    private _unit = player;
    private _weapon = currentWeapon _unit;

    if !(_weapon in [primaryWeapon _unit, handgunWeapon _unit]) exitWith {"Take a rifle or pistol in your hands first." call MHWMT_say};

    [_unit, _weapon, true] call mhwm_malfunctions_fnc_clear;
    [_unit, _weapon, _cause] call mhwm_malfunctions_fnc_jam;

    if (_mag isNotEqualTo "") then {
        private _state = [_unit, _weapon] call mhwm_malfunctions_fnc_state;
        _state set ["mag", _mag];
        [_unit, _weapon, _state] call mhwm_malfunctions_fnc_state;
    };

    format ["%1 on %2 - Ctrl+R: Tap-Rack, Ctrl+Shift+R or the action: the bench.", _this joinString " / ", getText (configFile >> "CfgWeapons" >> _weapon >> "displayName")] call MHWMT_say;
};

MHWMT_weapon = {
    params ["_weapon", "_mag", ["_handgun", false]];

    if (_handgun) then {
        player removeWeapon handgunWeapon player;
        player addWeapon _weapon;
        player addHandgunItem _mag;
    } else {
        player removeWeapon primaryWeapon player;
        player addWeapon _weapon;
        player addPrimaryWeaponItem _mag;
    };

    for "_i" from 1 to 4 do {player addMagazine _mag};
    player selectWeapon _weapon;
    format ["Now: %1", getText (configFile >> "CfgWeapons" >> _weapon >> "displayName")] call MHWMT_say;
};

MHWMT_toggle = {
    params ["_var", "_label"];

    private _value = !(missionNamespace getVariable [_var, false]);
    missionNamespace setVariable [_var, _value];
    format ["%1: %2", _label, ["off", "on"] select _value] call MHWMT_say;
};

// [label, code, group] - the groups become ACE sub-menus; in the action menu they are just in order.
MHWMT_entries = [
    ["Failure to feed (magazine loose)", {["feed", "loose"] call MHWMT_jam}, "Malfunctions"],
    ["Failure to feed (magazine seated)", {["feed", "in"] call MHWMT_jam}, "Malfunctions"],
    ["Dud", {["dud"] call MHWMT_jam}, "Malfunctions"],
    ["Stovepipe", {["stovepipe"] call MHWMT_jam}, "Malfunctions"],
    ["Double feed", {["double"] call MHWMT_jam}, "Malfunctions"],
    ["Failure to extract", {["extract"] call MHWMT_jam}, "Malfunctions"],
    ["Random (server weights)", {[""] call MHWMT_jam}, "Malfunctions"],

    ["Open the 3D bench", {[] call mhwm_workbench_fnc_open}, "Bench"],
    ["Show the field manual on next open", {profileNamespace setVariable ["mhwm_workbench_manualSeen", false]; "Field manual comes up with the next bench." call MHWMT_say}, "Bench"],
    ["Clear the malfunction", {[player, currentWeapon player] call mhwm_malfunctions_fnc_clear}, "Bench"],
    ["Refill magazines", {player setAmmo [currentWeapon player, 1e6]; "Magazine full." call MHWMT_say}, "Bench"],

    ["Toggle: minigames / buttons", {["mhwm_main_minigames", "Minigames"] call MHWMT_toggle}, "Settings"],
    ["Toggle: show what is wrong", {["mhwm_main_diagnosis", "Show what is wrong"] call MHWMT_toggle}, "Settings"],
    ["Toggle: jam often (50 per 1000)", {
        mhwm_main_rate = [50, 2] select (mhwm_main_rate >= 50);
        format ["Malfunctions per 1000 rounds: %1", mhwm_main_rate] call MHWMT_say;
    }, "Settings"],
    ["Toggle: ACE Overheating decides", {
        mhwm_main_aceMode = [1, 0] select (mhwm_main_aceMode == 1);
        format ["With ACE Overheating: %1", ["this mod decides", "ACE decides"] select mhwm_main_aceMode] call MHWMT_say;
    }, "Settings"],
    ["Toggle: quick key fumbles (0 / 50 %)", {
        mhwm_main_fumble = [0.5, 0] select (mhwm_main_fumble >= 0.5);
        format ["Quick key fumble chance: %1 %%", round (mhwm_main_fumble * 100)] call MHWMT_say;
    }, "Settings"],

    ["Weapon: MX (6.5 mm)", {["arifle_MX_F", "30Rnd_65x39_caseless_mag"] call MHWMT_weapon}, "Weapons"],
    ["Weapon: SPAR-16 (5.56, brass)", {["arifle_SPAR_01_blk_F", "30Rnd_556x45_Stanag"] call MHWMT_weapon}, "Weapons"],
    ["Weapon: AKM (7.62)", {["arifle_AKM_F", "30Rnd_762x39_Mag_F"] call MHWMT_weapon}, "Weapons"],
    ["Weapon: Mk200 (LMG, large magazine)", {["LMG_Mk200_F", "200Rnd_65x39_cased_Box"] call MHWMT_weapon}, "Weapons"],
    ["Weapon: Vermin (.45, subsonic)", {["SMG_01_F", "30Rnd_45ACP_Mag_SMG_01"] call MHWMT_weapon}, "Weapons"],
    ["Pistol: P07", {["hgun_P07_F", "16Rnd_9x21_Mag", true] call MHWMT_weapon}, "Weapons"],
    ["Pistol: ACP-C2", {["hgun_ACPC2_F", "9Rnd_45ACP_Mag", true] call MHWMT_weapon}, "Weapons"],

    ["AI: rifleman who jams (watch him clear)", {
        mhwm_main_ai = true;
        mhwm_main_rate = 50;
        private _ai = (createGroup west) createUnit ["B_Soldier_F", player getRelPos [4, 90], [], 0, "NONE"];
        _ai setDir 0;
        _ai doWatch (player getRelPos [40, 0]);
        [_ai] spawn {
            params ["_ai"];
            private _wasJammed = false;
            while {alive _ai} do {
                _ai forceWeaponFire [primaryWeapon _ai, "Single"];
                sleep 0.4;
                private _jammed = count ([_ai, primaryWeapon _ai] call mhwm_malfunctions_fnc_state) > 0;
                if (_jammed && {!_wasJammed}) then {"AI jammed - watch him clear it." call MHWMT_say};
                if (!_jammed && {_wasJammed}) then {"AI cleared his weapon." call MHWMT_say};
                _wasJammed = _jammed;
                if (!_jammed && {_ai ammo primaryWeapon _ai < 2}) then {_ai setAmmo [primaryWeapon _ai, 30]};
            };
        };
        "AI on, rate 50 per 1000: he fires single shots at the targets." call MHWMT_say;
    }, "AI"]
];

[] spawn {
    waitUntil {!isNull player && {time > 0}};

    private _center = [4096, 4096, 0];
    player setPosATL _center;
    player setDir 0;
    player allowDamage false;

    player setUnitLoadout [
        ["arifle_MX_F", "", "", "optic_Aco", ["30Rnd_65x39_caseless_mag", 30], [], ""],
        [],
        ["hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", 16], [], ""],
        ["U_B_CombatUniform_mcam", [["16Rnd_9x21_Mag", 2, 16]]],
        ["V_PlateCarrier1_rgr", [["30Rnd_65x39_caseless_mag", 6, 30]]],
        [],
        "H_HelmetB", "",
        [],
        ["ItemMap", "", "ItemRadio", "ItemCompass", "ItemWatch", ""]
    ];

    for "_i" from -3 to 3 do {
        private _target = "TargetP_Inf_F" createVehicle (_center vectorAdd [_i * 3, 25, 0]);
        _target setDir 180;
    };

    // The action menu: a header line, then every entry.
    player addAction ["<t color='#e0283f'>--- MHWM Test ---</t>", {}, nil, 1.6, false, false];
    {
        _x params ["_label", "_code", "_group"];
        player addAction [format ["<t color='#c8c8c8'>%1: </t>%2", _group, _label], _code, nil, 1.5 - _forEachIndex * 0.01, false, true];
    } forEach MHWMT_entries;

    // ACE: Self-Interaction > MHWM Test > group > entry.
    if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
        private _root = ["MHWMT", "MHWM Test", "", {}, {true}] call ace_interact_menu_fnc_createAction;
        [player, 1, ["ACE_SelfActions"], _root] call ace_interact_menu_fnc_addActionToObject;

        private _groups = [];
        {
            _x params ["_label", "_code", "_group"];

            if !(_group in _groups) then {
                _groups pushBack _group;
                private _sub = ["MHWMT_" + _group, _group, "", {}, {true}] call ace_interact_menu_fnc_createAction;
                [player, 1, ["ACE_SelfActions", "MHWMT"], _sub] call ace_interact_menu_fnc_addActionToObject;
            };

            private _action = [format ["MHWMT_%1", _forEachIndex], _label, "", {call (_this select 2)}, {true}, {}, _code] call ace_interact_menu_fnc_createAction;
            [player, 1, ["ACE_SelfActions", "MHWMT", "MHWMT_" + _group], _action] call ace_interact_menu_fnc_addActionToObject;
        } forEach MHWMT_entries;
    };

    "Mouse wheel or ACE Self-Interaction > MHWM Test." call MHWMT_say;

    // Clipboard remote control for the unattended runs.
    private _last = "";

    while {true} do {
        private _clip = copyFromClipboard;

        if (_clip isNotEqualTo _last && {_clip select [0, 8] == "MHWMCMD:"}) then {
            _last = _clip;

            private _body = _clip select [8];
            private _bar = _body find "|";
            private _id = _body select [0, _bar];
            private _code = _body select [_bar + 1];
            private _result = call compile _code;

            if (isNil "_result") then {_result = "nil"};

            copyToClipboard format ["MHWMRES:%1|%2", _id, _result];
            _last = copyFromClipboard;
        };

        sleep 0.3;
    };
};
