#define IDD_WORKBENCH 79420

// The look in config terms (script_macros.hpp has them as arrays for scripts).
#define CFG_TEXT {0.863, 0.863, 0.875, 1}
#define CFG_DIM {0.863, 0.863, 0.875, 0.55}
#define CFG_RED {0.878, 0.157, 0.247, 1}
#define CFG_BASE {0.043, 0.027, 0.031, 0.94}

// The 3D scene (fnc_scene): far off any map and high above the sea, inside a dark sphere of its own, filmed into a render
// target. The engine films a render target with the screen's shape whatever the texture string asks, and wants powers of
// two for the texture's sides - so the picture has the screen's shape and the view's group cuts it to size (learnt in AIO).
#define SCENE_PLACE [-4096, -4096]
#define SCENE_TARGET "mhwm_workbench"
#define SCENE_TEXTURE "#(argb,2048,1024,1)r2t(mhwm_workbench,1.0)"
#define SCENE_FOV 0.35
#define SCENE_ASPECT (getResolution select 4)
// The camera's vertical half-view tangent: its FOV times the profile's own (fovTop), never a fixed 0.75.
#define SCENE_TAN (SCENE_FOV * (((getResolution param [6, 0.75]) max 0.3) min 3))
#define SCENE_LIGHT 28
#define SCENE_LIGHT_REACH [0, 0, 0, 0, 30, 60]
#define SCENE_SPHERE_COLOR "#(argb,8,8,3)color(0.03,0.032,0.035,1)"
#define SCENE_PIP_DISTANCE 300

// How far the parts travel, in metres - the bolt's by the weapon's size (fnc_points).
#define TRAVEL_MAG 0.16
#define TRAVEL_SWEEP 0.07

// The minigames: how far the bolt must come back to count as a full stroke, and from where it is at least a short one;
// how many back-and-forths free a double feed, a stuck case, a round; the tap's window in the ring's beat.
#define RACK_FULL 0.9
#define RACK_SHORT 0.35
#define WIGGLE_DOUBLE 4
#define WIGGLE_CASE 6
#define WIGGLE_ROUND 2
#define TAP_PERIOD 1.1
#define TAP_WINDOW 0.18
#define INSERT_TOLERANCE 0.45
// Held all the way back this long, the bolt locks open (Mia: right click while dragging was too much).
#define LOCK_HOLD 0.7
// A dud held muzzle safe this long before the bolt may come back: no hang fire.
#define WAIT_HOLD 2

// Hotspots on the picture: how near the mouse has to be, their size.
#define HOTSPOT_RADIUS (0.024 * safeZoneH)
#define HOTSPOT_SIZE (0.021 * safeZoneH)
#define TEX_CIRCLE "\A3\ui_f\data\map\markers\military\circle_CA.paa"
#define TEX_DOT "\A3\ui_f\data\map\markers\military\dot_CA.paa"
#define TRACK_DOTS 10

// Where the mouse is - a test mission can stand in for it (mhwm_workbench_testMouse), the game never sets it.
#define MOUSE_POS (missionNamespace getVariable [QGVAR(testMouse), getMousePosition])

// The accent without a colour in the player's profile (AIO's orange), and how bright it must be at least to stand out
// from the dark panes (luminance) - as AIO's fnc_accentColour.
#define ACCENT_FALLBACK [0.84, 0.54, 0.1]
#define ACCENT_MIN_LUMA 0.12
