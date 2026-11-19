// Few settings, each one plain (Mia: too many options). What used to be a slider for experts is a fixed value below.

// The mod's switch, above every topic.
[QGVAR(enabled), "CHECKBOX", [LSTRING(Enabled), LSTRING(Enabled_Desc)], CBA_SETTINGS_CAT, true, 1] call CBA_fnc_addSetting;

// ----- Jamming (server) -----
private _cat = [CBA_SETTINGS_CAT, LLSTRING(Cat_Jamming)];

// Numbers
[QGVAR(rate), "SLIDER", [LSTRING(Rate), LSTRING(Rate_Desc)], _cat, [0, 50, 2, 1], 1] call CBA_fnc_addSetting;
[QGVAR(heatFactor), "SLIDER", [LSTRING(HeatFactor), LSTRING(HeatFactor_Desc)], _cat, [0, 5, 1, 1], 1] call CBA_fnc_addSetting;

// Switches
[QGVAR(handguns), "CHECKBOX", [LSTRING(Handguns), LSTRING(Handguns_Desc)], _cat, true, 1] call CBA_fnc_addSetting;
[QGVAR(ai), "CHECKBOX", [LSTRING(AI), LSTRING(AI_Desc)], _cat, false, 1] call CBA_fnc_addSetting;

// Text boxes
[QGVAR(weaponRates), "EDITBOX", [LSTRING(WeaponRates), LSTRING(WeaponRates_Desc)], _cat, "", 1, {
    EGVAR(malfunctions,weaponRateMap) = nil;
}] call CBA_fnc_addSetting;
[QGVAR(subsonicMags), "EDITBOX", [LSTRING(SubsonicMags), LSTRING(SubsonicMags_Desc)], _cat, "", 1, {
    EGVAR(malfunctions,subsonicCache) = nil;
}] call CBA_fnc_addSetting;

// ----- Clearing (server) -----
_cat = [CBA_SETTINGS_CAT, LLSTRING(Cat_Clearing)];

// Switches
[QGVAR(quickKeys), "CHECKBOX", [LSTRING(QuickKeys), LSTRING(QuickKeys_Desc)], _cat, true, 1] call CBA_fnc_addSetting;
[QGVAR(testKey), "CHECKBOX", [LSTRING(TestKey), LSTRING(TestKey_Desc)], _cat, false, 1] call CBA_fnc_addSetting;

// ----- Fixed -----
// Subsonic rounds in a weapon made for faster ones jam twice as often; drums and casket magazines (60+, no belts) 1.5x.
GVAR(subsonicFactor) = 2;
GVAR(bigMagSize) = 60;
GVAR(bigMagFactor) = 1.5;
// With ACE Overheating loaded this mod decides; heat only raises the rate (heatFactor), ACE's own jams are cleared.
GVAR(aceMode) = 0;
// How often each malfunction is picked, out of 10.
GVAR(weight_feed) = 3;
GVAR(weight_dud) = 2;
GVAR(weight_stovepipe) = 3;
GVAR(weight_double) = 1;
GVAR(weight_extract) = 1;
// The blind Tap-Rack takes about as long as by hand and never fumbles.
GVAR(quickTime) = 1;
GVAR(fumble) = 0;
// The 3D view always shows what is wrong and plays its minigames (buttons only without Picture-in-Picture).
GVAR(minigames) = true;
GVAR(diagnosis) = true;
GVAR(notify) = true;
GVAR(sounds) = true;
