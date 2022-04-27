{ config, pkgs, lib, ... }:

{
  #services.postfix.enable = true;
  services.postfix.hostname = "mx.uninsane.org";
}
