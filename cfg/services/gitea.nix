{ config, pkgs, lib, ... }:

{
  services.gitea.enable = true;
  services.gitea.user = "git";  # default is 'gitea'
  services.gitea.database.type = "postgres";
  services.gitea.database.user = "git";
  services.gitea.appName = "Perfectly Sane Git";
  services.gitea.domain = "git.uninsane.org";
  services.gitea.rootUrl = "https://git.uninsane.org/";
  services.gitea.cookieSecure = true;
  # services.gitea.disableRegistration = true;
}
