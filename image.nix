{ config, lib, pkgs, mobile-nixos, utils, ... }:

let
  # fileSystems = lib.filter utils.fsNeededForBoot config.system.build.fileSystems;
  fileSystems = config.fileSystems;
  bootFs = fileSystems."/boot";
  storeFs = fileSystems."/nix/store" or fileSystems."/nix" or fileSystems."/";
  # yield e.g. "nix/store", "/store" or ""
  storeRelPath = builtins.head (builtins.match "^${storeFs.mountPoint}(.+)" "/nix/store");
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
        partitionID = uuidFromFs storeFs;
        partitionUUID = uuidFromFs storeFs;
        # TODO: what's this?
        partitionType = "EBC597D0-2053-4B15-8B64-E0AAC75F4DB1";
        populateCommands =
        let
          closureInfo = buildPackages.closureInfo { rootPaths = config.system.build.toplevel; };
        in
        ''
          mkdir -p ./${storeRelPath}
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
