# geary is a gtk3 email client.
# outstanding issues:
# - it uses webkitgtk_4_1, which is expensive to build.
#   could be upgraded to webkitgtk latest if upgraded to gtk4
#   <https://gitlab.gnome.org/GNOME/geary/-/issues/1212>
{ ... }:
{
  sane.programs."gnome.geary" = {
    persist.byStore.private = [
      # attachments, and email -- contained in a sqlite db
      ".local/share/geary"
      # also `.cache/geary/web-resources`, which tends to stay << 1 MiB
    ];
    fs.".config/geary/account_01/geary.ini".symlink.text = ''
      [Metadata]
      version=1
      status=enabled

      [Account]
      ordinal=2
      label=
      # 14 = "fetch last 14d of mail every time i connect"
      # -1 = "fetch *all* mail"
      prefetch_days=-1
      save_drafts=true
      save_sent=true
      use_signature=false
      signature=
      sender_mailboxes=colin@uninsane.org;
      service_provider=other

      [Folders]
      archive_folder=Archive;
      drafts_folder=
      sent_folder=
      junk_folder=
      trash_folder=

      [Incoming]
      login=colin
      remember_password=true
      host=imap.uninsane.org
      port=993
      transport_security=transport
      credentials=custom

      [Outgoing]
      remember_password=true
      host=mx.uninsane.org
      port=465
      transport_security=transport
      credentials=use-incoming
    '';
  };
}