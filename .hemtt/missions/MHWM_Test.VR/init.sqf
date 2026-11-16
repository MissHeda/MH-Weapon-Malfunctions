// Test mission for MH Weapon Malfunctions: a soldier with an MX and a P07 on the VR map, targets in front.
//
// Driven from outside through the clipboard: every new "MHWMCMD:<id>|<code>" on the clipboard is run once; what the code
// returns comes back as "MHWMRES:<id>|<result>". Only in singleplayer (Eden "Play Scenario").
if (!hasInterface) exitWith {};

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

    for "_i" from -2 to 2 do {
        private _target = "TargetP_Inf_F" createVehicle (_center vectorAdd [_i * 3, 25, 0]);
        _target setDir 180;
    };

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
