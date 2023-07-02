{ config, lib, pkgs }:
let
  cfg = config.sane.gui.gtk;
  themes = {
    inherit (pkgs)
      # themes are in <repo:nixos/nixpkgs:pkgs/data/themes>
      adapta-gtk-theme
      adapta-kde-theme
      adementary-theme
      adi1090x-plymouth-themes
      adw-gtk3
      adwaita-qt
      adwaita-qt6
      albatross
      amarena-theme
      amber-theme
      ant-bloody-theme
      ant-nebula-theme
      ant-theme
      arc-kde-theme
      arc-theme
      artim-dark
      ayu-theme-gtk
      base16-schemes
      blackbird
      breath-theme
      canta-theme
      catppuccin-gtk
      catppuccin-kde
      catppuccin-kvantum
      catppuccin-plymouth
      clearlooks-phenix
      colloid-gtk-theme
      colloid-kde
      dracula-theme
      e17gtk
      equilux-theme
      flat-remix-gnome
      flat-remix-gtk
      fluent-gtk-theme
      graphite-gtk-theme
      graphite-kde-theme
      greybird
      gruvbox-dark-gtk
      gruvbox-gtk-theme
      gruvterial-theme
      juno-theme
      kde-gruvbox
      kde-rounded-corners
      layan-gtk-theme
      layan-kde
      lightly-boehs
      lightly-qt
      lounge-gtk-theme
      marwaita
      marwaita-manjaro
      marwaita-peppermint
      marwaita-pop_os
      marwaita-ubuntu
      matcha-gtk-theme
      materia-kde-theme
      materia-theme
      material-kwin-decoration
      mojave-gtk-theme
      nixos-bgrt-plymouth
      nordic
      numix-gtk-theme
      numix-solarized-gtk-theme
      numix-sx-gtk-theme
      oceanic-theme
      omni-gtk-theme
      onestepback
      openzone-cursors
      orchis-theme
      orion
      palenight-theme
      paper-gtk-theme
      pitch-black
      plano-theme
      plasma-overdose-kde-theme
      plata-theme
      pop-gtk-theme
      qogir-kde
      qogir-theme
      rose-pine-gtk-theme
      shades-of-gray-theme
      sierra-breeze-enhanced
      sierra-gtk-theme
      skeu
      snowblind
      solarc-gtk-theme
      spacx-gtk-theme
      stilo-themes
      sweet
      sweet-nova
      theme-jade1
      theme-obsidian2
      theme-vertex
      tokyo-night-gtk
      ubuntu-themes
      venta
      vimix-gtk-themes
      whitesur-gtk-theme
      yaru-remix-theme
      yaru-theme
      zuki-themes
    ;
  };
in
{
  options = with lib; {
    sane.gui.gtk.enable = mkOption {
      default = false;
      type = types.bool;
      description = "apply theme to gtk4 apps";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dconf.packages = [
      (pkgs.writeTextFile {
        name = "dconf-sway-settings";
        destination = "/etc/dconf/db/site.d/10_sway_settings";
        text = ''
          [org/gnome/desktop/interface]
          gtk-theme="Dracula"
          icon-theme="Dracula"
        '';
      })
    ];
    environment.systemPackages = lib.attrValues themes;
  };
}
