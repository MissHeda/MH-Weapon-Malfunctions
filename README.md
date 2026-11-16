# MH Weapon Malfunctions

Arma 3 mod: weapons jam in five real ways and are cleared by hand - in a 3D view of the weapon with minigames, or blind with quick keys. Works with and without ACE. Requires CBA_A3.

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

Server setting "Minigames in the 3D view" off, or Picture-in-Picture off: buttons instead.

## Quick keys

Tap-Rack (Ctrl + R), and unbound: tap, rack, lock/release, drop/insert, clear chamber. Server sets time and fumble chance.

## ACE

With ACE Overheating loaded, the server chooses who decides when a weapon jams: this mod (ACE's jams are cleared at once) or ACE Overheating (heat, its chance - each ACE jam becomes a malfunction of this mod). A hot barrel can raise this mod's rate.

## Weapon configs

`mhwm_reliability` in a weapon's CfgWeapons class multiplies the rate (0 = never jams). The server's "Weapon reliability" list overrides it.

## Development

| Command | |
|---|---|
| `hemtt launch` | CBA + ACE |
| `hemtt launch test` | Eden with the test mission |
| `hemtt launch vanilla` | CBA only |
| `tools\test\run_auto.ps1` | Unattended test with ACE: every malfunction cleared through the minigames, pictures per step |
