# MH Weapon Malfunctions

Arma 3 mod: weapons jam in five real ways and are cleared by hand - in a 3D view of the weapon with minigames, or blind with Tap-Rack. Works with and without ACE. Requires CBA_A3.

A rebuild from scratch of the idea behind *dzn Extended Jamming* by 10Dozen.

## Malfunctions

| Malfunction | What is seen | Drill |
|---|---|---|
| Failure to feed | Bolt closed, chamber empty, magazine often not seated | Tap, rack |
| Dud | Hammer falls, round does not fire | Rack |
| Stovepipe | Spent case caught in the ejection port | Rack, or sweep the case out |
| Double feed | Two rounds wedged in the chamber | Lock bolt, drop magazine, clear chamber, insert, release |
| Failure to extract | Spent case stuck in the chamber | Lock bolt, drop magazine, pry case out, insert, release |

## 3D view (Shift + R, ACE self-interaction or action menu)

| Part | Mouse |
|---|---|
| Charging handle | Drag back fully and let go: rack. Part way: short stroke. Right click at the end: lock open. Click when locked: release |
| Magazine | Click on the ring's beat: tap. Drag down: drop. Drag up straight: insert (off the line: not seated) |
| Ejection port | Swipe out: sweep a stovepipe |
| Chamber (bolt locked) | Hold and wiggle: clear |

Right drag turns the weapon, holding the middle button moves it, the wheel zooms. The side panel is a field notebook: one page per step, the whole sequence as a checklist. "Field manual" in the header shows every minigame on one page (built by `tools/manual/make_manual.py --paa` from the game's renders, `tools/test/run_auto.ps1 -Mission MHWM_Render`).

Without Picture-in-Picture: buttons instead.

## Keys

| Key | |
|---|---|
| Shift + R | Open the 3D view |
| Ctrl + R | Blind Tap-Rack (fixes only the simple malfunctions) |
| Ctrl + Shift + J | Test: malfunction now, the next type each press (singleplayer, editor, admins, or everyone with the server setting) |

## Settings

Enable, malfunctions per 1000 rounds, heat factor (ACE), handguns, AI, weapon reliability, more subsonic magazines, allow the blind Tap-Rack, test key for everyone.

## ACE

With ACE Overheating loaded this mod decides when a weapon jams; ACE's own jams are cleared at once. A hot barrel raises the rate (heat factor).

## Weapon configs

`mhwm_reliability` in a weapon's CfgWeapons class multiplies the rate (0 = never jams). The server's "Weapon reliability" list overrides it.

## Development

| Command | |
|---|---|
| `hemtt launch` | CBA + ACE |
| `hemtt launch test` | Eden with the test mission |
| `hemtt launch vanilla` | CBA only |
| `tools\test\run_auto.ps1` | Unattended test with ACE: every malfunction cleared through the minigames, pictures per step |
