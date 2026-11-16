// The mod's switch, above every topic.
[QGVAR(enabled), "CHECKBOX", [LSTRING(Enabled), LSTRING(Enabled_Desc)], CBA_SETTINGS_CAT, true, 1] call CBA_fnc_addSetting;

// ----- Jamming (server) -----
private _cat = [CBA_SETTINGS_CAT, LLSTRING(Cat_Jamming)];

// Numbers
[QGVAR(rate), "SLIDER", [LSTRING(Rate), LSTRING(Rate_Desc)], _cat, [0, 50, 2, 1], 1] call CBA_fnc_addSetting;
[QGVAR(subsonicFactor), "SLIDER", [LSTRING(SubsonicFactor), LSTRING(SubsonicFactor_Desc)], _cat, [1, 5, 2, 1], 1] call CBA_fnc_addSetting;
[QGVAR(bigMagSize), "SLIDER", [LSTRING(BigMagSize), LSTRING(BigMagSize_Desc)], _cat, [20, 200, 60, 0], 1] call CBA_fnc_addSetting;
[QGVAR(bigMagFactor), "SLIDER", [LSTRING(BigMagFactor), LSTRING(BigMagFactor_Desc)], _cat, [1, 5, 1.5, 1], 1] call CBA_fnc_addSetting;
[QGVAR(heatFactor), "SLIDER", [LSTRING(HeatFactor), LSTRING(HeatFactor_Desc)], _cat, [0, 5, 1, 1], 1] call CBA_fnc_addSetting;

// Switches
[QGVAR(handguns), "CHECKBOX", [LSTRING(Handguns), LSTRING(Handguns_Desc)], _cat, true, 1] call CBA_fnc_addSetting;
[QGVAR(ai), "CHECKBOX", [LSTRING(AI), LSTRING(AI_Desc)], _cat, false, 1] call CBA_fnc_addSetting;

// Lists
[
    QGVAR(aceMode), "LIST", [LSTRING(AceMode), LSTRING(AceMode_Desc)], _cat,
    [[0, 1], [LSTRING(AceMode_Own), LSTRING(AceMode_Ace)], 0], 1
] call CBA_fnc_addSetting;

// Text boxes
[QGVAR(weaponRates), "EDITBOX", [LSTRING(WeaponRates), LSTRING(WeaponRates_Desc)], _cat, "", 1, {
    EGVAR(malfunctions,weaponRateMap) = nil;
}] call CBA_fnc_addSetting;
[QGVAR(subsonicMags), "EDITBOX", [LSTRING(SubsonicMags), LSTRING(SubsonicMags_Desc)], _cat, "", 1, {
    EGVAR(malfunctions,subsonicCache) = nil;
}] call CBA_fnc_addSetting;

// ----- Malfunction types (server): how often each one is picked -----
_cat = [CBA_SETTINGS_CAT, LLSTRING(Cat_Types)];

[QGVAR(weight_feed), "SLIDER", [LSTRING(Weight_Feed), LSTRING(Weight_Feed_Desc)], _cat, [0, 10, 3, 0], 1] call CBA_fnc_addSetting;
[QGVAR(weight_dud), "SLIDER", [LSTRING(Weight_Dud), LSTRING(Weight_Dud_Desc)], _cat, [0, 10, 2, 0], 1] call CBA_fnc_addSetting;
[QGVAR(weight_stovepipe), "SLIDER", [LSTRING(Weight_Stovepipe), LSTRING(Weight_Stovepipe_Desc)], _cat, [0, 10, 3, 0], 1] call CBA_fnc_addSetting;
[QGVAR(weight_double), "SLIDER", [LSTRING(Weight_Double), LSTRING(Weight_Double_Desc)], _cat, [0, 10, 1, 0], 1] call CBA_fnc_addSetting;
[QGVAR(weight_extract), "SLIDER", [LSTRING(Weight_Extract), LSTRING(Weight_Extract_Desc)], _cat, [0, 10, 1, 0], 1] call CBA_fnc_addSetting;

// ----- Clearing (server) -----
_cat = [CBA_SETTINGS_CAT, LLSTRING(Cat_Clearing)];

// Numbers
[QGVAR(quickTime), "SLIDER", [LSTRING(QuickTime), LSTRING(QuickTime_Desc)], _cat, [0.5, 3, 1, 1], 1] call CBA_fnc_addSetting;
[QGVAR(fumble), "SLIDER", [LSTRING(Fumble), LSTRING(Fumble_Desc)], _cat, [0, 0.5, 0.1, 0, true], 1] call CBA_fnc_addSetting;

// Switches
[QGVAR(quickKeys), "CHECKBOX", [LSTRING(QuickKeys), LSTRING(QuickKeys_Desc)], _cat, true, 1] call CBA_fnc_addSetting;
[QGVAR(minigames), "CHECKBOX", [LSTRING(Minigames), LSTRING(Minigames_Desc)], _cat, true, 1] call CBA_fnc_addSetting;
[QGVAR(diagnosis), "CHECKBOX", [LSTRING(Diagnosis), LSTRING(Diagnosis_Desc)], _cat, true, 1] call CBA_fnc_addSetting;

// ----- Player (each player for himself) -----
_cat = [CBA_SETTINGS_CAT, LLSTRING(Cat_Player)];

// Switches
[QGVAR(notify), "CHECKBOX", [LSTRING(Notify), LSTRING(Notify_Desc)], _cat, true, 0] call CBA_fnc_addSetting;
[QGVAR(sounds), "CHECKBOX", [LSTRING(Sounds), LSTRING(Sounds_Desc)], _cat, true, 0] call CBA_fnc_addSetting;
