// The workbench's controls are made by fnc_open (ctrlCreate) from these classes; the dialog itself starts empty. Colours
// come from the theme (fnc_theme) at run time - the player's own Arma colour - so the classes are clear.
class RscText;
class RscPicture;
class RscStructuredText;
class RscButton;
class RscControlsGroupNoScrollbars;

class GVAR(text): RscText {
    font = "PuristaMedium";
    colorText[] = {1, 1, 1, 1};
    colorBackground[] = {0, 0, 0, 0};
    shadow = 0;
    sizeEx = QUOTE(0.03 * safeZoneH);
};

// A flat box in its background colour - a pane's bars (fnc_panel), lines, the dim behind the window.
class GVAR(rect): GVAR(text) {
    text = "";
};

class GVAR(box): GVAR(rect) {};

// A round corner texture stretched over its box (ST_PICTURE), tinted with the pane's colour (fnc_panel).
class GVAR(corner): RscPicture {
    style = 48;
    shadow = 0;
    colorBackground[] = {0, 0, 0, 0};
    colorText[] = {0, 0, 0, 0};
};

class GVAR(picture): RscPicture {
    colorText[] = {1, 1, 1, 1};
    shadow = 0;
};

class GVAR(structured): RscStructuredText {
    colorBackground[] = {0, 0, 0, 0};
    shadow = 0;
    size = QUOTE(0.03 * safeZoneH);
    class Attributes {
        font = "PuristaMedium";
        color = "#ffffff";
        align = "left";
        valign = "top";
        shadow = 0;
        size = 1;
    };
};

// A click area over a drawn button (fnc_button): no look of its own.
class GVAR(click): RscButton {
    text = "";
    shadow = 0;
    colorText[] = {0, 0, 0, 0};
    colorDisabled[] = {0, 0, 0, 0};
    colorBackground[] = {0, 0, 0, 0};
    colorBackgroundActive[] = {0, 0, 0, 0};
    colorBackgroundDisabled[] = {0, 0, 0, 0};
    colorFocused[] = {0, 0, 0, 0};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0, 0, 0};
    offsetPressedX = 0;
    offsetPressedY = 0;
    period = 0;
    periodFocus = 0;
    periodOver = 0;
    soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick", 0.09, 1};
};

class GVAR(group): RscControlsGroupNoScrollbars {};

class GVAR(dialog) {
    idd = IDD_WORKBENCH;
    movingEnable = 0;
    enableSimulation = 1;
    onUnload = QUOTE(call FUNC(close));
    class controlsBackground {};
    class controls {};
};
