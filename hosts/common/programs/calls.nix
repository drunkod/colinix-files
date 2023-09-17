# GNOME calls
# - <https://gitlab.gnome.org/GNOME/calls>
# - both a dialer and a call handler.
# - uses callaudiod dbus package.
#
# initial JMP.chat configuration:
# - message @cheogram.com "reset sip account"  (this is not destructive, despite the name)
# - the bot will reply with auto-generated username/password plus a SIP server endpoint.
#   just copy those into gnome-calls' GUI configurator
# - now gnome-calls can do outbound calls. inbound calls requires more chatting with the help bot
#
# my setup here is still very WIP.
# open questions:
# - can i receive calls even with GUI closed?
#   - e.g. activated by callaudiod?
#   - looks like `gnome-calls --daemon` does that?
{ config, lib, ... }:

{
  sane.programs.calls = {
    persist.private = [
      ".local/share/calls"  # call "records"
      # .local/share/folks  # contacts?
    ];
    suggestedPrograms = [
      "feedbackd"  # needs `phone-incoming-call`, in particular
    ];
  };
  programs.calls = lib.mkIf config.sane.programs.calls.enabled {
    enable = true;
  };
}
