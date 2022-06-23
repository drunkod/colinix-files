{ config, lib, pkgs, mobile-nixos, utils, ... }:

let
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
in
{
  system.build.img-without-firmware = with pkgs; imageBuilder.diskImage.makeGPT {
    name = "nixos";
    diskID = "01234567";
    # headerHole = imageBuilder.size.MiB 16;
    partitions = [
      (imageBuilder.fileSystem.makeESP {
        name = "ESP";
        partitionLabel = "ESP";
        partitionID = vfatUuidFromFs bootFs;
        # TODO: should this even have a part uuid?
        partitionUUID = "CFB21B5C-A580-DE40-940F-B9644B4466E3";
        size = imageBuilder.size.MiB 256;

        populateCommands = ''
          echo "running installBootLoader"
          ${config.system.build.installBootLoader} ${config.system.build.toplevel} -d .
          echo "ran installBootLoader"
        '';
      })
      # TODO: make format-aware
      (imageBuilder.fileSystem.makeExt4 {
        name = "NIXOS_SYSTEM";
        partitionLabel = "NIXOS_SYSTEM";
        partitionID = uuidFromFs nixFs;
        partitionUUID = uuidFromFs nixFs;
        # TODO: what's this?
        partitionType = "EBC597D0-2053-4B15-8B64-E0AAC75F4DB1";
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
  # TODO: pinephone build:
  # system.build.img = pkgs.runCommandNoCC "nixos_full-disk-image.img" {} ''
  #   cp -v ${config.system.build.without-bootloader}/nixos.img $out
  #   chmod +w $out
  #   dd if=${pkgs.tow-boot-pinephone}/Tow-Boot.noenv.bin of=$out bs=1024 seek=8 conv=notrunc
  # '';
}
