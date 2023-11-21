# discord gtk3 client
{ lib, pkgs, ... }:
{
  sane.programs.abaddon = {
    # nixpkgs marks this explicitly as x86_64-only.
    # but i can build it for aarch64 here.
    # the only x86_64 runtime dependency is gnum4, via gtkmm (likely unused; build remnant).
    # see upstream nixpkgs PR: <https://github.com/NixOS/nixpkgs/pull/268433>
    package = pkgs.abaddon.overrideAttrs (upstream: {
      meta = upstream.meta // {
        platforms = lib.platforms.linux;
      };
    });

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
  };
}
