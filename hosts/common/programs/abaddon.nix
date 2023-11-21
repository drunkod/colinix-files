# discord gtk3 client
{ config, lib, pkgs, ... }:
let
  cfg = config.sane.programs.abaddon;
in
{
  sane.programs.abaddon = {
    configOption = with lib; mkOption {
      default = {};
      type = types.submodule {
        options.autostart = mkOption {
          type = types.bool;
          default = true;
        };
      };
    };

    package = pkgs.abaddon.overrideAttrs (upstream: {
      patches = (upstream.patches or []) ++ [
        (pkgs.fetchpatch {
          url = "https://git.uninsane.org/colin/abaddon/commit/eb551f188d34679f75adcbc83cb8d5beb4d19fd6.patch";
          name = ''"view members" default to false'';
          hash = "sha256-9BX8iO86CU1lNrKS1G2BjDR+3IlV9bmhRNTsLrxChwQ=";
        })
        (pkgs.fetchpatch {
          # this makes it so Abaddon reports its app_name in notifications.
          # not 100% necessary; just a nice-to-have. maybe don't rely on it until it's merged upstream.
          # upstream PR: <https://github.com/uowuo/abaddon/pull/247>
          url = "https://git.uninsane.org/colin/abaddon/commit/18cd863fdbb5e6b1e9aaf9394dbd673d51839f30.patch";
          name = "set glib application name";
          hash = "sha256-IFYxf1D8hIsxgZehGd6hL3zJiBkPZfWGm+Faaa5ZFl4=";
        })
      ];
    });

    suggestedPrograms = [ "gnome-keyring" ];

    fs.".config/abaddon/abaddon.ini".symlink.text = ''
      # see abaddon README.md for options.
      # at time of writing:
      # | Setting       | Type    | Default | Description                                                                                      |
      # |[discord]------|---------|---------|--------------------------------------------------------------------------------------------------|
      # | `gateway`     | string  |         | override url for Discord gateway. must be json format and use zlib stream compression            |
      # | `api_base`    | string  |         | override base url for Discord API                                                                |
      # | `memory_db`   | boolean | false   | if true, Discord data will be kept in memory as opposed to on disk                               |
      # | `token`       | string  |         | Discord token used to login, this can be set from the menu                                       |
      # | `prefetch`    | boolean | false   | if true, new messages will cause the avatar and image attachments to be automatically downloaded |
      # | `autoconnect` | boolean | false   | autoconnect to discord                                                                           |
      # |[http]--------|--------|---------|---------------------------------------------------------------------------------------------|
      # | `user_agent` | string |         | sets the user-agent to use in HTTP requests to the Discord API (not including media/images) |
      # | `concurrent` | int    | 20      | how many images can be concurrently retrieved                                               |
      # |[gui}------------------------|---------|---------|----------------------------------------------------------------------------------------------------------------------------|
      # | `member_list_discriminator` | boolean | true    | show user discriminators in the member list                                                                                |
      # | `stock_emojis`              | boolean | true    | allow abaddon to substitute unicode emojis with images from emojis.bin, must be false to allow GTK to render emojis itself |
      # | `custom_emojis`             | boolean | true    | download and use custom Discord emojis                                                                                     |
      # | `css`                       | string  |         | path to the main CSS file                                                                                                  |
      # | `animations`                | boolean | true    | use animated images where available (e.g. server icons, emojis, avatars). false means static images will be used           |
      # | `animated_guild_hover_only` | boolean | true    | only animate guild icons when the guild is being hovered over                                                              |
      # | `owner_crown`               | boolean | true    | show a crown next to the owner                                                                                             |
      # | `unreads`                   | boolean | true    | show unread indicators and mention badges                                                                                  |
      # | `save_state`                | boolean | true    | save the state of the gui (active channels, tabs, expanded channels)                                                       |
      # | `alt_menu`                  | boolean | false   | keep the menu hidden unless revealed with alt key                                                                          |
      # | `hide_to_tray`              | boolean | false   | hide abaddon to the system tray on window close                                                                            |
      # | `show_deleted_indicator`    | boolean | true    | show \[deleted\] indicator next to deleted messages instead of actually deleting the message                               |
      # | `font_scale`                | double  |         | scale font rendering. 1 is unchanged                                                                                       |
      # |[style]------------------|--------|-----------------------------------------------------|
      # | `linkcolor`             | string | color to use for links in messages                  |
      # | `expandercolor`         | string | color to use for the expander in the channel list   |
      # | `nsfwchannelcolor`      | string | color to use for NSFW channels in the channel list  |
      # | `channelcolor`          | string | color to use for SFW channels in the channel list   |
      # | `mentionbadgecolor`     | string | background color for mention badges                 |
      # | `mentionbadgetextcolor` | string | color to use for number displayed on mention badges |
      # | `unreadcolor`           | string | color to use for the unread indicator               |
      # |[notifications]|---------|--------------------------|-------------------------------------------------------------------------------|
      # | `enabled`     | boolean | true (if not on Windows) | Enable desktop notifications                                                  |
      # | `playsound`   | boolean | true                     | Enable notification sounds. Requires ENABLE_NOTIFICATION_SOUNDS=TRUE in CMake |
      # |[voice]--|--------|------------------------------------|------------------------------------------------------------|
      # | `vad`   | string | rnnoise if enabled, gate otherwise | Method used for voice activity detection. Changeable in UI |
      # |[windows]|---------|---------|-------------------------|
      # | `hideconsole` | boolean | true    | Hide console on startup |

      # N.B.: abaddon writes this file itself (and even when i don't change anything internally).
      # it prefers no spaces around the equal sign.
      [discord]
      autoconnect=true

      [notifications]
      # playsound: i manage sounds via swaync
      playsound=false
    '';

    persist.byStore.private = [
      ".cache/abaddon"
    ];

    services.abaddon = {
      description = "unofficial Discord chat client";
      wantedBy = lib.mkIf cfg.config.autostart [ "default.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/abaddon";
        Type = "simple";
        Restart = "always";
        RestartSec = "20s";
      };
    };
  };
}
