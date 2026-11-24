# MH Weapon Malfunctions

Arma 3 mod: weapons jam in five real ways and are cleared by hand - in a 3D view of the weapon with minigames, or blind with Tap-Rack. Works with and without ACE. Requires CBA_A3.

A rebuild from scratch of the idea behind *dzn Extended Jamming* by 10Dozen.

## Malfunctions

| Malfunction | What is seen | Drill |
|---|---|---|
| Failure to feed, loose magazine | Bolt closed, chamber empty, magazine not seated | Tap, rack |
| Failure to feed, weak magazine | Magazine seated but not feeding | Drop, insert a new one, rack |
| Dud | Hammer falls, round does not fire | Wait out a possible hangfire, rack |
| Stovepipe | Spent case caught in the ejection port | Sweep the case out |
| Double feed | Two rounds wedged in the receiver | Lock bolt, drop magazine, pull both rounds out, insert, release |
| Failure to extract | Spent case stuck in the chamber | Lock bolt, drop magazine, work the case loose, insert, release |

## 3D view (Ctrl + Shift + R, ACE self-interaction or action menu)

| Part | Mouse |
|---|---|
| Charging handle / slide | Drag back fully and let go: rack. Part way: short stroke. Hold at the rear until the bar is full: lock open. Click when locked: release |
| Magazine | Click: tap. Drag down: drop. Drag up straight: insert (off the line: not seated) |
| Muzzle (dud) | Hold until the bar is full: wait out a hangfire |
| Ejection port | Swipe out: sweep a stovepipe |
| Chamber (bolt locked) | Hold and wiggle: work a stuck case loose. Drag up: pull a double-fed round out |

Right drag turns the weapon, holding the middle button moves it, the wheel zooms. The side panel is a field notebook: one page per step, the whole sequence as a checklist. "Field manual" in the header shows every minigame on one page (built by `tools/manual/make_manual.py --paa` from the game's renders, `tools/test/run_auto.ps1 -Mission MHWM_Render`).

Without Picture-in-Picture: buttons instead.

## Keys

| Key | |
|---|---|
| Ctrl + R | Blind Tap-Rack: the server sets for each malfunction whether it clears it and how long it takes (default: feed, dud, stovepipe) |
| Ctrl + Shift + R | Open the 3D view |

Ctrl + R is ACE's Check ammo too: while the weapon is jammed the mod holds ACE's ammo hint back, so the key is Tap-Rack.

## Settings

Enable, malfunctions per 1000 rounds, heat factor (ACE), handguns, AI, weapon reliability, more subsonic magazines, allow the blind Tap-Rack, per malfunction: Tap-Rack clears it, Tap-Rack time. Each player: show the field notebook (check box in the 3D view, remembered), show the field manual, show the malfunction notice.

## ACE

With ACE Overheating loaded this mod decides when a weapon jams; ACE's own jams are cleared at once. A hot barrel raises the rate (heat factor).

## Weapon configs

`mhwm_reliability` in a weapon's CfgWeapons class multiplies the rate (0 = never jams). The server's "Weapon reliability" list overrides it.

## Credits

The idea of *dzn Extended Jamming* by 10Dozen - none of its files are used. Magazine sounds from BigSoundBank (CC0), bolt sounds are Arma's own.

## Development

| Command | |
|---|---|
| `hemtt launch` | CBA + ACE |
| `hemtt launch test` | Eden with the test mission |
| `hemtt launch vanilla` | CBA only |
| `tools\test\run_auto.ps1` | Unattended test with ACE: every malfunction cleared through the minigames, pictures per step |
