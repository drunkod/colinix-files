{ config, lib, pkgs, mobile-nixos, utils, ... }:

with lib;
let
  cfg = config.colinsane.image;
in
{
  options = {
    colinsane.image.extraBootFiles = mkOption {
      default = [];
      type = types.listOf types.package;
    };
  };
  config = let
    # return true if super starts with sub
    startsWith = super: sub: (
      (builtins.substring 0 (builtins.stringLength sub) super) == sub
    );
    # return the (string) path to get from `stem` to `path`
    relPath = stem: path: (
      builtins.head (builtins.match "^${stem}(.+)" path)
    );

    fileSystems = config.fileSystems;
    bootFs = fileSystems."/boot";
    nixFs = fileSystems."/nix/store" or fileSystems."/nix" or fileSystems."/";
    # resolves to e.g. "nix/store", "/store" or ""
    storeRelPath = relPath nixFs.mountPoint "/nix/store";

    # return a list of all the `device` values -- one for each fileSystems."$x"
    devices = builtins.attrValues (builtins.mapAttrs (mount: entry: entry.device) fileSystems);
    # filter the devices to just those which sit under nixFs
    subNixMounts = builtins.filter (a: startsWith (builtins.toString a) nixFs.mountPoint) devices;
    # e.g. ["/nix/persist/var"] -> ["/persist/var"] if nixFs sits at /nix
    subNixRelMounts = builtins.map (m: relPath nixFs.mountPoint m) subNixMounts;
    makeSubNixMounts = builtins.toString (builtins.map (m: "mkdir -p ./${m};") subNixRelMounts);

    uuidFromFs = fs: builtins.head (builtins.match "/dev/disk/by-uuid/(.+)" fs.device);
    vfatUuidFromFs = fs: builtins.replaceStrings ["-"] [""] (uuidFromFs fs);

    fsBuilderMapBoot = {
      "vfat" = pkgs.imageBuilder.fileSystem.makeESP;
    };
    fsBuilderMapNix = {
      "ext4" = pkgs.imageBuilder.fileSystem.makeExt4;
      "btrfs" = pkgs.imageBuilder.fileSystem.makeBtrfs;
    };
  in {
    system.build.img-without-firmware = with pkgs; imageBuilder.diskImage.makeGPT {
      name = "nixos";
      diskID = vfatUuidFromFs bootFs;
      # leave some space for firmware
      # TODO: we'd prefer to turn this into a protected firmware partition, rather than reserving space in the GPT header itself
      # Tow-Boot manages to do that; not sure how.
      # TODO: does this method work on all systems (test on lappy)
      headerHole = imageBuilder.size.MiB 16;
      partitions = [
        (fsBuilderMapBoot."${bootFs.fsType}" {
          # fs properties
          name = "ESP";
          partitionID = vfatUuidFromFs bootFs;
          # partition properties
          partitionLabel = "EFI System";
          partitionUUID = "44444444-4444-4444-4444-4444${vfatUuidFromFs bootFs}";
          size = imageBuilder.size.MiB 256;

          populateCommands = let
            extras = builtins.toString (builtins.map (d: "cp -R ${d}/* ./") cfg.extraBootFiles);
          in ''
            echo "running installBootLoader"
            ${config.system.build.installBootLoader} ${config.system.build.toplevel} -d .
            echo "ran installBootLoader"
            ${extras}
            echo "copied extraBootFiles"
          '';
        })
        (fsBuilderMapNix."${nixFs.fsType}" {
          # fs properties
          name = "NIXOS_SYSTEM";
          partitionID = uuidFromFs nixFs;
          # partition properties
          partitionLabel = "Linux filesystem";
          partitionUUID = uuidFromFs nixFs;
          populateCommands =
          let
            closureInfo = buildPackages.closureInfo { rootPaths = config.system.build.toplevel; };
          in
          ''
            mkdir -p ./${storeRelPath}
            # TODO: we should either fix up the owners (and perms?), or only create the bare minimum needed for boot (i.e. /var/*)
            ${makeSubNixMounts}
            echo "Copying system closure..."
            while IFS= read -r path; do
              echo "  Copying $path"
              cp -prf "$path" ./${storeRelPath}
            done < "${closureInfo}/store-paths"
            echo "Done copying system closure..."
            cp -v ${closureInfo}/registration ./nix-path-registration
          '';
        })
      ];
    };
    system.build.img = lib.mkDefault config.system.build.img-without-firmware;
  };
}
