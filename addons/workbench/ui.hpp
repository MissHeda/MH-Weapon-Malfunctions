// The workbench's controls are made by fnc_open (ctrlCreate) from these classes; the dialog itself starts empty.
class RscText;
class RscPicture;
class RscStructuredText;
class RscButton;
class RscControlsGroupNoScrollbars;

class GVAR(text): RscText {
    font = "RobotoCondensed";
    colorText[] = CFG_TEXT;
    colorBackground[] = {0, 0, 0, 0};
    shadow = 0;
    sizeEx = QUOTE(0.032 * safeZoneH);
};

class GVAR(box): GVAR(text) {
    text = "";
    colorBackground[] = CFG_BASE;
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
        font = "RobotoCondensed";
        color = HEX_TEXT;
        align = "left";
        valign = "top";
        shadow = 0;
        size = 1;
    };
};

class GVAR(button): RscButton {
    font = "PuristaMedium";
    sizeEx = QUOTE(0.028 * safeZoneH);
    shadow = 0;
    colorText[] = CFG_TEXT;
    colorDisabled[] = CFG_DIM;
    colorBackground[] = {0.12, 0.07, 0.08, 1};
    colorBackgroundActive[] = CFG_RED;
    colorBackgroundDisabled[] = {0.08, 0.05, 0.05, 1};
    colorFocused[] = {0.2, 0.09, 0.11, 1};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0, 0, 0};
    offsetPressedX = 0;
    offsetPressedY = 0;
    period = 0;
    periodFocus = 0;
    periodOver = 0;
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
