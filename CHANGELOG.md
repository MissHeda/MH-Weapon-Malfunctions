# Changelog

## 1.0.0
First public release.
- Five real malfunctions: failure to feed (loose or weak magazine), dud with possible hangfire, stovepipe, double feed, stuck case.
- 3D view (Ctrl + Shift + R): turn, move and zoom the weapon and clear it by hand - each malfunction with its own movements.
- Field notebook beside it: the drill step by step, a page per step, the sequence as a checklist. Field manual page with every minigame.
- Blind Tap-Rack on Ctrl + R; the server sets per malfunction whether it clears it and how long it takes.
- Works with mod and DLC weapons (RHS, MCC tested), ACE Overheating and without ACE. AI clears its own weapons.
- Mouse wheel no longer scrolls the 3D view's picture under its marks (0.2.16); belt-fed weapons keep their own box (0.2.14).

## 0.2.13
- Mod and DLC weapons in the 3D view: framed by the model's real shape (as AIO does), not its proxy-blown box - the DMR-03's and LMG-03's magazine mark lay 1.9 m under the weapon.
- Magazine slots found in any case and in the first LOD that has them (MCC's weapons); rifles without a magazine slot get the magazine model in the well.
- Pistol magazine mark at the grip's base.

## 0.2.9
- Tap-Rack on Ctrl + R; while the weapon is jammed it takes over ACE's Check ammo (its hint is held back). The 3D view: Ctrl + Shift + R.
- One label at a time in the 3D view.
- Field notes check box under the view, its state remembered; the setting "Field notebook" off removes notebook and check box.
- Sounds: the bolt pulled back, and a snap when it goes home.
- Zoomed out, only the part nearest the mouse lights up.
- Player settings: field notebook, show the field manual.
- Server settings per malfunction: whether Tap-Rack clears it (default: feed, dud, stovepipe) and how long it takes.
- Test key (Ctrl + Shift + J) and its setting removed; the field manual no longer mentions it.

## 0.2.0
- Leaner: 9 settings instead of 30 and 3 keys instead of 8 (open, Tap-Rack, test). Malfunction weights, magazine and subsonic factors, quick key time and fumbles, minigames, diagnosis, notes and sounds are fixed now; with ACE Overheating this mod always decides.
- The side panel is a spiral field notebook: a page per step with its picture taped in, the sequence as a checklist, paged with the tabs at the bottom.
- The status chip in the header is gone; rings and labels in the 3D view shrink when zoomed out.
- RHS and other weapons: the orange slot placeholders of the model are hidden.

## 0.1.6
- The bench's side panel is a page of printed field notes, as the field manual: yellowed paper, ink caption boxes with number discs, red print; the buttons are caption boxes too.
- The hint line under the 3D view stays on one line (it shrinks to fit instead of breaking).
- Test mission (hemtt launch test): every malfunction variant, weapon and setting in the mouse wheel menu and under ACE Self-Interaction > MHWM Test.

## 0.1.5
- Field manual: one page in the style of an old army maintenance comic shows how every minigame is played - "Field manual" in the bench's header, comes up by itself the first time.
- Middle mouse button moves the weapon in the 3D view, a double click puts it back.
- The bench shows the weapon large: its picture and name in the header, the magazine and its rounds as a readout over the view.
- A stovepipe's case leans out of the ejection port instead of standing upright, and tips out further as it is swept.

## 0.1.4
- 3D view in the AIO Glass look: round-cornered dark panes, the accent follows the player's own Arma colour (Options > Game > Colors), sight brackets, monospace readouts, numbered sections, status chip.
- Test key (Ctrl + Shift + J): the weapon in the hands malfunctions at once, the next type each press. Singleplayer, editor, admins - or everyone with the server setting "Allow the test key for everyone".

## 0.1.3
- Fix: the magazine did not move while being dragged out in the 3D view.
- Fix: labels of parts close together overlapped; they now move aside next to their mark.
- The charging handle's mark sits at the ejection port on rifles; handguns show "Slide" at the slide's rear.

## 0.1.1
- First version: five malfunctions, 3D view with minigames, quick keys, ACE Overheating hand-over, AI clears its weapons itself.
