{ sane-lib, ... }:
{
  sane.gui.sxmo = {
    settings = {
      # touch screen
      SXMO_LISGD_INPUT_DEVICE = "/dev/input/by-path/platform-1c2ac00.i2c-event";
      # vol and power are detected correctly by upstream

      # preferences
      # N.B. some deviceprofiles explicitly set SXMO_SWAY_SCALE, overwriting what we put here.
      SXMO_SWAY_SCALE = "1.5";
      SXMO_ROTATION_GRAVITY = "12800";
      DEFAULT_COUNTRY = "US";
      BROWSWER = "librewolf";
    };
  };
}
