# docs: <https://nixos.wiki/wiki/MediaWiki>
{ config, lib, ... }:

{
  sops.secrets."mediawiki_pw" = {
    owner = config.users.users.mediawiki.name;
    sopsFile = ../../../secrets/servo.yaml;
  };
  # # mediawiki wants to serv itself over apache httpd:
  # # that doesn't work because nginx already binds port 80
  # services.httpd.enable = lib.mkForce false;
  # services.httpd.user = "nginx";
  # services.httpd.group = "nginx";

  users.users.mediawiki.uid = config.sane.allocations.mediawiki-uid;

  services.mediawiki.enable = true;
  services.mediawiki.name = "Uninsane Wiki";
  services.mediawiki.passwordFile = config.sops.secrets.mediawiki_pw.path;
  services.mediawiki.extraConfig = ''
    # Disable anonymous editing
    $wgGroupPermissions['*']['edit'] = false;
  '';
  services.mediawiki.virtualHost.listen = [
    {
      ip = "127.0.0.1";
      port = 8013;
      ssl = false;
    }
  ];
  services.mediawiki.virtualHost.hostName = "w.uninsane.org";
  services.mediawiki.virtualHost.adminAddr = "admin+mediawiki@uninsane.org";
  # services.mediawiki.extensions = TODO: wikipedia sync extension?

  # original apache config for MW
  # services.httpd = {
  #   enable = true;
  #   extraModules = [ "proxy_fcgi" ];
  #   virtualHosts.${cfg.virtualHost.hostName} = mkMerge [ cfg.virtualHost {
  #     documentRoot = mkForce "${pkg}/share/mediawiki";
  #     extraConfig = ''
  #       <Directory "${pkg}/share/mediawiki">
  #         <FilesMatch "\.php$">
  #           <If "-f %{REQUEST_FILENAME}">
  #             SetHandler "proxy:unix:${fpm.socket}|fcgi://localhost/"
  #           </If>
  #         </FilesMatch>

  #         Require all granted
  #         DirectoryIndex index.php
  #         AllowOverride All
  #       </Directory>
  #     '' + optionalString (cfg.uploadsDir != null) ''
  #       Alias "/images" "${cfg.uploadsDir}"
  #       <Directory "${cfg.uploadsDir}">
  #         Require all granted
  #       </Directory>
  #     '';
  #   } ];
  # };

}
